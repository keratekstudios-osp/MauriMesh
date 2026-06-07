import { Pressable, ScrollView, StyleSheet, Text, View } from "react-native";
import { useRouter } from "expo-router";
import { safeNavigate } from "../../lib/safeNavigate";
import { StatusBar } from "expo-status-bar";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { DS } from "../../src/design-system/colors";
import { typography } from "../../src/design-system/typography";
import { radius } from "../../src/design-system/radius";
import { spacing } from "../../src/design-system/spacing";
import { MeshHeader } from "../../src/components/ui/MeshHeader";
import { MeshCard } from "../../src/components/ui/MeshCard";
import { MeshStatusPill } from "../../src/components/ui/MeshStatusPill";

const SECTIONS = [
  { icon: "⬡", title: "Trust Engine",       subtitle: "Peer trust scores & levels",        route: "/trust/trust-engine",      accent: DS.mauriGreen  },
  { icon: "⟡", title: "Tikanga Engine",      subtitle: "Cultural governance protocols",     route: "/trust/tikanga-engine",    accent: DS.meshBlue    },
  { icon: "▤", title: "Governance Rules",    subtitle: "Active ruleset & policy",           route: "/trust/governance-rules",  accent: DS.warningAmber },
  { icon: "◎", title: "Reputation System",   subtitle: "Node reputation & history",         route: "/trust/reputation-system", accent: DS.mauriGreen  },
  { icon: "⊙", title: "Node Integrity",      subtitle: "Node verification & signing",       route: "/trust/node-integrity",    accent: DS.meshBlue    },
];

export default function TrustIndexScreen() {
  const router = useRouter();
  const insets = useSafeAreaInsets();
  return (
    <View style={styles.root}>
      <StatusBar style="light" />
      <MeshHeader title="Trust & Governance" subtitle="Sovereign mesh trust layer" />
      <ScrollView
        style={styles.scroll}
        contentContainerStyle={[styles.content, { paddingBottom: insets.bottom + 24 }]}
        showsVerticalScrollIndicator={false}
      >
        <MeshCard title="Trust Summary" glow>
          <View style={styles.summary}>
            {[
              { label: "Trusted Peers",   value: "2", color: DS.mauriGreen   },
              { label: "Verified Nodes",  value: "3", color: DS.meshBlue     },
              { label: "Flagged",         value: "0", color: DS.dangerRed    },
              { label: "Policy",          value: "Active", color: DS.textPrimary },
            ].map(({ label, value, color }) => (
              <View key={label} style={styles.stat}>
                <Text style={[styles.statVal, { color }]}>{value}</Text>
                <Text style={styles.statLbl}>{label}</Text>
              </View>
            ))}
          </View>
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
  root:     { flex: 1, backgroundColor: DS.deepSpace },
  scroll:   { flex: 1 },
  content:  { padding: spacing.lg, gap: spacing.sm },
  summary:  { flexDirection: "row", justifyContent: "space-around" },
  stat:     { alignItems: "center", gap: 2 },
  statVal:  { fontSize: typography.sizes.xl, fontFamily: typography.fonts.bold },
  statLbl:  { color: DS.textSecondary, fontSize: typography.sizes.xs, fontFamily: typography.fonts.regular },
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
