import React from "react";
import { ScrollView, StyleSheet, Text, View } from "react-native";
import { proofEvents } from "../src/lib/proofSimulation";

const MARKER = "SAFE_BLE_PROOF_UI_20260607_A";

export default function BleProofScreen() {
  return (
    <ScrollView style={styles.screen} contentContainerStyle={styles.content}>
      <Text style={styles.brand}>MauriMesh</Text>
      <Text style={styles.title}>BLE Proof UI</Text>
      <Text style={styles.marker}>{MARKER}</Text>

      <View style={styles.truthCard}>
        <Text style={styles.cardTitle}>Truth Boundary</Text>
        <Text style={styles.cardText}>
          This is a safe APK UI layer. It does not claim live BLE. Real BLE proof requires
          physical phones, permissions, native logs, TX/RX/ACK events, and two-phone validation.
        </Text>
      </View>

      {proofEvents.map((event) => (
        <View key={event.id} style={styles.card}>
          <Text style={styles.rowTitle}>{event.stage}</Text>
          <Text style={styles.status}>{event.status}</Text>
          <Text style={styles.cardText}>{event.detail}</Text>
        </View>
      ))}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: "#020617" },
  content: { padding: 24, paddingTop: 72 },
  brand: { color: "#00D084", fontSize: 38, fontWeight: "900", marginBottom: 8 },
  title: { color: "#FFFFFF", fontSize: 28, fontWeight: "900", marginBottom: 8 },
  marker: { color: "#38BDF8", fontSize: 12, fontWeight: "800", marginBottom: 20 },
  truthCard: {
    backgroundColor: "rgba(245,158,11,0.10)",
    borderColor: "rgba(245,158,11,0.45)",
    borderWidth: 1,
    borderRadius: 22,
    padding: 18,
    marginBottom: 16,
  },
  card: {
    backgroundColor: "rgba(255,255,255,0.06)",
    borderColor: "rgba(0,208,132,0.28)",
    borderWidth: 1,
    borderRadius: 22,
    padding: 18,
    marginBottom: 14,
  },
  cardTitle: { color: "#FFFFFF", fontSize: 18, fontWeight: "900", marginBottom: 10 },
  rowTitle: { color: "#FFFFFF", fontSize: 18, fontWeight: "900", marginBottom: 6 },
  status: { color: "#00D084", fontSize: 13, fontWeight: "900", marginBottom: 8 },
  cardText: { color: "rgba(255,255,255,0.76)", fontSize: 14, lineHeight: 22 },
});
