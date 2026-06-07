import { useRef, useState } from "react";
import {
  FlatList,
  KeyboardAvoidingView,
  Platform,
  Pressable,
  StyleSheet,
  Text,
  TextInput,
  View,
} from "react-native";
import { useRouter } from "expo-router";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import * as Haptics from "expo-haptics";

interface LocalMessage {
  id: string;
  text: string;
  timestamp: string;
}

export default function ChatScreen() {
  const router = useRouter();
  const insets = useSafeAreaInsets();
  const [messages, setMessages] = useState<LocalMessage[]>([]);
  const [inputText, setInputText] = useState("");
  const inputRef = useRef<TextInput>(null);

  function handleSend() {
    const text = inputText.trim();
    if (!text) return;
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    const timestamp = new Date().toLocaleTimeString([], {
      hour: "2-digit",
      minute: "2-digit",
    });
    setMessages((prev) => [{ id: `${Date.now()}`, text, timestamp }, ...prev]);
    setInputText("");
  }

  return (
    <View style={[styles.root, { paddingTop: insets.top }]}>
      {/* Header */}
      <View style={styles.header}>
        <Pressable
          onPress={() => { Haptics.selectionAsync(); router.back(); }}
          style={({ pressed }) => [styles.backBtn, pressed && styles.backBtnPressed]}
        >
          <Text style={styles.backText}>‹</Text>
        </Pressable>
        <View style={{ flex: 1 }}>
          <Text style={styles.headerTitle}>Mesh Chat</Text>
          <View style={styles.statusRow}>
            <View style={styles.statusDot} />
            <Text style={styles.statusLabel}>BLE TRANSPORT PENDING</Text>
          </View>
        </View>
        <View style={styles.broadcastPill}>
          <Text style={styles.broadcastText}>BROADCAST</Text>
        </View>
      </View>

      {/* Pending banner */}
      <View style={styles.banner}>
        <View style={styles.bannerDot} />
        <Text style={styles.bannerText}>
          Messages queue locally until BLE peers are in range
        </Text>
      </View>

      {/* Message list + input */}
      <KeyboardAvoidingView
        style={styles.flex}
        behavior={Platform.OS === "ios" ? "padding" : "height"}
        keyboardVerticalOffset={0}
      >
        <FlatList
          data={messages}
          inverted
          keyExtractor={(item) => item.id}
          contentContainerStyle={styles.listContent}
          showsVerticalScrollIndicator={false}
          keyboardDismissMode="interactive"
          keyboardShouldPersistTaps="handled"
          ListEmptyComponent={
            <View style={styles.empty}>
              <Text style={styles.emptyIcon}>◌</Text>
              <Text style={styles.emptyTitle}>No messages yet</Text>
              <Text style={styles.emptyBody}>
                Type a message below — it will relay over BLE when peers are in range.
              </Text>
            </View>
          }
          renderItem={({ item }) => (
            <View style={styles.bubbleWrap}>
              <View style={styles.bubble}>
                <Text style={styles.bubbleText}>{item.text}</Text>
              </View>
              <Text style={styles.bubbleTime}>{item.timestamp}</Text>
            </View>
          )}
        />

        {/* Input bar */}
        <View style={[styles.inputArea, { paddingBottom: insets.bottom + 8 }]}>
          <View style={styles.inputRow}>
            <TextInput
              ref={inputRef}
              value={inputText}
              onChangeText={setInputText}
              placeholder="Secure message…"
              placeholderTextColor="#4A5568"
              style={styles.input}
              multiline
              maxLength={2000}
              returnKeyType="send"
              onSubmitEditing={handleSend}
            />
            <Pressable
              onPress={handleSend}
              disabled={!inputText.trim()}
              style={({ pressed }) => [
                styles.sendBtn,
                !inputText.trim() && styles.sendBtnDisabled,
                pressed && !!inputText.trim() && styles.sendBtnPressed,
              ]}
            >
              <Text style={styles.sendBtnIcon}>↑</Text>
            </Pressable>
          </View>
        </View>
      </KeyboardAvoidingView>
    </View>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
    backgroundColor: "#050816",
  },
  flex: { flex: 1 },

  header: {
    flexDirection: "row",
    alignItems: "center",
    gap: 12,
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: "rgba(255,255,255,0.07)",
  },
  backBtn: {
    width: 44,
    height: 44,
    borderRadius: 13,
    alignItems: "center",
    justifyContent: "center",
    backgroundColor: "#101827",
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.08)",
  },
  backBtnPressed: { opacity: 0.7, transform: [{ scale: 0.95 }] },
  backText: {
    color: "#39FF14",
    fontSize: 36,
    lineHeight: 38,
    fontWeight: "400",
    fontFamily: "Inter_400Regular",
  },
  headerTitle: {
    color: "#FFFFFF",
    fontSize: 18,
    fontWeight: "900",
    fontFamily: "Inter_700Bold",
  },
  statusRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 5,
    marginTop: 2,
  },
  statusDot: {
    width: 6,
    height: 6,
    borderRadius: 3,
    backgroundColor: "#FACC15",
  },
  statusLabel: {
    color: "#FACC15",
    fontSize: 10,
    fontWeight: "700",
    fontFamily: "Inter_700Bold",
    letterSpacing: 2,
  },
  broadcastPill: {
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 10,
    backgroundColor: "rgba(57,255,20,0.08)",
    borderWidth: 1,
    borderColor: "rgba(57,255,20,0.20)",
  },
  broadcastText: {
    color: "#39FF14",
    fontSize: 9,
    fontWeight: "900",
    fontFamily: "Inter_700Bold",
    letterSpacing: 2,
  },

  banner: {
    flexDirection: "row",
    alignItems: "center",
    gap: 8,
    paddingHorizontal: 16,
    paddingVertical: 10,
    backgroundColor: "rgba(250,204,21,0.06)",
    borderBottomWidth: 1,
    borderBottomColor: "rgba(250,204,21,0.12)",
  },
  bannerDot: {
    width: 5,
    height: 5,
    borderRadius: 3,
    backgroundColor: "#FACC15",
  },
  bannerText: {
    color: "#FACC15",
    fontSize: 12,
    fontWeight: "500",
    fontFamily: "Inter_500Medium",
    flex: 1,
  },

  listContent: {
    paddingHorizontal: 16,
    paddingVertical: 20,
    flexGrow: 1,
  },
  empty: {
    alignItems: "center",
    justifyContent: "center",
    paddingVertical: 60,
    paddingHorizontal: 32,
  },
  emptyIcon: {
    color: "#39FF14",
    fontSize: 52,
    marginBottom: 16,
    opacity: 0.5,
  },
  emptyTitle: {
    color: "#FFFFFF",
    fontSize: 20,
    fontWeight: "900",
    fontFamily: "Inter_700Bold",
    textAlign: "center",
    marginBottom: 10,
  },
  emptyBody: {
    color: "#94A3B8",
    fontSize: 14,
    fontWeight: "400",
    fontFamily: "Inter_400Regular",
    textAlign: "center",
    lineHeight: 22,
  },

  bubbleWrap: {
    alignItems: "flex-end",
    marginBottom: 12,
  },
  bubble: {
    maxWidth: "80%",
    paddingHorizontal: 16,
    paddingVertical: 10,
    borderRadius: 20,
    borderBottomRightRadius: 6,
    backgroundColor: "#39FF14",
  },
  bubbleText: {
    color: "#050816",
    fontSize: 15,
    fontWeight: "600",
    fontFamily: "Inter_600SemiBold",
    lineHeight: 22,
  },
  bubbleTime: {
    color: "#64748B",
    fontSize: 11,
    fontFamily: "Inter_400Regular",
    marginTop: 4,
    marginRight: 4,
  },

  inputArea: {
    paddingHorizontal: 12,
    paddingTop: 8,
    borderTopWidth: 1,
    borderTopColor: "rgba(255,255,255,0.07)",
    backgroundColor: "#050816",
  },
  inputRow: {
    flexDirection: "row",
    alignItems: "flex-end",
    gap: 8,
    backgroundColor: "#101827",
    borderRadius: 24,
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.10)",
    paddingHorizontal: 16,
    paddingVertical: 8,
  },
  input: {
    flex: 1,
    color: "#FFFFFF",
    fontSize: 15,
    fontFamily: "Inter_400Regular",
    maxHeight: 120,
    paddingTop: 8,
    paddingBottom: 8,
  },
  sendBtn: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: "#39FF14",
    alignItems: "center",
    justifyContent: "center",
    shadowColor: "#39FF14",
    shadowOpacity: 0.35,
    shadowRadius: 10,
    elevation: 4,
  },
  sendBtnDisabled: {
    backgroundColor: "#1E2A3A",
    shadowOpacity: 0,
    elevation: 0,
  },
  sendBtnPressed: {
    opacity: 0.84,
    transform: [{ scale: 0.94 }],
  },
  sendBtnIcon: {
    color: "#050816",
    fontSize: 20,
    fontWeight: "900",
    fontFamily: "Inter_700Bold",
  },
});
