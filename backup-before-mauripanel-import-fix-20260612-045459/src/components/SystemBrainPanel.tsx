import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { SystemEvolutionSnapshot } from "../maurimesh/system-brain/systemTypes";
import { mauriTheme } from "../theme/mauriTheme";
import { StatusPill } from "./StatusPill";

export function SystemBrainPanel({ snapshot }: { snapshot: SystemEvolutionSnapshot }) {
  return (
    <View style={styles.card}>
      <StatusPill label="SYSTEM BRAIN" tone="success" />
      <Text style={styles.title}>Self-Efficient System Score</Text>
      <Text style={styles.score}>{snapshot.score}%</Text>
      <Text style={styles.summary}>{snapshot.summary}</Text>

      <View style={styles.row}>
        <Text style={styles.k}>Active Layers</Text>
        <Text style={styles.v}>
          {snapshot.activeLayers}/{snapshot.totalLayers}
        </Text>
      </View>

      <Text style={styles.section}>Recommendations</Text>
      {snapshot.recommendations.map((r, index) => (
        <Text key={index} style={styles.recommendation}>• {r}</Text>
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
    gap: mauriTheme.spacing.sm,
  },
  title: {
    color: mauriTheme.colors.white,
    fontSize: 22,
    fontWeight: "900",
  },
  score: {
    color: mauriTheme.colors.greenstone,
    fontSize: 48,
    fontWeight: "900",
  },
  summary: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 21,
  },
  row: {
    flexDirection: "row",
    justifyContent: "space-between",
    borderTopWidth: 1,
    borderTopColor: "rgba(255,255,255,0.08)",
    paddingTop: 10,
  },
  k: {
    color: mauriTheme.colors.mutedWhite,
    fontWeight: "800",
  },
  v: {
    color: mauriTheme.colors.white,
    fontWeight: "900",
  },
  section: {
    color: mauriTheme.colors.white,
    fontSize: 16,
    fontWeight: "900",
    marginTop: 8,
  },
  recommendation: {
    color: mauriTheme.colors.warning,
    lineHeight: 20,
    fontWeight: "700",
  },
});
