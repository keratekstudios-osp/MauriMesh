import { StyleSheet, Text, View } from "react-native";
import { DS } from "../../src/design-system/colors";
import { typography } from "../../src/design-system/typography";
import { radius } from "../../src/design-system/radius";
import { spacing } from "../../src/design-system/spacing";
import { ScreenWithHeader } from "../../src/components/ui/ScreenWithHeader";
import { MeshCard } from "../../src/components/ui/MeshCard";

export default function CallAnalyticsScreen() {
  return (
    <ScreenWithHeader title="Call Analytics" subtitle="Pixel Calling statistics">
      <MeshCard title="Current / Last Call" glow>
        <View style={styles.stats}>
          {[
            { label: "Duration",       value: "4:32",  color: DS.textPrimary  },
            { label: "Avg Bitrate",    value: "24 kbps",color: DS.mauriGreen  },
            { label: "Packet Loss",    value: "0.8%",  color: DS.mauriGreen   },
            { label: "Jitter",         value: "12 ms", color: DS.warningAmber },
          ].map(({ label, value, color }) => (
            <View key={label} style={styles.stat}>
              <Text style={[styles.statVal, { color }]}>{value}</Text>
              <Text style={styles.statLbl}>{label}</Text>
            </View>
          ))}
        </View>
      </MeshCard>

      <MeshCard title="Quality Timeline">
        <Text style={styles.hint}>
          Quality score over the last call (stub — real-time telemetry renders here when active)
        </Text>
        <View style={styles.timeline}>
          {[92, 88, 95, 82, 91, 78, 94, 96, 90, 85].map((q, i) => (
            <View key={i} style={styles.barWrap}>
              <View style={[
                styles.bar,
                { height: (q / 100) * 80, backgroundColor: q > 85 ? DS.mauriGreen : q > 70 ? DS.warningAmber : DS.dangerRed },
              ]} />
            </View>
          ))}
        </View>
      </MeshCard>

      <MeshCard title="Session Summary">
        {[
          ["Total calls",       "8"          ],
          ["Total duration",    "48 min"     ],
          ["Avg call length",   "6 min"      ],
          ["Best quality",      "98 / 100"   ],
          ["Avg quality",       "87 / 100"   ],
          ["Calls via relay",   "3"          ],
          ["Dropped calls",     "0"          ],
        ].map(([label, value]) => (
          <View key={label as string} style={styles.row}>
            <Text style={styles.rowLabel}>{label}</Text>
            <Text style={styles.rowValue}>{value}</Text>
          </View>
        ))}
      </MeshCard>
    </ScreenWithHeader>
  );
}

const styles = StyleSheet.create({
  stats:    { flexDirection: "row", justifyContent: "space-around" },
  stat:     { alignItems: "center", gap: 2 },
  statVal:  { fontSize: typography.sizes.lg, fontFamily: typography.fonts.bold },
  statLbl:  { color: DS.textSecondary, fontSize: typography.sizes.xs, fontFamily: typography.fonts.regular },
  hint:     { color: DS.textSecondary, fontSize: typography.sizes.xs, fontFamily: typography.fonts.regular, marginBottom: spacing.sm },
  timeline: { flexDirection: "row", alignItems: "flex-end", justifyContent: "space-around", height: 80, gap: 4 },
  barWrap:  { flex: 1, height: 80, justifyContent: "flex-end" },
  bar:      { width: "100%", borderRadius: radius.xs },
  row:      { flexDirection: "row", justifyContent: "space-between", paddingVertical: 6 },
  rowLabel: { color: DS.textSecondary, fontSize: typography.sizes.sm, fontFamily: typography.fonts.regular  },
  rowValue: { color: DS.textPrimary,   fontSize: typography.sizes.sm, fontFamily: typography.fonts.semibold },
});
