import React from "react";
import { Pressable, StyleSheet, Text, View } from "react-native";
import { mauriTheme } from "../theme/mauriTheme";
import { markButtonPress } from "../maurimesh/runtime/runtimeLog";

export function MauriButton({
  title,
  onPress,
  variant = "primary",
}: {
  title: string;
  onPress: () => void;
  variant?: "primary" | "secondary" | "danger";
}) {
  return (
    <Pressable
      onPress={() => { markButtonPress(title || "MauriButton"); onPress?.(); }}
      style={({ pressed }) => [
        styles.base,
        variant === "primary" && styles.primary,
        variant === "secondary" && styles.secondary,
        variant === "danger" && styles.danger,
        pressed && styles.pressed,
      ]}
    >
      {variant === "primary" ? <View style={styles.innerGlow} /> : null}
      <Text style={[styles.text, variant === "secondary" && styles.secondaryText]}>
        {title}
      </Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  base: {
    minHeight: 54,
    borderRadius: mauriTheme.radius.lg,
    alignItems: "center",
    justifyContent: "center",
    paddingHorizontal: mauriTheme.spacing.lg,
    borderWidth: 1,
    overflow: "hidden",
  },
  primary: {
    backgroundColor: mauriTheme.colors.greenstone,
    borderColor: mauriTheme.colors.mint,
    ...mauriTheme.shadow.card,
  },
  secondary: {
    backgroundColor: "rgba(255,255,255,0.06)",
    borderColor: mauriTheme.colors.panelBorder,
  },
  danger: {
    backgroundColor: "rgba(239,68,68,0.16)",
    borderColor: "rgba(239,68,68,0.55)",
  },
  pressed: {
    opacity: 0.76,
    transform: [{ scale: 0.985 }],
  },
  innerGlow: {
    position: "absolute",
    top: -20,
    left: 20,
    right: 20,
    height: 40,
    borderRadius: 999,
    backgroundColor: "rgba(255,255,255,0.20)",
  },
  text: {
    color: mauriTheme.colors.white,
    fontSize: 16,
    fontWeight: "900",
    letterSpacing: 0.2,
  },
  secondaryText: {
    color: mauriTheme.colors.mutedWhite,
  },
});
