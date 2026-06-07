import { StyleSheet, Text, View } from "react-native";
import { DS } from "../../src/design-system/colors";
import { typography } from "../../src/design-system/typography";
import { spacing } from "../../src/design-system/spacing";
import { ScreenWithHeader } from "../../src/components/ui/ScreenWithHeader";
import { MeshCard } from "../../src/components/ui/MeshCard";
import { MeshTopologyView } from "../../src/components/mesh/MeshTopologyView";
import { RouteBeam } from "../../src/components/mesh/RouteBeam";
import { type TopologyNode, type TopologyEdge } from "../../src/components/mesh/MeshTopologyView";

const NODES: TopologyNode[] = [
  { id: "self", label: "You",   x: 0.50, y: 0.08, role: "self"  },
  { id: "n1",   label: "Kupe",  x: 0.15, y: 0.55, role: "peer"  },
  { id: "n2",   label: "Rangi", x: 0.85, y: 0.55, role: "relay" },
  { id: "n3",   label: "Tama",  x: 0.50, y: 0.85, role: "peer"  },
];

const EDGES: TopologyEdge[] = [
  { from: "self", to: "n1",   strength: 88 },
  { from: "self", to: "n2",   strength: 62 },
  { from: "n2",   to: "n3",   strength: 44 },
];

const BEAMS = [
  { from: "You",  to: "Kupe",  quality: 88 },
  { from: "You",  to: "Rangi", quality: 62 },
  { from: "Rangi",to: "Tama",  quality: 44 },
];

export default function RouteVisualizationScreen() {
  return (
    <ScreenWithHeader title="Route Visualization" subtitle="Live mesh topology">
      <MeshCard title="Node Graph" glow accentColor={DS.blueBorder}>
        <MeshTopologyView nodes={NODES} edges={EDGES} height={240} />
      </MeshCard>

      <MeshCard title="Active Route Beams">
        {BEAMS.map((b) => (
          <View key={`${b.from}-${b.to}`} style={styles.beamRow}>
            <RouteBeam
              fromLabel={b.from}
              toLabel={b.to}
              signalStrength={b.quality}
              active
            />
          </View>
        ))}
      </MeshCard>

      <MeshCard title="Routing Stats">
        {[
          ["Total Routes",    "3"],
          ["Active Relays",   "1"],
          ["Avg Hop Count",   "1.7"],
          ["Route Age",       "4 min"],
        ].map(([label, value]) => (
          <View key={label} style={styles.row}>
            <Text style={styles.rowLabel}>{label}</Text>
            <Text style={styles.rowValue}>{value}</Text>
          </View>
        ))}
      </MeshCard>
    </ScreenWithHeader>
  );
}

const styles = StyleSheet.create({
  beamRow:  { paddingVertical: spacing.xs },
  row:      { flexDirection: "row", justifyContent: "space-between", paddingVertical: 6 },
  rowLabel: { color: DS.textSecondary, fontSize: typography.sizes.sm, fontFamily: typography.fonts.regular },
  rowValue: { color: DS.textPrimary,   fontSize: typography.sizes.sm, fontFamily: typography.fonts.bold    },
});
