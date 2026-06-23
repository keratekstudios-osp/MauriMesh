import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { mauriTheme } from "../theme/mauriTheme";
import { StatusPill } from "./StatusPill";

export function TikangaDecisionCard() {
  return (
    <View style={styles.card}>
      <StatusPill label="TIKANGA GOVERNANCE / UI" tone="success" />
      <Text style={styles.title}>Tikanga Engine</Text>
      <Text style={styles.subtitle}>
        Governance view for mana, tapu/noa, cultural risk, review state, and audit trail.
      </Text>

      <View style={styles.grid}>
        <Text style={styles.label}>Decision</Text>
        <Text style={styles.value}>APPROVED_WITH_WARNING</Text>

        <Text style={styles.label}>Cultural Risk</Text>
        <Text style={styles.value}>MEDIUM</Text>

        <Text style={styles.label}>Protocol</Text>
        <Text style={styles.value}>Respect mana, protect tapu content, require review for protected terms.</Text>

        <Text style={styles.label}>Audit Note</Text>
        <Text style={styles.value}>
          UI governance shell complete. Live policy execution must connect to the real Tikanga runtime later.
        </Text>
      </View>
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
  grid: {
    gap: 8,
  },
  label: {
    color: mauriTheme.colors.greenstone,
    fontWeight: "900",
    fontSize: 12,
    letterSpacing: 0.7,
  },
  value: {
    color: mauriTheme.colors.white,
    fontSize: 14,
    lineHeight: 20,
    marginBottom: 8,
  },
});
