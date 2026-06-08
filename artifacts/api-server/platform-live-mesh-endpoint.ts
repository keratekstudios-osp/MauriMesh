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
