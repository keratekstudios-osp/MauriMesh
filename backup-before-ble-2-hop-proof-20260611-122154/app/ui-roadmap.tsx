import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { StatusPill } from "../src/components/StatusPill";
import { UiRoadmapCard } from "../src/components/UiRoadmapCard";
import { getUiRemainderSummary, uiRemainderTasks } from "../src/lib/uiRemainder";
import { mauriTheme } from "../src/theme/mauriTheme";

export default function UiRoadmapScreen() {
  const summary = getUiRemainderSummary();

  return (
    <AppShell>
      <StatusPill label="UI REMAINDER BLUEPRINT" tone="info" />
      <Text style={styles.title}>What Is Left To Create</Text>
      <Text style={styles.subtitle}>{summary.message}</Text>

      <View style={styles.summaryCard}>
        <Text style={styles.summaryText}>Total tasks: {summary.total}</Text>
        <Text style={styles.summaryText}>P0 critical: {summary.p0}</Text>
        <Text style={styles.summaryText}>Missing: {summary.missing}</Text>
        <Text style={styles.summaryText}>Partial: {summary.partial}</Text>
        <Text style={styles.summaryText}>Requires APK/device proof: {summary.deviceProof}</Text>
      </View>

      {uiRemainderTasks.map((task) => (
        <UiRoadmapCard key={task.id} task={task} />
      ))}
    </AppShell>
  );
}

const styles = StyleSheet.create({
  title: {
    color: mauriTheme.colors.white,
    fontSize: 34,
    fontWeight: "900",
  },
  subtitle: {
    color: mauriTheme.colors.mutedWhite,
    fontSize: 15,
    lineHeight: 22,
  },
  summaryCard: {
    borderWidth: 1,
    borderColor: mauriTheme.colors.panelBorder,
    backgroundColor: mauriTheme.colors.panel,
    borderRadius: mauriTheme.radius.xl,
    padding: mauriTheme.spacing.lg,
    gap: 6,
  },
  summaryText: {
    color: mauriTheme.colors.white,
    fontSize: 14,
    fontWeight: "800",
  },
});
