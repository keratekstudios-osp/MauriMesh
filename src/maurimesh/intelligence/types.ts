export type IntelligenceMode = "SIMULATION" | "LIVE_API" | "DEVICE_PROOF_REQUIRED";

export type IntelligenceSignal = {
  id: string;
  name: string;
  score: number;
  status: "excellent" | "good" | "warning" | "critical";
  detail: string;
};

export type RouteCandidate = {
  id: string;
  name: string;
  transport: "BLE" | "BLE_RELAY" | "WIFI" | "WIFI_DIRECT" | "INTERNET" | "HYBRID";
  latencyMs: number;
  trust: number;
  energyCost: number;
  deliveryConfidence: number;
  available: boolean;
};

export type RouteDecision = {
  selected: RouteCandidate;
  candidates: RouteCandidate[];
  reason: string;
  score: number;
};

export type ProofDecision = {
  packetId: string;
  hashPresent: boolean;
  ackPresent: boolean;
  routePresent: boolean;
  timestampPresent: boolean;
  deviceLogPresent: boolean;
  confidence: number;
  truth: string;
};

export type GovernanceDecision = {
  action: "approved" | "approved_with_warning" | "review_required" | "refused";
  culturalRisk: "low" | "medium" | "high" | "protected";
  manaProtection: number;
  auditNote: string;
};

export type SelfHealingDecision = {
  healthScore: number;
  detectedFaults: string[];
  repairActions: string[];
  homeostasis: "stable" | "watching" | "repairing" | "critical";
};

export type DeviceReadinessDecision = {
  readinessScore: number;
  requiredProof: string[];
  readyForReplit: boolean;
  readyForApk: boolean;
  readyForRealBleProof: boolean;
};

export type IntelligenceReport = {
  mode: IntelligenceMode;
  overallScore: number;
  signals: IntelligenceSignal[];
  route: RouteDecision;
  proof: ProofDecision;
  governance: GovernanceDecision;
  selfHealing: SelfHealingDecision;
  deviceReadiness: DeviceReadinessDecision;
  finalTruth: string;
};
