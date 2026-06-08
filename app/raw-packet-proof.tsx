import React, { useState } from "react";
import { Pressable, ScrollView, StyleSheet, Text, TextInput, View } from "react-native";
import {
  getRawPacketReceiverStatus,
  makeProofPayload,
  RawPacketReceiverStatus,
  sendRawPacketUtf8,
  startRawPacketReceiver,
  stopRawPacketReceiver,
} from "../src/maurimesh/ble/rawPacketProofClient";

const MARKER = "TASK_165B_RAW_PACKET_PROOF_SCREEN_20260608_A";

export default function RawPacketProofScreen() {
  const [target, setTarget] = useState("");
  const [status, setStatus] = useState<RawPacketReceiverStatus | null>(null);
  const [log, setLog] = useState<string[]>([]);

  const push = (line: string) => setLog((prev) => [`${new Date().toISOString()} ${line}`, ...prev].slice(0, 50));

  async function run(label: string, fn: () => Promise<any>) {
    try {
      push(`START ${label}`);
      const result = await fn();
      push(`${label}: ${JSON.stringify(result)}`);
      if (result && typeof result === "object") setStatus(result);
    } catch (error) {
      push(`${label} ERROR: ${error instanceof Error ? error.message : String(error)}`);
    }
  }

  return (
    <ScrollView style={styles.root} contentContainerStyle={styles.content}>
      <Text style={styles.kicker}>{MARKER}</Text>
      <Text style={styles.title}>Raw Packet Proof</Text>
      <Text style={styles.body}>
        Start receiver on both phones. Start BLE scan on both phones. Copy the target phone BLE address from scan status.
        Send proof packet. The receiver should show receivedCount increase and the sender should receive an ACK if both phones are running receiver server.
      </Text>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Receiver Status</Text>
        <Text style={styles.mono}>{JSON.stringify(status, null, 2)}</Text>
      </View>

      <Pressable style={styles.button} onPress={() => run("startRawPacketReceiver", startRawPacketReceiver)}>
        <Text style={styles.buttonText}>Start Raw Packet Receiver</Text>
      </Pressable>

      <Pressable style={styles.button} onPress={() => run("getRawPacketReceiverStatus", getRawPacketReceiverStatus)}>
        <Text style={styles.buttonText}>Refresh Receiver Status</Text>
      </Pressable>

      <TextInput
        value={target}
        onChangeText={setTarget}
        placeholder="Target BLE address / nodeId, e.g. AA:BB:CC:DD:EE:FF"
        placeholderTextColor="rgba(255,255,255,0.45)"
        autoCapitalize="characters"
        style={styles.input}
      />

      <Pressable
        style={styles.button}
        onPress={() =>
          run("sendRawPacketUtf8", async () => {
            const payload = makeProofPayload("PHONE_TO_PHONE");
            const ok = await sendRawPacketUtf8(target.trim(), payload);
            return { ok, target: target.trim(), payload };
          })
        }
      >
        <Text style={styles.buttonText}>Send Proof Packet</Text>
      </Pressable>

      <Pressable style={[styles.button, styles.danger]} onPress={() => run("stopRawPacketReceiver", stopRawPacketReceiver)}>
        <Text style={styles.buttonText}>Stop Receiver</Text>
      </Pressable>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Proof Log</Text>
        {log.map((line, index) => (
          <Text key={`${line}-${index}`} style={styles.logLine}>{line}</Text>
        ))}
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: "#020403" },
  content: { padding: 18, gap: 14 },
  kicker: { color: "#00D084", fontWeight: "800", fontSize: 11 },
  title: { color: "#FFFFFF", fontSize: 30, fontWeight: "900" },
  body: { color: "rgba(255,255,255,0.75)", lineHeight: 21 },
  card: {
    borderWidth: 1,
    borderColor: "rgba(0,208,132,0.35)",
    backgroundColor: "rgba(255,255,255,0.06)",
    borderRadius: 18,
    padding: 14,
    gap: 8,
  },
  cardTitle: { color: "#FFFFFF", fontWeight: "900", fontSize: 16 },
  mono: { color: "#CFFFE8", fontFamily: "monospace", fontSize: 12 },
  button: {
    minHeight: 52,
    borderRadius: 16,
    backgroundColor: "#00D084",
    alignItems: "center",
    justifyContent: "center",
    paddingHorizontal: 14,
  },
  danger: { backgroundColor: "#EF4444" },
  buttonText: { color: "#FFFFFF", fontWeight: "900" },
  input: {
    minHeight: 52,
    borderRadius: 16,
    borderWidth: 1,
    borderColor: "rgba(0,208,132,0.35)",
    color: "#FFFFFF",
    paddingHorizontal: 14,
    backgroundColor: "rgba(255,255,255,0.06)",
  },
  logLine: { color: "rgba(255,255,255,0.72)", fontSize: 12, lineHeight: 18 },
});
