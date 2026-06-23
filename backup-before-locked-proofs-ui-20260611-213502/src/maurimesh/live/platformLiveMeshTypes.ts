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
