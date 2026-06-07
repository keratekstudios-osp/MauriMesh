import { StyleSheet, Text, View } from "react-native";
import { DS } from "../../src/design-system/colors";
import { typography } from "../../src/design-system/typography";
import { spacing } from "../../src/design-system/spacing";
import { radius } from "../../src/design-system/radius";
import { ScreenWithHeader } from "../../src/components/ui/ScreenWithHeader";
import { MeshCard } from "../../src/components/ui/MeshCard";

const DAILY = [
  { day: "Mon", delivered: 48, failed: 2 },
  { day: "Tue", delivered: 61, failed: 1 },
  { day: "Wed", delivered: 55, failed: 4 },
  { day: "Thu", delivered: 72, failed: 0 },
  { day: "Fri", delivered: 44, failed: 3 },
  { day: "Sat", delivered: 31, failed: 1 },
  { day: "Sun", delivered: 18, failed: 2 },
];

export default function DeliveryAnalyticsScreen() {
  const totalDelivered = DAILY.reduce((a, d) => a + d.delivered, 0);
  const totalFailed    = DAILY.reduce((a, d) => a + d.failed,    0);
  const rate = ((totalDelivered / (totalDelivered + totalFailed)) * 100).toFixed(1);
  const maxVal = Math.max(...DAILY.map((d) => d.delivered + d.failed));

  return (
    <ScreenWithHeader title="Delivery Analytics" subtitle="Message delivery success rates">
      <MeshCard title="7-Day Summary">
        <View style={styles.summary}>
          {[
            { label: "Delivered",  value: String(totalDelivered), color: DS.mauriGreen   },
            { label: "Failed",     value: String(totalFailed),    color: DS.dangerRed    },
            { label: "Rate",       value: `${rate}%`,             color: DS.meshBlue     },
          ].map(({ label, value, color }) => (
            <View key={label} style={styles.stat}>
              <Text style={[styles.statVal, { color }]}>{value}</Text>
              <Text style={styles.statLbl}>{label}</Text>
            </View>
          ))}
        </View>
      </MeshCard>

      <MeshCard title="Daily Breakdown">
        <View style={styles.chart}>
          {DAILY.map((d) => {
            const total = d.delivered + d.failed;
            const deliveredH = (d.delivered / maxVal) * 100;
            const failedH    = (d.failed    / maxVal) * 100;
            return (
              <View key={d.day} style={styles.barGroup}>
                <View style={styles.barStack}>
                  <View style={[styles.barSegment, { height: failedH, backgroundColor: DS.dangerRed }]} />
                  <View style={[styles.barSegment, { height: deliveredH, backgroundColor: DS.mauriGreen }]} />
                </View>
                <Text style={styles.barDay}>{d.day}</Text>
              </View>
            );
          })}
        </View>
      </MeshCard>

      <MeshCard title="Performance Breakdown">
        {[
          ["Avg delivery time",  "1.2 s"  ],
          ["Max delivery time",  "8.4 s"  ],
          ["Retry rate",         "4.2%"   ],
          ["Store-forward used", "12%"    ],
          ["Best peer",          "Kupe-1" ],
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
  summary:    { flexDirection: "row", justifyContent: "space-around" },
  stat:       { alignItems: "center", gap: 2 },
  statVal:    { fontSize: typography.sizes.xl, fontFamily: typography.fonts.bold },
  statLbl:    { color: DS.textSecondary, fontSize: typography.sizes.xs, fontFamily: typography.fonts.regular },
  chart:      { flexDirection: "row", alignItems: "flex-end", justifyContent: "space-around", height: 120, marginBottom: spacing.xs },
  barGroup:   { alignItems: "center", gap: 4, flex: 1 },
  barStack:   { flex: 1, width: 12, justifyContent: "flex-end", gap: 1 },
  barSegment: { width: 12, borderRadius: radius.xs },
  barDay:     { color: DS.textSecondary, fontSize: 9, fontFamily: typography.fonts.regular },
  row:        { flexDirection: "row", justifyContent: "space-between", paddingVertical: 6 },
  rowLabel:   { color: DS.textSecondary, fontSize: typography.sizes.sm, fontFamily: typography.fonts.regular },
  rowValue:   { color: DS.textPrimary,   fontSize: typography.sizes.sm, fontFamily: typography.fonts.semibold },
});
