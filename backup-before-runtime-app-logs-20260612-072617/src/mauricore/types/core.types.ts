export type RiskLevel = "low" | "medium" | "high" | "critical";

export type ProofResult = "pass" | "fail" | "blocked" | "requires_review";

export type LayerStatus =
  | "missing"
  | "created"
  | "partial"
  | "learning"
  | "stable"
  | "verified"
  | "protected"
  | "unsafe"
  | "deprecated";

export type HealthState =
  | "healthy"
  | "degraded"
  | "unstable"
  | "critical"
  | "safe_mode";

export type CoreMode =
  | "development"
  | "simulation"
  | "device_test"
  | "production";

export type TapuNoaState = "noa" | "tapu" | "restricted" | "review_required";

export type DecisionStatus =
  | "allowed"
  | "blocked"
  | "requires_review"
  | "safe_mode";

export type TransportKind =
  | "BLE"
  | "WIFI_DIRECT"
  | "LOCAL_WIFI"
  | "INTERNET"
  | "STORE_FORWARD"
  | "UNKNOWN";

export type CoreDecision = {
  id: string;
  timestamp: string;
  action: string;
  status: DecisionStatus;
  reason: string;
  risk: RiskLevel;
  confidence: number;
  requiresProof: boolean;
  requiresHumanApproval: boolean;
  tikanga?: TikangaDecision;
  evidence?: string[];
};

export type CoreLayer = {
  id: string;
  name: string;
  status: LayerStatus;
  confidence: number;
  dependencies: string[];
  proofRequired: boolean;
  testsRequired: string[];
  rollbackReady: boolean;
  riskLevel: RiskLevel;
  lastUpdated: string;
};

export type ProofRecord = {
  id: string;
  timestamp: string;
  layerId: string;
  action: string;
  result: ProofResult;
  evidence: string[];
  hash: string;
  previousHash?: string;
  confidence: number;
  note?: string;
};

export type MemoryQuality =
  | "observed"
  | "repeated"
  | "verified"
  | "trusted"
  | "inherited"
  | "outdated"
  | "unsafe"
  | "poisoned";

export type MemoryRecord = {
  id: string;
  timestamp: string;
  event: string;
  result: "success" | "failure" | "blocked" | "unknown";
  cause?: string;
  lesson?: string;
  futureBehaviour?: string;
  confidence: number;
  quality: MemoryQuality;
  evidence: string[];
};

export type TikangaDecision = {
  action: string;
  tapuNoa: TapuNoaState;
  manaImpact: number;
  pono: boolean;
  tika: boolean;
  kaitiakitangaProtected: boolean;
  rangatiratangaRespected: boolean;
  rahui: boolean;
  allowed: boolean;
  reason: string;
};

export type WhareTapaWhaHealth = {
  tahaTinana: number;
  tahaHinengaro: number;
  tahaWhanau: number;
  tahaWairua: number;
  whenua: number;
  overallBalance: number;
  repairNeeded: boolean;
};

export type RouteNode = {
  id: string;
  label: string;
  trust: number;
  battery: number;
  signal: number;
  online: boolean;
};

export type RouteEdge = {
  from: string;
  to: string;
  transport: TransportKind;
  latencyMs: number;
  ackSuccess: number;
  privacyRisk: number;
  batteryCost: number;
};

export type RoutePlan = {
  allowed: boolean;
  selectedPath: string[];
  transport: TransportKind;
  score: number;
  reason: string;
  fallback: TransportKind;
  requiresProof: boolean;
};

export type PacketPrivacy = "public" | "local_only" | "encrypted_relay" | "tapu_private" | "never_share";

export type CorePacket = {
  packetId: string;
  senderId: string;
  recipientId: string;
  timestamp: string;
  ttl: number;
  hopCount: number;
  routePath: string[];
  payloadHash: string;
  signature?: string;
  ackToken: string;
  retryCount: number;
  privacy: PacketPrivacy;
  transport: TransportKind;
  storeForward: boolean;
};

export type AdapterReport = {
  adapterId: string;
  ok: boolean;
  findings: string[];
  missing: string[];
  risk: RiskLevel;
};

export type VerificationReport = {
  ok: boolean;
  layerId: string;
  checks: Array<{
    name: string;
    ok: boolean;
    detail: string;
  }>;
  decision: "advance" | "hold" | "rollback" | "review";
};

export type RepairPlan = {
  id: string;
  timestamp: string;
  issue: string;
  healthState: HealthState;
  risk: RiskLevel;
  action: "observe" | "auto_repair" | "propose_repair" | "safe_mode" | "human_review";
  steps: string[];
  rollbackRequired: boolean;
};

export type BuildReadiness = {
  ok: boolean;
  canBuildApk: boolean;
  missing: string[];
  warnings: string[];
  requiredProof: string[];
};

export type AcceptanceProof = {
  accepted: boolean;
  summary: string;
  passed: string[];
  failed: string[];
  requiredNext: string[];
};
