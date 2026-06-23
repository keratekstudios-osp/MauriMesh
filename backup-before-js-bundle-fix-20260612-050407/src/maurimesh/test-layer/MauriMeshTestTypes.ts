export type MauriMeshTestSeverity = "PASS" | "WARN" | "FAIL";

export type MauriMeshTestCategory =
  | "APP_BOOT"
  | "UI_ROUTES"
  | "DASHBOARD_BUTTONS"
  | "BACKUP_NAVIGATION"
  | "MESSAGING_FLOW"
  | "ACK_PROOF"
  | "BLE_3_HOP_PROOF_PATH"
  | "NATIVE_TELEMETRY"
  | "PIXEL_CALLING"
  | "AI_PIXEL_RECONSTRUCTION"
  | "TRUTH_BOUNDARY"
  | "APK_DEVICE_PROOF"
  | "ONE_REAL_DEVICE_APK_TEST";

export type MauriMeshTestStep = {
  id: string;
  category: MauriMeshTestCategory;
  label: string;
  severity: MauriMeshTestSeverity;
  detail: string;
  proofRequired: boolean;
  proofTag: string;
};

export type MauriMeshTestSummaryStatus =
  | "PASSED"
  | "PASSED_WITH_WARNINGS"
  | "FAILED";

export type MauriMeshFullTestReport = {
  id: string;
  generatedAt: string;
  status: MauriMeshTestSummaryStatus;
  score: number;
  total: number;
  passed: number;
  warnings: number;
  failed: number;
  steps: MauriMeshTestStep[];
  finalReply: string;
  realDeviceTruth: string;
};

export type ThreeHopBleProofPlan = {
  testName: "THREE_HOP_BLE_MESSAGE_ACK_PROOF";
  path: ["PHONE_A_SENDER", "PHONE_B_RELAY", "PHONE_C_RECEIVER"];
  requiredEvents: string[];
  passCondition: string;
  truthBoundary: string;
};


export type OneRealDeviceApkProofPlan = {
  testName: "ONE_REAL_DEVICE_APK_PROOF";
  deviceRole: "PHONE_A_SINGLE_DEVICE";
  requiredBeforeTest: string[];
  inAppScreensToOpen: string[];
  adbProofEvents: string[];
  passCondition: string;
  warningCondition: string;
  failCondition: string;
  truthBoundary: string;
};
