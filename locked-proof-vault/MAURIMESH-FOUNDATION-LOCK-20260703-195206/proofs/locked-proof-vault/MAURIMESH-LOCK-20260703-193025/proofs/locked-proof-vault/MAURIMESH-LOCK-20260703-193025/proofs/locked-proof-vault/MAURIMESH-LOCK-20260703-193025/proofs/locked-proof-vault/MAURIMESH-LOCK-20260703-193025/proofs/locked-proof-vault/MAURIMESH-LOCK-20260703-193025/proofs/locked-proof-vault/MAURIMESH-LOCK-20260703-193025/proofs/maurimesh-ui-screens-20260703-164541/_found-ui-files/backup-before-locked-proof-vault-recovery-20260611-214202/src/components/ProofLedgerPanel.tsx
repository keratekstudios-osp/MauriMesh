import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { mauriTheme } from "../theme/mauriTheme";
import { StatusPill } from "./StatusPill";

export function ProofLedgerPanel() {
  const rows = [
    ["Packet ID", "MM-PROOF-UI-001"],
    ["Payload Hash", "sha256: simulation-placeholder"],
    ["Route", "Device A → Relay B → Device C"],
    ["ACK State", "SIMULATION ACK"],
    ["Truth", "UI proof ledger only until APK/device logcat proof is added"],
  ];

  return (
    <View style={styles.card}>
      <StatusPill label="SIMULATION / DEVICE PROOF READY" tone="warning" />
      <Text style={styles.title}>Proof Ledger</Text>
      <Text style={styles.subtitle}>
        Packet proof view for hashes, route path, ACK state, timestamps, and future native logcat evidence.
      </Text>

      {rows.map(([label, value]) => (
        <View key={label} style={styles.row}>
          <Text style={styles.label}>{label}</Text>
          <Text style={styles.value}>{value}</Text>
        </View>
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    borderWidth: 1,
    borderColor: mauriTheme.colors.panelBorder,
    backgroundColor: mauriTheme.colors.panel,
    borderRadius: mauriTheme.radius.xl,
    padding: mauriTheme.spacing.lg,
    gap: mauriTheme.spacing.md,
  },
  title: {
    color: mauriTheme.colors.white,
    fontSize: 24,
    fontWeight: "900",
  },
  subtitle: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 21,
  },
  row: {
    borderTopWidth: 1,
    borderTopColor: mauriTheme.colors.panelBorder,
    paddingTop: 10,
    gap: 4,
  },
  label: {
    color: mauriTheme.colors.greenstone,
    fontWeight: "900",
    fontSize: 12,
    letterSpacing: 0.6,
  },
  value: {
    color: mauriTheme.colors.white,
    fontSize: 14,
    lineHeight: 20,
  },
});
