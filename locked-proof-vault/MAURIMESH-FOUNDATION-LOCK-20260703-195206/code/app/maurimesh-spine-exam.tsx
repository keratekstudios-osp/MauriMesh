import React, { useMemo, useState } from "react";
import { ScrollView, StyleSheet, Text, TouchableOpacity, View } from "react-native";
import { mauriMeshUnifiedSpine } from "../src/maurimesh/intelligence/spine/unifiedSpine";
import { MauriMeshProofSignal } from "../src/maurimesh/intelligence/types";

function now() {
  return new Date().toISOString();
}

function sampleSignals(packetId: string): MauriMeshProofSignal[] {
  return [
    "PACKET_ID_CONFIRMED",
    "TX_A06_TO_S10",
    "RX_S10_FROM_A06",
    "RELAY_S10_TO_A16",
    "RX_A16_FROM_S10",
    "ACK_A16_TO_S10",
    "ACK_RELAY_S10_TO_A06",
    "ACK_RECEIVED_A06",
    "EXAM_APPROVED",
  ].map((event) => ({
    packetId,
    event,
    actor: event.includes("A16") ? "PHONE_C" : event.includes("S10") ? "PHONE_B" : "PHONE_A",
    transport: "BLE_SCREEN_WORKFLOW",
    timestamp: now(),
    source: "APK",
    raw: `MAURIMESH_EXAM_SAMPLE | ${event} | packetId=${packetId}`,
  }));
}

export default function MauriMeshSpineExamScreen() {
  const [packetId, setPacketId] = useState("MM3-EXAM-SPINE01");
  const [ran, setRan] = useState(false);

  const result = useMemo(() => {
    return mauriMeshUnifiedSpine({
      packetId,
      proofType: "3_DEVICE",
      signals: sampleSignals(packetId),
      vaultStored: true,
      dashboardStable: true,
      userApprovedExam: true,
    });
  }, [packetId]);

  function runExam() {
    const suffix = Math.random().toString(36).slice(2, 8).toUpperCase();
    setPacketId(`MM3-SPINE-${suffix}`);
    setRan(true);
  }

  return (
    <ScrollView style={styles.screen} contentContainerStyle={styles.content}>
      <Text style={styles.kicker}>MAURIMESH UNIFIED EXAM</Text>
      <Text style={styles.title}>Intelligence Spine Exam</Text>
      <Text style={styles.subtitle}>
        One simple audit screen for routing, resilience, governance, proof verdict, vault storage, learner truth, and native BLE/GATT claim protection.
      </Text>

      <TouchableOpacity style={styles.button} onPress={runExam}>
        <Text style={styles.buttonText}>Run Unified Spine Exam</Text>
      </TouchableOpacity>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Result</Text>
        <Text style={styles.line}>Packet: {result.packetId}</Text>
        <Text style={styles.line}>Passed: {String(result.exam.passed)}</Text>
        <Text style={styles.line}>Decision: {result.exam.decision}</Text>
        <Text style={styles.line}>Truth class: {result.exam.truthClass}</Text>
        <Text style={styles.line}>Score: {result.exam.score}%</Text>
        <Text style={styles.warning}>
          Native BLE/GATT packet-bound PASS: {String(result.nativeBleGattPacketBoundPass)}
        </Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Exam Checks</Text>
        {result.exam.checks.map((check) => (
          <View key={check.id} style={styles.check}>
            <Text style={check.passed ? styles.pass : styles.fail}>
              {check.passed ? "PASS" : "FAIL"} — {check.label}
            </Text>
            <Text style={styles.evidence}>{check.evidence}</Text>
          </View>
        ))}
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Architecture Truth</Text>
        <Text style={styles.evidence}>{result.truth}</Text>
        <Text style={styles.evidence}>Ran in this session: {String(ran)}</Text>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: "#020403" },
  content: { padding: 20, paddingBottom: 42, gap: 16 },
  kicker: { color: "#00D084", fontWeight: "900", letterSpacing: 1.4 },
  title: { color: "#FFFFFF", fontSize: 32, fontWeight: "900" },
  subtitle: { color: "rgba(255,255,255,0.72)", fontSize: 16, lineHeight: 24 },
  button: { backgroundColor: "#00D084", borderRadius: 18, padding: 17, alignItems: "center" },
  buttonText: { color: "#FFFFFF", fontWeight: "900", fontSize: 15 },
  card: {
    padding: 16,
    borderRadius: 22,
    backgroundColor: "rgba(0,20,12,0.86)",
    borderColor: "rgba(0,208,132,0.30)",
    borderWidth: 1,
    gap: 10,
  },
  cardTitle: { color: "#FFFFFF", fontSize: 20, fontWeight: "900" },
  line: { color: "#FFFFFF", lineHeight: 20, fontWeight: "700" },
  warning: { color: "#F59E0B", fontWeight: "900", lineHeight: 20 },
  check: { borderTopColor: "rgba(255,255,255,0.12)", borderTopWidth: 1, paddingTop: 10 },
  pass: { color: "#00D084", fontWeight: "900" },
  fail: { color: "#EF4444", fontWeight: "900" },
  evidence: { color: "rgba(255,255,255,0.72)", lineHeight: 20 },
});
