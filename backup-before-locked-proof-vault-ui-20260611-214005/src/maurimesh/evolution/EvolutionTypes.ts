export type EvolutionSignalKind =
  | "BUILD"
  | "TYPESCRIPT"
  | "EXPO_EXPORT"
  | "APK"
  | "BLE"
  | "ACK"
  | "ROUTE"
  | "TIKANGA"
  | "UI"
  | "DEVICE"
  | "PROOF"
  | "RUST"
  | "JUMPCODE";

export type EvolutionRisk =
  | "LOW"
  | "MEDIUM"
  | "HIGH"
  | "PROTECTED";

export type EvolutionDecision =
  | "OBSERVE_ONLY"
  | "RECOMMEND"
  | "RECOMMEND_WITH_WARNING"
  | "REQUIRE_OPERATOR_APPROVAL"
  | "BLOCK_AUTONOMOUS_CHANGE";

export type EvolutionSource =
  | "PRIMARY_EVOLUTION_ENGINE"
  | "BACKUP_EVOLUTION_MEMORY"
  | "SAFE_FALLBACK_EVOLUTION";

export type EvolutionSignal = {
  id: string;
  kind: EvolutionSignalKind;
  label: string;
  passed: boolean;
  confidence: number;
  evidence: string;
  timestamp: string;
};

export type EvolutionProposal = {
  id: string;
  title: string;
  summary: string;
  risk: EvolutionRisk;
  decision: EvolutionDecision;
  source: EvolutionSource;
  targetLayer: string;
  requiredProof: string[];
  rollbackPlan: string[];
  tikangaNotes: string[];
  canAutoApply: false;
};

export type EvolutionReport = {
  id: string;
  generatedAt: string;
  score: number;
  status: "STABLE" | "WATCHING" | "NEEDS_PROOF" | "BLOCKED";
  source: EvolutionSource;
  signals: EvolutionSignal[];
  proposals: EvolutionProposal[];
  truthBoundary: string;
};
