import { useCallback, useEffect, useRef, useState } from "react";
import {
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from "react-native";
import { StatusBar } from "expo-status-bar";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import * as Haptics from "expo-haptics";
import { useRouter } from "expo-router";
import { DS } from "../../src/design-system/colors";
import { typography } from "../../src/design-system/typography";
import { spacing } from "../../src/design-system/spacing";
import { radius } from "../../src/design-system/radius";
import { shadows } from "../../src/design-system/shadows";
import { MeshCard } from "../../src/components/ui/MeshCard";
import { MeshStatusPill } from "../../src/components/ui/MeshStatusPill";

// ── Types ──────────────────────────────────────────────────────────────────

interface TikangaRule {
  id: string;
  name: string;
  nameEn: string;
  desc: string;
  weight: string;
  enabled: boolean;
  color: string;
  borderColor: string;
  bgColor: string;
}

interface DecisionEntry {
  id: string;
  timestamp: string;
  principle: string;
  action: string;
  outcome: string;
  outcomeColor: string;
}

// ── Static data ────────────────────────────────────────────────────────────

const INITIAL_RULES: TikangaRule[] = [
  {
    id: "manaakitanga",
    name: "Manaakitanga",
    nameEn: "Hospitality",
    desc: "Relay messages from unknown nodes in good faith — no identity required.",
    weight: "+0%  relay allow",
    enabled: true,
    color: DS.mauriGreen,
    borderColor: DS.greenBorder,
    bgColor: DS.greenDim,
  },
  {
    id: "kaitiakitanga",
    name: "Kaitiakitanga",
    nameEn: "Guardianship",
    desc: "Protect mesh participants' sovereignty — local data never leaves without consent.",
    weight: "Block exports",
    enabled: true,
    color: DS.meshBlue,
    borderColor: DS.blueBorder,
    bgColor: DS.blueDim,
  },
  {
    id: "whanaungatanga",
    name: "Whanaungatanga",
    nameEn: "Kinship",
    desc: "Prioritise trusted kin nodes in routing — shared trust raises route score.",
    weight: "+15% kin boost",
    enabled: true,
    color: "#A78BFA",
    borderColor: "rgba(167,139,250,0.28)",
    bgColor: "rgba(167,139,250,0.10)",
  },
  {
    id: "tikanga",
    name: "Tikanga",
    nameEn: "The Proper Way",
    desc: "Enforce community-agreed protocols — flag any node violating mesh ethics.",
    weight: "Flag + quarantine",
    enabled: true,
    color: DS.warningAmber,
    borderColor: DS.amberBorder,
    bgColor: DS.amberDim,
  },
];

const DECISION_TEMPLATES: Array<{
  principle: string;
  actions: string[];
  outcomes: string[];
  outcomeColors: string[];
}> = [
  {
    principle: "Manaakitanga",
    actions: [
      "Relayed packet from unknown node MM-A3F2",
      "Forwarded broadcast from unverified MM-9C1A",
      "Accepted store-forward from MM-B7D4",
    ],
    outcomes: ["Allowed", "Relayed", "Accepted"],
    outcomeColors: [DS.mauriGreen, DS.mauriGreen, DS.mauriGreen],
  },
  {
    principle: "Kaitiakitanga",
    actions: [
      "Blocked data-export request from MM-E5F2",
      "Denied off-mesh sync from MM-2D9E",
      "Prevented profile broadcast from MM-F4B2",
    ],
    outcomes: ["Blocked", "Denied", "Protected"],
    outcomeColors: [DS.dangerRed, DS.dangerRed, DS.meshBlue],
  },
  {
    principle: "Whanaungatanga",
    actions: [
      "Priority boost applied to kin node Kupe-3",
      "Route weight raised for trusted node Tama-1",
      "Kin-path selected over shorter unknown path",
    ],
    outcomes: ["+15%", "+12%", "Kin-routed"],
    outcomeColors: ["#A78BFA", "#A78BFA", "#A78BFA"],
  },
  {
    principle: "Tikanga",
    actions: [
      "Protocol violation flagged on MM-C9D1",
      "Unusual broadcast pattern detected on MM-7A3F",
      "Ethics check failed — node quarantined",
    ],
    outcomes: ["Flagged", "Warned", "Quarantined"],
    outcomeColors: [DS.warningAmber, DS.warningAmber, DS.dangerRed],
  },
];

function now(): string {
  return new Date().toLocaleTimeString([], {
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
  });
}

function pickRandom<T>(arr: T[]): T {
  return arr[Math.floor(Math.random() * arr.length)];
}

function generateDecision(rules: TikangaRule[]): DecisionEntry | null {
  const active = rules.filter((r) => r.enabled);
  if (active.length === 0) return null;
  const rule = pickRandom(active);
  const template = DECISION_TEMPLATES.find((t) => t.principle === rule.name);
  if (!template) return null;
  const idx = Math.floor(Math.random() * template.actions.length);
  return {
    id: `dec-${Date.now()}-${Math.random().toString(36).slice(2, 6)}`,
    timestamp: now(),
    principle: rule.name,
    action: template.actions[idx],
    outcome: template.outcomes[idx],
    outcomeColor: template.outcomeColors[idx],
  };
}

// ── Component ──────────────────────────────────────────────────────────────

export default function TikangaEngineScreen() {
  const router = useRouter();
  const insets = useSafeAreaInsets();

  const [rules, setRules] = useState<TikangaRule[]>(INITIAL_RULES);
  const [feed, setFeed] = useState<DecisionEntry[]>(() => {
    const seed: DecisionEntry[] = [];
    const tempRules = INITIAL_RULES;
    for (let i = 0; i < 5; i++) {
      const d = generateDecision(tempRules);
      if (d) seed.unshift(d);
    }
    return seed;
  });
  const [totalDecisions, setTotalDecisions] = useState(5);
  const rulesRef = useRef(rules);
  rulesRef.current = rules;

  useEffect(() => {
    const interval = setInterval(() => {
      const d = generateDecision(rulesRef.current);
      if (!d) return;
      setFeed((prev) => [d, ...prev].slice(0, 30));
      setTotalDecisions((n) => n + 1);
    }, 2800);
    return () => clearInterval(interval);
  }, []);

  const toggleRule = useCallback((id: string) => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    setRules((prev) =>
      prev.map((r) => (r.id === id ? { ...r, enabled: !r.enabled } : r))
    );
  }, []);

  const activeCount = rules.filter((r) => r.enabled).length;
  const compliance = activeCount === 0 ? 0 : Math.round((activeCount / rules.length) * 100);

  return (
    <>
      <StatusBar style="light" />
      <ScrollView
        style={styles.root}
        contentContainerStyle={{
          paddingTop: insets.top + 20,
          paddingBottom: insets.bottom + 48,
        }}
        showsVerticalScrollIndicator={false}
      >
        {/* Header */}
        <View style={styles.header}>
          <Pressable
            onPress={() => { Haptics.selectionAsync(); router.back(); }}
            style={({ pressed }) => [styles.back, pressed && styles.backPressed]}
          >
            <Text style={styles.backText}>‹</Text>
          </Pressable>
          <View style={{ flex: 1 }}>
            <Text style={styles.title}>Tikanga Engine</Text>
            <Text style={styles.subtitle}>Cultural governance protocols</Text>
          </View>
        </View>

        <View style={styles.body}>
          {/* Engine status */}
          <MeshCard title="Engine Status" glow accentColor={DS.blueBorder}>
            <View style={styles.statusRow}>
              <MeshStatusPill label="Active" variant="online" />
              <MeshStatusPill label="Ruleset v2.1" variant="syncing" />
              <MeshStatusPill
                label={`${activeCount}/${rules.length} rules`}
                variant={activeCount === rules.length ? "online" : "warning"}
              />
            </View>
            <Text style={styles.desc}>
              The Tikanga Engine embeds Māori cultural values into mesh routing
              and trust decisions. Toggle individual principles below to adjust
              governance behaviour in real time.
            </Text>
          </MeshCard>

          {/* Stats row */}
          <View style={styles.statsRow}>
            <StatChip label="Decisions" value={totalDecisions} color={DS.mauriGreen} />
            <StatChip label="Active Rules" value={activeCount} color={DS.meshBlue} />
            <StatChip label="Compliance" value={`${compliance}%`} color="#A78BFA" />
          </View>

          {/* Rule toggles */}
          <Text style={styles.sectionLabel}>GOVERNING PRINCIPLES</Text>

          {rules.map((rule) => (
            <Pressable
              key={rule.id}
              onPress={() => toggleRule(rule.id)}
              style={({ pressed }) => [
                styles.ruleCard,
                { borderColor: rule.enabled ? rule.borderColor : "rgba(255,255,255,0.07)" },
                pressed && styles.rulePressed,
              ]}
            >
              {/* Toggle */}
              <View style={[
                styles.toggle,
                rule.enabled
                  ? { backgroundColor: rule.color }
                  : { backgroundColor: "rgba(255,255,255,0.12)" },
              ]}>
                <View style={[
                  styles.toggleThumb,
                  rule.enabled ? styles.toggleThumbOn : styles.toggleThumbOff,
                ]} />
              </View>

              <View style={{ flex: 1 }}>
                <View style={styles.ruleNameRow}>
                  <Text style={[styles.ruleName, { color: rule.enabled ? rule.color : DS.textSecondary }]}>
                    {rule.name}
                  </Text>
                  <Text style={styles.ruleNameEn}>{rule.nameEn}</Text>
                </View>
                <Text style={styles.ruleDesc} numberOfLines={2}>{rule.desc}</Text>
                <View style={[
                  styles.weightPill,
                  { backgroundColor: rule.bgColor, borderColor: rule.borderColor },
                ]}>
                  <Text style={[styles.weightText, { color: rule.color }]}>
                    {rule.weight}
                  </Text>
                </View>
              </View>
            </Pressable>
          ))}

          {/* Live decision feed */}
          <Text style={[styles.sectionLabel, { marginTop: 8 }]}>LIVE DECISION FEED</Text>

          <View style={styles.feedCard}>
            {feed.slice(0, 12).map((entry, i) => (
              <View
                key={entry.id}
                style={[styles.feedRow, i < feed.length - 1 && styles.feedRowBorder]}
              >
                <View style={styles.feedLeft}>
                  <Text style={styles.feedTime}>{entry.timestamp}</Text>
                  <Text style={styles.feedPrinciple}>{entry.principle}</Text>
                </View>
                <View style={styles.feedRight}>
                  <Text style={styles.feedAction} numberOfLines={2}>{entry.action}</Text>
                  <Text style={[styles.feedOutcome, { color: entry.outcomeColor }]}>
                    {entry.outcome}
                  </Text>
                </View>
              </View>
            ))}
          </View>

          {/* Implementation details */}
          <MeshCard title="Implementation Details">
            {[
              ["Ruleset version",    "v2.1 — Hui-approved"],
              ["Routing weight",     "+15% for kin nodes (Whanaungatanga)"],
              ["Packet filter",      "Allow unknown — Manaakitanga default"],
              ["Data sovereignty",   "Local only — Kaitiakitanga enforced"],
              ["Violation response", "Flag → warn → quarantine (Tikanga)"],
              ["Sync interval",      "Every 5 min via store-forward"],
            ].map(([label, value]) => (
              <View key={label as string} style={styles.detailRow}>
                <Text style={styles.detailLabel}>{label}</Text>
                <Text style={styles.detailValue}>{value}</Text>
              </View>
            ))}
          </MeshCard>
        </View>
      </ScrollView>
    </>
  );
}

// ── Sub-components ─────────────────────────────────────────────────────────

function StatChip({
  label,
  value,
  color,
}: {
  label: string;
  value: number | string;
  color: string;
}) {
  return (
    <View style={[styles.statChip, { borderColor: `${color}28` }]}>
      <Text style={[styles.statValue, { color }]}>{value}</Text>
      <Text style={styles.statLabel}>{label}</Text>
    </View>
  );
}

// ── Styles ─────────────────────────────────────────────────────────────────

const styles = StyleSheet.create({
  root: {
    flex: 1,
    backgroundColor: "#050816",
    paddingHorizontal: 0,
  },
  header: {
    paddingHorizontal: 24,
    flexDirection: "row",
    alignItems: "center",
    gap: 14,
    paddingBottom: 8,
    borderBottomWidth: 1,
    borderColor: "rgba(255,255,255,0.06)",
  },
  back: {
    width: 44,
    height: 44,
    borderRadius: 13,
    alignItems: "center",
    justifyContent: "center",
    backgroundColor: "#101827",
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.08)",
  },
  backPressed: {
    opacity: 0.7,
    transform: [{ scale: 0.95 }],
  },
  backText: {
    color: DS.mauriGreen,
    fontSize: 36,
    lineHeight: 38,
    fontWeight: "400",
  },
  title: {
    color: "#FFFFFF",
    fontSize: 26,
    fontWeight: "900",
    fontFamily: typography.fonts.bold,
  },
  subtitle: {
    marginTop: 3,
    color: "#94A3B8",
    fontSize: 13,
    fontWeight: "600",
    fontFamily: typography.fonts.semibold,
  },
  body: {
    paddingHorizontal: 24,
    paddingTop: 28,
    gap: spacing.md,
  },
  statusRow: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: spacing.xs,
    marginBottom: spacing.sm,
  },
  desc: {
    color: DS.textSecondary,
    fontSize: typography.sizes.sm,
    fontFamily: typography.fonts.regular,
    lineHeight: typography.sizes.sm * typography.lineHeight.relaxed,
  },
  statsRow: {
    flexDirection: "row",
    gap: 10,
  },
  statChip: {
    flex: 1,
    alignItems: "center",
    paddingVertical: 16,
    borderRadius: radius.lg,
    backgroundColor: "#0B1220",
    borderWidth: 1,
    gap: 4,
  },
  statValue: {
    fontSize: 22,
    fontWeight: "900",
    fontFamily: typography.fonts.bold,
  },
  statLabel: {
    color: DS.textSecondary,
    fontSize: 10,
    fontWeight: "700",
    fontFamily: typography.fonts.bold,
    letterSpacing: 1,
  },
  sectionLabel: {
    color: DS.textSecondary,
    fontSize: typography.sizes.xs,
    fontFamily: typography.fonts.bold,
    letterSpacing: 4,
  },
  ruleCard: {
    flexDirection: "row",
    alignItems: "flex-start",
    gap: 14,
    padding: spacing.md,
    borderRadius: radius.lg,
    backgroundColor: "#101827",
    borderWidth: 1,
  },
  rulePressed: {
    opacity: 0.82,
    transform: [{ scale: 0.984 }],
  },
  toggle: {
    width: 44,
    height: 26,
    borderRadius: 13,
    justifyContent: "center",
    paddingHorizontal: 3,
    marginTop: 2,
    flexShrink: 0,
  },
  toggleThumb: {
    width: 20,
    height: 20,
    borderRadius: 10,
    backgroundColor: "#FFFFFF",
    ...shadows.card,
  },
  toggleThumbOn: {
    alignSelf: "flex-end",
  },
  toggleThumbOff: {
    alignSelf: "flex-start",
  },
  ruleNameRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 8,
    flexWrap: "wrap",
    marginBottom: 4,
  },
  ruleName: {
    fontSize: typography.sizes.base,
    fontWeight: "900",
    fontFamily: typography.fonts.bold,
  },
  ruleNameEn: {
    color: DS.textSecondary,
    fontSize: 11,
    fontFamily: typography.fonts.regular,
    fontStyle: "italic",
  },
  ruleDesc: {
    color: DS.textSecondary,
    fontSize: typography.sizes.sm,
    fontFamily: typography.fonts.regular,
    lineHeight: 19,
    marginBottom: 8,
  },
  weightPill: {
    alignSelf: "flex-start",
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 999,
    borderWidth: 1,
  },
  weightText: {
    fontSize: 10,
    fontWeight: "800",
    fontFamily: typography.fonts.bold,
    letterSpacing: 0.6,
  },
  feedCard: {
    borderRadius: radius.lg,
    backgroundColor: "#0B1220",
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.07)",
    overflow: "hidden",
  },
  feedRow: {
    flexDirection: "row",
    gap: 12,
    padding: 12,
  },
  feedRowBorder: {
    borderBottomWidth: 1,
    borderBottomColor: "rgba(255,255,255,0.05)",
  },
  feedLeft: {
    width: 80,
    gap: 3,
    flexShrink: 0,
  },
  feedTime: {
    color: "rgba(255,255,255,0.30)",
    fontSize: 10,
    fontFamily: typography.fonts.regular,
  },
  feedPrinciple: {
    color: DS.meshBlue,
    fontSize: 9,
    fontWeight: "800",
    fontFamily: typography.fonts.bold,
    letterSpacing: 0.4,
  },
  feedRight: {
    flex: 1,
    gap: 3,
  },
  feedAction: {
    color: "#FFFFFF",
    fontSize: 12,
    fontFamily: typography.fonts.regular,
    lineHeight: 17,
  },
  feedOutcome: {
    fontSize: 11,
    fontWeight: "900",
    fontFamily: typography.fonts.bold,
    letterSpacing: 0.5,
  },
  detailRow: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "flex-start",
    paddingVertical: 6,
    gap: 12,
  },
  detailLabel: {
    color: DS.textSecondary,
    fontSize: typography.sizes.sm,
    fontFamily: typography.fonts.regular,
    flexShrink: 0,
  },
  detailValue: {
    color: DS.textPrimary,
    fontSize: typography.sizes.sm,
    fontFamily: typography.fonts.semibold,
    textAlign: "right",
    flex: 1,
  },
});
