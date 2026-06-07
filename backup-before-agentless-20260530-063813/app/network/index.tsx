import { Pressable, ScrollView, StyleSheet, Text, View } from "react-native";
import { useRouter } from "expo-router";
import { StatusBar } from "expo-status-bar";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { DS } from "../../src/design-system/colors";
import { typography } from "../../src/design-system/typography";
import { radius } from "../../src/design-system/radius";
import { spacing } from "../../src/design-system/spacing";
import { MeshHeader } from "../../src/components/ui/MeshHeader";
import { MeshStatusPill } from "../../src/components/ui/MeshStatusPill";
import { safeNavigate } from "../../lib/safeNavigate";

const SECTIONS = [
  { icon: "◈", title: "Diagnostics",        subtitle: "System health & BLE state",       route: "/network/diagnostics",         accent: DS.mauriGreen  },
  { icon: "⊕", title: "Connectivity",        subtitle: "Transport layer status",           route: "/network/connectivity",        accent: DS.meshBlue    },
  { icon: "▤", title: "Route Health",        subtitle: "Per-peer route quality",           route: "/network/route-health",        accent: DS.mauriGreen  },
  { icon: "⧗", title: "Latency Monitoring",  subtitle: "Round-trip time per node",         route: "/network/latency-monitoring",  accent: DS.warningAmber },
  { icon: "◌", title: "Packet Analysis",     subtitle: "Packet flow & status",             route: "/network/packet-analysis",     accent: DS.meshBlue    },
  { icon: "⟳", title: "Delivery Analytics",  subtitle: "Message delivery success rates",   route: "/network/delivery-analytics",  accent: DS.mauriGreen  },
];

export default function NetworkIndexScreen() {
  const router = useRouter();
  const insets = useSafeAreaInsets();
  return (
    <View style={styles.root}>
      <StatusBar style="light" />
      <MeshHeader title="Network Diagnostics" subtitle="Transport & routing analysis" />
      <ScrollView
        style={styles.scroll}
        contentContainerStyle={[styles.content, { paddingBottom: insets.bottom + 24 }]}
        showsVerticalScrollIndicator={false}
      >
        <View style={styles.statusRow}>
          <MeshStatusPill label="BLE — Pending" variant="warning" />
          <MeshStatusPill label="LoRa — N/A"    variant="offline" />
        </View>
        {SECTIONS.map((s) => (
          <Pressable
            key={s.route}
            onPress={() => safeNavigate(router, s.route)}
            style={({ pressed }) => [
              styles.card,
              { borderColor: `${s.accent}25` },
              pressed && styles.pressed,
            ]}
          >
            <View style={[styles.iconWrap, { backgroundColor: `${s.accent}12` }]}>
              <Text style={[styles.icon, { color: s.accent }]}>{s.icon}</Text>
            </View>
            <View style={styles.text}>
              <Text style={styles.cardTitle}>{s.title}</Text>
              <Text style={styles.cardSub}>{s.subtitle}</Text>
            </View>
            <Text style={[styles.arrow, { color: s.accent }]}>→</Text>
          </Pressable>
        ))}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  root:      { flex: 1, backgroundColor: DS.deepSpace },
  scroll:    { flex: 1 },
  content:   { padding: spacing.lg, gap: spacing.sm },
  statusRow: { flexDirection: "row", gap: spacing.xs, marginBottom: spacing.xs },
  card: {
    flexDirection: "row", alignItems: "center", gap: spacing.sm,
    backgroundColor: DS.card, borderRadius: radius.lg, borderWidth: 1, padding: spacing.md,
  },
  pressed:  { opacity: 0.80, transform: [{ scale: 0.985 }] },
  iconWrap: { width: 44, height: 44, borderRadius: radius.sm, alignItems: "center", justifyContent: "center", flexShrink: 0 },
  icon:     { fontSize: 22 },
  text:     { flex: 1, gap: 2 },
  cardTitle:{ color: DS.textPrimary,   fontSize: typography.sizes.base, fontFamily: typography.fonts.semibold },
  cardSub:  { color: DS.textSecondary, fontSize: typography.sizes.xs,   fontFamily: typography.fonts.regular  },
  arrow:    { fontSize: 22, fontFamily: typography.fonts.regular, flexShrink: 0 },
});
