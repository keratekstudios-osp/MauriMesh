import React from "react";
import {
  StyleProp,
  StyleSheet,
  Text,
  View,
  ViewStyle,
} from "react-native";

type MauriPanelProps = {
  title?: string;
  subtitle?: string;
  label?: string;
  glow?: boolean;
  children?: React.ReactNode;
  style?: StyleProp<ViewStyle>;
};

export function MauriPanel({
  title,
  subtitle,
  label,
  glow = false,
  children,
  style,
}: MauriPanelProps) {
  return (
    <View style={[styles.panel, glow && styles.glow, style]}>
      {label ? <Text style={styles.label}>{label}</Text> : null}
      {title ? <Text style={styles.title}>{title}</Text> : null}
      {subtitle ? <Text style={styles.subtitle}>{subtitle}</Text> : null}
      {children}
    </View>
  );
}

export default MauriPanel;

const styles = StyleSheet.create({
  panel: {
    width: "100%",
    borderRadius: 24,
    borderWidth: 1,
    borderColor: "rgba(34,197,94,0.28)",
    backgroundColor: "rgba(2,12,8,0.86)",
    padding: 18,
    marginVertical: 8,
  },
  glow: {
    borderColor: "rgba(0,208,132,0.72)",
    backgroundColor: "rgba(0,208,132,0.10)",
  },
  label: {
    color: "#00D084",
    fontSize: 12,
    fontWeight: "900",
    letterSpacing: 1,
    marginBottom: 8,
  },
  title: {
    color: "#FFFFFF",
    fontSize: 20,
    fontWeight: "900",
    marginBottom: 6,
  },
  subtitle: {
    color: "rgba(255,255,255,0.72)",
    fontSize: 14,
    lineHeight: 20,
    marginBottom: 10,
  },
});
