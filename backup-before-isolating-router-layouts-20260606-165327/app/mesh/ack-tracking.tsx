import { StyleSheet, Text, View } from "react-native";
import { DS } from "../../src/design-system/colors";
import { typography } from "../../src/design-system/typography";
import { spacing } from "../../src/design-system/spacing";
import { ScreenWithHeader } from "../../src/components/ui/ScreenWithHeader";
import { MeshCard } from "../../src/components/ui/MeshCard";
import { MeshBadge } from "../../src/components/ui/MeshBadge";
import { AckPathView } from "../../src/components/mesh/AckPathView";
import { type AckNode } from "../../src/components/mesh/AckPathView";

const TRACKED = [
  {
    msgId: "MSG-001",
    label: "Hello mesh",
    nodes: [
      { id: "origin", label: "You",   acked: true  },
      { id: "r1",     label: "Kupe",  acked: true  },
      { id: "r2",     label: "Rangi", acked: false },
      { id: "dest",   label: "Tama",  acked: false },
    ] satisfies AckNode[],
  },
  {
    msgId: "MSG-002",
    label: "Status check",
    nodes: [
      { id: "origin", label: "You",   acked: true },
      { id: "r1",     label: "Kupe",  acked: true },
      { id: "dest",   label: "Rangi", acked: true },
    ] satisfies AckNode[],
  },
];

export default function AckTrackingScreen() {
  return (
    <ScreenWithHeader title="ACK Tracking" subtitle="Message acknowledgement paths">
      {TRACKED.map((t) => {
        const allAcked = t.nodes.every((n) => n.acked);
        return (
          <MeshCard key={t.msgId} title={t.msgId}>
            <View style={styles.msgHeader}>
              <Text style={styles.msgLabel}>{t.label}</Text>
              <MeshBadge
                label={allAcked ? "Delivered" : "In Transit"}
                variant={allAcked ? "green" : "amber"}
              />
            </View>
            <AckPathView nodes={t.nodes} direction="horizontal" />
          </MeshCard>
        );
      })}

      <MeshCard title="ACK Statistics">
        {[
          ["Messages sent",    "14"],
          ["Fully acked",      "12"],
          ["Partially acked",   "2"],
          ["Avg delivery time", "1.4 s"],
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
  msgHeader: { flexDirection: "row", alignItems: "center", justifyContent: "space-between", marginBottom: spacing.sm },
  msgLabel:  { color: DS.textSecondary, fontSize: typography.sizes.sm, fontFamily: typography.fonts.regular, flex: 1 },
  row:       { flexDirection: "row", justifyContent: "space-between", paddingVertical: 6 },
  rowLabel:  { color: DS.textSecondary, fontSize: typography.sizes.sm, fontFamily: typography.fonts.regular },
  rowValue:  { color: DS.textPrimary,   fontSize: typography.sizes.sm, fontFamily: typography.fonts.bold    },
});
