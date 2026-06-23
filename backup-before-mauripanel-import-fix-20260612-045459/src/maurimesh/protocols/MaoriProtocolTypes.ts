export type MaoriProtocolRisk =
  | "LOW"
  | "MEDIUM"
  | "HIGH"
  | "PROTECTED";

export type MaoriProtocolAction =
  | "APPROVED"
  | "APPROVED_WITH_WARNING"
  | "REVIEW_REQUIRED"
  | "REFUSED"
  | "APK_PROOF_REQUIRED"
  | "MULTI_DEVICE_PROOF_REQUIRED"
  | "UNAVAILABLE_FALLBACK";

export type MaoriProtocolSource =
  | "PRIMARY_TIKANGA_ENGINE"
  | "BACKUP_PROTOCOL_REGISTRY"
  | "SAFE_FALLBACK_PROTOCOL";

export type MaoriProtocolTerm = {
  id: string;
  reo: string;
  english: string;
  engineeringMeaning: string;
  risk: MaoriProtocolRisk;
  action: MaoriProtocolAction;
  source: MaoriProtocolSource;
  proofLabel: string;
};

export type MaoriProtocolDecision = {
  id: string;
  screen: string;
  action: MaoriProtocolAction;
  source: MaoriProtocolSource;
  risk: MaoriProtocolRisk;
  reoSummary: string;
  englishSummary: string;
  terms: MaoriProtocolTerm[];
  warnings: string[];
  truthBoundary: string;
};
