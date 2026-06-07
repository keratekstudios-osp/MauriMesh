import { StyleSheet, View, type ViewStyle } from "react-native";
import type { ReactNode } from "react";
import { mauriColors, mauriRadius, mauriShadow } from "./mauriTheme";

interface MauriGlassCardProps {
  children: ReactNode;
  style?: ViewStyle;
  noPadding?: boolean;
  intense?: boolean;
  blue?: boolean;
}

export function MauriGlassCard({
  children,
  style,
  noPadding = false,
  intense = false,
  blue = false,
}: MauriGlassCardProps) {
  return (
    <View
      style={[
        styles.card,
        intense && styles.cardIntense,
        blue && styles.cardBlue,
        noPadding && styles.noPadding,
        style,
      ]}
    >
      {children}
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: mauriColors.bgCard,
    borderWidth: 1,
    borderColor: mauriColors.border,
    borderRadius: mauriRadius.xl,
    padding: 16,
    ...mauriShadow.card,
  },
  cardIntense: {
    borderColor: mauriColors.borderBright,
    ...mauriShadow.glow,
  },
  cardBlue: {
    borderColor: mauriColors.meshBlueDim,
    shadowColor: mauriColors.meshBlue,
    shadowOpacity: 0.20,
    shadowRadius: 16,
    elevation: 6,
  },
  noPadding: {
    padding: 0,
    overflow: "hidden",
  },
});
