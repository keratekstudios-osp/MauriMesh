import React from "react";
import { ScrollView, StyleSheet, Text, View } from "react-native";
import { useAllIntegrations } from "../src/maurimesh/integration/useAllIntegrations";

export default function AckTrackingScreen() {
  const { snapshot } = useAllIntegrations(1000);
  const data = snapshot?.ackTracking;

  return (
    <ScrollView style={styles.root} contentContainerStyle={styles.content}>
      <Text style={styles.brand}>MauriMesh</Text>
      <Text style={styles.title}>ACK Tracking</Text>
      <Text style={styles.subtitle}>Message acknowledgement paths</Text>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>ACK Statistics</Text>
        <Text style={styles.line}>Delivered: {data?.delivered ?? 0}</Text>
        <Text style={styles.line}>ACKed: {data?.acked ?? 0}</Text>
        <Text style={styles.line}>In transit: {data?.inTransit ?? 0}</Text>
        <Text style={styles.line}>ACK rate: {data?.ackRate ?? 0}%</Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Delivery Pipeline</Text>
        <Text style={styles.line}>Relay count: {snapshot?.proofMetrics.relayHops ?? 0}</Text>
        <Text style={styles.line}>Delivery count: {snapshot?.proofMetrics.delivered ?? 0}</Text>
        <Text style={styles.line}>ACK count: {snapshot?.proofMetrics.acknowledged ?? 0}</Text>
        <Text style={styles.line}>Failures: {snapshot?.proofMetrics.failed ?? 0}</Text>
        <Text style={styles.line}>Avg latency: {snapshot?.proofMetrics.avgLatencyMs ?? 0} ms</Text>
        <Text style={styles.line}>Truth level: physical_proof</Text>
      </View>

      <View style={styles.truth}>
        <Text style={styles.truthTitle}>Truth Boundary</Text>
        <Text style={styles.truthText}>
          ACK counts update only from proof metric ACK events. No acknowledgement is
          claimed until a real ACK event is recorded.
        </Text>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: "#020403" },
  content: { padding: 22, gap: 16 },
  brand: { color: "#00D084", fontSize: 34, fontWeight: "900" },
  title: { color: "#FFFFFF", fontSize: 30, fontWeight: "900" },
  subtitle: { color: "rgba(255,255,255,0.6)", fontSize: 16, fontWeight: "800" },
  card: { borderWidth: 1, borderColor: "rgba(0,208,132,0.26)", backgroundColor: "rgba(255,255,255,0.045)", borderRadius: 18, padding: 16, gap: 10 },
  cardTitle: { color: "#FFFFFF", fontSize: 20, fontWeight: "900" },
  line: { color: "rgba(255,255,255,0.78)", fontSize: 16, lineHeight: 24 },
  truth: { borderWidth: 1, borderColor: "rgba(245,158,11,0.45)", borderRadius: 18, padding: 16 },
  truthTitle: { color: "#FFFFFF", fontSize: 18, fontWeight: "900" },
  truthText: { color: "rgba(255,255,255,0.7)", lineHeight: 22, marginTop: 8 },
});
