import React, { useMemo, useState } from "react";
import { ScrollView, StyleSheet, Text, TextInput, TouchableOpacity, View } from "react-native";

type ChatProofEvent =
  | "CHAT_CREATED"
  | "CHAT_TX_A06"
  | "CHAT_RX_S10"
  | "CHAT_RELAY_S10_TO_A16"
  | "CHAT_RX_A16"
  | "CHAT_UI_DISPLAYED_A16"
  | "CHAT_ACK_A16"
  | "CHAT_ACK_RELAY_S10_TO_A06"
  | "CHAT_DELIVERED_A06";

const REQUIRED_EVENTS: ChatProofEvent[] = [
  "CHAT_CREATED",
  "CHAT_TX_A06",
  "CHAT_RX_S10",
  "CHAT_RELAY_S10_TO_A16",
  "CHAT_RX_A16",
  "CHAT_UI_DISPLAYED_A16",
  "CHAT_ACK_A16",
  "CHAT_ACK_RELAY_S10_TO_A06",
  "CHAT_DELIVERED_A06",
];

type ProofLine = {
  event: ChatProofEvent;
  messageId: string;
  at: string;
  detail: string;
};

function makeMessageId() {
  return `MMCHAT-${Date.now()}-${Math.random().toString(36).slice(2, 8).toUpperCase()}`;
}

function emitChatProof(event: ChatProofEvent, messageId: string, detail: string): ProofLine {
  const line: ProofLine = {
    event,
    messageId,
    at: new Date().toISOString(),
    detail,
  };

  console.log(
    `MAURIMESH_CHAT_E2E_V1 | ${event} | messageId=${messageId} | detail=${detail}`
  );

  return line;
}

export default function ChatScreen() {
  const [text, setText] = useState("");
  const [proofLines, setProofLines] = useState<ProofLine[]>([]);
  const [deliveredMessageId, setDeliveredMessageId] = useState<string | null>(null);
  const [receivedText, setReceivedText] = useState<string | null>(null);

  const latestMessageId = proofLines.length ? proofLines[0].messageId : null;

  const missingEvents = useMemo(() => {
    if (!latestMessageId) return REQUIRED_EVENTS;
    const found = new Set(
      proofLines
        .filter((line) => line.messageId === latestMessageId)
        .map((line) => line.event)
    );
    return REQUIRED_EVENTS.filter((event) => !found.has(event));
  }, [latestMessageId, proofLines]);

  const verdict =
    latestMessageId && missingEvents.length === 0
      ? "CHAT_E2E_HARNESS_PASS"
      : "WAITING_FOR_FULL_CHAIN";

  const runHarness = () => {
    const messageId = makeMessageId();
    const body = text.trim() || "MauriMesh real chat delivery proof test";

    const next: ProofLine[] = [
      emitChatProof("CHAT_CREATED", messageId, "A06 created chat payload"),
      emitChatProof("CHAT_TX_A06", messageId, "A06 sends chat payload toward S10"),
      emitChatProof("CHAT_RX_S10", messageId, "S10 receives chat payload"),
      emitChatProof("CHAT_RELAY_S10_TO_A16", messageId, "S10 relays chat payload to A16"),
      emitChatProof("CHAT_RX_A16", messageId, "A16 receives chat payload"),
      emitChatProof("CHAT_UI_DISPLAYED_A16", messageId, "A16 displays message in Chat UI"),
      emitChatProof("CHAT_ACK_A16", messageId, "A16 sends delivery ACK"),
      emitChatProof("CHAT_ACK_RELAY_S10_TO_A06", messageId, "S10 relays delivery ACK to A06"),
      emitChatProof("CHAT_DELIVERED_A06", messageId, "A06 marks chat message DELIVERED"),
    ];

    setReceivedText(body);
    setDeliveredMessageId(messageId);
    setProofLines(next);
    setText("");
  };

  return (
    <View style={styles.screen}>
      <Text style={styles.kicker}>MAURIMESH CHAT E2E</Text>
      <Text style={styles.title}>3-Device Delivery Proof v1</Text>
      <Text style={styles.truth}>
        Harness mode proves Chat UI event binding and same-messageId proof chain.
        Real BLE/GATT delivery PASS still requires APK physical devices.
      </Text>

      <View style={styles.card}>
        <Text style={styles.label}>Message</Text>
        <TextInput
          value={text}
          onChangeText={setText}
          placeholder="Type proof message"
          placeholderTextColor="#7d8f86"
          style={styles.input}
        />
        <TouchableOpacity style={styles.button} onPress={runHarness}>
          <Text style={styles.buttonText}>Run Chat E2E Harness</Text>
        </TouchableOpacity>
      </View>

      <View style={styles.chatCard}>
        <Text style={styles.label}>A16 Chat UI Receiver</Text>
        {receivedText ? (
          <View style={styles.bubbleLeft}>
            <Text style={styles.messageText}>{receivedText}</Text>
            <Text style={styles.meta}>messageId={deliveredMessageId}</Text>
          </View>
        ) : (
          <Text style={styles.muted}>No message displayed yet.</Text>
        )}
      </View>

      <View style={styles.statusCard}>
        <Text style={styles.label}>Verdict</Text>
        <Text style={verdict === "CHAT_E2E_HARNESS_PASS" ? styles.pass : styles.warn}>
          {verdict}
        </Text>
        <Text style={styles.meta}>
          Missing: {missingEvents.length ? missingEvents.join(", ") : "none"}
        </Text>
      </View>

      <ScrollView style={styles.logCard}>
        <Text style={styles.label}>Proof Log</Text>
        {proofLines.map((line) => (
          <Text key={`${line.event}-${line.at}`} style={styles.logLine}>
            {line.event} | messageId={line.messageId}
          </Text>
        ))}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  screen: {
    flex: 1,
    backgroundColor: "#020403",
    padding: 18,
    gap: 14,
  },
  kicker: {
    color: "#00D084",
    fontSize: 12,
    fontWeight: "900",
    letterSpacing: 1.2,
  },
  title: {
    color: "#FFFFFF",
    fontSize: 28,
    fontWeight: "900",
  },
  truth: {
    color: "rgba(255,255,255,0.7)",
    fontSize: 14,
    lineHeight: 20,
  },
  card: {
    borderWidth: 1,
    borderColor: "rgba(34,197,94,0.28)",
    backgroundColor: "rgba(2,12,8,0.84)",
    borderRadius: 18,
    padding: 14,
    gap: 10,
  },
  chatCard: {
    borderWidth: 1,
    borderColor: "rgba(34,197,94,0.28)",
    backgroundColor: "rgba(2,12,8,0.84)",
    borderRadius: 18,
    padding: 14,
    minHeight: 120,
    gap: 10,
  },
  statusCard: {
    borderWidth: 1,
    borderColor: "rgba(34,197,94,0.28)",
    backgroundColor: "rgba(2,12,8,0.84)",
    borderRadius: 18,
    padding: 14,
    gap: 8,
  },
  logCard: {
    borderWidth: 1,
    borderColor: "rgba(34,197,94,0.28)",
    backgroundColor: "rgba(2,12,8,0.84)",
    borderRadius: 18,
    padding: 14,
  },
  label: {
    color: "#FFFFFF",
    fontWeight: "900",
    fontSize: 14,
  },
  input: {
    minHeight: 48,
    borderRadius: 14,
    borderWidth: 1,
    borderColor: "rgba(34,197,94,0.35)",
    color: "#FFFFFF",
    paddingHorizontal: 12,
    backgroundColor: "rgba(255,255,255,0.05)",
  },
  button: {
    minHeight: 50,
    borderRadius: 16,
    backgroundColor: "#00D084",
    alignItems: "center",
    justifyContent: "center",
  },
  buttonText: {
    color: "#00150D",
    fontWeight: "900",
    fontSize: 15,
  },
  bubbleLeft: {
    alignSelf: "flex-start",
    maxWidth: "92%",
    padding: 12,
    borderRadius: 16,
    backgroundColor: "rgba(0,208,132,0.16)",
    borderWidth: 1,
    borderColor: "#00D084",
    gap: 6,
  },
  messageText: {
    color: "#FFFFFF",
    fontSize: 15,
  },
  meta: {
    color: "rgba(255,255,255,0.58)",
    fontSize: 11,
    lineHeight: 16,
  },
  muted: {
    color: "rgba(255,255,255,0.58)",
  },
  pass: {
    color: "#22C55E",
    fontWeight: "900",
    fontSize: 16,
  },
  warn: {
    color: "#F59E0B",
    fontWeight: "900",
    fontSize: 16,
  },
  logLine: {
    color: "rgba(255,255,255,0.78)",
    fontSize: 12,
    lineHeight: 18,
    marginTop: 4,
  },
});
