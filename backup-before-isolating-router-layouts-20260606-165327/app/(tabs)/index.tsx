import { Feather } from "@expo/vector-icons";
import { FlashList } from "@shopify/flash-list";
import * as Haptics from "expo-haptics";
import { memo, useCallback, useEffect, useMemo, useRef, useState } from "react";
import {
  ActivityIndicator,
  Platform,
  Pressable,
  StyleSheet,
  Text,
  TextInput,
  View,
} from "react-native";
import { KeyboardAvoidingView } from "react-native-keyboard-controller";
import { useSafeAreaInsets } from "react-native-safe-area-context";

import { useRouter } from "expo-router";
import { safeNavigate } from "../../lib/safeNavigate";

import { useColors, type Colors } from "../../hooks/useColors";
import { useMeshTransport } from "../../lib/mesh/useMeshTransport";
import { useMeshStore, type ChatMessage } from "../../lib/store/meshStore";
import { getOrCreateNodeId } from "../../lib/mesh/deviceIdentity";
import { IncomingCallBanner } from "../../src/components/ui/IncomingCallBanner";
import { NetworkLoadingVideo } from "../../components/NetworkLoadingVideo";
import {
  loadMeshMessages,
  saveMeshMessage,
  storedToChatMessage,
  chatMessageToStored,
} from "../../lib/mesh/meshMessageStore";

const TARGET_NODE_ID = "BROADCAST";

// ── MessageItem — memoised so FlashList doesn't re-render unchanged rows ──────

interface MessageItemProps {
  msg: ChatMessage;
  colors: Colors;
  styles: ReturnType<typeof makeStyles>;
}

const MessageItem = memo(function MessageItem({
  msg,
  colors,
  styles,
}: MessageItemProps) {
  const isMe = msg.sender === "me";
  return (
    <View style={[styles.msgRow, isMe ? styles.msgRowMe : styles.msgRowOther]}>
      <View
        style={[styles.bubble, isMe ? styles.bubbleMe : styles.bubbleOther]}
      >
        {!isMe && msg.senderId ? (
          <Text style={styles.senderId}>{msg.senderId.toUpperCase()}</Text>
        ) : null}
        <Text
          style={[
            styles.msgText,
            isMe ? styles.msgTextMe : styles.msgTextOther,
          ]}
        >
          {msg.text}
        </Text>
      </View>
      <View style={styles.msgMeta}>
        <Text style={styles.timestamp}>{msg.timestamp}</Text>
        {msg.transport === "ble" && !isMe ? (
          <Feather name="bluetooth" size={9} color={colors.primary} />
        ) : null}
        {isMe ? (
          msg.status === "read" ? (
            // Double-check indicator (accent colour) — distinct from "delivered"
            <View style={styles.doubleCheck}>
              <Feather name="check" size={10} color={colors.primary} />
              <Feather
                name="check"
                size={10}
                color={colors.primary}
                style={styles.doubleCheckSecond}
              />
            </View>
          ) : (
            <Feather
              name={
                msg.status === "delivered"
                  ? "check-circle"
                  : msg.status === "queued"
                  ? "clock"
                  : "check"
              }
              size={10}
              color={colors.mutedForeground}
            />
          )
        ) : null}
      </View>
    </View>
  );
});

// ── Screen ────────────────────────────────────────────────────────────────────

export default function MessengerScreen() {
  const [myNodeId, setMyNodeId] = useState<string | null>(null);

  useEffect(() => {
    getOrCreateNodeId().then(setMyNodeId);
  }, []);

  if (!myNodeId) {
    return (
      <View style={{ flex: 1, alignItems: "center", justifyContent: "center" }}>
        <ActivityIndicator />
      </View>
    );
  }

  return <MessengerContent myNodeId={myNodeId} />;
}

function MessengerContent({ myNodeId }: { myNodeId: string }) {
  const colors = useColors();
  const insets = useSafeAreaInsets();
  const router = useRouter();

  const [inputValue, setInputValue] = useState("");
  const [isSending, setIsSending] = useState(false);
  const inputRef = useRef<TextInput>(null);

  // Read state from Zustand store (single source of truth)
  const messages = useMeshStore((s) => s.messages);
  const peers = useMeshStore((s) => s.peers);
  const transportStatus = useMeshStore((s) => s.transportStatus);
  const addMessage = useMeshStore((s) => s.addMessage);
  const updateMessageStatus = useMeshStore((s) => s.updateMessageStatus);
  const markMessageRead = useMeshStore((s) => s.markMessageRead);
  const incomingCall = useMeshStore((s) => s.incomingCall);
  const setIncomingCall = useMeshStore((s) => s.setIncomingCall);
  const hydrateMessages = useMeshStore((s) => s.hydrateMessages);

  // Hydrate store from AsyncStorage on mount
  useEffect(() => {
    loadMeshMessages().then((stored) => {
      const chatMsgs = stored.map((s) => storedToChatMessage(s, myNodeId));
      hydrateMessages(chatMsgs);
    });
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [myNodeId]);

  const { sendMessage, sendReadAck, sendCallInvite } = useMeshTransport(myNodeId);

  const { bleReady, bridgeOnline, queueSize } = transportStatus;
  const nodeCount = peers.length;
  const isError = !bleReady && !bridgeOnline;
  const topInset = Platform.OS === "web" ? 67 : insets.top;
  const bottomInset = Platform.OS === "web" ? 34 : insets.bottom;
  // Memoize styles so the object reference only changes when theme or insets
  // change — prevents FlashList from re-rendering memoized rows on unrelated
  // state updates (e.g., typing, peer list refresh).
  const styles = useMemo(() => makeStyles(colors, bottomInset), [colors, bottomInset]);

  const statusLabel = bleReady
    ? `BLE · ${nodeCount} peer${nodeCount !== 1 ? "s" : ""}`
    : bridgeOnline
    ? "Bridge"
    : queueSize > 0
    ? `Offline · ${queueSize} queued`
    : "Offline";

  // ── Send ───────────────────────────────────────────────────────────────────

  const handleSend = useCallback(async () => {
    const text = inputValue.trim();
    if (!text || isSending) return;
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);

    const id = `${Date.now()}${Math.random().toString(36).slice(2, 8)}`;
    const now = Date.now();
    const msg: ChatMessage = {
      id,
      text,
      sender: "me",
      timestamp: new Date(now).toLocaleTimeString([], {
        hour: "2-digit",
        minute: "2-digit",
      }),
      timeMs: now,
      status: "queued",
      read: false,
    };
    addMessage(msg);
    saveMeshMessage({ ...chatMessageToStored(msg, myNodeId), status: "queued" }).catch(() => {});
    setInputValue("");
    setIsSending(true);

    try {
      // sendMessage now manages all status transitions internally:
      //   queued → sending → sent (BLE/bridge)
      //   queued → sending → queued (no path, enqueued for retry)
      // ACK receipt from peer drives: sent → ack_confirmed
      await sendMessage(text, TARGET_NODE_ID, id);
    } catch {
      // Unexpected error — message stays queued and will be retried from queue
    } finally {
      setIsSending(false);
    }
  }, [inputValue, isSending, addMessage, sendMessage, updateMessageStatus]);

  // ── Call invite ────────────────────────────────────────────────────────────

  const handleCall = useCallback(async () => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    const callId = `call_${Date.now()}`;
    const now = Date.now();
    // Add a local bubble immediately so the caller sees feedback.
    addMessage({
      id: callId,
      text: "📞 Initiating audio call…",
      sender: "me",
      timestamp: new Date(now).toLocaleTimeString([], {
        hour: "2-digit",
        minute: "2-digit",
      }),
      timeMs: now,
      status: "sent",
      read: false,
    });
    // Send a true CALL_INVITE packet (priority 7) — higher than chat traffic
    // so it jumps the relay queue and reaches the recipient as fast as possible.
    await sendCallInvite(callId, "audio", TARGET_NODE_ID);
  }, [addMessage, sendCallInvite]);

  // ── READ_ACK on visible items ─────────────────────────────────────────────

  const onViewableItemsChanged = useCallback(
    ({ viewableItems }: { viewableItems: Array<{ item: ChatMessage }> }) => {
      for (const { item } of viewableItems) {
        if (item.sender === "other" && !item.read && item.senderId) {
          markMessageRead(item.id);
          sendReadAck(item.id, item.senderId);
        }
      }
    },
    [markMessageRead, sendReadAck]
  );

  // ── Render helpers ────────────────────────────────────────────────────────

  const renderItem = useCallback(
    ({ item }: { item: ChatMessage }) => (
      <MessageItem msg={item} colors={colors} styles={styles} />
    ),
    [colors, styles]
  );

  const keyExtractor = useCallback((item: ChatMessage) => item.id, []);

  return (
    <View style={[styles.container, { paddingTop: topInset }]}>
      {/* Network connect video — morphs out once BLE or bridge is ready */}
      <NetworkLoadingVideo connected={bleReady || bridgeOnline} />

      {/* Incoming call overlay */}
      {incomingCall ? (
        <IncomingCallBanner
          call={incomingCall}
          onAccept={() => setIncomingCall(null)}
          onDecline={() => setIncomingCall(null)}
        />
      ) : null}

      {/* Header */}
      <View style={styles.header}>
        <View style={styles.headerLeft}>
          <View style={styles.avatarContainer}>
            <View style={styles.avatar}>
              <Feather name="radio" size={20} color={colors.primary} />
            </View>
            <View
              style={[
                styles.statusDot,
                {
                  backgroundColor: isError
                    ? colors.destructive
                    : bleReady
                    ? colors.primary
                    : "#f59e0b",
                },
              ]}
            />
          </View>
          <View>
            <Text style={styles.headerTitle}>MauriMesh Network</Text>
            <View style={styles.statusRow}>
              {isError ? (
                <>
                  <Feather
                    name="wifi-off"
                    size={10}
                    color={colors.destructive}
                  />
                  <Text
                    style={[
                      styles.statusText,
                      { color: colors.destructive },
                    ]}
                  >
                    {" "}
                    Connection Lost
                  </Text>
                </>
              ) : (
                <>
                  <View
                    style={[
                      styles.pulseDot,
                      {
                        backgroundColor: bleReady
                          ? colors.primary
                          : "#f59e0b",
                      },
                    ]}
                  />
                  <Text
                    style={[
                      styles.statusText,
                      { color: bleReady ? colors.primary : "#f59e0b" },
                    ]}
                  >
                    {" "}
                    {statusLabel}
                  </Text>
                </>
              )}
            </View>
          </View>
        </View>
        <View style={styles.headerActions}>
          <Pressable
            style={({ pressed }) => [
              styles.iconBtn,
              pressed && styles.iconBtnPressed,
            ]}
            onPress={() => safeNavigate(router, "/add-friend")}
            testID="button-add-friend"
          >
            <Feather name="user-plus" size={20} color={colors.mutedForeground} />
          </Pressable>
          <Pressable
            style={({ pressed }) => [
              styles.iconBtn,
              pressed && styles.iconBtnPressed,
            ]}
            onPress={handleCall}
            testID="button-call"
          >
            <Feather name="phone" size={20} color={colors.mutedForeground} />
          </Pressable>
          <Pressable
            style={({ pressed }) => [
              styles.iconBtn,
              pressed && styles.iconBtnPressed,
            ]}
            onPress={() => safeNavigate(router, "/device-proof")}
            testID="button-device-proof"
          >
            <Feather name="cpu" size={20} color={colors.mutedForeground} />
          </Pressable>
          <Pressable
            style={({ pressed }) => [
              styles.iconBtn,
              pressed && styles.iconBtnPressed,
            ]}
            onPress={() => safeNavigate(router, "/(tabs)/settings")}
            testID="button-settings"
          >
            <Feather
              name="more-vertical"
              size={20}
              color={colors.mutedForeground}
            />
          </Pressable>
        </View>
      </View>

      {/* Messages + Input */}
      <KeyboardAvoidingView
        style={styles.flex}
        behavior="padding"
        keyboardVerticalOffset={0}
      >
        <FlashList
          data={messages}
          keyExtractor={keyExtractor}
          renderItem={renderItem}
          estimatedItemSize={72}
          inverted
          contentContainerStyle={styles.listContent}
          keyboardDismissMode="interactive"
          keyboardShouldPersistTaps="handled"
          showsVerticalScrollIndicator={false}
          onViewableItemsChanged={onViewableItemsChanged}
          viewabilityConfig={{ itemVisiblePercentThreshold: 50 }}
          ListEmptyComponent={
            <View style={styles.emptyState}>
              <Feather
                name="message-circle"
                size={40}
                color={colors.mutedForeground}
              />
              <Text style={styles.emptyText}>No messages yet</Text>
              <Text style={styles.emptySubText}>
                Send a message over the mesh
              </Text>
            </View>
          }
        />

        {/* Input Area */}
        <View style={[styles.inputArea, { paddingBottom: bottomInset + 8 }]}>
          <View style={styles.inputRow}>
            <Pressable style={styles.inputIcon}>
              <Feather name="image" size={20} color={colors.mutedForeground} />
            </Pressable>
            <TextInput
              ref={inputRef}
              value={inputValue}
              onChangeText={setInputValue}
              placeholder="Secure message…"
              placeholderTextColor={colors.mutedForeground}
              style={styles.textInput}
              multiline
              maxLength={2000}
              returnKeyType="send"
              onSubmitEditing={handleSend}
              testID="input-message"
            />
            {!inputValue.trim() ? (
              <Pressable style={styles.inputIcon}>
                <Feather name="mic" size={20} color={colors.mutedForeground} />
              </Pressable>
            ) : null}
          </View>
          {inputValue.trim() ? (
            <Pressable
              style={({ pressed }) => [
                styles.sendBtn,
                pressed && styles.sendBtnPressed,
              ]}
              onPress={handleSend}
              disabled={isSending}
              testID="button-send"
            >
              {isSending ? (
                <ActivityIndicator
                  size="small"
                  color={colors.primaryForeground}
                />
              ) : (
                <Feather
                  name="send"
                  size={18}
                  color={colors.primaryForeground}
                />
              )}
            </Pressable>
          ) : null}
        </View>
      </KeyboardAvoidingView>
    </View>
  );
}

function makeStyles(colors: Colors, bottomInset: number) {
  return StyleSheet.create({
    container: {
      flex: 1,
      backgroundColor: colors.background,
    },
    flex: {
      flex: 1,
    },
    header: {
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "space-between",
      paddingHorizontal: 16,
      paddingBottom: 12,
      paddingTop: 8,
      backgroundColor: colors.background + "cc",
      borderBottomWidth: StyleSheet.hairlineWidth,
      borderBottomColor: colors.border,
    },
    headerLeft: {
      flexDirection: "row",
      alignItems: "center",
      gap: 12,
    },
    avatarContainer: {
      position: "relative",
    },
    avatar: {
      width: 40,
      height: 40,
      borderRadius: 20,
      backgroundColor: colors.secondary,
      borderWidth: 2,
      borderColor: colors.primary + "33",
      alignItems: "center",
      justifyContent: "center",
    },
    statusDot: {
      position: "absolute",
      bottom: 0,
      right: 0,
      width: 12,
      height: 12,
      borderRadius: 6,
      borderWidth: 2,
      borderColor: colors.background,
    },
    headerTitle: {
      fontSize: 14,
      fontWeight: "600" as const,
      color: colors.foreground,
      fontFamily: "Inter_600SemiBold",
      letterSpacing: -0.3,
    },
    statusRow: {
      flexDirection: "row",
      alignItems: "center",
      gap: 4,
      marginTop: 2,
    },
    pulseDot: {
      width: 6,
      height: 6,
      borderRadius: 3,
    },
    statusText: {
      fontSize: 11,
      fontFamily: "Inter_400Regular",
    },
    headerActions: {
      flexDirection: "row",
      alignItems: "center",
    },
    iconBtn: {
      width: 40,
      height: 40,
      borderRadius: 20,
      alignItems: "center",
      justifyContent: "center",
    },
    iconBtnPressed: {
      opacity: 0.6,
    },
    listContent: {
      paddingHorizontal: 16,
      paddingVertical: 12,
    },
    msgRow: {
      maxWidth: "85%",
      marginVertical: 4,
    },
    msgRowMe: {
      alignSelf: "flex-end",
      alignItems: "flex-end",
    },
    msgRowOther: {
      alignSelf: "flex-start",
      alignItems: "flex-start",
    },
    bubble: {
      paddingHorizontal: 14,
      paddingVertical: 10,
      borderRadius: 18,
    },
    bubbleMe: {
      backgroundColor: colors.primary + "1a",
      borderWidth: 1,
      borderColor: colors.primary + "33",
      borderBottomRightRadius: 4,
    },
    bubbleOther: {
      backgroundColor: colors.card,
      borderWidth: 1,
      borderColor: colors.border,
      borderBottomLeftRadius: 4,
    },
    senderId: {
      fontSize: 10,
      fontWeight: "700" as const,
      color: colors.mutedForeground,
      letterSpacing: 1,
      marginBottom: 3,
      fontFamily: "Inter_700Bold",
    },
    msgText: {
      fontSize: 15,
      lineHeight: 22,
      fontFamily: "Inter_400Regular",
    },
    msgTextMe: {
      color: colors.foreground,
    },
    msgTextOther: {
      color: colors.foreground,
    },
    msgMeta: {
      flexDirection: "row",
      alignItems: "center",
      gap: 4,
      marginTop: 3,
      paddingHorizontal: 4,
    },
    timestamp: {
      fontSize: 10,
      color: colors.mutedForeground,
      fontFamily: "Inter_400Regular",
    },
    doubleCheck: {
      flexDirection: "row",
      alignItems: "center",
    },
    doubleCheckSecond: {
      marginLeft: -5,
    },
    emptyState: {
      alignItems: "center",
      justifyContent: "center",
      paddingVertical: 80,
      gap: 8,
    },
    emptyText: {
      fontSize: 16,
      fontWeight: "600" as const,
      color: colors.mutedForeground,
      fontFamily: "Inter_600SemiBold",
    },
    emptySubText: {
      fontSize: 13,
      color: colors.mutedForeground,
      fontFamily: "Inter_400Regular",
      opacity: 0.7,
    },
    inputArea: {
      flexDirection: "row",
      alignItems: "flex-end",
      paddingHorizontal: 12,
      paddingTop: 10,
      borderTopWidth: StyleSheet.hairlineWidth,
      borderTopColor: colors.border,
      backgroundColor: colors.background + "cc",
      gap: 8,
    },
    inputRow: {
      flex: 1,
      flexDirection: "row",
      alignItems: "center",
      backgroundColor: colors.card,
      borderRadius: 24,
      borderWidth: 1,
      borderColor: colors.border,
      paddingHorizontal: 4,
      minHeight: 44,
    },
    inputIcon: {
      width: 40,
      height: 40,
      alignItems: "center",
      justifyContent: "center",
    },
    textInput: {
      flex: 1,
      fontSize: 15,
      color: colors.foreground,
      fontFamily: "Inter_400Regular",
      paddingVertical: 10,
      maxHeight: 120,
    },
    sendBtn: {
      width: 44,
      height: 44,
      borderRadius: 22,
      backgroundColor: colors.primary,
      alignItems: "center",
      justifyContent: "center",
      shadowColor: colors.primary,
      shadowOffset: { width: 0, height: 4 },
      shadowOpacity: 0.3,
      shadowRadius: 8,
      elevation: 4,
    },
    sendBtnPressed: {
      opacity: 0.85,
      transform: [{ scale: 0.95 }],
    },
  });
}
