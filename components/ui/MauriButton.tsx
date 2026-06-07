import { ActivityIndicator, Pressable, StyleSheet, Text, type ViewStyle } from "react-native";
import { Feather } from "@expo/vector-icons";
import { mauriColors, mauriFonts, mauriRadius, mauriShadow } from "./mauriTheme";

interface MauriButtonProps {
  label: string;
  onPress?: () => void;
  icon?: React.ComponentProps<typeof Feather>["name"];
  loading?: boolean;
  disabled?: boolean;
  variant?: "primary" | "secondary" | "ghost" | "danger";
  style?: ViewStyle;
  fullWidth?: boolean;
}

export function MauriButton({
  label,
  onPress,
  icon,
  loading = false,
  disabled = false,
  variant = "primary",
  style,
  fullWidth = false,
}: MauriButtonProps) {
  const isPrimary   = variant === "primary";
  const isSecondary = variant === "secondary";
  const isDanger    = variant === "danger";

  const iconColor = isPrimary ? mauriColors.bg : isDanger ? mauriColors.destructive : mauriColors.accent;
  const labelColor = isPrimary ? mauriColors.bg : isDanger ? mauriColors.destructive : mauriColors.accent;

  return (
    <Pressable
      onPress={onPress}
      disabled={disabled || loading}
      style={({ pressed }) => [
        styles.base,
        isPrimary   && styles.primary,
        isSecondary && styles.secondary,
        isDanger    && styles.danger,
        !isPrimary && !isSecondary && !isDanger && styles.ghost,
        fullWidth && styles.fullWidth,
        pressed && !disabled && !loading && styles.pressed,
        (disabled || loading) && styles.disabled,
        style,
      ]}
    >
      {loading ? (
        <ActivityIndicator size="small" color={iconColor} />
      ) : icon ? (
        <Feather name={icon} size={16} color={iconColor} style={styles.icon} />
      ) : null}
      <Text style={[styles.label, { color: labelColor }]}>
        {label}
      </Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  base: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    borderRadius: mauriRadius.md,
    paddingVertical: 14,
    paddingHorizontal: 20,
    gap: 8,
  },
  primary: {
    backgroundColor: mauriColors.accentBright,
    ...mauriShadow.glowStrong,
  },
  secondary: {
    backgroundColor: mauriColors.accentDim,
    borderWidth: 1,
    borderColor: mauriColors.border,
    ...mauriShadow.glow,
  },
  danger: {
    backgroundColor: "rgba(239,68,68,0.10)",
    borderWidth: 1,
    borderColor: "rgba(239,68,68,0.30)",
  },
  ghost: {
    backgroundColor: "transparent",
  },
  fullWidth: {
    alignSelf: "stretch",
  },
  pressed: {
    opacity: 0.82,
    transform: [{ scale: 0.97 }],
  },
  disabled: {
    opacity: 0.40,
  },
  label: {
    fontSize: 15,
    fontWeight: "700",
    fontFamily: mauriFonts.bold,
    letterSpacing: 0.3,
  },
  icon: {
    marginRight: 2,
  },
});
