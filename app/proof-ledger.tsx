import React from "react";
import { ScrollView, StyleSheet, Text, View } from "react-native";
import { proofEvents } from "../src/lib/proofSimulation";

const MARKER = "SAFE_PROOF_LEDGER_20260607_A";

export default function ProofLedgerScreen() {
  return (
    <ScrollView style={styles.screen} contentContainerStyle={styles.content}>
      <Text style={styles.brand}>MauriMesh</Text>
      <Text style={styles.title}>Proof Ledger</Text>
      <Text style={styles.marker}>{MARKER}</Text>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Current Verified State</Text>
        <Text style={styles.cardText}>APK shell: PASS</Text>
        <Text style={styles.cardText}>Package identity: com.maurimesh.messenger</Text>
        <Text style={styles.cardText}>RootLayout crash: isolated and bypassed</Text>
        <Text style={styles.cardText}>Safe UI shell: PASS</Text>
      </View>

      {proofEvents.map((event, index) => (
        <View key={event.id} style={styles.ledgerRow}>
          <Text style={styles.index}>{String(index + 1).padStart(2, "0")}</Text>
          <View style={styles.rowBody}>
            <Text style={styles.rowTitle}>{event.stage}</Text>
            <Text style={styles.rowText}>{event.detail}</Text>
            <Text style={styles.rowStatus}>{event.status}</Text>
          </View>
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
  card: {
    backgroundColor: "rgba(255,255,255,0.06)",
    borderColor: "rgba(0,208,132,0.28)",
    borderWidth: 1,
    borderRadius: 22,
    padding: 18,
    marginBottom: 18,
  },
  cardTitle: { color: "#FFFFFF", fontSize: 18, fontWeight: "900", marginBottom: 10 },
  cardText: { color: "rgba(255,255,255,0.76)", fontSize: 14, lineHeight: 22 },
  ledgerRow: {
    flexDirection: "row",
    gap: 14,
    backgroundColor: "rgba(255,255,255,0.05)",
    borderColor: "rgba(0,208,132,0.22)",
    borderWidth: 1,
    borderRadius: 18,
    padding: 16,
    marginBottom: 12,
  },
  index: { color: "#38BDF8", fontSize: 14, fontWeight: "900", width: 30 },
  rowBody: { flex: 1 },
  rowTitle: { color: "#FFFFFF", fontSize: 16, fontWeight: "900", marginBottom: 6 },
  rowText: { color: "rgba(255,255,255,0.72)", fontSize: 14, lineHeight: 21 },
  rowStatus: { color: "#00D084", fontSize: 12, fontWeight: "900", marginTop: 8 },
});
