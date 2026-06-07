import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { StatusPill } from "../src/components/StatusPill";
import { MAURIMESH_INVENTION_REGISTER } from "../src/lib/mauriEssentials";
import { mauriTheme } from "../src/theme/mauriTheme";

function toneForStatus(status: string): "success" | "warning" | "danger" | "info" {
  if (status === "UI_WIRED" || status === "CODED_LOGIC") return "success";
  if (status === "PROTECTED_CONCEPT") return "info";
  return "warning";
}

export default function InventionRegisterScreen() {
  return (
    <AppShell>
      <StatusPill label="OFFICIAL REGISTER" tone="success" />
      <Text style={styles.title}>MauriMesh Invention Register</Text>
      <Text style={styles.subtitle}>
        All invention candidates are listed with their current build status,
        reason, enhancement value, and proof boundary.
      </Text>

      {MAURIMESH_INVENTION_REGISTER.map((item) => (
        <View key={item.id} style={styles.card}>
          <StatusPill label={item.status} tone={toneForStatus(item.status)} />
          <Text style={styles.itemTitle}>
            {item.id}. {item.name}
          </Text>
          <Text style={styles.label}>Reason it belongs</Text>
          <Text style={styles.text}>{item.reason}</Text>
          <Text style={styles.label}>Enhancement</Text>
          <Text style={styles.text}>{item.enhances}</Text>
          <Text style={styles.label}>Proof boundary</Text>
          <Text style={styles.boundary}>{item.proofBoundary}</Text>
        </View>
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
    lineHeight: 22,
  },
  card: {
    borderWidth: 1,
    borderColor: mauriTheme.colors.panelBorder,
    backgroundColor: mauriTheme.colors.panel,
    borderRadius: mauriTheme.radius.xl,
    padding: mauriTheme.spacing.lg,
    gap: mauriTheme.spacing.sm,
  },
  itemTitle: {
    color: mauriTheme.colors.white,
    fontSize: 20,
    fontWeight: "900",
  },
  label: {
    color: mauriTheme.colors.greenstone,
    fontSize: 12,
    fontWeight: "900",
    letterSpacing: 0.7,
    marginTop: 6,
  },
  text: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 21,
  },
  boundary: {
    color: mauriTheme.colors.warning,
    lineHeight: 21,
    fontWeight: "700",
  },
});
