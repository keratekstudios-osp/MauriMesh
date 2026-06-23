import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { mauriTheme } from "../theme/mauriTheme";

export function MauriMetricCard({
  label,
  value,
  detail,
}: {
  label: string;
  value: string;
  detail: string;
}) {
  return (
    <View style={styles.card}>
      <Text style={styles.value}>{value}</Text>
      <Text style={styles.label}>{label}</Text>
      <Text style={styles.detail}>{detail}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    flex: 1,
    minWidth: 130,
    borderWidth: 1,
    borderColor: mauriTheme.colors.panelBorder,
    backgroundColor: "rgba(0,208,132,0.08)",
    borderRadius: mauriTheme.radius.lg,
    padding: mauriTheme.spacing.md,
    gap: 4,
  },
  value: {
    color: mauriTheme.colors.greenstone,
    fontSize: 26,
    fontWeight: "900",
  },
  label: {
    color: mauriTheme.colors.white,
    fontSize: 13,
    fontWeight: "900",
  },
  detail: {
    color: mauriTheme.colors.mutedWhite,
    fontSize: 12,
    lineHeight: 17,
  },
});
