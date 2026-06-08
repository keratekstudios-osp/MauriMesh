import React from "react";
import { View } from "react-native";
import { useRouter } from "expo-router";
import { useLiveMesh } from "../../src/maurimesh/live/useLiveMesh";
import {
  LiveScreen,
  Card,
  Line,
  Pill,
  LiveButton,
  EmptyNote,
  COLORS,
} from "../../src/maurimesh/live/liveMeshUi";
import {
  rssiQuality,
  timeAgo,
  nodeDisplayName,
} from "../../src/maurimesh/live/liveMeshFormat";

export default function BleDiscoveryScreen() {
  const router = useRouter();
  const { state, loading, startScan, stopScan, refresh } = useLiveMesh(1000);

  return (
    <LiveScreen
      title="BLE Discovery"
      subtitle="Bluetooth Low Energy scanning"
      onBack={() => router.back()}
    >
      <Card title="Scan Status">
        <View style={{ marginBottom: 12 }}>
          <Pill
            label={state.scanActive ? "SCANNING…" : "IDLE"}
            color={state.scanActive ? COLORS.green : COLORS.muted}
          />
        </View>
        <Line label="Native module" value={state.nativeModulePresent ? "PRESENT" : "NOT CONFIRMED"} />
        <Line
          label="Permissions"
          value={state.permissionsGranted ? "granted" : "denied"}
          color={state.permissionsGranted ? COLORS.green : COLORS.red}
        />
        <Line label="Discovered (this scan)" value={state.discoveredCount} />
        <Line label="Mode" value={state.lastNativeStatus.mode || "unknown"} />
        {state.lastNativeStatus.lastError ? (
          <Line label="Last error" value={state.lastNativeStatus.lastError} color={COLORS.red} />
        ) : null}
      </Card>

      <LiveButton
        label={loading ? "Working…" : state.scanActive ? "Stop BLE Scan" : "Start BLE Scan"}
        variant={state.scanActive ? "danger" : "primary"}
        disabled={loading}
        onPress={state.scanActive ? stopScan : startScan}
      />
      <LiveButton label="Refresh" variant="secondary" disabled={loading} onPress={refresh} />

      <Card title={`Discovered Nodes (${state.nodes.length})`}>
        {state.nodes.length === 0 ? (
          <EmptyNote text="No BLE nodes discovered yet. Start a scan with another MauriMesh device nearby to populate this list." />
        ) : (
          state.nodes.map((n) => {
            const q = rssiQuality(n.lastRssi);
            return (
              <View key={n.id} style={{ marginBottom: 14 }}>
                <Line label="Node" value={nodeDisplayName(n)} />
                {n.address ? <Line label="Address" value={n.address} /> : null}
                <Line label="RSSI" value={`${n.lastRssi ?? 0} dBm (${q.label})`} color={q.color} />
                <Line label="Seen" value={`${n.seenCount}× · last ${timeAgo(n.lastSeenAt)}`} />
              </View>
            );
          })
        )}
      </Card>

      <Card title="Truth Boundary" warning>
        <EmptyNote text={state.truthBoundary} />
      </Card>
    </LiveScreen>
  );
}
