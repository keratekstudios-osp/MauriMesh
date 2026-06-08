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
import { isFresh, nodeDisplayName, timeAgo } from "../../src/maurimesh/live/liveMeshFormat";
import {
  useMeshHistory,
  bucketDeltas,
  FIVE_MIN_MS,
} from "../../src/maurimesh/live/useMeshHistory";
import { BarChart } from "../../src/maurimesh/live/meshCharts";

const RELAY_BUCKET_MS = 30_000;

export default function RelayAnalyticsScreen() {
  const router = useRouter();
  const { state } = useLiveMesh(5000);
  const m = state.metrics;

  const history = useMeshHistory(m, state.updatedAt, FIVE_MIN_MS);
  const relayBuckets = bucketDeltas(history, Date.now(), FIVE_MIN_MS, RELAY_BUCKET_MS, "relayCount");

  const relayCapable = state.nodes.filter((n) => isFresh(n.lastSeenAt));
  const delivered = m.deliveryCount;
  const relayed = m.relayCount;
  const relayRate = delivered > 0 ? Math.round((relayed / delivered) * 100) : 0;

  return (
    <LiveScreen
      title="Relay Analytics"
      subtitle="Multi-hop relay performance"
      onBack={() => router.back()}
    >
      <Card title="Relay Statistics">
        <StatRow
          stats={[
            { label: "Relayed", value: relayed, color: COLORS.blue },
            { label: "Delivered", value: delivered, color: "#FFFFFF" },
            { label: "Relay %", value: `${relayRate}%`, color: relayRate > 0 ? COLORS.green : COLORS.muted },
          ]}
        />
      </Card>

      <Card title="Relay Activity (30s buckets)">
        {history.length < 2 ? (
          <EmptyNote text="Collecting live relay data… the activity trend appears once two or more snapshots have arrived. Each bar is the real number of relay hops counted within a 30-second window." />
        ) : (
          <BarChart values={relayBuckets} color={COLORS.blue} label="Relay hops" />
        )}
      </Card>

      <Card title="Relay Pipeline">
        <Line label="Relay count" value={relayed} color={relayed > 0 ? COLORS.blue : undefined} />
        <Line label="Delivery count" value={delivered} />
        <Line label="ACK count" value={m.ackCount} color={m.ackCount > 0 ? COLORS.green : undefined} />
        <Line label="Failures" value={m.failureCount} color={m.failureCount > 0 ? COLORS.red : undefined} />
        <Line label="Truth level" value={m.truthLevel} />
      </Card>

      <Card title={`Relay-Capable Peers (${relayCapable.length})`}>
        {relayCapable.length === 0 ? (
          <EmptyNote text="No live peers available to relay through yet. Discover at least one nearby node — reachable peers can act as relay hops once multi-hop forwarding is proven." />
        ) : (
          relayCapable.map((n) => (
            <View key={n.id} style={{ marginBottom: 12 }}>
              <View style={{ flexDirection: "row", justifyContent: "space-between", alignItems: "center", marginBottom: 4 }}>
                <Line label="Peer" value={nodeDisplayName(n)} />
                <Pill label={n.role.toUpperCase()} color={COLORS.blue} />
              </View>
              <Line label="Signal" value={`${n.lastRssi ?? 0} dBm`} />
              <Line label="Last seen" value={timeAgo(n.lastSeenAt)} />
            </View>
          ))
        )}
      </Card>

      <Card title="Truth Boundary" warning>
        <EmptyNote text="Relay counts come from the live mesh metrics spine. The peer list above is real BLE discovery, but no multi-hop relay is claimed until a forwarded packet is proven end-to-end." />
      </Card>
    </LiveScreen>
  );
}
