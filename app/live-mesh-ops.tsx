import React from "react";
import {
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from "react-native";
import { useLiveMesh } from "../src/maurimesh/live/useLiveMesh";
import { PlatformLiveMeshPanel } from "../src/maurimesh/live/PlatformLiveMeshPanel";

const MARKER = "LIVE_MESH_OPS_20260608_A";

function Card({
  title,
  children,
  warning,
}: {
  title: string;
  children: React.ReactNode;
  warning?: boolean;
}) {
  return (
    <View style={[styles.card, warning && styles.warningCard]}>
      <Text style={styles.cardTitle}>{title}</Text>
      {children}
    </View>
  );
}

function Line({ label, value }: { label: string; value: string | number | boolean }) {
  return (
    <Text style={styles.body}>
      <Text style={styles.label}>{label}: </Text>
      {String(value)}
    </Text>
  );
}

export default function LiveMeshOpsScreen() {
  const { state, loading, refresh, startScan, stopScan } = useLiveMesh(2000);

  return (
    <ScrollView style={styles.page} contentContainerStyle={styles.content}>
      <Text style={styles.brand}>MauriMesh</Text>
      <Text style={styles.title}>Live Mesh Ops</Text>
      <Text style={styles.marker}>{MARKER}</Text>

      <Card title="Truth Boundary" warning>
        <Text style={styles.body}>{state.truthBoundary}</Text>
      </Card>

      <Card title="Live BLE Source">
        <Text style={state.scanActive ? styles.good : styles.bad}>
          {state.scanActive ? "SCAN ACTIVE" : "SCAN STOPPED"}
        </Text>
        <Line label="Native module" value={state.nativeModulePresent ? "PRESENT" : "NOT CONFIRMED"} />
        <Line label="Permissions" value={state.permissionsGranted ? "granted" : "denied"} />
        <Line label="Discovered count" value={state.discoveredCount} />
        <Line label="Mode" value={state.lastNativeStatus.mode || "unknown"} />
        <Line label="Last error" value={state.lastNativeStatus.lastError || "none"} />
      </Card>

      <Card title="Persistent Mesh Registry">
        <Line label="Node records" value={state.nodes.length} />
        <Line label="Latest node" value={state.nodes[0]?.label || "none"} />
        <Line label="Latest address" value={state.nodes[0]?.address || "none"} />
        <Line label="Latest RSSI" value={state.nodes[0]?.lastRssi || 0} />
      </Card>

      <Card title="Metrics Spine">
        <Line label="Node count" value={state.metrics.nodeCount} />
        <Line label="Route count" value={state.metrics.routeCount} />
        <Line label="Delivery count" value={state.metrics.deliveryCount} />
        <Line label="Relay count" value={state.metrics.relayCount} />
        <Line label="ACK count" value={state.metrics.ackCount} />
        <Line label="Failures" value={state.metrics.failureCount} />
        <Line label="Truth level" value={state.metrics.truthLevel} />
      </Card>

      <PlatformLiveMeshPanel title="Live BLE-Mesh Data (read-only spine)" />

      <TouchableOpacity
        style={[styles.button, state.scanActive && styles.stopButton]}
        disabled={loading}
        onPress={state.scanActive ? stopScan : startScan}
      >
        <Text style={styles.buttonText}>
          {loading ? "Working..." : state.scanActive ? "Stop Live Scan" : "Start Live Scan"}
        </Text>
      </TouchableOpacity>

      <TouchableOpacity style={styles.secondaryButton} disabled={loading} onPress={refresh}>
        <Text style={styles.secondaryButtonText}>Refresh Live Mesh</Text>
      </TouchableOpacity>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  page: { flex: 1, backgroundColor: "#050816" },
  content: { padding: 24, paddingTop: 56, paddingBottom: 80 },
  brand: {
    color: "#00D084",
    fontSize: 42,
    fontWeight: "900",
    marginBottom: 24,
  },
  title: {
    color: "#FFFFFF",
    fontSize: 30,
    fontWeight: "900",
    marginBottom: 12,
  },
  marker: {
    color: "#4FC3F7",
    fontSize: 14,
    fontWeight: "900",
    letterSpacing: 1.5,
    marginBottom: 28,
  },
  card: {
    borderWidth: 1,
    borderColor: "rgba(0, 208, 132, 0.28)",
    borderRadius: 20,
    padding: 22,
    marginBottom: 18,
    backgroundColor: "rgba(255,255,255,0.035)",
  },
  warningCard: {
    borderColor: "rgba(245, 158, 11, 0.55)",
    backgroundColor: "rgba(245, 158, 11, 0.055)",
  },
  cardTitle: {
    color: "#FFFFFF",
    fontSize: 22,
    fontWeight: "900",
    marginBottom: 16,
  },
  body: {
    color: "rgba(255,255,255,0.76)",
    fontSize: 17,
    lineHeight: 27,
    marginBottom: 6,
  },
  label: {
    color: "#FFFFFF",
    fontWeight: "900",
  },
  good: {
    color: "#00D084",
    fontSize: 30,
    fontWeight: "900",
    letterSpacing: 1.5,
    marginBottom: 12,
  },
  bad: {
    color: "#FF4D5E",
    fontSize: 30,
    fontWeight: "900",
    letterSpacing: 1.5,
    marginBottom: 12,
  },
  button: {
    backgroundColor: "#00D084",
    borderRadius: 18,
    padding: 20,
    alignItems: "center",
    marginBottom: 14,
  },
  stopButton: {
    backgroundColor: "#FF4D5E",
  },
  buttonText: {
    color: "#03120C",
    fontSize: 18,
    fontWeight: "900",
  },
  secondaryButton: {
    borderWidth: 1,
    borderColor: "rgba(0, 208, 132, 0.5)",
    borderRadius: 18,
    padding: 18,
    alignItems: "center",
    marginBottom: 20,
  },
  secondaryButtonText: {
    color: "#00D084",
    fontSize: 17,
    fontWeight: "900",
  },
});
