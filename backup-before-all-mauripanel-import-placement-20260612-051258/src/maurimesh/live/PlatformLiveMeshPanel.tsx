import React, { useEffect, useState } from "react";
import { StyleSheet, Text, View } from "react-native";
import { readPlatformLiveMeshState } from "./platformLiveMeshBridge";
import type { PlatformLiveMeshState } from "./platformLiveMeshTypes";
import { PLATFORM_LIVE_BLE_MESH_BRIDGE_MARKER } from "./platformLiveMeshTypes";

function emptyState(): PlatformLiveMeshState {
  return {
    marker: PLATFORM_LIVE_BLE_MESH_BRIDGE_MARKER,
    updatedAt: new Date().toISOString(),
    source: "unavailable",
    nativeModulePresent: false,
    permissionsGranted: false,
    scanActive: false,
    discoveredCount: 0,
    nodeCount: 0,
    routeCount: 0,
    deliveryCount: 0,
    relayCount: 0,
    ackCount: 0,
    failureCount: 0,
    nodes: [],
    metrics: [],
    truthLevel: "unavailable",
    truthBoundary: "Loading platform live mesh bridge.",
  };
}

export function PlatformLiveMeshPanel({ title = "Live BLE-Mesh Data" }: { title?: string }) {
  const [state, setState] = useState<PlatformLiveMeshState>(emptyState());

  useEffect(() => {
    let alive = true;

    async function tick() {
      const next = await readPlatformLiveMeshState();
      if (alive) setState(next);
    }

    tick();
    const timer = setInterval(tick, 2500);

    return () => {
      alive = false;
      clearInterval(timer);
    };
  }, []);

  return (
    <View style={styles.card}>
      <Text style={styles.title}>{title}</Text>
      <Text style={styles.marker}>{state.marker}</Text>

      <View style={styles.row}>
        <Text style={styles.label}>Source</Text>
        <Text style={styles.value}>{state.source}</Text>
      </View>

      <View style={styles.row}>
        <Text style={styles.label}>Truth</Text>
        <Text style={styles.value}>{state.truthLevel}</Text>
      </View>

      <View style={styles.row}>
        <Text style={styles.label}>Scan</Text>
        <Text style={state.scanActive ? styles.good : styles.warn}>
          {state.scanActive ? "ACTIVE" : "STOPPED"}
        </Text>
      </View>

      <View style={styles.row}>
        <Text style={styles.label}>Discovered</Text>
        <Text style={styles.value}>{state.discoveredCount}</Text>
      </View>

      <View style={styles.row}>
        <Text style={styles.label}>Nodes</Text>
        <Text style={styles.value}>{state.nodeCount}</Text>
      </View>

      <View style={styles.row}>
        <Text style={styles.label}>Routes</Text>
        <Text style={styles.value}>{state.routeCount}</Text>
      </View>

      <View style={styles.row}>
        <Text style={styles.label}>ACK</Text>
        <Text style={styles.value}>{state.ackCount}</Text>
      </View>

      <Text style={styles.truth}>{state.truthBoundary}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    borderWidth: 1,
    borderColor: "rgba(0, 208, 132, 0.32)",
    backgroundColor: "rgba(255,255,255,0.035)",
    borderRadius: 20,
    padding: 18,
    marginVertical: 12,
  },
  title: {
    color: "#FFFFFF",
    fontSize: 20,
    fontWeight: "900",
    marginBottom: 8,
  },
  marker: {
    color: "#4FC3F7",
    fontSize: 11,
    fontWeight: "900",
    letterSpacing: 1,
    marginBottom: 14,
  },
  row: {
    flexDirection: "row",
    justifyContent: "space-between",
    gap: 12,
    paddingVertical: 5,
  },
  label: {
    color: "rgba(255,255,255,0.72)",
    fontSize: 14,
    fontWeight: "700",
  },
  value: {
    color: "#FFFFFF",
    fontSize: 14,
    fontWeight: "900",
  },
  good: {
    color: "#00D084",
    fontSize: 14,
    fontWeight: "900",
  },
  warn: {
    color: "#F59E0B",
    fontSize: 14,
    fontWeight: "900",
  },
  truth: {
    color: "rgba(255,255,255,0.68)",
    fontSize: 13,
    lineHeight: 20,
    marginTop: 12,
  },
});
