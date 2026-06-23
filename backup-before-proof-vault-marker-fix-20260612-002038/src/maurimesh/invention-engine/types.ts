export type TransportKind =
  | "BLE"
  | "WIFI_DIRECT"
  | "LOCAL_WIFI"
  | "INTERNET"
  | "SATELLITE"
  | "STORE_FORWARD";

export type NodeRole =
  | "ENDPOINT"
  | "RELAY"
  | "GATEWAY"
  | "SUPERNODE"
  | "ANCHOR"
  | "UNKNOWN";

export type TrustLevel =
  | "BLOCKED"
  | "UNKNOWN"
  | "OBSERVED"
  | "TRUSTED"
  | "VERIFIED"
  | "GUARDIAN";

export type CulturalState =
  | "NOA_OPEN"
  | "TAPU_PROTECTED"
  | "WHANAUNGATANGA_TRUSTED"
  | "MANAAKITANGA_CARE"
  | "KAITIAKITANGA_GUARDIAN"
  | "KIA_KAHA_EMERGENCY";

export type DeliveryStatus =
  | "CREATED"
  | "QUEUED"
  | "ROUTING"
  | "SENT"
  | "RELAYED"
  | "STORED"
  | "DELIVERED"
  | "ACKED"
  | "FAILED"
  | "HEALING"
  | "DEFERRED";

export type MeshNode = {
  id: string;
  label?: string;
  role: NodeRole;
  trust: TrustLevel;
  batteryPct: number;
  signalPct: number;
  online: boolean;
  lastSeenMs: number;
  transports: TransportKind[];
  culturalState?: CulturalState;
};

export type MeshPacket = {
  id: string;
  from: string;
  to: string;
  body: string;
  createdAtMs: number;
  ttl: number;
  priority: number;
  culturalState: CulturalState;
  encrypted?: boolean;
  metadata?: Record<string, unknown>;
};

export type RouteHop = {
  nodeId: string;
  transport: TransportKind;
  score: number;
  reason: string;
};

export type RoutePlan = {
  packetId: string;
  hops: RouteHop[];
  totalScore: number;
  transport: TransportKind;
  decisionReason: string;
  storeAndForward: boolean;
  governanceApproved: boolean;
};

export type DeliveryLedgerEvent = {
  packetId: string;
  status: DeliveryStatus;
  atMs: number;
  nodeId?: string;
  route?: string[];
  reason?: string;
};

export type LearningMemory = {
  routeKey: string;
  successCount: number;
  failureCount: number;
  averageLatencyMs: number;
  trustDelta: number;
  lastUpdatedMs: number;
};

export type GovernanceDecision = {
  approved: boolean;
  reason: string;
  culturalState: CulturalState;
  restrictions: string[];
};

export type SynthAgentName = "CLEO_SYNTH" | "CHANELLE_SYNTH";

export type SynthMessage = {
  agent: SynthAgentName;
  tone: "calm" | "protective" | "educational" | "technical" | "emergency";
  text: string;
};

export type EngineResult = {
  packet: MeshPacket;
  governance: GovernanceDecision;
  routePlan: RoutePlan;
  ledger: DeliveryLedgerEvent[];
  synth: SynthMessage[];
};
