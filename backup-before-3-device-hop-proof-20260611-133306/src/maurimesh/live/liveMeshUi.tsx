import React from "react";
import {
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from "react-native";

export function LiveScreen({
  title,
  subtitle,
  onBack,
  children,
}: {
  title: string;
  subtitle?: string;
  onBack?: () => void;
  children: React.ReactNode;
}) {
  return (
    <ScrollView style={styles.page} contentContainerStyle={styles.content}>
      <View style={styles.headerRow}>
        <Text style={styles.brand}>MauriMesh</Text>
        {onBack ? (
          <TouchableOpacity onPress={onBack} hitSlop={12}>
            <Text style={styles.back}>← Back</Text>
          </TouchableOpacity>
        ) : null}
      </View>
      <Text style={styles.title}>{title}</Text>
      {subtitle ? <Text style={styles.subtitle}>{subtitle}</Text> : null}
      {children}
    </ScrollView>
  );
}

export function Card({
  title,
  children,
  warning,
}: {
  title?: string;
  children: React.ReactNode;
  warning?: boolean;
}) {
  return (
    <View style={[styles.card, warning && styles.warningCard]}>
      {title ? <Text style={styles.cardTitle}>{title}</Text> : null}
      {children}
    </View>
  );
}

export function Line({
  label,
  value,
  color,
}: {
  label: string;
  value: string | number | boolean;
  color?: string;
}) {
  return (
    <Text style={styles.body}>
      <Text style={styles.label}>{label}: </Text>
      <Text style={color ? { color, fontWeight: "900" } : undefined}>
        {String(value)}
      </Text>
    </Text>
  );
}

export function StatRow({
  stats,
}: {
  stats: { label: string; value: string | number; color?: string }[];
}) {
  return (
    <View style={styles.statRow}>
      {stats.map((s) => (
        <View key={s.label} style={styles.stat}>
          <Text style={[styles.statValue, s.color ? { color: s.color } : null]}>
            {s.value}
          </Text>
          <Text style={styles.statLabel}>{s.label}</Text>
        </View>
      ))}
    </View>
  );
}

export function Bars({ bars, color }: { bars: number; color: string }) {
  return (
    <View style={styles.bars}>
      {[0, 1, 2, 3].map((i) => (
        <View
          key={i}
          style={[
            styles.bar,
            { height: 8 + i * 6 },
            i < bars
              ? { backgroundColor: color }
              : { backgroundColor: "rgba(255,255,255,0.14)" },
          ]}
        />
      ))}
    </View>
  );
}

export function Pill({ label, color }: { label: string; color: string }) {
  return (
    <View style={[styles.pill, { borderColor: color }]}>
      <Text style={[styles.pillText, { color }]}>{label}</Text>
    </View>
  );
}

export function EmptyNote({ text }: { text: string }) {
  return <Text style={styles.empty}>{text}</Text>;
}

export function LiveButton({
  label,
  onPress,
  variant = "primary",
  disabled,
}: {
  label: string;
  onPress: () => void;
  variant?: "primary" | "secondary" | "danger";
  disabled?: boolean;
}) {
  return (
    <TouchableOpacity
      style={[
        styles.button,
        variant === "secondary" && styles.buttonSecondary,
        variant === "danger" && styles.buttonDanger,
        disabled && styles.buttonDisabled,
      ]}
      onPress={onPress}
      disabled={disabled}
      activeOpacity={0.85}
    >
      <Text
        style={[
          styles.buttonText,
          variant !== "primary" && styles.buttonTextOutline,
        ]}
      >
        {label}
      </Text>
    </TouchableOpacity>
  );
}

export const COLORS = {
  green: "#00D084",
  blue: "#4FC3F7",
  amber: "#F59E0B",
  red: "#FF4D5E",
  muted: "#64748B",
};

const styles = StyleSheet.create({
  page: { flex: 1, backgroundColor: "#050816" },
  content: { padding: 24, paddingTop: 56, paddingBottom: 80 },
  headerRow: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    marginBottom: 18,
  },
  brand: { color: "#00D084", fontSize: 34, fontWeight: "900" },
  back: { color: "#4FC3F7", fontSize: 16, fontWeight: "900" },
  title: { color: "#FFFFFF", fontSize: 28, fontWeight: "900", marginBottom: 6 },
  subtitle: {
    color: "rgba(255,255,255,0.6)",
    fontSize: 15,
    fontWeight: "600",
    marginBottom: 22,
  },
  card: {
    borderWidth: 1,
    borderColor: "rgba(0, 208, 132, 0.28)",
    borderRadius: 20,
    padding: 20,
    marginBottom: 16,
    backgroundColor: "rgba(255,255,255,0.035)",
  },
  warningCard: {
    borderColor: "rgba(245, 158, 11, 0.55)",
    backgroundColor: "rgba(245, 158, 11, 0.055)",
  },
  cardTitle: {
    color: "#FFFFFF",
    fontSize: 19,
    fontWeight: "900",
    marginBottom: 14,
  },
  body: {
    color: "rgba(255,255,255,0.76)",
    fontSize: 16,
    lineHeight: 26,
    marginBottom: 4,
  },
  label: { color: "#FFFFFF", fontWeight: "900" },
  statRow: { flexDirection: "row", justifyContent: "space-around" },
  stat: { alignItems: "center", gap: 2 },
  statValue: { color: "#FFFFFF", fontSize: 26, fontWeight: "900" },
  statLabel: {
    color: "rgba(255,255,255,0.6)",
    fontSize: 12,
    fontWeight: "700",
  },
  bars: { flexDirection: "row", alignItems: "flex-end", gap: 3, height: 30 },
  bar: { width: 6, borderRadius: 2 },
  pill: {
    borderWidth: 1,
    borderRadius: 999,
    paddingHorizontal: 12,
    paddingVertical: 4,
    alignSelf: "flex-start",
  },
  pillText: { fontSize: 12, fontWeight: "900", letterSpacing: 0.6 },
  empty: {
    color: "rgba(255,255,255,0.6)",
    fontSize: 15,
    lineHeight: 23,
  },
  button: {
    backgroundColor: "#00D084",
    borderRadius: 16,
    padding: 18,
    alignItems: "center",
    marginBottom: 12,
  },
  buttonSecondary: {
    backgroundColor: "transparent",
    borderWidth: 1,
    borderColor: "rgba(0, 208, 132, 0.5)",
  },
  buttonDanger: {
    backgroundColor: "transparent",
    borderWidth: 1,
    borderColor: "rgba(255, 77, 94, 0.6)",
  },
  buttonDisabled: { opacity: 0.5 },
  buttonText: { color: "#03120C", fontSize: 17, fontWeight: "900" },
  buttonTextOutline: { color: "#FFFFFF" },
});
