import { StyleSheet, Text, View } from "react-native";
import { DS } from "../../src/design-system/colors";
import { typography } from "../../src/design-system/typography";
import { radius } from "../../src/design-system/radius";
import { spacing } from "../../src/design-system/spacing";
import { ScreenWithHeader } from "../../src/components/ui/ScreenWithHeader";
import { MeshCard } from "../../src/components/ui/MeshCard";
import { SignalMeter, rssiToBars } from "../../src/components/mesh/SignalMeter";

const SIGNAL_HISTORY = [62, 71, 68, 74, 58, 66, 72, 69, 75, 63, 70, 68];

export default function SignalVisualizationScreen() {
  const currentRssi = -63;
  const bars        = rssiToBars(currentRssi);
  const peak        = Math.max(...SIGNAL_HISTORY);
  const avg         = Math.round(SIGNAL_HISTORY.reduce((a, b) => a + b, 0) / SIGNAL_HISTORY.length);

  return (
    <ScreenWithHeader title="Signal Visualization" subtitle="Call signal quality & RSSI">
      <MeshCard title="Live Signal" glow>
        <View style={styles.liveRow}>
          <SignalMeter bars={bars} size="lg" color={DS.mauriGreen} />
          <View style={styles.liveMeta}>
            <Text style={styles.rssiLarge}>{currentRssi} dBm</Text>
            <Text style={styles.rssiQuality}>Excellent Signal</Text>
          </View>
        </View>
      </MeshCard>

      <MeshCard title="Signal History">
        <Text style={styles.hint}>RSSI over last 12 samples (dBm, lower = weaker)</Text>
        <View style={styles.chart}>
          {SIGNAL_HISTORY.map((val, i) => {
            const quality = val < 65 ? DS.mauriGreen : val < 80 ? DS.warningAmber : DS.dangerRed;
            const h = (1 - (val - 50) / 60) * 80;
            return (
              <View key={i} style={styles.barWrap}>
                <View style={[styles.bar, { height: h, backgroundColor: quality }]} />
              </View>
            );
          })}
        </View>
      </MeshCard>

      <MeshCard title="Signal Statistics">
        {[
          ["Current RSSI",   `${currentRssi} dBm`    ],
          ["Peak RSSI",      `-${peak} dBm`           ],
          ["Avg RSSI",       `-${avg} dBm`            ],
          ["Signal bars",    `${bars} / 5`            ],
          ["Transport",      "BLE 5.0"                ],
          ["Channel",        "Auto-select"            ],
          ["Encoding",       "Opus · 16 kHz · Mono"   ],
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
  liveRow:     { flexDirection: "row", alignItems: "center", gap: spacing.lg },
  liveMeta:    { gap: 4 },
  rssiLarge:   { color: DS.mauriGreen,    fontSize: typography.sizes["3xl"], fontFamily: typography.fonts.bold },
  rssiQuality: { color: DS.textSecondary, fontSize: typography.sizes.sm,     fontFamily: typography.fonts.regular },
  hint:        { color: DS.textSecondary, fontSize: typography.sizes.xs, fontFamily: typography.fonts.regular, marginBottom: spacing.sm },
  chart:       { flexDirection: "row", alignItems: "flex-end", justifyContent: "space-around", height: 80, gap: 4 },
  barWrap:     { flex: 1, height: 80, justifyContent: "flex-end" },
  bar:         { width: "100%", borderRadius: radius.xs },
  row:         { flexDirection: "row", justifyContent: "space-between", paddingVertical: 6 },
  rowLabel:    { color: DS.textSecondary, fontSize: typography.sizes.sm, fontFamily: typography.fonts.regular  },
  rowValue:    { color: DS.textPrimary,   fontSize: typography.sizes.sm, fontFamily: typography.fonts.semibold },
});
