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
