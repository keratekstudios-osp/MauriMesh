import { useRef, useState } from "react";
import { KeyboardAvoidingView, Platform, ScrollView, StyleSheet, Text, TextInput, TouchableOpacity, View } from "react-native";
import { DS } from "../../src/design-system/colors";
import { typography } from "../../src/design-system/typography";
import { spacing } from "../../src/design-system/spacing";
import { radius } from "../../src/design-system/radius";
import { ScreenWithHeader } from "../../src/components/ui/ScreenWithHeader";

interface Msg { role: "user" | "ai"; text: string; }

const INIT: Msg[] = [{ role: "ai", text: "Kia ora. I'm MauriMesh AI. Ask me about signal strength, routes, ACK patterns, or mesh health. (Scaffold mode)" }];

function getReply(text: string): string {
  const l = text.toLowerCase();
  if (l.includes("signal") || l.includes("rssi")) return "Signal: Kupe-Node-1 −52 dBm (Excellent), Rangi-Node-2 −71 dBm (Fair), Tama-Relay-3 −84 dBm (Poor).";
  if (l.includes("route"))   return "Best route MM-7A3F → MM-E5F2: 2 hops via MM-B1C4 (score: 94).";
  if (l.includes("ack"))     return "ACK stats — last 100 msgs: 97 delivered, 3 timed out. MM-E5F2 may be at mesh edge.";
  return "Running in scaffold mode. Full AI inference available in MauriMesh v1.5.";
}

export default function AiAssistantScreen() {
  const [msgs, setMsgs] = useState<Msg[]>(INIT);
  const [input, setInput] = useState("");
  const scrollRef = useRef<ScrollView>(null);

  function send() {
    if (!input.trim()) return;
    const userMsg: Msg = { role: "user", text: input.trim() };
    setMsgs((prev) => [...prev, userMsg]);
    setInput("");
    setTimeout(() => {
      setMsgs((prev) => [...prev, { role: "ai", text: getReply(userMsg.text) }]);
      scrollRef.current?.scrollToEnd({ animated: true });
    }, 700);
  }

  return (
    <ScreenWithHeader title="AI Assistant" subtitle="On-mesh intelligence — scaffold" scrollable={false}>
      <KeyboardAvoidingView style={styles.flex} behavior={Platform.OS === "ios" ? "padding" : undefined}>
        <ScrollView
          ref={scrollRef}
          style={styles.flex}
          contentContainerStyle={styles.messages}
          onContentSizeChange={() => scrollRef.current?.scrollToEnd({ animated: true })}
        >
          {msgs.map((m, i) => (
            <View key={i} style={[styles.bubble, m.role === "user" ? styles.userBubble : styles.aiBubble]}>
              <Text style={[styles.bubbleText, m.role === "user" ? styles.userText : styles.aiText]}>{m.text}</Text>
            </View>
          ))}
        </ScrollView>
        <View style={styles.inputRow}>
          <TextInput
            style={styles.input}
            value={input}
            onChangeText={setInput}
            placeholder="Ask about signal, routes, ACKs…"
            placeholderTextColor={DS.mutedText}
            onSubmitEditing={send}
            returnKeyType="send"
          />
          <TouchableOpacity style={styles.sendBtn} onPress={send} disabled={!input.trim()}>
            <Text style={styles.sendText}>→</Text>
          </TouchableOpacity>
        </View>
      </KeyboardAvoidingView>
    </ScreenWithHeader>
  );
}

const styles = StyleSheet.create({
  flex:       { flex: 1 },
  messages:   { padding: spacing.md, gap: spacing.sm },
  bubble:     { maxWidth: "85%", borderRadius: radius.lg, padding: spacing.sm },
  aiBubble:   { alignSelf: "flex-start", backgroundColor: DS.card, borderWidth: 1, borderColor: DS.divider },
  userBubble: { alignSelf: "flex-end",   backgroundColor: DS.greenDim, borderWidth: 1, borderColor: DS.greenBorder },
  bubbleText: { fontSize: typography.sizes.sm, fontFamily: typography.fonts.regular },
  aiText:     { color: DS.textPrimary },
  userText:   { color: DS.mauriGreen },
  inputRow:   { flexDirection: "row", gap: spacing.sm, padding: spacing.sm, borderTopWidth: 1, borderTopColor: DS.divider },
  input:      { flex: 1, backgroundColor: DS.card, color: DS.textPrimary, borderRadius: radius.md, paddingHorizontal: spacing.sm, paddingVertical: spacing.xs, fontSize: typography.sizes.sm, fontFamily: typography.fonts.regular },
  sendBtn:    { backgroundColor: DS.greenDim, borderRadius: radius.md, paddingHorizontal: spacing.md, justifyContent: "center" },
  sendText:   { color: DS.mauriGreen, fontSize: 18 },
});
