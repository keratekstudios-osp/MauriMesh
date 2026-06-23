import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { mauriTheme } from "../theme/mauriTheme";
import { StatusPill } from "./StatusPill";

export function MauriPageHeader({
  eyebrow,
  title,
  subtitle,
  tone = "success",
}: {
  eyebrow: string;
  title: string;
  subtitle: string;
  tone?: "success" | "warning" | "danger" | "info";
}) {
  return (
    <View style={styles.wrap}>
      <StatusPill label={eyebrow} tone={tone} />
      <Text style={styles.title}>{title}</Text>
      <Text style={styles.subtitle}>{subtitle}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    gap: mauriTheme.spacing.sm,
    marginBottom: mauriTheme.spacing.sm,
  },
  title: {
    color: mauriTheme.colors.white,
    fontSize: mauriTheme.typography.title,
    lineHeight: 42,
    fontWeight: "900",
    letterSpacing: -0.8,
  },
  subtitle: {
    color: mauriTheme.colors.mutedWhite,
    fontSize: mauriTheme.typography.body,
    lineHeight: 23,
  },
});
