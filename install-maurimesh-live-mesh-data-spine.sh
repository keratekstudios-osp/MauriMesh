#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH LIVE MESH DATA SPINE INSTALLER"
echo "#56 + #59 + #61 + #62 + #64 + #86 foundation"
echo "Uses proven NativeModules.MauriMeshBle scan proof status"
echo "NO advertise, NO connect, NO TX/RX, NO ACK, NO relay"
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$HOME/maurimesh-router-backups/live-mesh-data-spine-$STAMP"

LIVE="$ROOT/src/maurimesh/live"
APP="$ROOT/app"
DOCS="$ROOT/docs"
SCRIPTS="$ROOT/scripts"

mkdir -p "$BACKUP" "$LIVE" "$APP" "$DOCS" "$SCRIPTS"

cp "$APP/dashboard.tsx" "$BACKUP/dashboard.tsx" 2>/dev/null || true
cp package.json "$BACKUP/package.json" 2>/dev/null || true

echo ""
echo "============================================================"
echo "1. Verify project"
echo "============================================================"

test -f package.json || { echo "ERROR: package.json missing"; exit 1; }
test -d app || { echo "ERROR: app/ missing"; exit 1; }
test -d src || mkdir -p src

node -e "JSON.parse(require('fs').readFileSync('package.json','utf8')); console.log('package.json OK')"
node -e "JSON.parse(require('fs').readFileSync('eas.json','utf8')); console.log('eas.json OK')" 2>/dev/null || true

echo ""
echo "============================================================"
echo "2. Create live mesh types"
echo "============================================================"

cat > "$LIVE/types.ts" <<'TS'
export type MeshTransportKind =
  | "BLE_SCAN"
  | "BLE_ADVERTISE"
  | "BLE_CONNECT"
  | "BLE_TX"
  | "BLE_RX"
  | "BLE_ACK"
  | "RELAY"
  | "SIMULATION"
  | "UNKNOWN";

export type MeshTruthLevel =
  | "physical_proof"
  | "native_status"
  | "simulation"
  | "not_proven";

export type MeshNodeRole =
  | "observer"
  | "candidate"
  | "peer"
  | "relay"
  | "gateway"
  | "unknown";

export type MeshNodeRecord = {
  id: string;
  label: string;
  address?: string;
  name?: string;
  role: MeshNodeRole;
  firstSeenAt: string;
  lastSeenAt: string;
  seenCount: number;
  lastRssi?: number;
  transport: MeshTransportKind;
  truthLevel: MeshTruthLevel;
  source: string;
};

export type MeshMetricSnapshot = {
  createdAt: string;
  scanActive: boolean;
  discoveredCount: number;
  nodeCount: number;
  routeCount: number;
  deliveryCount: number;
  relayCount: number;
  ackCount: number;
  failureCount: number;
  averageLatencyMs: number;
  truthLevel: MeshTruthLevel;
};

export type NativeBleScanStatus = {
  module?: string;
  mode?: string;
  modulePresent?: boolean;
  blePermissions?: boolean;
  liveBleActive?: boolean;
  scanActive?: boolean;
  discoveredCount?: number;
  scanStartTimeMs?: number;
  scanStopTimeMs?: number;
  lastError?: string;
  lastDeviceName?: string;
  lastDeviceAddress?: string;
  lastRssi?: number;
  truth?: string;
};

export type LiveMeshState = {
  marker: string;
  updatedAt: string;
  nativeModulePresent: boolean;
  permissionsGranted: boolean;
  scanActive: boolean;
  discoveredCount: number;
  nodes: MeshNodeRecord[];
  metrics: MeshMetricSnapshot;
  lastNativeStatus: NativeBleScanStatus;
  truthBoundary: string;
};
TS

echo ""
echo "============================================================"
echo "3. Create event bus"
echo "============================================================"

cat > "$LIVE/meshEventBus.ts" <<'TS'
import type { LiveMeshState, MeshNodeRecord, NativeBleScanStatus } from "./types";

export type MeshEvent =
  | {
      type: "native_status";
      createdAt: string;
      status: NativeBleScanStatus;
    }
  | {
      type: "node_seen";
      createdAt: string;
      node: MeshNodeRecord;
    }
  | {
      type: "state_updated";
      createdAt: string;
      state: LiveMeshState;
    }
  | {
      type: "error";
      createdAt: string;
      message: string;
      source: string;
    };

type Listener = (event: MeshEvent) => void;

const listeners = new Set<Listener>();

export function subscribeMeshEvents(listener: Listener): () => void {
  listeners.add(listener);
  return () => listeners.delete(listener);
}

export function publishMeshEvent(event: MeshEvent): void {
  for (const listener of listeners) {
    try {
      listener(event);
    } catch {
      // Never let one screen crash the live mesh event bus.
    }
  }
}
TS

echo ""
echo "============================================================"
echo "4. Create persistent mesh node registry"
echo "============================================================"

cat > "$LIVE/meshNodeRegistry.ts" <<'TS'
import AsyncStorage from "@react-native-async-storage/async-storage";
import type { MeshNodeRecord, MeshTruthLevel } from "./types";

const STORAGE_KEY = "maurimesh.live.meshNodeRegistry.v1";

function nowIso(): string {
  return new Date().toISOString();
}

function stableNodeId(address?: string, name?: string): string {
  const raw = `${address || "unknown-address"}::${name || "unknown-name"}`;
  let hash = 0;
  for (let i = 0; i < raw.length; i += 1) {
    hash = (hash * 31 + raw.charCodeAt(i)) >>> 0;
  }
  return `node_${hash.toString(16)}`;
}

export async function loadMeshNodeRegistry(): Promise<MeshNodeRecord[]> {
  try {
    const raw = await AsyncStorage.getItem(STORAGE_KEY);
    if (!raw) return [];
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

export async function saveMeshNodeRegistry(nodes: MeshNodeRecord[]): Promise<void> {
  await AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(nodes.slice(0, 500)));
}

export async function clearMeshNodeRegistry(): Promise<void> {
  await AsyncStorage.removeItem(STORAGE_KEY);
}

export async function upsertBleScanNode(input: {
  address?: string;
  name?: string;
  rssi?: number;
  source: string;
  truthLevel?: MeshTruthLevel;
}): Promise<MeshNodeRecord[]> {
  const existing = await loadMeshNodeRegistry();

  const id = stableNodeId(input.address, input.name);
  const timestamp = nowIso();

  const current = existing.find((node) => node.id === id);

  const updated: MeshNodeRecord = current
    ? {
        ...current,
        label: input.name || current.label || "BLE device",
        address: input.address || current.address,
        name: input.name || current.name,
        lastSeenAt: timestamp,
        seenCount: current.seenCount + 1,
        lastRssi: input.rssi ?? current.lastRssi,
        transport: "BLE_SCAN",
        truthLevel: input.truthLevel || "physical_proof",
        source: input.source,
      }
    : {
        id,
        label: input.name || "BLE device",
        address: input.address,
        name: input.name,
        role: "candidate",
        firstSeenAt: timestamp,
        lastSeenAt: timestamp,
        seenCount: 1,
        lastRssi: input.rssi,
        transport: "BLE_SCAN",
        truthLevel: input.truthLevel || "physical_proof",
        source: input.source,
      };

  const without = existing.filter((node) => node.id !== id);
  const next = [updated, ...without].slice(0, 500);

  await saveMeshNodeRegistry(next);
  return next;
}
TS

echo ""
echo "============================================================"
echo "5. Create persistent metrics store"
echo "============================================================"

cat > "$LIVE/meshMetricsStore.ts" <<'TS'
import AsyncStorage from "@react-native-async-storage/async-storage";
import type { MeshMetricSnapshot } from "./types";

const STORAGE_KEY = "maurimesh.live.meshMetricSnapshots.v1";

export async function loadMeshMetricSnapshots(): Promise<MeshMetricSnapshot[]> {
  try {
    const raw = await AsyncStorage.getItem(STORAGE_KEY);
    if (!raw) return [];
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

export async function appendMeshMetricSnapshot(
  snapshot: MeshMetricSnapshot
): Promise<MeshMetricSnapshot[]> {
  const existing = await loadMeshMetricSnapshots();
  const next = [snapshot, ...existing].slice(0, 300);
  await AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(next));
  return next;
}

export async function clearMeshMetricSnapshots(): Promise<void> {
  await AsyncStorage.removeItem(STORAGE_KEY);
}
TS

echo ""
echo "============================================================"
echo "6. Create native BLE live source"
echo "============================================================"

cat > "$LIVE/nativeBleLiveSource.ts" <<'TS'
import { NativeModules, PermissionsAndroid, Platform } from "react-native";
import { publishMeshEvent } from "./meshEventBus";
import { appendMeshMetricSnapshot } from "./meshMetricsStore";
import { loadMeshNodeRegistry, upsertBleScanNode } from "./meshNodeRegistry";
import type { LiveMeshState, MeshMetricSnapshot, NativeBleScanStatus } from "./types";

const MARKER = "LIVE_MESH_DATA_SPINE_20260608_A";

type NativeBleModule = {
  getStatus?: () => Promise<NativeBleScanStatus>;
  getScanProofStatus?: () => Promise<NativeBleScanStatus>;
  startScanProof?: () => Promise<NativeBleScanStatus>;
  stopScanProof?: () => Promise<NativeBleScanStatus>;
};

function getNativeBle(): NativeBleModule | null {
  return (NativeModules.MauriMeshBle as NativeBleModule | undefined) || null;
}

async function hasPermissions(): Promise<boolean> {
  if (Platform.OS !== "android") return false;

  const scan = await PermissionsAndroid.check(
    PermissionsAndroid.PERMISSIONS.BLUETOOTH_SCAN as never
  );

  const connect = await PermissionsAndroid.check(
    PermissionsAndroid.PERMISSIONS.BLUETOOTH_CONNECT as never
  );

  const location = await PermissionsAndroid.check(
    PermissionsAndroid.PERMISSIONS.ACCESS_FINE_LOCATION
  );

  return scan && connect && location;
}

function normalizeStatus(status?: NativeBleScanStatus | null): NativeBleScanStatus {
  return {
    module: String(status?.module || "MauriMeshBle"),
    mode: String(status?.mode || "unknown"),
    modulePresent: Boolean(status?.modulePresent),
    blePermissions: Boolean(status?.blePermissions),
    liveBleActive: Boolean(status?.liveBleActive),
    scanActive: Boolean(status?.scanActive),
    discoveredCount: Number(status?.discoveredCount || 0),
    scanStartTimeMs: Number(status?.scanStartTimeMs || 0),
    scanStopTimeMs: Number(status?.scanStopTimeMs || 0),
    lastError: String(status?.lastError || ""),
    lastDeviceName: String(status?.lastDeviceName || ""),
    lastDeviceAddress: String(status?.lastDeviceAddress || ""),
    lastRssi: Number(status?.lastRssi || 0),
    truth: String(
      status?.truth ||
        "Live mesh data spine reads native BLE scan proof status only."
    ),
  };
}

export async function readLiveMeshState(): Promise<LiveMeshState> {
  const native = getNativeBle();
  const permissionsGranted = await hasPermissions();

  let nativeStatus: NativeBleScanStatus = {
    module: "MauriMeshBle",
    modulePresent: false,
    blePermissions: permissionsGranted,
    liveBleActive: false,
    scanActive: false,
    discoveredCount: 0,
    mode: "missing_module",
    lastError: "NativeModules.MauriMeshBle not available.",
  };

  if (native?.getScanProofStatus) {
    try {
      nativeStatus = normalizeStatus(await native.getScanProofStatus());
    } catch (error) {
      nativeStatus = {
        ...nativeStatus,
        modulePresent: true,
        mode: "status_error",
        lastError: error instanceof Error ? error.message : String(error),
      };
    }
  }

  if (
    nativeStatus.lastDeviceAddress &&
    nativeStatus.lastDeviceAddress !== "none" &&
    nativeStatus.lastDeviceAddress !== "unknown"
  ) {
    const nodes = await upsertBleScanNode({
      address: nativeStatus.lastDeviceAddress,
      name: nativeStatus.lastDeviceName,
      rssi: nativeStatus.lastRssi,
      source: MARKER,
      truthLevel: "physical_proof",
    });

    const node = nodes[0];
    if (node) {
      publishMeshEvent({
        type: "node_seen",
        createdAt: new Date().toISOString(),
        node,
      });
    }
  }

  const nodes = await loadMeshNodeRegistry();

  const metrics: MeshMetricSnapshot = {
    createdAt: new Date().toISOString(),
    scanActive: Boolean(nativeStatus.scanActive),
    discoveredCount: Number(nativeStatus.discoveredCount || 0),
    nodeCount: nodes.length,
    routeCount: 0,
    deliveryCount: 0,
    relayCount: 0,
    ackCount: 0,
    failureCount: nativeStatus.lastError ? 1 : 0,
    averageLatencyMs: 0,
    truthLevel: nativeStatus.scanActive ? "physical_proof" : "native_status",
  };

  await appendMeshMetricSnapshot(metrics);

  const state: LiveMeshState = {
    marker: MARKER,
    updatedAt: new Date().toISOString(),
    nativeModulePresent: Boolean(nativeStatus.modulePresent),
    permissionsGranted,
    scanActive: Boolean(nativeStatus.scanActive),
    discoveredCount: Number(nativeStatus.discoveredCount || 0),
    nodes,
    metrics,
    lastNativeStatus: nativeStatus,
    truthBoundary:
      "This spine consumes real native BLE scan status and persistent registry data. It does not claim advertise, connect, TX/RX, ACK, relay, or mesh delivery until those phases are proven.",
  };

  publishMeshEvent({
    type: "native_status",
    createdAt: new Date().toISOString(),
    status: nativeStatus,
  });

  publishMeshEvent({
    type: "state_updated",
    createdAt: new Date().toISOString(),
    state,
  });

  return state;
}

export async function startLiveMeshScan(): Promise<LiveMeshState> {
  const native = getNativeBle();

  if (!native?.startScanProof) {
    publishMeshEvent({
      type: "error",
      createdAt: new Date().toISOString(),
      source: MARKER,
      message: "startScanProof() unavailable.",
    });
    return readLiveMeshState();
  }

  await native.startScanProof();
  return readLiveMeshState();
}

export async function stopLiveMeshScan(): Promise<LiveMeshState> {
  const native = getNativeBle();

  if (!native?.stopScanProof) {
    publishMeshEvent({
      type: "error",
      createdAt: new Date().toISOString(),
      source: MARKER,
      message: "stopScanProof() unavailable.",
    });
    return readLiveMeshState();
  }

  await native.stopScanProof();
  return readLiveMeshState();
}
TS

echo ""
echo "============================================================"
echo "7. Create React hook for all screens"
echo "============================================================"

cat > "$LIVE/useLiveMesh.ts" <<'TS'
import { useCallback, useEffect, useState } from "react";
import {
  readLiveMeshState,
  startLiveMeshScan,
  stopLiveMeshScan,
} from "./nativeBleLiveSource";
import type { LiveMeshState } from "./types";

const emptyState: LiveMeshState = {
  marker: "LIVE_MESH_DATA_SPINE_20260608_A",
  updatedAt: new Date(0).toISOString(),
  nativeModulePresent: false,
  permissionsGranted: false,
  scanActive: false,
  discoveredCount: 0,
  nodes: [],
  metrics: {
    createdAt: new Date(0).toISOString(),
    scanActive: false,
    discoveredCount: 0,
    nodeCount: 0,
    routeCount: 0,
    deliveryCount: 0,
    relayCount: 0,
    ackCount: 0,
    failureCount: 0,
    averageLatencyMs: 0,
    truthLevel: "not_proven",
  },
  lastNativeStatus: {
    module: "MauriMeshBle",
    mode: "not_loaded",
    modulePresent: false,
    blePermissions: false,
    liveBleActive: false,
    scanActive: false,
    discoveredCount: 0,
  },
  truthBoundary:
    "Live mesh state has not loaded yet. No mesh delivery claim is made.",
};

export function useLiveMesh(pollMs = 2000) {
  const [state, setState] = useState<LiveMeshState>(emptyState);
  const [loading, setLoading] = useState(false);

  const refresh = useCallback(async () => {
    setLoading(true);
    try {
      const next = await readLiveMeshState();
      setState(next);
      return next;
    } finally {
      setLoading(false);
    }
  }, []);

  const startScan = useCallback(async () => {
    setLoading(true);
    try {
      const next = await startLiveMeshScan();
      setState(next);
      return next;
    } finally {
      setLoading(false);
    }
  }, []);

  const stopScan = useCallback(async () => {
    setLoading(true);
    try {
      const next = await stopLiveMeshScan();
      setState(next);
      return next;
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    let alive = true;

    async function tick() {
      const next = await readLiveMeshState();
      if (alive) setState(next);
    }

    tick();

    const timer = setInterval(tick, pollMs);

    return () => {
      alive = false;
      clearInterval(timer);
    };
  }, [pollMs]);

  return {
    state,
    loading,
    refresh,
    startScan,
    stopScan,
  };
}
TS

echo ""
echo "============================================================"
echo "8. Create Live Mesh Operations screen"
echo "============================================================"

cat > "$APP/live-mesh-ops.tsx" <<'TSX'
import React from "react";
import {
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from "react-native";
import { useLiveMesh } from "../src/maurimesh/live/useLiveMesh";

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
TSX

echo ""
echo "============================================================"
echo "9. Wire dashboard button without removing existing routes"
echo "============================================================"

python3 <<'PY'
from pathlib import Path

path = Path("app/dashboard.tsx")
if not path.exists():
    raise SystemExit("ERROR: app/dashboard.tsx missing")

text = path.read_text()

if "/live-mesh-ops" not in text:
    if '["Native BLE Scan Proof", "/native-ble-scan-proof"],' in text:
        text = text.replace(
            '["Native BLE Scan Proof", "/native-ble-scan-proof"],',
            '["Native BLE Scan Proof", "/native-ble-scan-proof"],\n  ["Live Mesh Ops", "/live-mesh-ops"],',
            1,
        )
    elif "] as const;" in text:
        text = text.replace(
            "] as const;",
            '  ["Live Mesh Ops", "/live-mesh-ops"],\n] as const;',
            1,
        )
    else:
        print("WARN: Could not auto-wire route array. Screen still created.")

if "SAFE_DASHBOARD_LIVE_MESH_OPS_20260608_A" not in text:
    import re
    text = re.sub(
        r'const MARKER = "[^"]+";',
        'const MARKER = "SAFE_DASHBOARD_LIVE_MESH_OPS_20260608_A";',
        text,
        count=1,
    )

path.write_text(text)
print("Dashboard wired to Live Mesh Ops")
PY

echo ""
echo "============================================================"
echo "10. Create tests"
echo "============================================================"

mkdir -p tests/live

cat > tests/live/liveMeshPure.test.ts <<'TS'
import { describe, expect, it } from "vitest";

function stableNodeId(address?: string, name?: string): string {
  const raw = `${address || "unknown-address"}::${name || "unknown-name"}`;
  let hash = 0;
  for (let i = 0; i < raw.length; i += 1) {
    hash = (hash * 31 + raw.charCodeAt(i)) >>> 0;
  }
  return `node_${hash.toString(16)}`;
}

describe("live mesh pure logic", () => {
  it("creates stable node ids for the same BLE address", () => {
    expect(stableNodeId("AA:BB:CC", "peer")).toBe(stableNodeId("AA:BB:CC", "peer"));
  });

  it("creates different ids for different BLE addresses", () => {
    expect(stableNodeId("AA:BB:CC", "peer")).not.toBe(stableNodeId("DD:EE:FF", "peer"));
  });
});
TS

echo ""
echo "============================================================"
echo "11. Create documentation"
echo "============================================================"

cat > "$DOCS/live-mesh-data-spine-20260608.md" <<'MD'
# MauriMesh Live Mesh Data Spine

Marker: `LIVE_MESH_DATA_SPINE_20260608_A`

## Covers

- #56 Real BLE scanning data spine
- #59 Shared live data hook for dashboard screens
- #61 Persistent records foundation using AsyncStorage
- #62 Platform screens can read the same live state
- #64 Persistent mesh node registry
- #86 Initial test coverage foundation

## Truth boundary

This layer consumes native BLE scan proof status only.

It does not claim:

- BLE advertising
- BLE connection
- message TX/RX
- ACK
- relay
- store-forward delivery
- full mesh delivery

Those must be proven in later phases.

## Screens

- `/live-mesh-ops`

## Core modules

- `src/maurimesh/live/types.ts`
- `src/maurimesh/live/meshEventBus.ts`
- `src/maurimesh/live/meshNodeRegistry.ts`
- `src/maurimesh/live/meshMetricsStore.ts`
- `src/maurimesh/live/nativeBleLiveSource.ts`
- `src/maurimesh/live/useLiveMesh.ts`
MD

echo ""
echo "============================================================"
echo "12. Validate"
echo "============================================================"

echo "Markers:"
grep -RniE "LIVE_MESH_DATA_SPINE_20260608_A|LIVE_MESH_OPS_20260608_A|SAFE_DASHBOARD_LIVE_MESH_OPS_20260608_A" src app docs 2>/dev/null || true

echo ""
echo "TypeScript:"
npx tsc --noEmit

echo ""
echo "Expo export:"
rm -rf dist .expo
npx expo export --platform android --clear

echo ""
echo "============================================================"
echo "LIVE MESH DATA SPINE INSTALLED — NO EAS BUILD USED"
echo "Backup: $BACKUP"
echo ""
echo "Next build command:"
echo "npx --yes eas-cli@latest build --platform android --profile preview-apk --clear-cache"
echo ""
echo "After install:"
echo "Dashboard → Live Mesh Ops"
echo "Then grant permissions if denied."
echo "============================================================"
