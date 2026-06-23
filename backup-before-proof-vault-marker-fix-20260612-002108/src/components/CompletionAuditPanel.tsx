import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { MauriCompletionAudit } from "../lib/mauriEssentials";
import { mauriTheme } from "../theme/mauriTheme";

export function CompletionAuditPanel({ audit }: { audit: MauriCompletionAudit }) {
  return (
    <View style={styles.card}>
      <Text style={styles.title}>Completion Audit</Text>
      <Text style={styles.score}>{audit.score}%</Text>
      <Text style={styles.summary}>{audit.summary}</Text>

      {audit.items.map((item) => (
        <View key={item.name} style={styles.item}>
          <Text
            style={[
              styles.status,
              item.status === "PASS" && styles.pass,
              item.status === "WARN" && styles.warn,
              item.status === "FAIL" && styles.fail,
            ]}
          >
            {item.status}
          </Text>
          <View style={styles.itemBody}>
            <Text style={styles.itemName}>{item.name}</Text>
            <Text style={styles.detail}>{item.detail}</Text>
          </View>
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
    fontSize: 22,
    fontWeight: "900",
  },
  score: {
    color: mauriTheme.colors.greenstone,
    fontSize: 44,
    fontWeight: "900",
  },
  summary: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 21,
  },
  item: {
    flexDirection: "row",
    gap: 12,
    borderTopWidth: 1,
    borderTopColor: "rgba(255,255,255,0.08)",
    paddingTop: 12,
  },
  status: {
    width: 48,
    fontSize: 12,
    fontWeight: "900",
  },
  pass: {
    color: mauriTheme.colors.success,
  },
  warn: {
    color: mauriTheme.colors.warning,
  },
  fail: {
    color: mauriTheme.colors.danger,
  },
  itemBody: {
    flex: 1,
    gap: 4,
  },
  itemName: {
    color: mauriTheme.colors.white,
    fontWeight: "900",
  },
  detail: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 20,
  },
});
