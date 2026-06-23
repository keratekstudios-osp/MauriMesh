import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { mauriTheme } from "../theme/mauriTheme";
import { StatusPill } from "./StatusPill";

export function InventionEngineCard({
  title,
  value,
  tone = "success",
}: {
  title: string;
  value: string;
  tone?: "success" | "warning" | "danger" | "info";
}) {
  return (
    <View style={styles.card}>
      <StatusPill label="INVENTION ENGINE" tone={tone} />
      <Text style={styles.title}>{title}</Text>
      <Text style={styles.value}>{value}</Text>
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
    fontSize: 19,
    fontWeight: "900",
  },
  value: {
    color: mauriTheme.colors.mutedWhite,
    fontSize: 14,
    lineHeight: 21,
  },
});
