import React, { useEffect } from "react";
import { Pressable, ScrollView, StyleSheet, Text, View } from "react-native";
import { clearProofMetrics } from "../src/maurimesh/live/proofMetricsSpine";
import { useProofMetrics } from "../src/maurimesh/live/useProofMetrics";
import { startNativeProofEventBridge } from "../src/maurimesh/live/nativeProofEventBridge";

const MARKER = "TASK_190_PROOF_METRICS_SCREEN_20260608_A";

function Stat({ label, value }: { label: string; value: string | number }) {
  return (
    <View style={styles.stat}>
      <Text style={styles.statValue}>{value}</Text>
      <Text style={styles.statLabel}>{label}</Text>
    </View>
  );
}

export default function ProofMetricsScreen() {
  useEffect(() => {
    const nativeProofBridgeStatus = startNativeProofEventBridge();
    console.log("[TASK_192_NATIVE_PROOF_EVENT_BRIDGE]", nativeProofBridgeStatus);
  }, []);

  const { snapshot, refresh } = useProofMetrics(1000);

  return (
    <ScrollView style={styles.root} contentContainerStyle={styles.content}>
      <Text style={styles.brand}>MauriMesh</Text>
      <Text style={styles.title}>Proof Metrics Spine</Text>
      <Text style={styles.subtitle}>{MARKER}</Text>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Delivery / ACK</Text>
        <View style={styles.grid}>
          <Stat label="Attempted" value={snapshot?.attempted ?? 0} />
          <Stat label="Delivered" value={snapshot?.delivered ?? 0} />
          <Stat label="ACKed" value={snapshot?.acknowledged ?? 0} />
          <Stat label="Failed" value={snapshot?.failed ?? 0} />
          <Stat label="Success %" value={`${snapshot?.successRate ?? 0}%`} />
          <Stat label="ACK %" value={`${snapshot?.ackRate ?? 0}%`} />
        </View>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Transport</Text>
        <Text style={styles.line}>Reachable peers: {snapshot?.reachablePeers ?? 0}</Text>
        <Text style={styles.line}>Known peers: {snapshot?.knownPeers ?? 0}</Text>
        <Text style={styles.line}>Relay hops: {snapshot?.relayHops ?? 0}</Text>
        <Text style={styles.line}>Avg latency: {snapshot?.avgLatencyMs ?? 0} ms</Text>
        <Text style={styles.line}>Packet loss: {snapshot?.packetLossPercent ?? 0}%</Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Store-Forward</Text>
        <Text style={styles.line}>Total: {snapshot?.storeForwardTotal ?? 0}</Text>
        <Text style={styles.line}>Pending: {snapshot?.storeForwardPending ?? 0}</Text>
        <Text style={styles.line}>Failed: {snapshot?.storeForwardFailed ?? 0}</Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Recent Events</Text>
        {(snapshot?.events || []).slice(-20).reverse().map((event) => (
          <Text key={event.id} style={styles.event}>
            {event.type} · {event.packetId} · {event.transport || "BLE"}
          </Text>
        ))}
        {(snapshot?.events || []).length === 0 ? (
          <Text style={styles.muted}>No proof metric events recorded yet.</Text>
        ) : null}
      </View>

      <Pressable
        style={styles.button}
        onPress={async () => {
          await refresh();
        }}
      >
        <Text style={styles.buttonText}>Refresh</Text>
      </Pressable>

      <Pressable
        style={[styles.button, styles.danger]}
        onPress={async () => {
          await clearProofMetrics();
          await refresh();
        }}
      >
        <Text style={styles.buttonText}>Clear Local Proof Metrics</Text>
      </Pressable>

      <View style={styles.truth}>
        <Text style={styles.truthTitle}>Truth Boundary</Text>
        <Text style={styles.truthText}>
          These metrics only change when proof events are recorded by real send/RX/ACK
          actions or local proof instrumentation. Physical delivery still requires
          two Android phones and log proof.
        </Text>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: "#020403" },
  content: { padding: 22, gap: 16 },
  brand: { color: "#00D084", fontSize: 36, fontWeight: "900" },
  title: { color: "#FFFFFF", fontSize: 28, fontWeight: "900" },
  subtitle: { color: "#38BDF8", fontSize: 12, fontWeight: "800" },
  card: {
    borderWidth: 1,
    borderColor: "rgba(0,208,132,0.26)",
    backgroundColor: "rgba(255,255,255,0.045)",
    borderRadius: 18,
    padding: 16,
    gap: 10,
  },
  cardTitle: { color: "#FFFFFF", fontSize: 20, fontWeight: "900" },
  grid: { flexDirection: "row", flexWrap: "wrap", gap: 10 },
  stat: {
    minWidth: "30%",
    flexGrow: 1,
    borderRadius: 14,
    backgroundColor: "rgba(255,255,255,0.05)",
    padding: 12,
  },
  statValue: { color: "#00D084", fontSize: 24, fontWeight: "900", textAlign: "center" },
  statLabel: { color: "rgba(255,255,255,0.65)", fontSize: 12, fontWeight: "700", textAlign: "center" },
  line: { color: "rgba(255,255,255,0.78)", fontSize: 15, lineHeight: 22 },
  event: { color: "#D1FAE5", fontSize: 12, lineHeight: 18 },
  muted: { color: "rgba(255,255,255,0.55)", lineHeight: 20 },
  button: {
    minHeight: 52,
    borderRadius: 16,
    backgroundColor: "#00D084",
    alignItems: "center",
    justifyContent: "center",
  },
  danger: { backgroundColor: "#EF4444" },
  buttonText: { color: "#FFFFFF", fontWeight: "900" },
  truth: {
    borderWidth: 1,
    borderColor: "rgba(245,158,11,0.45)",
    borderRadius: 18,
    padding: 16,
  },
  truthTitle: { color: "#FFFFFF", fontSize: 18, fontWeight: "900" },
  truthText: { color: "rgba(255,255,255,0.7)", lineHeight: 22, marginTop: 8 },
});
