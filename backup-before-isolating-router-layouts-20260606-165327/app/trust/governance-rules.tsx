import { useState } from "react";
import { Pressable, StyleSheet, Text, View } from "react-native";
import { DS } from "../../src/design-system/colors";
import { typography } from "../../src/design-system/typography";
import { radius } from "../../src/design-system/radius";
import { spacing } from "../../src/design-system/spacing";
import { ScreenWithHeader } from "../../src/components/ui/ScreenWithHeader";
import { MeshCard } from "../../src/components/ui/MeshCard";
import { MeshBadge } from "../../src/components/ui/MeshBadge";

type RuleStatus = "active" | "inactive" | "draft";

const RULES: { id: string; name: string; desc: string; priority: number; status: RuleStatus }[] = [
  { id: "R-001", name: "Kin Routing Priority",   desc: "Route through verified kin nodes first",  priority: 1, status: "active"   },
  { id: "R-002", name: "Stranger Relay Limit",   desc: "Cap relays via unknown nodes to 3 hops",  priority: 2, status: "active"   },
  { id: "R-003", name: "Zero-Knowledge Routing", desc: "Route without revealing message content",  priority: 3, status: "active"   },
  { id: "R-004", name: "Consent-First Discovery",desc: "Require consent before peer visibility",  priority: 4, status: "active"   },
  { id: "R-005", name: "Emergency Broadcast",    desc: "Allow untrusted relay in emergency mode",  priority: 5, status: "inactive" },
  { id: "R-006", name: "Cross-Mesh Federation",  desc: "Allow bridging to external mesh networks", priority: 6, status: "draft"    },
];

const statusVariant: Record<RuleStatus, "green" | "amber" | "blue"> = {
  active:   "green",
  inactive: "amber",
  draft:    "blue",
};

export default function GovernanceRulesScreen() {
  const [expanded, setExpanded] = useState<string | null>(null);

  return (
    <ScreenWithHeader title="Governance Rules" subtitle="Active mesh policy & ruleset">
      <MeshCard title="Ruleset Info">
        {[
          ["Version",    "2.1.4"],
          ["Published",  "10 May 2026"],
          ["Authority",  "MauriMesh Community DAO"],
          ["Active rules","4 of 6"],
        ].map(([label, value]) => (
          <View key={label as string} style={styles.row}>
            <Text style={styles.rowLabel}>{label}</Text>
            <Text style={styles.rowValue}>{value}</Text>
          </View>
        ))}
      </MeshCard>

      <Text style={styles.sectionLabel}>RULES</Text>

      {RULES.map((rule) => (
        <Pressable
          key={rule.id}
          onPress={() => setExpanded(expanded === rule.id ? null : rule.id)}
          style={({ pressed }) => [styles.rule, pressed && styles.rulePressed]}
        >
          <View style={styles.ruleHeader}>
            <Text style={styles.rulePriority}>#{rule.priority}</Text>
            <View style={styles.ruleMeta}>
              <Text style={styles.ruleName}>{rule.name}</Text>
              <Text style={styles.ruleId}>{rule.id}</Text>
            </View>
            <MeshBadge label={rule.status} variant={statusVariant[rule.status]} />
          </View>
          {expanded === rule.id && (
            <Text style={styles.ruleDesc}>{rule.desc}</Text>
          )}
        </Pressable>
      ))}
    </ScreenWithHeader>
  );
}

const styles = StyleSheet.create({
  row:          { flexDirection: "row", justifyContent: "space-between", paddingVertical: 6 },
  rowLabel:     { color: DS.textSecondary, fontSize: typography.sizes.sm, fontFamily: typography.fonts.regular  },
  rowValue:     { color: DS.textPrimary,   fontSize: typography.sizes.sm, fontFamily: typography.fonts.semibold },
  sectionLabel: { color: DS.textSecondary, fontSize: typography.sizes.xs, fontFamily: typography.fonts.bold, letterSpacing: typography.tracking.wide },
  rule: {
    backgroundColor: DS.card, borderRadius: radius.lg, borderWidth: 1,
    borderColor: DS.divider, padding: spacing.md, gap: spacing.xs,
  },
  rulePressed:  { opacity: 0.80 },
  ruleHeader:   { flexDirection: "row", alignItems: "center", gap: spacing.sm },
  rulePriority: { color: DS.textSecondary, fontSize: typography.sizes.sm, fontFamily: typography.fonts.bold, width: 20, flexShrink: 0 },
  ruleMeta:     { flex: 1, gap: 2 },
  ruleName:     { color: DS.textPrimary,   fontSize: typography.sizes.base, fontFamily: typography.fonts.semibold },
  ruleId:       { color: DS.mutedText,     fontSize: typography.sizes.xs,   fontFamily: typography.fonts.regular  },
  ruleDesc:     { color: DS.textSecondary, fontSize: typography.sizes.sm, fontFamily: typography.fonts.regular, lineHeight: typography.sizes.sm * typography.lineHeight.relaxed, marginTop: spacing.xs },
});
