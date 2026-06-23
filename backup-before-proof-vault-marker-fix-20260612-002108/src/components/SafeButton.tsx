import React from "react";
import { Alert, Pressable, StyleSheet, Text, ViewStyle } from "react-native";

type SafeButtonProps = {
  title: string;
  auditId: string;
  onPress: () => void;
  variant?: "primary" | "secondary" | "danger" | "warning";
  style?: ViewStyle;
};

function colorForVariant(variant: SafeButtonProps["variant"]) {
  if (variant === "danger") return "#EF4444";
  if (variant === "warning") return "#F59E0B";
  if (variant === "secondary") return "#38BDF8";
  return "#00D084";
}

export function SafeButton({
  title,
  auditId,
  onPress,
  variant = "primary",
  style,
}: SafeButtonProps) {
  const color = colorForVariant(variant);

  function handlePress() {
    try {
      console.log(`MAURIMESH_BUTTON_AUDIT | PRESS_START | ${auditId} | ${title}`);
      onPress();
      console.log(`MAURIMESH_BUTTON_AUDIT | PRESS_OK | ${auditId} | ${title}`);
    } catch (err) {
      const message =
        err instanceof Error ? err.message : String(err || "Unknown button error");

      console.log(
        `MAURIMESH_BUTTON_AUDIT | PRESS_ERROR | ${auditId} | ${title} | ${message}`
      );

      Alert.alert(
        "Button fallback activated",
        `${title} could not complete safely.\n\nAudit ID:\n${auditId}\n\nError:\n${message}`
      );
    }
  }

  return (
    <Pressable
      onPress={handlePress}
      style={({ pressed }) => [
        styles.button,
        {
          backgroundColor: variant === "primary" ? color : `${color}22`,
          borderColor: color,
          opacity: pressed ? 0.72 : 1,
        },
        style,
      ]}
    >
      <Text style={styles.text}>{title}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  button: {
    minHeight: 52,
    borderRadius: 16,
    borderWidth: 1,
    alignItems: "center",
    justifyContent: "center",
    paddingHorizontal: 16,
  },
  text: {
    color: "white",
    fontSize: 15,
    fontWeight: "900",
  },
});
