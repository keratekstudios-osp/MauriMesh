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
import { timeAgo } from "../../src/maurimesh/live/liveMeshFormat";

export default function PacketAnalysisScreen() {
  const router = useRouter();
  const { state } = useLiveMesh(1000);
  const m = state.metrics;
  const ns = state.lastNativeStatus;

  return (
    <LiveScreen
      title="Packet Analysis"
      subtitle="Live BLE scan packet activity"
      onBack={() => router.back()}
    >
      <Card title="Scan Activity">
        <StatRow
          stats={[
            { label: "Discovered", value: state.discoveredCount, color: COLORS.blue },
            { label: "Known nodes", value: m.nodeCount, color: "#FFFFFF" },
            { label: "Failures", value: m.failureCount, color: m.failureCount > 0 ? COLORS.red : COLORS.muted },
          ]}
        />
      </Card>

      <Card title="Last Observed Advertisement">
        <Pill
          label={state.scanActive ? "SCAN ACTIVE" : "SCAN IDLE"}
          color={state.scanActive ? COLORS.green : COLORS.muted}
        />
        <View style={{ height: 12 }} />
        {ns.lastDeviceAddress && ns.lastDeviceAddress !== "none" && ns.lastDeviceAddress !== "unknown" ? (
          <>
            <Line label="Device" value={ns.lastDeviceName || "(unnamed)"} />
            <Line label="Address" value={ns.lastDeviceAddress} />
            <Line label="RSSI" value={`${ns.lastRssi ?? 0} dBm`} color={COLORS.blue} />
          </>
        ) : (
          <EmptyNote text="No advertisement packets captured yet. Start a BLE scan near another device — each discovered advertisement updates here in real time." />
        )}
      </Card>

      <Card title="Native Bridge">
        <Line label="Module present" value={state.nativeModulePresent ? "yes" : "no"} color={state.nativeModulePresent ? COLORS.green : COLORS.red} />
        <Line label="Mode" value={ns.mode || "unknown"} />
        <Line label="Updated" value={timeAgo(state.updatedAt)} />
        {ns.lastError ? <Line label="Last error" value={ns.lastError} color={COLORS.red} /> : null}
      </Card>

      <Card title="Truth Boundary" warning>
        <EmptyNote text="Counts reflect real BLE scan advertisements observed by the native bridge. Application-layer packet decode (TX/RX payloads) is not claimed until message exchange is proven." />
      </Card>
    </LiveScreen>
  );
}
