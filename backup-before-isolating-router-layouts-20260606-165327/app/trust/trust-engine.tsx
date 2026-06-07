import { StyleSheet, Text, View } from "react-native";
import { DS } from "../../src/design-system/colors";
import { typography } from "../../src/design-system/typography";
import { radius } from "../../src/design-system/radius";
import { spacing } from "../../src/design-system/spacing";
import { ScreenWithHeader } from "../../src/components/ui/ScreenWithHeader";
import { MeshCard } from "../../src/components/ui/MeshCard";
import { MeshBadge } from "../../src/components/ui/MeshBadge";

type TrustLevel = "verified" | "trusted" | "unknown" | "blocked";

const PEERS: { name: string; id: string; score: number; level: TrustLevel; interactions: number }[] = [
  { name: "Kupe-Node-1",  id: "MM-7A3F", score: 96, level: "verified", interactions: 142 },
  { name: "Rangi-Node-2", id: "MM-2D9E", score: 72, level: "trusted",  interactions: 38  },
  { name: "Tama-Relay-3", id: "MM-B1C4", score: 55, level: "unknown",  interactions: 6   },
];

const levelColor: Record<TrustLevel, string> = {
  verified: DS.mauriGreen,
  trusted:  DS.meshBlue,
  unknown:  DS.warningAmber,
  blocked:  DS.dangerRed,
};

const levelVariant: Record<TrustLevel, "green" | "blue" | "amber" | "red"> = {
  verified: "green",
  trusted:  "blue",
  unknown:  "amber",
  blocked:  "red",
};

function TrustBar({ score }: { score: number }) {
  const color = score > 80 ? DS.mauriGreen : score > 50 ? DS.warningAmber : DS.dangerRed;
  return (
    <View style={styles.barWrap}>
      <View style={[styles.bar, { flex: score,         backgroundColor: color }]} />
      <View style={              { flex: 100 - score                           }} />
    </View>
  );
}

export default function TrustEngineScreen() {
  return (
    <ScreenWithHeader title="Trust Engine" subtitle="Peer trust scores & verification">
      <MeshCard title="Trust Policy">
        {[
          ["Algorithm",    "Cumulative Interaction Score"],
          ["Decay period", "30 days"],
          ["Threshold",    "80 = Verified · 50 = Trusted"],
        ].map(([label, value]) => (
          <View key={label as string} style={styles.row}>
            <Text style={styles.rowLabel}>{label}</Text>
            <Text style={styles.rowValue}>{value}</Text>
          </View>
        ))}
      </MeshCard>

      <Text style={styles.sectionLabel}>PEER TRUST SCORES</Text>

      {PEERS.map((p) => (
        <MeshCard key={p.id} accentColor={`${levelColor[p.level]}35`}>
          <View style={styles.peerHeader}>
            <View style={styles.peerMeta}>
              <Text style={styles.peerName}>{p.name}</Text>
              <Text style={styles.peerId}>{p.id}</Text>
            </View>
            <MeshBadge label={p.level} variant={levelVariant[p.level]} />
          </View>
          <TrustBar score={p.score} />
          <View style={styles.peerStats}>
            <Text style={[styles.scoreText, { color: levelColor[p.level] }]}>{p.score} / 100</Text>
            <Text style={styles.interactions}>{p.interactions} interactions</Text>
          </View>
        </MeshCard>
      ))}
    </ScreenWithHeader>
  );
}

const styles = StyleSheet.create({
  row:           { flexDirection: "row", justifyContent: "space-between", paddingVertical: 6 },
  rowLabel:      { color: DS.textSecondary, fontSize: typography.sizes.sm, fontFamily: typography.fonts.regular  },
  rowValue:      { color: DS.textPrimary,   fontSize: typography.sizes.sm, fontFamily: typography.fonts.semibold },
  sectionLabel:  { color: DS.textSecondary, fontSize: typography.sizes.xs, fontFamily: typography.fonts.bold, letterSpacing: typography.tracking.wide },
  peerHeader:    { flexDirection: "row", alignItems: "center", justifyContent: "space-between", marginBottom: spacing.sm },
  peerMeta:      { gap: 2 },
  peerName:      { color: DS.textPrimary,   fontSize: typography.sizes.base, fontFamily: typography.fonts.semibold },
  peerId:        { color: DS.mutedText,     fontSize: typography.sizes.xs,   fontFamily: typography.fonts.regular  },
  barWrap:       { flexDirection: "row", height: 6, backgroundColor: DS.surface, borderRadius: radius.full, overflow: "hidden", marginBottom: spacing.xs },
  bar:           { height: 6 },
  peerStats:     { flexDirection: "row", justifyContent: "space-between", marginTop: 4 },
  scoreText:     { fontSize: typography.sizes.sm, fontFamily: typography.fonts.bold    },
  interactions:  { color: DS.textSecondary, fontSize: typography.sizes.xs, fontFamily: typography.fonts.regular },
});
