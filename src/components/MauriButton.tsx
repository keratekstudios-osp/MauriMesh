import React from "react";
import { Pressable, StyleSheet, Text } from "react-native";
import { mauriTheme } from "../theme/mauriTheme";

export function MauriButton({
  title,
  onPress,
  variant = "primary"
}: {
  title: string;
  onPress: () => void;
  variant?: "primary" | "secondary" | "danger";
}) {
  return (
    <Pressable
      onPress={onPress}
      style={({ pressed }) => [
        styles.base,
        variant === "primary" && styles.primary,
        variant === "secondary" && styles.secondary,
        variant === "danger" && styles.danger,
        pressed && { opacity: 0.76, transform: [{ scale: 0.98 }] }
      ]}
    >
      <Text style={styles.text}>{title}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  base: {
    minHeight: 52,
    borderRadius: mauriTheme.radius.lg,
    alignItems: "center",
    justifyContent: "center",
    paddingHorizontal: mauriTheme.spacing.lg,
    borderWidth: 1
  },
  primary: {
    backgroundColor: mauriTheme.colors.greenstone,
    borderColor: mauriTheme.colors.greenstone
  },
  secondary: {
    backgroundColor: mauriTheme.colors.panel,
    borderColor: mauriTheme.colors.panelBorder
  },
  danger: {
    backgroundColor: "rgba(239,68,68,0.16)",
    borderColor: "rgba(239,68,68,0.5)"
  },
  text: {
    color: mauriTheme.colors.white,
    fontSize: 16,
    fontWeight: "800"
  }
});
