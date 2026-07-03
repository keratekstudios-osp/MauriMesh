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
  rssiQuality,
  isFresh,
  timeAgo,
  nodeDisplayName,
} from "../../src/maurimesh/live/liveMeshFormat";

export default function PeerMappingScreen() {
  const router = useRouter();
  const { state } = useLiveMesh(2000);

  const online = state.nodes.filter((n) => isFresh(n.lastSeenAt)).length;
  const offline = state.nodes.length - online;

  return (
    <LiveScreen
      title="Peer Mapping"
      subtitle="Connected mesh nodes"
      onBack={() => router.back()}
    >
      <Card title="Mesh Summary">
        <StatRow
          stats={[
            { label: "Online", value: online, color: COLORS.green },
            { label: "Offline", value: offline, color: COLORS.muted },
            { label: "Known", value: state.nodes.length, color: COLORS.blue },
          ]}
        />
      </Card>

      <Card title={`All Peers (${state.nodes.length})`}>
        {state.nodes.length === 0 ? (
          <EmptyNote text="No peers mapped yet. Run a BLE scan near another MauriMesh device — discovered nodes will appear here." />
        ) : (
          state.nodes.map((n) => {
            const live = isFresh(n.lastSeenAt);
            const q = rssiQuality(n.lastRssi);
            return (
              <View key={n.id} style={{ marginBottom: 14 }}>
                <View style={{ flexDirection: "row", justifyContent: "space-between", alignItems: "center", marginBottom: 4 }}>
                  <Line label="Peer" value={nodeDisplayName(n)} />
                  <Pill label={live ? "ONLINE" : "OFFLINE"} color={live ? COLORS.green : COLORS.muted} />
                </View>
                <Line label="Role" value={n.role} />
                <Line label="Signal" value={`${n.lastRssi ?? 0} dBm (${q.label})`} color={q.color} />
                <Line label="Last seen" value={timeAgo(n.lastSeenAt)} />
              </View>
            );
          })
        )}
      </Card>
    </LiveScreen>
  );
}
