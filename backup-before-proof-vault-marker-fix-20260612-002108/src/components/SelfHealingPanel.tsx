import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { mauriTheme } from "../theme/mauriTheme";
import { StatusPill } from "./StatusPill";

export function SelfHealingPanel() {
  const repairs = [
    "Detect stale route memory",
    "Lower trust on failed relay",
    "Recalculate hybrid path",
    "Preserve store-and-forward queue",
  ];

  return (
    <View style={styles.card}>
      <StatusPill label="SELF-HEALING / HOMEOSTASIS" tone="warning" />
      <Text style={styles.title}>Self-Healing</Text>
      <Text style={styles.subtitle}>
        Health screen for faults, repair actions, resilience score, and living mesh homeostasis.
      </Text>

      <View style={styles.scoreBox}>
        <Text style={styles.score}>86%</Text>
        <Text style={styles.scoreLabel}>Resilience Score</Text>
      </View>

      {repairs.map((item) => (
        <Text key={item} style={styles.item}>✓ {item}</Text>
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
  scoreBox: {
    borderRadius: mauriTheme.radius.xl,
    borderWidth: 1,
    borderColor: mauriTheme.colors.greenstone,
    backgroundColor: "rgba(0,208,132,0.12)",
    padding: mauriTheme.spacing.lg,
    alignItems: "center",
  },
  score: {
    color: mauriTheme.colors.greenstone,
    fontSize: 42,
    fontWeight: "900",
  },
  scoreLabel: {
    color: mauriTheme.colors.white,
    fontWeight: "800",
  },
  item: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 21,
  },
});
