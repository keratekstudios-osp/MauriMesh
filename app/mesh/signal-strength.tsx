import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { useRouter } from "expo-router";
import { useLiveMesh } from "../../src/maurimesh/live/useLiveMesh";
import {
  LiveScreen,
  Card,
  Bars,
  EmptyNote,
} from "../../src/maurimesh/live/liveMeshUi";
import {
  rssiQuality,
  timeAgo,
  nodeDisplayName,
} from "../../src/maurimesh/live/liveMeshFormat";

export default function SignalStrengthScreen() {
  const router = useRouter();
  const { state } = useLiveMesh(2000);

  return (
    <LiveScreen
      title="Signal Strength"
      subtitle="Per-peer RSSI & quality"
      onBack={() => router.back()}
    >
      <Card title="Signal Overview">
        <EmptyNote text="RSSI measured in dBm — closer to 0 = stronger signal. Values come from the live BLE scan." />
      </Card>

      {state.nodes.length === 0 ? (
        <Card>
          <EmptyNote text="No live signal readings yet. Start a BLE scan to measure nearby node strength." />
        </Card>
      ) : (
        state.nodes.map((n) => {
          const q = rssiQuality(n.lastRssi);
          return (
            <View key={n.id} style={styles.row}>
              <View style={styles.left}>
                <Text style={styles.name}>{nodeDisplayName(n)}</Text>
                <Text style={styles.seen}>last {timeAgo(n.lastSeenAt)}</Text>
              </View>
              <View style={styles.right}>
                <Bars bars={q.bars} color={q.color} />
                <Text style={[styles.rssi, { color: q.color }]}>
                  {n.lastRssi ?? 0} dBm
                </Text>
                <Text style={[styles.quality, { color: q.color }]}>{q.label}</Text>
              </View>
            </View>
          );
        })
      )}
    </LiveScreen>
  );
}

const styles = StyleSheet.create({
  row: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.1)",
    borderRadius: 16,
    padding: 16,
    marginBottom: 12,
    backgroundColor: "rgba(255,255,255,0.035)",
  },
  left: { flex: 1, gap: 3 },
  right: { alignItems: "flex-end", gap: 4 },
  name: { color: "#FFFFFF", fontSize: 16, fontWeight: "800" },
  seen: { color: "rgba(255,255,255,0.5)", fontSize: 12 },
  rssi: { fontSize: 18, fontWeight: "900" },
  quality: { fontSize: 12, fontWeight: "900" },
});
