import { Pressable, ScrollView, StyleSheet, Text, View } from "react-native";
import { useRouter } from "expo-router";
import { StatusBar } from "expo-status-bar";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { DS } from "../../src/design-system/colors";
import { typography } from "../../src/design-system/typography";
import { radius } from "../../src/design-system/radius";
import { spacing } from "../../src/design-system/spacing";
import { MeshHeader } from "../../src/components/ui/MeshHeader";
import { MeshCard } from "../../src/components/ui/MeshCard";
import { MeshStatusPill } from "../../src/components/ui/MeshStatusPill";
import { safeNavigate } from "../../lib/safeNavigate";

const SECTIONS = [
  { icon: "✆", title: "Incoming Call",         subtitle: "Simulate an incoming Pixel Call",    route: "/calling/incoming-call",       accent: DS.mauriGreen  },
  { icon: "▶", title: "Active Call",            subtitle: "Call controls & audio management",   route: "/calling/active-call",         accent: DS.mauriGreen  },
  { icon: "▤", title: "Call Analytics",         subtitle: "Statistics & session history",        route: "/calling/call-analytics",      accent: DS.meshBlue    },
  { icon: "◑", title: "Adaptive Quality",       subtitle: "Bitrate & quality profiles",          route: "/calling/adaptive-quality",    accent: DS.warningAmber },
  { icon: "⟳", title: "Reconstruction Engine",  subtitle: "FEC & PLC packet repair",            route: "/calling/reconstruction-engine", accent: DS.meshBlue  },
  { icon: "📶", title: "Signal Visualization",   subtitle: "RSSI & call signal quality",          route: "/calling/signal-visualization", accent: DS.mauriGreen },
];

export default function CallingIndexScreen() {
  const router = useRouter();
  const insets = useSafeAreaInsets();
  return (
    <View style={styles.root}>
      <StatusBar style="light" />
      <MeshHeader title="Pixel Calling" subtitle="Mesh-native encrypted voice" />
      <ScrollView
        style={styles.scroll}
        contentContainerStyle={[styles.content, { paddingBottom: insets.bottom + 24 }]}
        showsVerticalScrollIndicator={false}
      >
        <MeshCard title="Calling System">
          <View style={styles.statusRow}>
            <MeshStatusPill label="Engine Ready" variant="online"  />
            <MeshStatusPill label="Codec: Opus"  variant="syncing" />
          </View>
          {[
            ["Transport",  "BLE 5.0 primary · Store-forward fallback"],
            ["Codec",      "Opus 24 kbps mono"],
            ["Encryption", "AES-256 end-to-end"],
            ["Call type",  "Pixel P2P — no central server"],
          ].map(([label, value]) => (
            <View key={label as string} style={styles.row}>
              <Text style={styles.rowLabel}>{label}</Text>
              <Text style={styles.rowValue}>{value}</Text>
            </View>
          ))}
        </MeshCard>

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
  row:       { flexDirection: "row", justifyContent: "space-between", paddingVertical: 4 },
  rowLabel:  { color: DS.textSecondary, fontSize: typography.sizes.xs, fontFamily: typography.fonts.regular  },
  rowValue:  { color: DS.textPrimary,   fontSize: typography.sizes.xs, fontFamily: typography.fonts.semibold },
  card: {
    flexDirection: "row", alignItems: "center", gap: spacing.sm,
    backgroundColor: DS.card, borderRadius: radius.lg, borderWidth: 1, padding: spacing.md,
  },
  pressed:   { opacity: 0.80, transform: [{ scale: 0.985 }] },
  iconWrap:  { width: 44, height: 44, borderRadius: radius.sm, alignItems: "center", justifyContent: "center", flexShrink: 0 },
  icon:      { fontSize: 22 },
  text:      { flex: 1, gap: 2 },
  cardTitle: { color: DS.textPrimary,   fontSize: typography.sizes.base, fontFamily: typography.fonts.semibold },
  cardSub:   { color: DS.textSecondary, fontSize: typography.sizes.xs,   fontFamily: typography.fonts.regular  },
  arrow:     { fontSize: 22, fontFamily: typography.fonts.regular, flexShrink: 0 },
});
