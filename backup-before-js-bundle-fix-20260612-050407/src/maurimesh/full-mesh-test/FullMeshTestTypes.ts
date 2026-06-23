export type FullMeshCheckStatus =
  | "PASS"
  | "WARN"
  | "FAIL"
  | "APK_REQUIRED"
  | "TWO_PHONE_REQUIRED"
  | "THREE_PHONE_REQUIRED"
  | "NATIVE_REQUIRED"
  | "NOT_PROVEN";

export type FullMeshCheck = {
  id: string;
  title: string;
  status: FullMeshCheckStatus;
  detail: string;
  proofRequired: string[];
};

export type FullMeshReport = {
  id: string;
  generatedAt: string;
  appMode: "APK_IN_APP_REPORT";
  score: number;
  passCount: number;
  warnCount: number;
  failCount: number;
  apkRequiredCount: number;
  deviceProofRequiredCount: number;
  checks: FullMeshCheck[];
  routeInventory: {
    total: number;
    present: number;
    missing: number;
    requiredPresent: number;
    requiredMissing: number;
    lines: string[];
  };
  finalTruth: string;
  copyBlock: string;
};
