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

export default function StoreForwardQueueScreen() {
  const router = useRouter();
  const { state } = useLiveMesh(5000);
  const m = state.metrics;

  const pending = m.relayCount;
  const failed = m.failureCount;
  const total = pending + failed;

  return (
    <LiveScreen
      title="Store-Forward Queue"
      subtitle="Offline message relay"
      onBack={() => router.back()}
    >
      <Card title="Queue Summary">
        <StatRow
          stats={[
            { label: "Total", value: total, color: "#FFFFFF" },
            { label: "Pending", value: pending, color: COLORS.amber },
            { label: "Failed", value: failed, color: COLORS.red },
          ]}
        />
      </Card>

      <Card title="Transport">
        <Pill
          label={state.scanActive ? "LINK ACTIVE" : "LINK IDLE"}
          color={state.scanActive ? COLORS.green : COLORS.muted}
        />
        <Line label="Reachable peers" value={state.nodes.length} />
        <Line label="Relay count" value={m.relayCount} />
        <Line label="Delivery count" value={m.deliveryCount} />
        <Line label="Truth level" value={m.truthLevel} />
      </Card>

      <Card title={`Message Queue (${total})`}>
        {total === 0 ? (
          <EmptyNote text="The store-forward queue is empty. Messages that can't be delivered immediately are held here and relayed once a peer becomes reachable. Queued traffic appears here as soon as mesh delivery is exercised." />
        ) : (
          <Line label="Pending relays" value={pending} color={COLORS.amber} />
        )}
      </Card>

      <Card title="Truth Boundary" warning>
        <EmptyNote text={state.truthBoundary} />
      </Card>
    </LiveScreen>
  );
}
