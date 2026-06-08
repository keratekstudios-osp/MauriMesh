import React from "react";
import { View } from "react-native";
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
import {
  deriveRouteHealth,
  timeAgo,
  nodeDisplayName,
} from "../../src/maurimesh/live/liveMeshFormat";
import {
  useMeshHistory,
  bucketPercentiles,
  FIVE_MIN_MS,
} from "../../src/maurimesh/live/useMeshHistory";
import { MultiLineChart } from "../../src/maurimesh/live/meshCharts";

const LATENCY_BUCKET_MS = 15_000;

export default function LatencyMonitoringScreen() {
  const router = useRouter();
  const { state } = useLiveMesh(3000);
  const m = state.metrics;

  const history = useMeshHistory(m, state.updatedAt, FIVE_MIN_MS);
  const { p50, p90, p99 } = bucketPercentiles(
    history,
    Date.now(),
    FIVE_MIN_MS,
    LATENCY_BUCKET_MS,
  );

  const routes = state.nodes.map(deriveRouteHealth);

  return (
    <LiveScreen
      title="Latency Monitoring"
      subtitle="Round-trip timing & reachability"
      onBack={() => router.back()}
    >
      <Card title="Latency Overview">
        <StatRow
          stats={[
            { label: "Avg latency", value: `${m.averageLatencyMs} ms`, color: m.averageLatencyMs > 0 ? COLORS.blue : COLORS.muted },
            { label: "Samples", value: m.ackCount, color: "#FFFFFF" },
            { label: "Failures", value: m.failureCount, color: m.failureCount > 0 ? COLORS.red : COLORS.muted },
          ]}
        />
      </Card>

      <Card title="Latency Trend (last 5 min)">
        {history.length < 2 ? (
          <EmptyNote text="Collecting live latency samples… the P50/P90/P99 trend appears once at least two readings have arrived from the BLE bridge. Until a real round-trip is timed, the lines stay at 0 ms." />
        ) : (
          <MultiLineChart
            unit="ms"
            series={[
              { label: "P50", color: COLORS.green, values: p50 },
              { label: "P90", color: COLORS.amber, values: p90 },
              { label: "P99", color: COLORS.red, values: p99 },
            ]}
          />
        )}
      </Card>

      <Card title={`Peer Reachability (${routes.length})`}>
        {routes.length === 0 ? (
          <EmptyNote text="No peers to time yet. Discover nearby nodes first — reachability and recency are derived from the live BLE scan." />
        ) : (
          routes.map((r) => (
            <View key={r.id} style={{ marginBottom: 12 }}>
              <View style={{ flexDirection: "row", justifyContent: "space-between", alignItems: "center", marginBottom: 4 }}>
                <Line label="Peer" value={r.label} />
                <Pill
                  label={r.fresh ? "REACHABLE" : "STALE"}
                  color={r.fresh ? COLORS.green : COLORS.muted}
                />
              </View>
              <Line label="Signal" value={`${r.rssi ?? 0} dBm (${r.quality.label})`} color={r.quality.color} />
              <Line label="Last seen" value={timeAgo(r.lastSeenAt)} />
            </View>
          ))
        )}
      </Card>

      <Card title="Truth Boundary" warning>
        <EmptyNote text="Average latency comes from the live mesh metrics spine and stays at 0 ms until a real TX/RX/ACK round-trip is timed. Reachability above is derived only from genuine signal strength and recency." />
      </Card>
    </LiveScreen>
  );
}
