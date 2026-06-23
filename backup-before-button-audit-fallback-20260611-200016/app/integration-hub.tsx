import React, { useEffect } from "react";
import { Pressable, ScrollView, StyleSheet, Text, View } from "react-native";
import { useRouter } from "expo-router";
import { useAllIntegrations } from "../src/maurimesh/integration/useAllIntegrations";

const MARKER = "TASK_191_INTEGRATION_HUB_SCREEN_20260608_A";

function Row({ label, value }: { label: string; value: string | number }) {
  return (
    <View style={styles.row}>
      <Text style={styles.rowLabel}>{label}</Text>
      <Text style={styles.rowValue}>{value}</Text>
    </View>
  );
}

function NavButton({ title, route }: { title: string; route: string }) {
  const router = useRouter();
  return (
    <Pressable style={styles.button} onPress={() => router.push(route as never)}>
      <Text style={styles.buttonText}>{title}</Text>
    </Pressable>
  );
}

export default function IntegrationHubScreen() {
  useEffect(() => {
    const nativeProofBridgeStatus = startNativeProofEventBridge();
    console.log("[TASK_192_NATIVE_PROOF_EVENT_BRIDGE]", nativeProofBridgeStatus);
  }, []);

  const { snapshot } = useAllIntegrations(1000);

  return (
    <ScrollView style={styles.root} contentContainerStyle={styles.content}>
      <Text style={styles.brand}>MauriMesh</Text>
      <Text style={styles.title}>Integration Hub</Text>
      <Text style={styles.subtitle}>{MARKER}</Text>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>All Integration Status</Text>
        <Row label="Delivery status" value={snapshot?.deliveryAnalytics.status || "loading"} />
        <Row label="ACK status" value={snapshot?.ackTracking.status || "loading"} />
        <Row label="Queue status" value={snapshot?.storeForward.status || "loading"} />
        <Row label="Latency status" value={snapshot?.latency.status || "loading"} />
        <Row label="Route health status" value={snapshot?.routeHealth.status || "loading"} />
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Live Proof Metrics</Text>
        <Row label="Attempted" value={snapshot?.proofMetrics.attempted ?? 0} />
        <Row label="Delivered" value={snapshot?.proofMetrics.delivered ?? 0} />
        <Row label="ACKed" value={snapshot?.proofMetrics.acknowledged ?? 0} />
        <Row label="Failed" value={snapshot?.proofMetrics.failed ?? 0} />
        <Row label="Success %" value={`${snapshot?.proofMetrics.successRate ?? 0}%`} />
        <Row label="ACK %" value={`${snapshot?.proofMetrics.ackRate ?? 0}%`} />
      </View>

      <View style={styles.grid}>
        <NavButton title="Raw Packet Proof" route="/raw-packet-proof" />
        <NavButton title="BLE Proof" route="/ble-proof" />
        <NavButton title="Proof Metrics" route="/proof-metrics" />
        <NavButton title="Proof Ledger" route="/proof-ledger" />
        <NavButton title="Delivery Analytics" route="/delivery-analytics" />
        <NavButton title="ACK Tracking" route="/ack-tracking" />
        <NavButton title="Store-Forward Queue" route="/store-forward-queue" />
        <NavButton title="Latency Monitoring" route="/latency-monitoring" />
        <NavButton title="Route Health" route="/route-health" />
      </View>

      <View style={styles.truth}>
        <Text style={styles.truthTitle}>Truth Boundary</Text>
        <Text style={styles.truthText}>
          This hub wires the integration layer. It does not claim delivery until real
          TX/RX/ACK events are recorded by the hardware proof flow.
        </Text>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: "#020403" },
  content: { padding: 22, gap: 16 },
  brand: { color: "#00D084", fontSize: 36, fontWeight: "900" },
  title: { color: "#FFFFFF", fontSize: 30, fontWeight: "900" },
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
  row: { flexDirection: "row", justifyContent: "space-between", gap: 10 },
  rowLabel: { color: "rgba(255,255,255,0.72)", fontWeight: "700", flex: 1 },
  rowValue: { color: "#00D084", fontWeight: "900", textAlign: "right" },
  grid: { gap: 10 },
  button: {
    minHeight: 50,
    borderRadius: 16,
    backgroundColor: "rgba(0,208,132,0.14)",
    borderWidth: 1,
    borderColor: "rgba(0,208,132,0.4)",
    alignItems: "center",
    justifyContent: "center",
  },
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
