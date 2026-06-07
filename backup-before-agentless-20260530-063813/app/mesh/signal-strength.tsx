import { StyleSheet, Text, View } from "react-native";
import { DS } from "../../src/design-system/colors";
import { typography } from "../../src/design-system/typography";
import { spacing } from "../../src/design-system/spacing";
import { radius } from "../../src/design-system/radius";
import { ScreenWithHeader } from "../../src/components/ui/ScreenWithHeader";
import { MeshCard } from "../../src/components/ui/MeshCard";
import { SignalMeter, rssiToBars } from "../../src/components/mesh/SignalMeter";

const PEERS = [
  { id: "MM-7A3F", name: "Kupe-Node-1",  rssi: -52, hops: 1 },
  { id: "MM-2D9E", name: "Rangi-Node-2", rssi: -71, hops: 2 },
  { id: "MM-B1C4", name: "Tama-Relay-3", rssi: -84, hops: 2 },
  { id: "MM-E5F2", name: "Hine-Node-4",  rssi: -95, hops: 3 },
];

function rssiQuality(rssi: number) {
  if (rssi >= -65) return { label: "Excellent", color: DS.mauriGreen };
  if (rssi >= -75) return { label: "Good",      color: DS.meshBlue    };
  if (rssi >= -85) return { label: "Fair",      color: DS.warningAmber };
  return                   { label: "Weak",     color: DS.dangerRed   };
}

export default function SignalStrengthScreen() {
  return (
    <ScreenWithHeader title="Signal Strength" subtitle="Per-peer RSSI & quality">
      <MeshCard title="Signal Overview">
        <Text style={styles.hint}>
          RSSI measured in dBm · closer to 0 = stronger signal
        </Text>
      </MeshCard>

      {PEERS.map((p) => {
        const q = rssiQuality(p.rssi);
        const bars = rssiToBars(p.rssi);
        return (
          <View key={p.id} style={styles.card}>
            <View style={styles.cardLeft}>
              <Text style={styles.peerName}>{p.name}</Text>
              <Text style={styles.peerId}>{p.id}</Text>
            </View>
            <View style={styles.cardRight}>
              <SignalMeter bars={bars} size="lg" color={q.color} />
              <Text style={[styles.rssi, { color: q.color }]}>{p.rssi} dBm</Text>
              <Text style={[styles.quality, { color: q.color }]}>{q.label}</Text>
              <Text style={styles.hops}>{p.hops} {p.hops === 1 ? "hop" : "hops"}</Text>
            </View>
          </View>
        );
      })}
    </ScreenWithHeader>
  );
}

const styles = StyleSheet.create({
  hint:      { color: DS.textSecondary, fontSize: typography.sizes.xs, fontFamily: typography.fonts.regular },
  card: {
    flexDirection:   "row",
    alignItems:      "center",
    justifyContent:  "space-between",
    backgroundColor: DS.card,
    borderRadius:    radius.lg,
    borderWidth:     1,
    borderColor:     DS.divider,
    padding:         spacing.md,
  },
  cardLeft:  { flex: 1, gap: 4 },
  cardRight: { alignItems: "flex-end", gap: 4 },
  peerName:  { color: DS.textPrimary,   fontSize: typography.sizes.base, fontFamily: typography.fonts.semibold },
  peerId:    { color: DS.mutedText,     fontSize: typography.sizes.xs,   fontFamily: typography.fonts.regular  },
  rssi:      { fontSize: typography.sizes.lg,   fontFamily: typography.fonts.bold    },
  quality:   { fontSize: typography.sizes.xs,   fontFamily: typography.fonts.bold    },
  hops:      { color: DS.textSecondary, fontSize: typography.sizes.xs,   fontFamily: typography.fonts.regular  },
});
