import { useState } from "react";
import { StyleSheet, Switch, Text, View } from "react-native";
import { DS } from "../../src/design-system/colors";
import { typography } from "../../src/design-system/typography";
import { spacing } from "../../src/design-system/spacing";
import { ScreenWithHeader } from "../../src/components/ui/ScreenWithHeader";
import { MeshCard } from "../../src/components/ui/MeshCard";

const PRIVACY_GROUPS = [
  {
    title: "Telemetry",
    items: [
      { key: "analytics",  label: "Usage Analytics",    sub: "Anonymous feature usage statistics" },
      { key: "crash",      label: "Crash Reports",       sub: "Automatic crash logs — never includes messages" },
      { key: "perf",       label: "Performance Metrics", sub: "Latency & battery impact data" },
    ],
  },
  {
    title: "Visibility",
    items: [
      { key: "discover",   label: "Discoverable",        sub: "Allow nearby nodes to detect you" },
      { key: "read_rcpt",  label: "Read Receipts",       sub: "Send read confirmations to peers" },
      { key: "typing",     label: "Typing Indicators",   sub: "Broadcast typing status to peers" },
    ],
  },
  {
    title: "Data Storage",
    items: [
      { key: "local_logs", label: "Store Diagnostic Logs", sub: "Keep logs for troubleshooting" },
      { key: "cache_mesh", label: "Cache Mesh State",       sub: "Remember topology between sessions" },
    ],
  },
];

export default function PrivacyScreen() {
  const defaults = Object.fromEntries(
    PRIVACY_GROUPS.flatMap((g) =>
      g.items.map((i) => [i.key, !["analytics", "perf"].includes(i.key)])
    )
  );
  const [state, setState] = useState<Record<string, boolean>>(defaults);

  return (
    <ScreenWithHeader title="Privacy" subtitle="Analytics & data sharing preferences">
      {PRIVACY_GROUPS.map((group) => (
        <MeshCard key={group.title} title={group.title}>
          {group.items.map((item) => (
            <View key={item.key} style={styles.row}>
              <View style={styles.text}>
                <Text style={styles.label}>{item.label}</Text>
                <Text style={styles.sub}>{item.sub}</Text>
              </View>
              <Switch
                value={state[item.key]}
                onValueChange={(v) => setState((s) => ({ ...s, [item.key]: v }))}
                trackColor={{ false: DS.surface, true: DS.greenDim }}
                thumbColor={state[item.key] ? DS.mauriGreen : DS.textSecondary}
              />
            </View>
          ))}
        </MeshCard>
      ))}
      <Text style={styles.note}>
        MauriMesh never reads, transmits, or stores message contents on external servers. All data is local.
      </Text>
    </ScreenWithHeader>
  );
}

const styles = StyleSheet.create({
  row:   { flexDirection: "row", alignItems: "center", justifyContent: "space-between", paddingVertical: spacing.xs },
  text:  { flex: 1, gap: 2 },
  label: { color: DS.textPrimary,   fontSize: typography.sizes.base, fontFamily: typography.fonts.medium  },
  sub:   { color: DS.textSecondary, fontSize: typography.sizes.xs,   fontFamily: typography.fonts.regular },
  note:  { color: DS.mutedText, fontSize: typography.sizes.xs, fontFamily: typography.fonts.regular, textAlign: "center", lineHeight: typography.sizes.xs * typography.lineHeight.relaxed },
});
