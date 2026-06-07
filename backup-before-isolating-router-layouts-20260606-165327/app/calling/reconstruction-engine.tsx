import { StyleSheet, Text, View } from "react-native";
import { DS } from "../../src/design-system/colors";
import { typography } from "../../src/design-system/typography";
import { radius } from "../../src/design-system/radius";
import { spacing } from "../../src/design-system/spacing";
import { ScreenWithHeader } from "../../src/components/ui/ScreenWithHeader";
import { MeshCard } from "../../src/components/ui/MeshCard";
import { MeshStatusPill } from "../../src/components/ui/MeshStatusPill";
import { PacketFlowView, type Packet } from "../../src/components/mesh/PacketFlowView";

const SAMPLE_PACKETS: Packet[] = [
  { id: "p01", status: "delivered", hopCount: 1, label: "Frame-001" },
  { id: "p02", status: "delivered", hopCount: 1, label: "Frame-002" },
  { id: "p03", status: "dropped",                label: "Frame-003" },
  { id: "p04", status: "delivered", hopCount: 2, label: "Frame-004" },
  { id: "p05", status: "in-flight", hopCount: 1, label: "Frame-005" },
];

export default function ReconstructionEngineScreen() {
  const delivered = SAMPLE_PACKETS.filter((p) => p.status === "delivered").length;
  const dropped   = SAMPLE_PACKETS.filter((p) => p.status === "dropped").length;
  const recRate   = ((delivered / SAMPLE_PACKETS.length) * 100).toFixed(1);

  return (
    <ScreenWithHeader title="Reconstruction Engine" subtitle="Packet reconstruction & repair">
      <MeshCard title="Engine Status" glow accentColor={DS.blueBorder}>
        <View style={styles.statusRow}>
          <MeshStatusPill label="FEC Active" variant="online"  />
          <MeshStatusPill label="PLC Active" variant="syncing" />
        </View>
        <Text style={styles.desc}>
          Forward Error Correction (FEC) and Packet Loss Concealment (PLC) rebuild
          lost audio frames using redundancy packets and interpolation.
        </Text>
      </MeshCard>

      <MeshCard title="Reconstruction Stats">
        {[
          ["Received frames",     String(SAMPLE_PACKETS.length) ],
          ["Reconstructed",       String(delivered)             ],
          ["Dropped (unrecoverable)", String(dropped)           ],
          ["Recovery rate",       `${recRate}%`                 ],
          ["FEC redundancy",      "20%"                         ],
          ["PLC algorithm",       "Linear interpolation"        ],
          ["Buffer depth",        "3 frames · 60 ms"           ],
        ].map(([label, value]) => (
          <View key={label as string} style={styles.row}>
            <Text style={styles.rowLabel}>{label}</Text>
            <Text style={[styles.rowValue, label === "Recovery rate" && { color: DS.mauriGreen }]}>
              {value}
            </Text>
          </View>
        ))}
      </MeshCard>

      <MeshCard title="Frame Flow">
        <PacketFlowView
          packets={SAMPLE_PACKETS}
          fromLabel="Sender"
          toLabel="Playback"
        />
      </MeshCard>
    </ScreenWithHeader>
  );
}

const styles = StyleSheet.create({
  statusRow: { flexDirection: "row", gap: spacing.xs, marginBottom: spacing.sm },
  desc:      { color: DS.textSecondary, fontSize: typography.sizes.xs, fontFamily: typography.fonts.regular, lineHeight: typography.sizes.xs * typography.lineHeight.relaxed },
  row:       { flexDirection: "row", justifyContent: "space-between", paddingVertical: 6 },
  rowLabel:  { color: DS.textSecondary, fontSize: typography.sizes.sm, fontFamily: typography.fonts.regular  },
  rowValue:  { color: DS.textPrimary,   fontSize: typography.sizes.sm, fontFamily: typography.fonts.semibold },
});
