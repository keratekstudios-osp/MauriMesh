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
