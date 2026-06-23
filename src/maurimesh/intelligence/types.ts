export type MauriMeshTruthClass =
  | "APK_PROOF_SCREEN_WORKFLOW"
  | "LOCAL_PROOF_VAULT_STORAGE"
  | "LEARNER_CLASSIFICATION_REPORT"
  | "NATIVE_BLE_GATT_PACKET_BOUND"
  | "INCONCLUSIVE"
  | "BLOCKED";

export type MauriMeshDecision =
  | "APPROVED"
  | "APPROVED_WITH_WARNING"
  | "REVIEW_REQUIRED"
  | "REFUSED"
  | "BLOCKED";

export type MauriMeshRiskLevel = "LOW" | "MEDIUM" | "HIGH" | "PROTECTED";

export type MauriMeshTransport = "BLE_GATT" | "BLE_SCREEN_WORKFLOW" | "WIFI_LOCAL" | "STORE_FORWARD" | "UNKNOWN";

export type MauriMeshNodeRole = "PHONE_A" | "PHONE_B" | "PHONE_C" | "GATEWAY" | "RELAY" | "ANCHOR" | "UNKNOWN";

export type MauriMeshProofSignal = {
  packetId: string;
  event: string;
  actor: string;
  transport: MauriMeshTransport;
  timestamp: string;
  source: "APK" | "REACT_NATIVE_JS" | "ANDROID_NATIVE" | "LOGCAT" | "VAULT" | "LEARNER";
  raw?: string;
};

export type MauriMeshRouteCandidate = {
  id: string;
  path: string[];
  transport: MauriMeshTransport;
  latencyScore: number;
  trustScore: number;
  resilienceScore: number;
  governanceScore: number;
  congestionScore: number;
  finalScore: number;
  decision: MauriMeshDecision;
  reason: string;
};

export type MauriMeshGovernanceResult = {
  decision: MauriMeshDecision;
  risk: MauriMeshRiskLevel;
  tikanga: string[];
  warnings: string[];
  reason: string;
};

export type MauriMeshResilienceResult = {
  health: "GREEN" | "AMBER" | "RED";
  issues: string[];
  recoveryPlan: string[];
  selfHealAllowed: boolean;
};

export type MauriMeshProofVerdict = {
  packetId: string;
  truthClass: MauriMeshTruthClass;
  decision: MauriMeshDecision;
  requiredEvents: string[];
  foundEvents: string[];
  missingEvents: string[];
  nativeBleGattPacketBoundPass: boolean;
  reason: string;
};

export type MauriMeshExamResult = {
  examId: string;
  name: string;
  passed: boolean;
  decision: MauriMeshDecision;
  truthClass: MauriMeshTruthClass;
  score: number;
  checks: Array<{
    id: string;
    label: string;
    passed: boolean;
    evidence: string;
  }>;
};
