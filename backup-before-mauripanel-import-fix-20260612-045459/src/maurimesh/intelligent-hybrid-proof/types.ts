export type MeshNodeRole =
  | "PHONE_A_SENDER"
  | "PHONE_B_RELAY"
  | "PHONE_C_RECEIVER"
  | "PHONE_A_GATEWAY"
  | "PHONE_B_CLIENT"
  | "MAC_C_BRIDGE_CANDIDATE"
  | "BLE_PERIPHERAL_OBSERVED_ONLY";

export type MeshTransport =
  | "BLE"
  | "WIFI_HOTSPOT"
  | "WIFI_DIRECT"
  | "LOCAL_WIFI"
  | "INTERNET"
  | "APP_LOGIC";

export type MeshProofStage =
  | "RUNTIME_BOOT"
  | "GOVERNANCE_CHECK"
  | "MEMORY_LOAD"
  | "ROUTE_CANDIDATES_BUILT"
  | "BEST_PIPELINE_SELECTED"
  | "BLE_HYBRID_READY"
  | "TWO_HOP_A_TO_B_TX"
  | "TWO_HOP_B_RX"
  | "TWO_HOP_B_FORWARD"
  | "TWO_HOP_ACK_B_TO_A"
  | "TWO_HOP_SIGNED_OFF"
  | "ABC_A_TX_TO_B"
  | "ABC_B_RX_FROM_A"
  | "ABC_B_FORWARD_TO_C"
  | "ABC_C_RX_FROM_B"
  | "ABC_C_ACK_TO_B"
  | "ABC_B_ACK_TO_A"
  | "ABC_APP_READY_SIGNED_OFF"
  | "SELF_HEAL_APPLIED"
  | "MISTAKE_REMEMBERED"
  | "TRUST_UPDATED"
  | "LOGIC_TRUST_100"
  | "PROOF_COMPLETE";

export type RoutePipeline = {
  id: string;
  label: string;
  hops: string[];
  transports: MeshTransport[];
  trust: number;
  latencyMs: number;
  mistakes: number;
  successes: number;
  signedOff: boolean;
  truth: string;
};

export type ProofEvent = {
  id: string;
  stage: MeshProofStage;
  role: MeshNodeRole;
  pipelineId: string;
  trust: number;
  timestamp: string;
  detail: string;
  signed: boolean;
};

export type MeshMemory = {
  version: number;
  generatedAt: string;
  routePipelines: RoutePipeline[];
  mistakes: string[];
  signedProofs: string[];
  governanceWarnings: string[];
};
