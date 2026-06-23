import React from "react";
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
  useMeshHistory,
  bucketDeltas,
  FIVE_MIN_MS,
} from "../../src/maurimesh/live/useMeshHistory";
import { StackedAreaChart } from "../../src/maurimesh/live/meshCharts";

const DELIVERY_BUCKET_MS = 30_000;

export default function DeliveryAnalyticsScreen() {
  const router = useRouter();
  const { state } = useLiveMesh(5000);
  const m = state.metrics;

  const history = useMeshHistory(m, state.updatedAt, FIVE_MIN_MS);
  const now = Date.now();
  const deliveredBuckets = bucketDeltas(history, now, FIVE_MIN_MS, DELIVERY_BUCKET_MS, "deliveryCount");
  const droppedBuckets = bucketDeltas(history, now, FIVE_MIN_MS, DELIVERY_BUCKET_MS, "failureCount");

  const delivered = m.deliveryCount;
  const acked = m.ackCount;
  const failed = m.failureCount;
  const attempted = delivered + failed;
  const successRate = attempted > 0 ? Math.round((delivered / attempted) * 100) : 0;
  const ackRate = delivered > 0 ? Math.round((acked / delivered) * 100) : 0;

  return (
    <LiveScreen
      title="Delivery Analytics"
      subtitle="End-to-end delivery outcomes"
      onBack={() => router.back()}
    >
      <Card title="Delivery Summary">
        <StatRow
          stats={[
            { label: "Delivered", value: delivered, color: COLORS.green },
            { label: "Failed", value: failed, color: failed > 0 ? COLORS.red : COLORS.muted },
            { label: "Success %", value: `${successRate}%`, color: successRate > 0 ? COLORS.green : COLORS.muted },
          ]}
        />
      </Card>

      <Card title="Delivered vs Dropped (30s buckets)">
        {history.length < 2 ? (
          <EmptyNote text="Collecting live delivery data… the delivered-vs-dropped trend fills in once two or more snapshots have arrived. Each bar is the real change in delivered and failed counts within a 30-second window." />
        ) : (
          <StackedAreaChart
            lower={deliveredBuckets}
            upper={droppedBuckets}
            lowerColor={COLORS.green}
            upperColor={COLORS.red}
            lowerLabel="Delivered"
            upperLabel="Dropped"
          />
        )}
      </Card>

      <Card title="Delivery Breakdown">
        <Line label="Attempted" value={attempted} />
        <Line label="Delivered" value={delivered} color={delivered > 0 ? COLORS.green : undefined} />
        <Line label="Acknowledged" value={acked} color={acked > 0 ? COLORS.green : undefined} />
        <Line label="ACK rate" value={`${ackRate}%`} />
        <Line label="Failures" value={failed} color={failed > 0 ? COLORS.red : undefined} />
        <Line label="Relay hops" value={m.relayCount} />
        <Line label="Avg latency" value={`${m.averageLatencyMs} ms`} />
        <Line label="Truth level" value={m.truthLevel} />
      </Card>

      <Card title="Status">
        {attempted === 0 ? (
          <EmptyNote text="No delivery attempts recorded yet. Once a message is sent over the mesh, its delivery, acknowledgement, and failure outcomes will be aggregated here." />
        ) : (
          <Pill
            label={successRate === 100 ? "ALL DELIVERED" : "PARTIAL DELIVERY"}
            color={successRate === 100 ? COLORS.green : COLORS.amber}
          />
        )}
      </Card>

      <Card title="Truth Boundary" warning>
        <EmptyNote text="Delivery, ACK, and failure counts come from the live mesh metrics spine. They report only proven exchanges — no end-to-end delivery is claimed until a real message round-trip occurs." />
      </Card>
    </LiveScreen>
  );
}
