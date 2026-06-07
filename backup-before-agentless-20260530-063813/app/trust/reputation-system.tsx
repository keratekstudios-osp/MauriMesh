import { StyleSheet, Text, View } from "react-native";
import { DS } from "../../src/design-system/colors";
import { typography } from "../../src/design-system/typography";
import { radius } from "../../src/design-system/radius";
import { spacing } from "../../src/design-system/spacing";
import { ScreenWithHeader } from "../../src/components/ui/ScreenWithHeader";
import { MeshCard } from "../../src/components/ui/MeshCard";
import { MeshBadge } from "../../src/components/ui/MeshBadge";

const HISTORY = [
  { date: "14 May", event: "Relayed 12 messages",   delta: +8  },
  { date: "13 May", event: "Peer verified",          delta: +15 },
  { date: "12 May", event: "Message undelivered",    delta: -3  },
  { date: "11 May", event: "Relay node joined",      delta: +5  },
  { date: "10 May", event: "Initial join",           delta: +50 },
];

const MY_SCORE = 91;
const SCORE_COLOR = MY_SCORE > 80 ? DS.mauriGreen : MY_SCORE > 50 ? DS.warningAmber : DS.dangerRed;

export default function ReputationSystemScreen() {
  return (
    <ScreenWithHeader title="Reputation System" subtitle="Node reputation & history">
      <MeshCard title="Your Reputation" glow accentColor={DS.greenBorderBright}>
        <View style={styles.scoreCenter}>
          <View style={styles.scoreOrb}>
            <Text style={[styles.scoreNum, { color: SCORE_COLOR }]}>{MY_SCORE}</Text>
            <Text style={styles.scoreMax}>/100</Text>
          </View>
          <MeshBadge label="Verified Node" variant="green" />
        </View>
        <View style={styles.barWrap}>
          <View style={[styles.bar, { flex: MY_SCORE,           backgroundColor: SCORE_COLOR }]} />
          <View style={              { flex: 100 - MY_SCORE                                   }} />
        </View>
        <View style={styles.scoreStats}>
          {[
            { label: "Rank",        value: "#12 / 48" },
            { label: "Messages relayed", value: "142" },
            { label: "Uptime",      value: "94%"      },
          ].map(({ label, value }) => (
            <View key={label} style={styles.scoreStat}>
              <Text style={styles.scoreStatVal}>{value}</Text>
              <Text style={styles.scoreStatLbl}>{label}</Text>
            </View>
          ))}
        </View>
      </MeshCard>

      <Text style={styles.sectionLabel}>REPUTATION HISTORY</Text>

      {HISTORY.map((h, i) => (
        <View key={i} style={styles.historyRow}>
          <Text style={styles.historyDate}>{h.date}</Text>
          <Text style={styles.historyEvent}>{h.event}</Text>
          <Text style={[styles.historyDelta, { color: h.delta > 0 ? DS.mauriGreen : DS.dangerRed }]}>
            {h.delta > 0 ? `+${h.delta}` : h.delta}
          </Text>
        </View>
      ))}
    </ScreenWithHeader>
  );
}

const styles = StyleSheet.create({
  scoreCenter:   { alignItems: "center", gap: spacing.sm, marginBottom: spacing.sm },
  scoreOrb:      { flexDirection: "row", alignItems: "baseline", gap: 4 },
  scoreNum:      { fontSize: 52, fontFamily: typography.fonts.bold },
  scoreMax:      { color: DS.textSecondary, fontSize: typography.sizes.xl, fontFamily: typography.fonts.regular },
  barWrap:       { flexDirection: "row", height: 8, backgroundColor: DS.surface, borderRadius: radius.full, overflow: "hidden", marginBottom: spacing.md },
  bar:           { height: 8 },
  scoreStats:    { flexDirection: "row", justifyContent: "space-around" },
  scoreStat:     { alignItems: "center", gap: 2 },
  scoreStatVal:  { color: DS.textPrimary,   fontSize: typography.sizes.base, fontFamily: typography.fonts.bold },
  scoreStatLbl:  { color: DS.textSecondary, fontSize: typography.sizes.xs,   fontFamily: typography.fonts.regular },
  sectionLabel:  { color: DS.textSecondary, fontSize: typography.sizes.xs, fontFamily: typography.fonts.bold, letterSpacing: typography.tracking.wide },
  historyRow:    { flexDirection: "row", alignItems: "center", gap: spacing.sm, backgroundColor: DS.card, borderRadius: radius.md, borderWidth: 1, borderColor: DS.divider, padding: spacing.sm },
  historyDate:   { color: DS.mutedText, fontSize: typography.sizes.xs, fontFamily: typography.fonts.regular, width: 44, flexShrink: 0 },
  historyEvent:  { color: DS.textPrimary, fontSize: typography.sizes.sm, fontFamily: typography.fonts.regular, flex: 1 },
  historyDelta:  { fontSize: typography.sizes.sm, fontFamily: typography.fonts.bold, flexShrink: 0 },
});
