export type ProofClass =
  | "APK_WORKFLOW_PROOF"
  | "REACTNATIVEJS_MONITOR_PROOF"
  | "BRIDGE_LOG_ONLY"
  | "NATIVE_BLE_GATT_PACKET_BOUND"
  | "INCONCLUSIVE"
  | "NO_PACKET_FOUND";

export type ProofVerdict =
  | "LOCKED_PASS"
  | "PASS_CANDIDATE"
  | "ATTEMPT_LOCKED"
  | "FAIL"
  | "INCONCLUSIVE";

export type DeviceRole = "A06_PHONE_A" | "S10_PHONE_B" | "A16_PHONE_C" | string;

export type LearnerEvidence = {
  id: string;
  timestamp: string;
  packetId: string;
  event: string;
  role: DeviceRole;
  device?: string;
  source:
    | "APK_SCREEN"
    | "REACT_NATIVE_JS"
    | "NATIVE_BRIDGE"
    | "NATIVE_BLE_GATT"
    | "ADB"
    | "GRADLE"
    | "EAS"
    | "MANUAL"
    | "LEDGER";
  rawLine: string;
  proofClass: ProofClass;
  confidence: number;
};

export type RouteDecision = {
  id: string;
  timestamp: string;
  packetId: string;
  route: string[];
  decision: string;
  score: number;
  reason: string;
  verdict: ProofVerdict;
};

export type DeviceTrust = {
  role: DeviceRole;
  successCount: number;
  failCount: number;
  lastSeen?: string;
  trustScore: number;
  notes: string[];
};

export type RecoveryPlan = {
  issue: string;
  cause: string;
  nextAction: string;
  shellHint?: string;
  confidence: number;
};
