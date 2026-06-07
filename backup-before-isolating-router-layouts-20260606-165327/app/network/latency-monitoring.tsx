import { StyleSheet, Text, View } from "react-native";
import { DS } from "../../src/design-system/colors";
import { typography } from "../../src/design-system/typography";
import { spacing } from "../../src/design-system/spacing";
import { radius } from "../../src/design-system/radius";
import { ScreenWithHeader } from "../../src/components/ui/ScreenWithHeader";
import { MeshCard } from "../../src/components/ui/MeshCard";

const LATENCY_DATA: { peer: string; p50: number; p90: number; p99: number; jitter: number }[] = [
  { peer: "Kupe-Node-1",  p50: 42,  p90: 68,  p99: 112, jitter: 8  },
  { peer: "Rangi-Node-2", p50: 118, p90: 188, p99: 310, jitter: 24 },
  { peer: "Tama-Relay-3", p50: 290, p90: 420, p99: 680, jitter: 55 },
];

function msColor(ms: number) {
  if (ms < 80)  return DS.mauriGreen;
  if (ms < 300) return DS.warningAmber;
  return DS.dangerRed;
}

export default function LatencyMonitoringScreen() {
  return (
    <ScreenWithHeader title="Latency Monitoring" subtitle="Round-trip time per node">
      <MeshCard title="Network Averages">
        {[
          ["Median (P50)",     "150 ms"],
          ["95th Percentile",  "225 ms"],
          ["99th Percentile",  "367 ms"],
          ["Avg Jitter",        "29 ms"],
        ].map(([label, value]) => (
          <View key={label as string} style={styles.row}>
            <Text style={styles.rowLabel}>{label}</Text>
            <Text style={styles.rowValue}>{value}</Text>
          </View>
        ))}
      </MeshCard>

      <Text style={styles.sectionLabel}>PER-PEER BREAKDOWN</Text>

      {LATENCY_DATA.map((d) => (
        <MeshCard key={d.peer} title={d.peer}>
          <View style={styles.latencyRow}>
            <LatCell label="P50"    value={d.p50}    />
            <LatCell label="P90"    value={d.p90}    />
            <LatCell label="P99"    value={d.p99}    />
            <LatCell label="Jitter" value={d.jitter} />
          </View>
          <View style={styles.barWrap}>
            <View style={[styles.bar, { flex: Math.min(d.p50 / 8, 100),         backgroundColor: msColor(d.p50) }]} />
            <View style={              { flex: 100 - Math.min(d.p50 / 8, 100)                                   }} />
          </View>
        </MeshCard>
      ))}
    </ScreenWithHeader>
  );
}

function LatCell({ label, value }: { label: string; value: number }) {
  return (
    <View style={styles.latCell}>
      <Text style={[styles.latVal, { color: msColor(value) }]}>{value}</Text>
      <Text style={styles.latUnit}>ms</Text>
      <Text style={styles.latLabel}>{label}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  row:          { flexDirection: "row", justifyContent: "space-between", paddingVertical: 6 },
  rowLabel:     { color: DS.textSecondary, fontSize: typography.sizes.sm, fontFamily: typography.fonts.regular },
  rowValue:     { color: DS.textPrimary,   fontSize: typography.sizes.sm, fontFamily: typography.fonts.bold    },
  sectionLabel: { color: DS.textSecondary, fontSize: typography.sizes.xs, fontFamily: typography.fonts.bold, letterSpacing: typography.tracking.wide },
  latencyRow:   { flexDirection: "row", justifyContent: "space-around" },
  latCell:      { alignItems: "center", gap: 2 },
  latVal:       { fontSize: typography.sizes.lg, fontFamily: typography.fonts.bold },
  latUnit:      { color: DS.textSecondary, fontSize: typography.sizes.xs, fontFamily: typography.fonts.regular },
  latLabel:     { color: DS.textSecondary, fontSize: typography.sizes.xs, fontFamily: typography.fonts.regular },
  barWrap:      { flexDirection: "row", height: 4, backgroundColor: DS.surface, borderRadius: radius.full, marginTop: spacing.sm, overflow: "hidden" },
  bar:          { height: 4 },
});
