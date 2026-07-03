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
