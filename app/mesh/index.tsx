import React from "react";
import { StyleSheet, Text, TouchableOpacity, View } from "react-native";
import { useRouter } from "expo-router";
import { useLiveMesh } from "../../src/maurimesh/live/useLiveMesh";
import { LiveScreen, Card, Pill, COLORS } from "../../src/maurimesh/live/liveMeshUi";
import { isFresh } from "../../src/maurimesh/live/liveMeshFormat";

const SECTIONS: { title: string; subtitle: string; route: string }[] = [
  { title: "BLE Discovery", subtitle: "Scan for nearby mesh nodes", route: "/mesh/ble-discovery" },
  { title: "Peer Mapping", subtitle: "Connected mesh nodes", route: "/mesh/peer-mapping" },
  { title: "Signal Strength", subtitle: "Per-peer RSSI & quality", route: "/mesh/signal-strength" },
  { title: "Route Health", subtitle: "Per-peer route quality", route: "/network/route-health" },
  { title: "Store-Forward Queue", subtitle: "Offline message relay", route: "/mesh/store-forward-queue" },
  { title: "ACK Tracking", subtitle: "Message acknowledgement paths", route: "/mesh/ack-tracking" },
];

export default function MeshIndexScreen() {
  const router = useRouter();
  const { state } = useLiveMesh(2000);
  const livePeers = state.nodes.filter((n) => isFresh(n.lastSeenAt)).length;

  return (
    <LiveScreen
      title="Mesh Network"
      subtitle="BLE mesh system — live data"
      onBack={() => router.back()}
    >
      <Card>
        <View style={styles.statusRow}>
          <Pill
            label={state.scanActive ? "SCAN ACTIVE" : "SCAN IDLE"}
            color={state.scanActive ? COLORS.green : COLORS.muted}
          />
          <Pill
            label={`${livePeers} live · ${state.nodes.length} known`}
            color={livePeers > 0 ? COLORS.blue : COLORS.muted}
          />
        </View>
      </Card>

      {SECTIONS.map((s) => (
        <TouchableOpacity
          key={s.route}
          style={styles.card}
          onPress={() => router.push(s.route as never)}
          activeOpacity={0.85}
        >
          <View style={{ flex: 1 }}>
            <Text style={styles.cardTitle}>{s.title}</Text>
            <Text style={styles.cardSub}>{s.subtitle}</Text>
          </View>
          <Text style={styles.arrow}>→</Text>
        </TouchableOpacity>
      ))}
    </LiveScreen>
  );
}

const styles = StyleSheet.create({
  statusRow: { flexDirection: "row", gap: 8, flexWrap: "wrap" },
  card: {
    flexDirection: "row",
    alignItems: "center",
    borderWidth: 1,
    borderColor: "rgba(0, 208, 132, 0.22)",
    borderRadius: 16,
    padding: 18,
    marginBottom: 12,
    backgroundColor: "rgba(255,255,255,0.035)",
  },
  cardTitle: { color: "#FFFFFF", fontSize: 17, fontWeight: "900" },
  cardSub: { color: "rgba(255,255,255,0.6)", fontSize: 13, marginTop: 2 },
  arrow: { color: "#00D084", fontSize: 22, fontWeight: "900" },
});
