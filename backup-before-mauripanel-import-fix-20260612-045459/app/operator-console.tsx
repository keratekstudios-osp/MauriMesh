import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { MauriCoreStatusPanel } from "../src/components/MauriCoreStatusPanel";
import { StatusPill } from "../src/components/StatusPill";
import { mauriTheme } from "../src/theme/mauriTheme";

export default function OperatorConsoleScreen() {
  return (
    <AppShell>
      <StatusPill label="OPERATOR CONSOLE" tone="info" />
      <Text style={styles.title}>Operator Console</Text>
      <Text style={styles.subtitle}>
        Current UI control page for mode, readiness, completion, warnings, and final proof requirements.
      </Text>

      <MauriCoreStatusPanel />

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Build Readiness</Text>
        <Text style={styles.row}>UI screens: READY AFTER CHECK</Text>
        <Text style={styles.row}>TypeScript: RUNNING IN SCRIPT</Text>
        <Text style={styles.row}>Replit proof: UI ONLY</Text>
        <Text style={styles.row}>APK proof: REQUIRED FOR BLE</Text>
      </View>
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
    gap: 8,
  },
  cardTitle: {
    color: mauriTheme.colors.greenstone,
    fontSize: 18,
    fontWeight: "900",
  },
  row: {
    color: mauriTheme.colors.white,
    fontWeight: "800",
  },
});
