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

export default function AckTrackingScreen() {
  const router = useRouter();
  const { state } = useLiveMesh(2000);
  const m = state.metrics;

  const acked = m.ackCount;
  const inTransit = Math.max(m.deliveryCount - m.ackCount, 0);

  return (
    <LiveScreen
      title="ACK Tracking"
      subtitle="Message acknowledgement paths"
      onBack={() => router.back()}
    >
      <Card title="ACK Statistics">
        <StatRow
          stats={[
            { label: "Delivered", value: m.deliveryCount, color: "#FFFFFF" },
            { label: "Acked", value: acked, color: COLORS.green },
            { label: "In transit", value: inTransit, color: COLORS.amber },
          ]}
        />
      </Card>

      <Card title="Delivery Pipeline">
        <Line label="Relay count" value={m.relayCount} />
        <Line label="Delivery count" value={m.deliveryCount} />
        <Line label="ACK count" value={acked} color={acked > 0 ? COLORS.green : undefined} />
        <Line label="Failures" value={m.failureCount} color={m.failureCount > 0 ? COLORS.red : undefined} />
        <Line label="Avg latency" value={`${m.averageLatencyMs} ms`} />
        <Line label="Truth level" value={m.truthLevel} />
      </Card>

      <Card title="Delivery Paths">
        {m.deliveryCount === 0 ? (
          <EmptyNote text="No acknowledgement paths yet. Once a message is delivered over the mesh, its origin → relay → destination ACK path will be tracked here." />
        ) : (
          <Pill
            label={acked === m.deliveryCount ? "ALL ACKED" : "PARTIAL ACK"}
            color={acked === m.deliveryCount ? COLORS.green : COLORS.amber}
          />
        )}
      </Card>

      <Card title="Truth Boundary" warning>
        <EmptyNote text="ACK and delivery counts come from the live mesh metrics spine. They report only proven exchanges — no acknowledgement is claimed until a real TX/RX/ACK round-trip occurs." />
      </Card>
    </LiveScreen>
  );
}
