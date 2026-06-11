import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { mauriTheme } from "../theme/mauriTheme";

export function StatusPill({
  label,
  tone = "success",
}: {
  label: string;
  tone?: "success" | "warning" | "danger" | "info";
}) {
  const color =
    tone === "success"
      ? mauriTheme.colors.success
      : tone === "warning"
        ? mauriTheme.colors.warning
        : tone === "danger"
          ? mauriTheme.colors.danger
          : mauriTheme.colors.blueWeb;

  return (
    <View style={[styles.pill, { borderColor: color }]}>
      <View style={[styles.dot, { backgroundColor: color }]} />
      <Text style={[styles.text, { color }]}>{label}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  pill: {
    alignSelf: "flex-start",
    flexDirection: "row",
    alignItems: "center",
    gap: 7,
    borderWidth: 1,
    borderRadius: 999,
    paddingVertical: 7,
    paddingHorizontal: 12,
    backgroundColor: "rgba(255,255,255,0.055)",
  },
  dot: {
    width: 7,
    height: 7,
    borderRadius: 4,
  },
  text: {
    fontWeight: "900",
    fontSize: 11,
    letterSpacing: 0.9,
  },
});
