import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { generateIntelligenceReport } from "../maurimesh/intelligence";
import { mauriTheme } from "../theme/mauriTheme";
import { StatusPill } from "./StatusPill";
import { MauriPanel } from "./MauriPanel";

function toneFromStatus(status: string): "success" | "warning" | "danger" | "info" {
  if (status === "excellent" || status === "good") return "success";
  if (status === "warning") return "warning";
  if (status === "critical") return "danger";
  return "info";
}

export function IntelligencePanel() {
  const report = generateIntelligenceReport();

  return (
    <View style={styles.wrap}>
      <MauriPanel glow>
        <StatusPill label={report.mode} tone="warning" />
        <Text style={styles.heroScore}>{report.overallScore}%</Text>
        <Text style={styles.heroTitle}>System Intelligence Score</Text>
        <Text style={styles.heroText}>{report.finalTruth}</Text>
      </MauriPanel>

      {report.signals.map((signal) => (
        <MauriPanel key={signal.id}>
          <View style={styles.row}>
            <Text style={styles.signalTitle}>{signal.name}</Text>
            <StatusPill label={`${signal.score}%`} tone={toneFromStatus(signal.status)} />
          </View>
          <Text style={styles.signalDetail}>{signal.detail}</Text>
        </MauriPanel>
      ))}

      <MauriPanel>
        <Text style={styles.sectionTitle}>Selected Route</Text>
        <Text style={styles.value}>{report.route.selected.name}</Text>
        <Text style={styles.signalDetail}>{report.route.reason}</Text>
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Self-Healing Actions</Text>
        {report.selfHealing.repairActions.map((action) => (
          <Text key={action} style={styles.bullet}>✓ {action}</Text>
        ))}
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Device Proof Still Required</Text>
        {report.deviceReadiness.requiredProof.map((item) => (
          <Text key={item} style={styles.bullet}>□ {item}</Text>
        ))}
      </MauriPanel>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    gap: mauriTheme.spacing.md,
  },
  heroScore: {
    color: mauriTheme.colors.greenstone,
    fontSize: 54,
    fontWeight: "900",
    letterSpacing: -1.4,
  },
  heroTitle: {
    color: mauriTheme.colors.white,
    fontSize: 22,
    fontWeight: "900",
  },
  heroText: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 21,
  },
  row: {
    flexDirection: "row",
    justifyContent: "space-between",
    gap: 12,
    alignItems: "center",
  },
  signalTitle: {
    color: mauriTheme.colors.white,
    fontSize: 17,
    fontWeight: "900",
    flex: 1,
  },
  signalDetail: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 21,
  },
  sectionTitle: {
    color: mauriTheme.colors.greenstone,
    fontSize: 18,
    fontWeight: "900",
  },
  value: {
    color: mauriTheme.colors.white,
    fontSize: 18,
    fontWeight: "900",
  },
  bullet: {
    color: mauriTheme.colors.white,
    lineHeight: 22,
  },
});
