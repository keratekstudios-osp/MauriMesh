import React from "react";
import { ScrollView, StyleSheet, Text, View } from "react-native";
import { useAllIntegrations } from "../src/maurimesh/integration/useAllIntegrations";

export default function StoreForwardQueueScreen() {
  const { snapshot } = useAllIntegrations(1000);
  const data = snapshot?.storeForward;

  return (
    <ScrollView style={styles.root} contentContainerStyle={styles.content}>
      <Text style={styles.brand}>MauriMesh</Text>
      <Text style={styles.title}>Store-Forward Queue</Text>
      <Text style={styles.subtitle}>Offline message relay</Text>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Queue Summary</Text>
        <Text style={styles.line}>Total: {data?.total ?? 0}</Text>
        <Text style={styles.line}>Pending: {data?.pending ?? 0}</Text>
        <Text style={styles.line}>Failed: {data?.failed ?? 0}</Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Transport</Text>
        <Text style={styles.line}>Reachable peers: {data?.reachablePeers ?? 0}</Text>
        <Text style={styles.line}>Relay count: {data?.relayCount ?? 0}</Text>
        <Text style={styles.line}>Delivery count: {data?.deliveryCount ?? 0}</Text>
        <Text style={styles.line}>Truth level: physical_proof</Text>
      </View>

      <View style={styles.truth}>
        <Text style={styles.truthTitle}>Truth Boundary</Text>
        <Text style={styles.truthText}>
          Queue counts update from proof metric events. Real store-forward delivery
          still requires hardware proof.
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
