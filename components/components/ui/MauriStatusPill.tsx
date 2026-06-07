import { StyleSheet, Text, View, type ViewStyle } from "react-native";
import { Feather } from "@expo/vector-icons";
import { mauriColors, mauriFonts, mauriRadius } from "./mauriTheme";

type PillVariant = "success" | "warning" | "error" | "info" | "offline" | "blue";

const VARIANT_COLORS: Record<PillVariant, { bg: string; border: string; text: string; dot: string }> = {
  success: {
    bg:     "rgba(57,255,20,0.08)",
    border: "rgba(57,255,20,0.20)",
    text:   mauriColors.accent,
    dot:    mauriColors.accent,
  },
  warning: {
    bg:     "rgba(250,204,21,0.10)",
    border: "rgba(250,204,21,0.26)",
    text:   mauriColors.amber,
    dot:    mauriColors.amber,
  },
  error: {
    bg:     "rgba(239,68,68,0.10)",
    border: "rgba(239,68,68,0.26)",
    text:   mauriColors.destructive,
    dot:    mauriColors.destructive,
  },
  info: {
    bg:     "rgba(148,163,184,0.10)",
    border: "rgba(148,163,184,0.20)",
    text:   mauriColors.silver,
    dot:    mauriColors.silver,
  },
  offline: {
    bg:     "rgba(100,116,139,0.10)",
    border: "rgba(100,116,139,0.22)",
    text:   mauriColors.grey,
    dot:    mauriColors.grey,
  },
  blue: {
    bg:     "rgba(0,191,255,0.10)",
    border: "rgba(0,191,255,0.26)",
    text:   mauriColors.meshBlue,
    dot:    mauriColors.meshBlue,
  },
};

interface MauriStatusPillProps {
  label: string;
  variant?: PillVariant;
  icon?: React.ComponentProps<typeof Feather>["name"];
  dot?: boolean;
  style?: ViewStyle;
}

export function MauriStatusPill({
  label,
  variant = "info",
  icon,
  dot = false,
  style,
}: MauriStatusPillProps) {
  const c = VARIANT_COLORS[variant];
  return (
    <View style={[styles.pill, { backgroundColor: c.bg, borderColor: c.border }, style]}>
      {dot && <View style={[styles.dot, { backgroundColor: c.dot }]} />}
      {icon && <Feather name={icon} size={10} color={c.text} />}
      <Text style={[styles.label, { color: c.text }]}>{label}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  pill: {
    flexDirection: "row",
    alignItems: "center",
    gap: 5,
    paddingHorizontal: 10,
    paddingVertical: 5,
    borderRadius: mauriRadius.full,
    borderWidth: 1,
  },
  dot: {
    width: 6,
    height: 6,
    borderRadius: 3,
  },
  label: {
    fontSize: 10,
    fontWeight: "600",
    fontFamily: mauriFonts.semibold,
    letterSpacing: 0.5,
  },
});
