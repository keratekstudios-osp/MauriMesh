import React from "react";
import { StyleSheet, View } from "react-native";
import { mauriTheme } from "../theme/mauriTheme";

export function MauriPanel({
  children,
  glow = false,
}: {
  children: React.ReactNode;
  glow?: boolean;
}) {
  return <View style={[styles.panel, glow && styles.glow]}>{children}</View>;
}

const styles = StyleSheet.create({
  panel: {
    borderWidth: 1,
    borderColor: mauriTheme.colors.panelBorder,
    backgroundColor: mauriTheme.colors.panel,
    borderRadius: mauriTheme.radius.xl,
    padding: mauriTheme.spacing.lg,
    gap: mauriTheme.spacing.md,
    ...mauriTheme.shadow.card,
  },
  glow: {
    borderColor: mauriTheme.colors.panelBorderStrong,
    backgroundColor: mauriTheme.colors.panelStrong,
  },
});
