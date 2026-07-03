#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "#62 PLATFORM LIVE BLE-MESH DATA BRIDGE"
echo "Safe foundation for mobile platform + web platform + advanced screens"
echo "NO advertise, NO connect, NO TX/RX, NO ACK, NO relay"
echo "Consumes proven live scan spine where available"
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$HOME/maurimesh-router-backups/task-62-platform-live-bridge-$STAMP"

mkdir -p "$BACKUP"

MOBILE_APP="$ROOT/artifacts/messenger-mobile/app/platform"
MOBILE_STORE="$ROOT/artifacts/messenger-mobile/src/store"
WEB_PLATFORM="$ROOT/artifacts/maurimesh/src/pages/platform"
WEB_ADVANCED="$ROOT/artifacts/maurimesh/src/pages/advanced"
WEB_LIB="$ROOT/artifacts/maurimesh/src/lib"
WEB_COMPONENTS="$ROOT/artifacts/maurimesh/src/components/live"
API_SERVER="$ROOT/artifacts/api-server"
DOCS="$ROOT/docs"
SCRIPTS="$ROOT/scripts"

mkdir -p "$MOBILE_APP" "$MOBILE_STORE" "$WEB_PLATFORM" "$WEB_ADVANCED" "$WEB_LIB" "$WEB_COMPONENTS" "$API_SERVER" "$DOCS" "$SCRIPTS"

echo ""
echo "============================================================"
echo "1. Backup target platform folders"
echo "============================================================"

cp -R "$MOBILE_APP" "$BACKUP/mobile-platform" 2>/dev/null || true
cp -R "$MOBILE_STORE" "$BACKUP/mobile-store" 2>/dev/null || true
cp -R "$WEB_PLATFORM" "$BACKUP/web-platform" 2>/dev/null || true
cp -R "$WEB_ADVANCED" "$BACKUP/web-advanced" 2>/dev/null || true
cp -R "$WEB_LIB" "$BACKUP/web-lib" 2>/dev/null || true
cp package.json "$BACKUP/package.json" 2>/dev/null || true

echo "Backup: $BACKUP"

echo ""
echo "============================================================"
echo "2. Verify current live spine"
echo "============================================================"

if [ -f "$ROOT/src/maurimesh/live/useLiveMesh.ts" ]; then
  echo "Root live mesh spine found: src/maurimesh/live/useLiveMesh.ts"
else
  echo "WARN: Root live mesh spine not found. #62 bridge will still install with safe unavailable state."
fi

if [ -f "$ROOT/src/maurimesh/live/nativeBleLiveSource.ts" ]; then
  grep -Rni "LIVE_MESH_DATA_SPINE_20260608_A" "$ROOT/src/maurimesh/live/nativeBleLiveSource.ts" || true
fi

echo ""
echo "============================================================"
echo "3. Create shared platform live mesh types"
echo "============================================================"

cat > "$MOBILE_STORE/platformLiveMeshTypes.ts" <<'TS'
export const PLATFORM_LIVE_BLE_MESH_BRIDGE_MARKER =
  "PLATFORM_LIVE_BLE_MESH_BRIDGE_20260608_A";

export type PlatformLiveTruthLevel =
  | "physical_proof"
  | "native_status"
  | "api_live"
  | "simulation_labelled"
  | "unavailable";

export type PlatformLiveNode = {
  id: string;
  label: string;
  address?: string;
  name?: string;
  role: string;
  firstSeenAt?: string;
  lastSeenAt?: string;
  seenCount?: number;
  lastRssi?: number;
  truthLevel: PlatformLiveTruthLevel;
};

export type PlatformLiveMetric = {
  key: string;
  label: string;
  value: string | number | boolean;
  truthLevel: PlatformLiveTruthLevel;
};

export type PlatformLiveMeshState = {
  marker: string;
  updatedAt: string;
  source: "mobile-native-spine" | "web-api" | "api-server" | "unavailable";
  nativeModulePresent: boolean;
  permissionsGranted: boolean;
  scanActive: boolean;
  discoveredCount: number;
  nodeCount: number;
  routeCount: number;
  deliveryCount: number;
  relayCount: number;
  ackCount: number;
  failureCount: number;
  nodes: PlatformLiveNode[];
  metrics: PlatformLiveMetric[];
  truthLevel: PlatformLiveTruthLevel;
  truthBoundary: string;
};
TS

cp "$MOBILE_STORE/platformLiveMeshTypes.ts" "$WEB_LIB/platformLiveMeshTypes.ts"

echo ""
echo "============================================================"
echo "4. Create mobile bridge store"
echo "============================================================"

cat > "$MOBILE_STORE/platformLiveMeshBridge.ts" <<'TS'
import AsyncStorage from "@react-native-async-storage/async-storage";
import type {
  PlatformLiveMeshState,
  PlatformLiveMetric,
  PlatformLiveNode,
} from "./platformLiveMeshTypes";
import { PLATFORM_LIVE_BLE_MESH_BRIDGE_MARKER } from "./platformLiveMeshTypes";

const REGISTRY_KEY = "maurimesh.live.meshNodeRegistry.v1";
const METRICS_KEY = "maurimesh.live.meshMetricSnapshots.v1";

function emptyState(reason = "Live mesh data unavailable."): PlatformLiveMeshState {
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
    truthBoundary: reason,
  };
}

async function readJsonArray<T>(key: string): Promise<T[]> {
  try {
    const raw = await AsyncStorage.getItem(key);
    if (!raw) return [];
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

export async function readPlatformLiveMeshState(): Promise<PlatformLiveMeshState> {
  const nodesRaw = await readJsonArray<any>(REGISTRY_KEY);
  const metricsRaw = await readJsonArray<any>(METRICS_KEY);

  const nodes: PlatformLiveNode[] = nodesRaw.map((node, index) => ({
    id: String(node.id || `node_${index}`),
    label: String(node.label || node.name || "BLE node"),
    address: node.address ? String(node.address) : undefined,
    name: node.name ? String(node.name) : undefined,
    role: String(node.role || "candidate"),
    firstSeenAt: node.firstSeenAt ? String(node.firstSeenAt) : undefined,
    lastSeenAt: node.lastSeenAt ? String(node.lastSeenAt) : undefined,
    seenCount: Number(node.seenCount || 0),
    lastRssi: Number(node.lastRssi || 0),
    truthLevel: node.truthLevel || "physical_proof",
  }));

  const latestMetric = metricsRaw[0] || {};

  const metrics: PlatformLiveMetric[] = [
    {
      key: "discoveredCount",
      label: "Discovered BLE devices",
      value: Number(latestMetric.discoveredCount || 0),
      truthLevel: latestMetric.truthLevel || "native_status",
    },
    {
      key: "nodeCount",
      label: "Persistent node records",
      value: nodes.length,
      truthLevel: nodes.length > 0 ? "physical_proof" : "native_status",
    },
    {
      key: "routeCount",
      label: "Routes",
      value: Number(latestMetric.routeCount || 0),
      truthLevel: "unavailable",
    },
    {
      key: "deliveryCount",
      label: "Delivered packets",
      value: Number(latestMetric.deliveryCount || 0),
      truthLevel: "unavailable",
    },
    {
      key: "ackCount",
      label: "ACK count",
      value: Number(latestMetric.ackCount || 0),
      truthLevel: "unavailable",
    },
  ];

  if (!nodes.length && !metricsRaw.length) {
    return emptyState(
      "No live registry or metrics were found yet. Start Native BLE Scan Proof or Live Mesh Ops first."
    );
  }

  return {
    marker: PLATFORM_LIVE_BLE_MESH_BRIDGE_MARKER,
    updatedAt: new Date().toISOString(),
    source: "mobile-native-spine",
    nativeModulePresent: true,
    permissionsGranted: true,
    scanActive: Boolean(latestMetric.scanActive),
    discoveredCount: Number(latestMetric.discoveredCount || 0),
    nodeCount: nodes.length,
    routeCount: Number(latestMetric.routeCount || 0),
    deliveryCount: Number(latestMetric.deliveryCount || 0),
    relayCount: Number(latestMetric.relayCount || 0),
    ackCount: Number(latestMetric.ackCount || 0),
    failureCount: Number(latestMetric.failureCount || 0),
    nodes,
    metrics,
    truthLevel: latestMetric.truthLevel || (nodes.length ? "physical_proof" : "native_status"),
    truthBoundary:
      "This platform bridge reads the proven native BLE scan registry and metrics spine. It does not claim advertise, connect, TX/RX, ACK, relay, or delivery until those phases are proven.",
  };
}
TS

echo ""
echo "============================================================"
echo "5. Create mobile reusable live platform panel"
echo "============================================================"

cat > "$MOBILE_STORE/PlatformLiveMeshPanel.tsx" <<'TSX'
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
TSX

echo ""
echo "============================================================"
echo "6. Create web/API bridge for platform + advanced screens"
echo "============================================================"

cat > "$WEB_LIB/platformLiveMeshBridge.ts" <<'TS'
import type {
  PlatformLiveMeshState,
  PlatformLiveMetric,
  PlatformLiveNode,
} from "./platformLiveMeshTypes";
import { PLATFORM_LIVE_BLE_MESH_BRIDGE_MARKER } from "./platformLiveMeshTypes";

function unavailable(reason: string): PlatformLiveMeshState {
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
    truthBoundary: reason,
  };
}

export async function readPlatformLiveMeshState(): Promise<PlatformLiveMeshState> {
  try {
    const response = await fetch("/api/platform/live-mesh", {
      method: "GET",
      headers: {
        Accept: "application/json",
      },
    });

    if (!response.ok) {
      return unavailable(
        "API /api/platform/live-mesh is unavailable. Web platform screens cannot claim live BLE until the API server is connected to device telemetry."
      );
    }

    const data = await response.json();

    const nodes: PlatformLiveNode[] = Array.isArray(data.nodes) ? data.nodes : [];
    const metrics: PlatformLiveMetric[] = Array.isArray(data.metrics) ? data.metrics : [];

    return {
      marker: PLATFORM_LIVE_BLE_MESH_BRIDGE_MARKER,
      updatedAt: String(data.updatedAt || new Date().toISOString()),
      source: "web-api",
      nativeModulePresent: Boolean(data.nativeModulePresent),
      permissionsGranted: Boolean(data.permissionsGranted),
      scanActive: Boolean(data.scanActive),
      discoveredCount: Number(data.discoveredCount || 0),
      nodeCount: Number(data.nodeCount || nodes.length || 0),
      routeCount: Number(data.routeCount || 0),
      deliveryCount: Number(data.deliveryCount || 0),
      relayCount: Number(data.relayCount || 0),
      ackCount: Number(data.ackCount || 0),
      failureCount: Number(data.failureCount || 0),
      nodes,
      metrics,
      truthLevel: data.truthLevel || "api_live",
      truthBoundary:
        data.truthBoundary ||
        "Web platform bridge reads API telemetry only. It does not directly prove Android BLE radio state.",
    };
  } catch {
    return unavailable(
      "Web platform live mesh API request failed. Showing unavailable state, not mock data."
    );
  }
}
TS

cat > "$WEB_COMPONENTS/PlatformLiveMeshPanel.tsx" <<'TSX'
import React, { useEffect, useState } from "react";
import { readPlatformLiveMeshState } from "../../lib/platformLiveMeshBridge";
import type { PlatformLiveMeshState } from "../../lib/platformLiveMeshTypes";
import { PLATFORM_LIVE_BLE_MESH_BRIDGE_MARKER } from "../../lib/platformLiveMeshTypes";

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
    const timer = window.setInterval(tick, 3000);

    return () => {
      alive = false;
      window.clearInterval(timer);
    };
  }, []);

  return (
    <section
      style={{
        border: "1px solid rgba(0,208,132,0.32)",
        background: "rgba(255,255,255,0.035)",
        borderRadius: 20,
        padding: 20,
        margin: "16px 0",
      }}
    >
      <h2 style={{ color: "#fff", margin: "0 0 8px" }}>{title}</h2>
      <div style={{ color: "#4FC3F7", fontSize: 12, fontWeight: 800, letterSpacing: 1 }}>
        {state.marker}
      </div>

      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12, marginTop: 16 }}>
        <Metric label="Source" value={state.source} />
        <Metric label="Truth" value={state.truthLevel} />
        <Metric label="Scan" value={state.scanActive ? "ACTIVE" : "STOPPED"} />
        <Metric label="Discovered" value={state.discoveredCount} />
        <Metric label="Nodes" value={state.nodeCount} />
        <Metric label="Routes" value={state.routeCount} />
        <Metric label="Delivery" value={state.deliveryCount} />
        <Metric label="ACK" value={state.ackCount} />
      </div>

      <p style={{ color: "rgba(255,255,255,0.68)", lineHeight: 1.6, marginTop: 16 }}>
        {state.truthBoundary}
      </p>
    </section>
  );
}

function Metric({ label, value }: { label: string; value: string | number | boolean }) {
  return (
    <div>
      <div style={{ color: "rgba(255,255,255,0.64)", fontSize: 12, fontWeight: 700 }}>
        {label}
      </div>
      <div style={{ color: "#fff", fontSize: 18, fontWeight: 900 }}>
        {String(value)}
      </div>
    </div>
  );
}
TSX

echo ""
echo "============================================================"
echo "7. Create API server endpoint contract"
echo "============================================================"

cat > "$API_SERVER/platform-live-mesh-endpoint.ts" <<'TS'
export const PLATFORM_LIVE_MESH_API_MARKER =
  "PLATFORM_LIVE_MESH_API_CONTRACT_20260608_A";

export function createPlatformLiveMeshUnavailableResponse() {
  return {
    marker: PLATFORM_LIVE_MESH_API_MARKER,
    updatedAt: new Date().toISOString(),
    source: "api-server",
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
    truthBoundary:
      "API contract installed. Server must be connected to device telemetry before web screens can claim live BLE data.",
  };
}
TS

echo ""
echo "============================================================"
echo "8. Create platform wiring audit script"
echo "============================================================"

cat > "$SCRIPTS/audit-task-62-platform-live-wiring.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo "#62 PLATFORM LIVE WIRING AUDIT"
echo "============================================================"

TARGETS=(
  "artifacts/messenger-mobile/app/platform"
  "artifacts/maurimesh/src/pages/platform"
  "artifacts/maurimesh/src/pages/advanced"
)

echo ""
echo "1. Target screen counts"
for dir in "${TARGETS[@]}"; do
  if [ -d "$dir" ]; then
    count="$(find "$dir" -type f \( -name "*.tsx" -o -name "*.ts" -o -name "*.jsx" -o -name "*.js" \) | wc -l | tr -d ' ')"
    echo "$dir: $count files"
  else
    echo "$dir: MISSING"
  fi
done

echo ""
echo "2. Files with mock/static indicators"
grep -RniE "mock|Mock|MOCK|hardcoded|Hardcoded|sample|Sample|dummy|Dummy|fake|Fake|simulation|Simulation" "${TARGETS[@]}" 2>/dev/null || true

echo ""
echo "3. Files already wired to live panel"
grep -RniE "PlatformLiveMeshPanel|platformLiveMeshBridge|PLATFORM_LIVE_BLE_MESH_BRIDGE_20260608_A" "${TARGETS[@]}" artifacts/messenger-mobile/src/store artifacts/maurimesh/src 2>/dev/null || true

echo ""
echo "4. Required bridge files"
test -f artifacts/messenger-mobile/src/store/platformLiveMeshBridge.ts && echo "mobile bridge OK"
test -f artifacts/messenger-mobile/src/store/PlatformLiveMeshPanel.tsx && echo "mobile panel OK"
test -f artifacts/maurimesh/src/lib/platformLiveMeshBridge.ts && echo "web bridge OK"
test -f artifacts/maurimesh/src/components/live/PlatformLiveMeshPanel.tsx && echo "web panel OK"
test -f artifacts/api-server/platform-live-mesh-endpoint.ts && echo "api endpoint contract OK"

echo ""
echo "============================================================"
echo "#62 AUDIT COMPLETE"
echo "============================================================"
SH

chmod +x "$SCRIPTS/audit-task-62-platform-live-wiring.sh"

echo ""
echo "============================================================"
echo "9. Create docs"
echo "============================================================"

cat > "$DOCS/task-62-platform-live-ble-mesh-data.md" <<'MD'
# Task #62 — Platform Live BLE-Mesh Data Bridge

Marker: `PLATFORM_LIVE_BLE_MESH_BRIDGE_20260608_A`

## Installed foundation

Mobile:
- `artifacts/messenger-mobile/src/store/platformLiveMeshTypes.ts`
- `artifacts/messenger-mobile/src/store/platformLiveMeshBridge.ts`
- `artifacts/messenger-mobile/src/store/PlatformLiveMeshPanel.tsx`

Web:
- `artifacts/maurimesh/src/lib/platformLiveMeshTypes.ts`
- `artifacts/maurimesh/src/lib/platformLiveMeshBridge.ts`
- `artifacts/maurimesh/src/components/live/PlatformLiveMeshPanel.tsx`

API:
- `artifacts/api-server/platform-live-mesh-endpoint.ts`

Audit:
- `scripts/audit-task-62-platform-live-wiring.sh`

## Truth boundary

This bridge reads proven native BLE scan registry/metrics where available.

It does not claim:
- BLE advertising
- BLE connection
- packet TX/RX
- ACK
- relay
- store-forward delivery

Those must be connected in later phases.

## Done means

Every platform/advanced screen must import and display real values from the bridge or an explicit unavailable state. No unlabelled mock data should remain.
MD

echo ""
echo "============================================================"
echo "10. Validate markers and TypeScript"
echo "============================================================"

grep -RniE "PLATFORM_LIVE_BLE_MESH_BRIDGE_20260608_A|PLATFORM_LIVE_MESH_API_CONTRACT_20260608_A" artifacts docs scripts 2>/dev/null || true

echo ""
echo "TypeScript root check"
npx tsc --noEmit

echo ""
echo "Expo export check"
rm -rf dist .expo
npx expo export --platform android --clear

echo ""
echo "Run audit"
bash "$SCRIPTS/audit-task-62-platform-live-wiring.sh"

echo ""
echo "============================================================"
echo "#62 PLATFORM LIVE BLE-MESH BRIDGE INSTALLED"
echo "Backup: $BACKUP"
echo ""
echo "This is the safe bridge foundation."
echo "Next step: wire each platform screen to PlatformLiveMeshPanel or readPlatformLiveMeshState."
echo "============================================================"
