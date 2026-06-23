import React from "react";
import { StyleSheet, Text, View } from "react-native";
import {
  forceBackupIntelligence,
  generateProtectedIntelligenceReport,
} from "../maurimesh/intelligence";
import { mauriTheme } from "../theme/mauriTheme";
import { MauriPanel } from "./MauriPanel";
import { StatusPill } from "./StatusPill";

function toneFromScore(score: number): "success" | "warning" | "danger" | "info" {
  if (score >= 75) return "success";
  if (score >= 50) return "warning";
  return "danger";
}

export function BackupIntelligencePanel() {
  const protectedState = generateProtectedIntelligenceReport();
  const forcedBackup = forceBackupIntelligence("UI verification of backup brain");

  return (
    <View style={styles.wrap}>
      <MauriPanel glow>
        <StatusPill
          label={protectedState.backupActivated ? "BACKUP ACTIVE" : "PRIMARY PROTECTED"}
          tone={protectedState.backupActivated ? "warning" : "success"}
        />
        <Text style={styles.score}>{protectedState.report.overallScore}%</Text>
        <Text style={styles.title}>Protected Intelligence</Text>
        <Text style={styles.detail}>{protectedState.failoverReason}</Text>
        <Text style={styles.truth}>{protectedState.report.finalTruth}</Text>
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Forced Backup Test</Text>
        <Text style={styles.detail}>
          This confirms backup intelligence can run independently of the primary orchestrator.
        </Text>
        <StatusPill
          label={`${forcedBackup.report.overallScore}% BACKUP SCORE`}
          tone={toneFromScore(forcedBackup.report.overallScore)}
        />
      </MauriPanel>

      {forcedBackup.report.signals.map((signal) => (
        <MauriPanel key={signal.id}>
          <View style={styles.row}>
            <Text style={styles.signalTitle}>{signal.name}</Text>
            <StatusPill label={`${signal.score}%`} tone={toneFromScore(signal.score)} />
          </View>
          <Text style={styles.detail}>{signal.detail}</Text>
        </MauriPanel>
      ))}

      <MauriPanel>
        <Text style={styles.sectionTitle}>Protected Engines</Text>
        {protectedState.protection.protectedEngines.map((engine) => (
          <Text key={engine} style={styles.bullet}>✓ {engine}</Text>
        ))}
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Fallback Rules</Text>
        {protectedState.protection.fallbackRules.map((rule) => (
          <Text key={rule} style={styles.bullet}>• {rule}</Text>
        ))}
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Final Truth</Text>
        <Text style={styles.truth}>{protectedState.protection.finalTruth}</Text>
      </MauriPanel>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    gap: mauriTheme.spacing.md,
  },
  score: {
    color: mauriTheme.colors.greenstone,
    fontSize: 54,
    fontWeight: "900",
    letterSpacing: -1.4,
  },
  title: {
    color: mauriTheme.colors.white,
    fontSize: 22,
    fontWeight: "900",
  },
  sectionTitle: {
    color: mauriTheme.colors.greenstone,
    fontSize: 18,
    fontWeight: "900",
  },
  signalTitle: {
    color: mauriTheme.colors.white,
    fontSize: 16,
    fontWeight: "900",
    flex: 1,
  },
  detail: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 21,
  },
  truth: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 21,
    fontWeight: "700",
  },
  row: {
    flexDirection: "row",
    gap: 12,
    alignItems: "center",
    justifyContent: "space-between",
  },
  bullet: {
    color: mauriTheme.colors.white,
    lineHeight: 22,
  },
});
