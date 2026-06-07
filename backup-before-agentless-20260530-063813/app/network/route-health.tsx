import { StyleSheet, Text, View } from "react-native";
import { DS } from "../../src/design-system/colors";
import { typography } from "../../src/design-system/typography";
import { spacing } from "../../src/design-system/spacing";
import { ScreenWithHeader } from "../../src/components/ui/ScreenWithHeader";
import { MeshCard } from "../../src/components/ui/MeshCard";
import { RouteHealthCard } from "../../src/components/mesh/RouteHealthCard";

const ROUTES = [
  { nodeId: "MM-7A3F", name: "Kupe-Node-1",  latencyMs: 42,  packetLoss: 0.4, hops: 1, rssi: -52 },
  { nodeId: "MM-2D9E", name: "Rangi-Node-2", latencyMs: 118, packetLoss: 2.1, hops: 2, rssi: -71 },
  { nodeId: "MM-B1C4", name: "Tama-Relay-3", latencyMs: 290, packetLoss: 7.8, hops: 2, rssi: -84 },
];

export default function RouteHealthScreen() {
  return (
    <ScreenWithHeader title="Route Health" subtitle="Per-peer route quality metrics">
      <MeshCard title="Health Summary">
        <View style={styles.summary}>
          {[
            { label: "Healthy",   value: "1", color: DS.mauriGreen  },
            { label: "Fair",      value: "1", color: DS.warningAmber },
            { label: "Poor",      value: "1", color: DS.dangerRed   },
          ].map(({ label, value, color }) => (
            <View key={label} style={styles.stat}>
              <Text style={[styles.statVal, { color }]}>{value}</Text>
              <Text style={styles.statLbl}>{label}</Text>
            </View>
          ))}
        </View>
      </MeshCard>

      <Text style={styles.sectionLabel}>ROUTE CARDS</Text>

      {ROUTES.map((r) => (
        <RouteHealthCard
          key={r.nodeId}
          nodeId={r.nodeId}
          name={r.name}
          latencyMs={r.latencyMs}
          packetLoss={r.packetLoss}
          hops={r.hops}
          rssi={r.rssi}
        />
      ))}
    </ScreenWithHeader>
  );
}

const styles = StyleSheet.create({
  summary:      { flexDirection: "row", justifyContent: "space-around" },
  stat:         { alignItems: "center", gap: 2 },
  statVal:      { fontSize: typography.sizes.xl, fontFamily: typography.fonts.bold },
  statLbl:      { color: DS.textSecondary, fontSize: typography.sizes.xs, fontFamily: typography.fonts.regular },
  sectionLabel: { color: DS.textSecondary, fontSize: typography.sizes.xs, fontFamily: typography.fonts.bold, letterSpacing: typography.tracking.wide },
});
