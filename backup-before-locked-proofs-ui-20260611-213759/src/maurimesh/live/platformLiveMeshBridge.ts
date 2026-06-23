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
