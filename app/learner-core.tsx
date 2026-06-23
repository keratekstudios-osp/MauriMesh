import React, { useMemo, useState } from "react";
import { ScrollView, StyleSheet, Text, TextInput, View } from "react-native";
import { runMauriMeshLearnerCore } from "../src/maurimesh/learner/mauriMeshLearnerCore";
import AsyncStorage from "@react-native-async-storage/async-storage";

const sample = `ReactNativeJS: MAURIMESH_3_DEVICE_PROOF | TX_A06_TO_S10 | packetId=MM3-SAMPLE-123456
ReactNativeJS: MAURIMESH_3_DEVICE_PROOF | RX_S10_FROM_A06 | packetId=MM3-SAMPLE-123456
ReactNativeJS: MAURIMESH_3_DEVICE_PROOF | RELAY_S10_TO_A16 | packetId=MM3-SAMPLE-123456
ReactNativeJS: MAURIMESH_3_DEVICE_PROOF | RX_A16_FROM_S10 | packetId=MM3-SAMPLE-123456
ReactNativeJS: MAURIMESH_3_DEVICE_PROOF | ACK_A16_TO_S10 | packetId=MM3-SAMPLE-123456
ReactNativeJS: MAURIMESH_3_DEVICE_PROOF | ACK_RELAY_S10_TO_A06 | packetId=MM3-SAMPLE-123456
ReactNativeJS: MAURIMESH_3_DEVICE_PROOF | ACK_RECEIVED_A06 | packetId=MM3-SAMPLE-123456
ReactNativeJS: MAURIMESH_3_DEVICE_PROOF | EXAM_APPROVED | packetId=MM3-SAMPLE-123456`;

export default function LearnerCoreScreen() {
  const [input, setInput] = useState(sample);
  const report = useMemo(() => runMauriMeshLearnerCore(input), [input]);

  return (
    <ScrollView style={styles.screen} contentContainerStyle={styles.content}>
      <Text style={styles.title}>MauriMesh Learner Core</Text>
      <Text style={styles.subtitle}>
        Evidence memory, proof classifier, recovery planner, trust ledger.
      </Text>

      <TextInput
        value={input}
        onChangeText={setInput}
        multiline
        style={styles.input}
        placeholder="Paste proof logs here..."
        placeholderTextColor="rgba(255,255,255,0.45)"
      />

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Decision</Text>
        <Text style={styles.line}>Packet: {report.packetId}</Text>
        <Text style={styles.line}>Verdict: {report.decision.verdict}</Text>
        <Text style={styles.line}>Score: {report.decision.score}/100</Text>
        <Text style={styles.line}>Reason: {report.decision.reason}</Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Recovery</Text>
        <Text style={styles.line}>Issue: {report.recovery.issue}</Text>
        <Text style={styles.line}>Cause: {report.recovery.cause}</Text>
        <Text style={styles.line}>Next: {report.recovery.nextAction}</Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Trust Ledger</Text>
        {report.trustLedger.map((d) => (
          <Text key={d.role} style={styles.line}>
            {d.role}: {d.trustScore}/100 · success {d.successCount} · fail {d.failCount}
          </Text>
        ))}
      </View>

      <Text style={styles.truth}>{report.truth}</Text>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: "#020403" },
  content: { padding: 18, gap: 14 },
  title: { color: "#FFFFFF", fontSize: 30, fontWeight: "900" },
  subtitle: { color: "rgba(255,255,255,0.72)", lineHeight: 21 },
  input: {
    minHeight: 220,
    color: "#FFFFFF",
    backgroundColor: "rgba(255,255,255,0.06)",
    borderColor: "rgba(34,197,94,0.28)",
    borderWidth: 1,
    borderRadius: 18,
    padding: 14,
    textAlignVertical: "top",
  },
  card: {
    padding: 16,
    borderRadius: 20,
    borderWidth: 1,
    borderColor: "rgba(34,197,94,0.28)",
    backgroundColor: "rgba(2,12,8,0.84)",
    gap: 8,
  },
  cardTitle: { color: "#00D084", fontSize: 18, fontWeight: "900" },
  line: { color: "#FFFFFF", lineHeight: 20 },
  truth: { color: "#F59E0B", lineHeight: 20, fontWeight: "700" },
});



/* MAURIMESH_LEARNER_CORE_REPORT_VAULT_STORAGE_V1_START */
async function mauriMeshSaveLearnerCoreReportToVault(packetId: string, report: unknown) {
  try {
    const safePacketId = String(packetId || "NO_PACKET_ID").trim();
    const key = `maurimesh_learner_report_${safePacketId}_${Date.now()}`;
    const payload = {
      type: "MAURIMESH_LEARNER_CORE_REPORT",
      packetId: safePacketId,
      truthClass: "LEARNER_CLASSIFICATION_REPORT",
      nativeBleGattPacketBoundPass: false,
      savedAt: new Date().toISOString(),
      report,
      warning:
        "Learner Core classifies evidence and recommends recovery. It does not prove native BLE/GATT transport by itself.",
    };

    await AsyncStorage.setItem(key, JSON.stringify(payload));

    console.log(
      `MAURIMESH_LEARNER_REPORT_SAVE | packetId=${safePacketId} | key=${key} | nativeBleGattPacketBoundPass=false`
    );
  } catch (err) {
    console.log(
      `MAURIMESH_LEARNER_REPORT_SAVE_ERROR | packetId=${packetId || "NO_PACKET_ID"} | error=${
        err instanceof Error ? err.message : "UNKNOWN"
      }`
    );
  }
}
/* MAURIMESH_LEARNER_CORE_REPORT_VAULT_STORAGE_V1_END */



/*
MAURIMESH_LEARNER_CORE_REPORT_SAVE_RULE

When the user runs Learner Core against proof logs, call:

void mauriMeshSaveLearnerCoreReportToVault(report.packetId, report);

Saved key format:

maurimesh_learner_report_<packetId>_<timestamp>

Truth:
This stores learner classification output.
It does not claim native BLE/GATT packet-bound proof.
*/

