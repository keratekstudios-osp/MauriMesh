import { StyleSheet, Text, View } from "react-native";
import { DS } from "../../src/design-system/colors";
import { typography } from "../../src/design-system/typography";
import { spacing } from "../../src/design-system/spacing";
import { ScreenWithHeader } from "../../src/components/ui/ScreenWithHeader";
import { MeshCard } from "../../src/components/ui/MeshCard";
import { PacketFlowView, type Packet } from "../../src/components/mesh/PacketFlowView";

const PACKETS: Packet[] = [
  { id: "pkt-001", status: "delivered", hopCount: 1, label: "MSG-001 / Kupe"     },
  { id: "pkt-002", status: "delivered", hopCount: 2, label: "MSG-002 / Rangi"    },
  { id: "pkt-003", status: "in-flight", hopCount: 1, label: "MSG-003 / Broadcast"},
  { id: "pkt-004", status: "dropped",               label: "MSG-004 / Tama"      },
  { id: "pkt-005", status: "delivered", hopCount: 3, label: "MSG-005 / Hine"     },
];

export default function PacketAnalysisScreen() {
  const delivered = PACKETS.filter((p) => p.status === "delivered").length;
  const dropped   = PACKETS.filter((p) => p.status === "dropped").length;
  const inFlight  = PACKETS.filter((p) => p.status === "in-flight").length;

  return (
    <ScreenWithHeader title="Packet Analysis" subtitle="Packet flow & delivery status">
      <MeshCard title="Packet Summary">
        <View style={styles.summary}>
          {[
            { label: "Delivered", value: delivered, color: DS.mauriGreen   },
            { label: "In Flight", value: inFlight,  color: DS.meshBlue     },
            { label: "Dropped",   value: dropped,   color: DS.dangerRed    },
            { label: "Total",     value: PACKETS.length, color: DS.textPrimary },
          ].map(({ label, value, color }) => (
            <View key={label} style={styles.stat}>
              <Text style={[styles.statVal, { color }]}>{value}</Text>
              <Text style={styles.statLbl}>{label}</Text>
            </View>
          ))}
        </View>
      </MeshCard>

      <MeshCard title="Flow View" accentColor={DS.blueBorder}>
        <PacketFlowView
          packets={PACKETS}
          fromLabel="This Node"
          toLabel="Network"
        />
      </MeshCard>

      <MeshCard title="Drop Analysis">
        {[
          ["Dropped count",      String(dropped)          ],
          ["Drop rate",          `${((dropped / PACKETS.length) * 100).toFixed(1)}%`],
          ["Cause",              "BLE range exceeded"     ],
          ["Recovery action",    "Store-forward queued"   ],
        ].map(([label, value]) => (
          <View key={label as string} style={styles.row}>
            <Text style={styles.rowLabel}>{label}</Text>
            <Text style={[styles.rowValue, label === "Drop rate" && dropped > 0 ? { color: DS.warningAmber } : {}]}>
              {value}
            </Text>
          </View>
        ))}
      </MeshCard>
    </ScreenWithHeader>
  );
}

const styles = StyleSheet.create({
  summary:  { flexDirection: "row", justifyContent: "space-around" },
  stat:     { alignItems: "center", gap: 2 },
  statVal:  { fontSize: typography.sizes.xl, fontFamily: typography.fonts.bold },
  statLbl:  { color: DS.textSecondary, fontSize: typography.sizes.xs, fontFamily: typography.fonts.regular },
  row:      { flexDirection: "row", justifyContent: "space-between", paddingVertical: 6 },
  rowLabel: { color: DS.textSecondary, fontSize: typography.sizes.sm, fontFamily: typography.fonts.regular },
  rowValue: { color: DS.textPrimary,   fontSize: typography.sizes.sm, fontFamily: typography.fonts.semibold },
});
