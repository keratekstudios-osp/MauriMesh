import React from "react";
import { ScrollView, StyleSheet, Text, View } from "react-native";
import { MaoriProtocolPanel } from "../src/components/MaoriProtocolPanel";
import { getMaoriProtocolBackupSummary } from "../src/maurimesh/protocols";

export default function MaoriProtocolsScreen() {
  const summary = getMaoriProtocolBackupSummary();

  return (
    <ScrollView style={styles.root} contentContainerStyle={styles.content}>
      <View style={styles.header}>
        <Text style={styles.kicker}>MauriMesh</Text>
        <Text style={styles.title}>Māori Protocols</Text>
        <Text style={styles.subtitle}>
          Te reo Māori, Tikanga governance, cultural proof labels, and safe fallback protocol
          wiring for APK/device proof screens.
        </Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Fallback Status</Text>
        <Text style={styles.line}>Status: {summary.status}</Text>
        <Text style={styles.line}>Primary terms: {summary.primaryTerms}</Text>
        <Text style={styles.line}>Backup terms: {summary.backupTerms}</Text>
        <Text style={styles.line}>Safe fallback terms: {summary.fallbackTerms}</Text>
        <Text style={styles.truth}>{summary.truth}</Text>
      </View>

      <MaoriProtocolPanel screen="Dashboard" />
      <MaoriProtocolPanel screen="Tikanga Engine" />
      <MaoriProtocolPanel screen="JumpCode Proof" />
      <MaoriProtocolPanel screen="Test Layer" />
      <MaoriProtocolPanel screen="Proof Ledger" />
      <MaoriProtocolPanel screen="Message Fallback ACK" />
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: "#020403" },
  content: { padding: 18, gap: 14, paddingBottom: 42 },
  header: { gap: 8 },
  kicker: { color: "#00D084", fontSize: 12, fontWeight: "900", letterSpacing: 1 },
  title: { color: "#FFFFFF", fontSize: 34, fontWeight: "900", letterSpacing: -1 },
  subtitle: { color: "rgba(255,255,255,0.72)", fontSize: 15, lineHeight: 22 },
  card: {
    borderWidth: 1,
    borderColor: "rgba(0,208,132,0.32)",
    borderRadius: 22,
    backgroundColor: "rgba(2,12,8,0.92)",
    padding: 15,
    gap: 6,
  },
  cardTitle: { color: "#FFFFFF", fontSize: 20, fontWeight: "900" },
  line: { color: "rgba(255,255,255,0.72)", fontSize: 14, lineHeight: 20 },
  truth: { color: "#F59E0B", fontSize: 12, lineHeight: 18 },
});
