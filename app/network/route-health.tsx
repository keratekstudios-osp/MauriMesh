import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { useRouter } from "expo-router";
import { useLiveMesh } from "../../src/maurimesh/live/useLiveMesh";
import {
  LiveScreen,
  Card,
  Line,
  StatRow,
  Pill,
  EmptyNote,
  COLORS,
} from "../../src/maurimesh/live/liveMeshUi";
import { deriveRouteHealth, timeAgo } from "../../src/maurimesh/live/liveMeshFormat";

const TIER_COLOR: Record<string, string> = {
  Healthy: COLORS.green,
  Fair: COLORS.amber,
  Poor: COLORS.red,
};

export default function RouteHealthScreen() {
  const router = useRouter();
  const { state } = useLiveMesh(3000);

  const routes = state.nodes.map(deriveRouteHealth);
  const healthy = routes.filter((r) => r.tier === "Healthy").length;
  const fair = routes.filter((r) => r.tier === "Fair").length;
  const poor = routes.filter((r) => r.tier === "Poor").length;

  return (
    <LiveScreen
      title="Route Health"
      subtitle="Per-peer route quality metrics"
      onBack={() => router.back()}
    >
      <Card title="Health Summary">
        <StatRow
          stats={[
            { label: "Healthy", value: healthy, color: COLORS.green },
            { label: "Fair", value: fair, color: COLORS.amber },
            { label: "Poor", value: poor, color: COLORS.red },
          ]}
        />
      </Card>

      {routes.length === 0 ? (
        <Card>
          <EmptyNote text="No routes to score yet. Discover BLE peers first — route health is derived from their live signal and recency." />
        </Card>
      ) : (
        routes.map((r) => (
          <View key={r.id} style={styles.card}>
            <View style={styles.headerRow}>
              <Text style={styles.name}>{r.label}</Text>
              <Pill label={r.tier} color={TIER_COLOR[r.tier]} />
            </View>
            <Line label="Route score" value={`${r.score} / 100`} color={TIER_COLOR[r.tier]} />
            <Line label="Signal" value={`${r.rssi ?? 0} dBm (${r.quality.label})`} color={r.quality.color} />
            <Line label="Sightings" value={`${r.seenCount}× · last ${timeAgo(r.lastSeenAt)}`} />
            <Line label="Reachable" value={r.fresh ? "yes" : "stale"} color={r.fresh ? COLORS.green : COLORS.muted} />
          </View>
        ))
      )}

      <Card title="Latency & Packet Loss" warning>
        <EmptyNote text="Round-trip latency and packet loss are not yet measured: they require proven TX/RX/ACK exchange between two devices. Route scores above are derived only from real signal strength and recency." />
      </Card>
    </LiveScreen>
  );
}

const styles = StyleSheet.create({
  card: {
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.1)",
    borderRadius: 16,
    padding: 16,
    marginBottom: 12,
    backgroundColor: "rgba(255,255,255,0.035)",
  },
  headerRow: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    marginBottom: 6,
  },
  name: { color: "#FFFFFF", fontSize: 16, fontWeight: "800", flex: 1 },
});
