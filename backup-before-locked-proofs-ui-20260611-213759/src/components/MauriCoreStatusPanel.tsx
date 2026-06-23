import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { mauriTheme } from "../theme/mauriTheme";
import { StatusPill } from "./StatusPill";

export function MauriCoreStatusPanel() {
  const rows = [
    ["Living Memory", "UI READY"],
    ["Governance", "UI READY"],
    ["BLE Runtime", "REQUIRES APK"],
    ["Routing", "SIMULATION READY"],
    ["Self-Healing", "UI READY"],
  ];

  return (
    <View style={styles.card}>
      <StatusPill label="MAURICORE STATUS" tone="info" />
      <Text style={styles.title}>MauriCore</Text>
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
    gap: mauriTheme.spacing.sm,
  },
  title: {
    color: mauriTheme.colors.white,
    fontSize: 22,
    fontWeight: "900",
  },
  row: {
    flexDirection: "row",
    justifyContent: "space-between",
    borderTopWidth: 1,
    borderTopColor: mauriTheme.colors.panelBorder,
    paddingTop: 8,
    gap: 12,
  },
  label: {
    color: mauriTheme.colors.mutedWhite,
    fontWeight: "700",
  },
  value: {
    color: mauriTheme.colors.greenstone,
    fontWeight: "900",
  },
});
