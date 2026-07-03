import {
  createBleRuntimeTuning,
  createProofRuntimeTuning,
  evaluateHardwareRuntimeController,
  HardwareRuntimeControllerState,
} from "../device-hardware";
import {
  BleHardwareBackupPolicy,
  createBleHardwareBackupPolicy,
} from "./BleHardwareBackupPolicy";

export type BleHardwareRuntimeMode =
  | "NATIVE_CONTROLLED"
  | "JS_FALLBACK_CONTROLLED"
  | "BACKUP_CONTROLLED";

export type BleHardwareRuntimeDecision = {
  mode: BleHardwareRuntimeMode;
  controllerState?: HardwareRuntimeControllerState;
  backupPolicy?: BleHardwareBackupPolicy;
  allowScan: boolean;
  allowAdvertise: boolean;
  scanWindowMs: number;
  scanCooldownMs: number;
  maxRetries: number;
  allowProofHashing: boolean;
  proofBatchSize: number;
  reduceAnimations: boolean;
  useStoreForward: boolean;
  safeMode: boolean;
  operatorAlert: string;
  finalTruth: string;
};

export async function evaluateBleHardwareRuntime(): Promise<BleHardwareRuntimeDecision> {
  try {
    const controllerState = await evaluateHardwareRuntimeController();
    const ble = createBleRuntimeTuning(controllerState);
    const proof = createProofRuntimeTuning(controllerState);

    const mode: BleHardwareRuntimeMode =
      controllerState.source === "NATIVE_ANDROID"
        ? "NATIVE_CONTROLLED"
        : "JS_FALLBACK_CONTROLLED";

    return {
      mode,
      controllerState,
      allowScan: ble.allowScan,
      allowAdvertise: ble.allowAdvertise,
      scanWindowMs: ble.scanWindowMs,
      scanCooldownMs: ble.scanCooldownMs,
      maxRetries: ble.maxRetries,
      allowProofHashing: proof.allowProofHashing,
      proofBatchSize: proof.proofBatchSize,
      reduceAnimations: controllerState.shouldReduceAnimations,
      useStoreForward: controllerState.shouldUseStoreForward,
      safeMode: controllerState.runtimeMode === "safe_mode",
      operatorAlert: `${controllerState.operatorAlert} BLE tuning: ${ble.reason}`,
      finalTruth:
        "BLE hardware runtime uses telemetry-driven tuning when available. Real BLE delivery still requires APK TX/RX/ACK logcat proof.",
    };
  } catch (error) {
    const backup = createBleHardwareBackupPolicy(
      error instanceof Error ? error.message : "Unknown controller failure"
    );

    return {
      mode: "BACKUP_CONTROLLED",
      backupPolicy: backup,
      allowScan: backup.allowScan,
      allowAdvertise: backup.allowAdvertise,
      scanWindowMs: backup.scanWindowMs,
      scanCooldownMs: backup.scanCooldownMs,
      maxRetries: backup.maxRetries,
      allowProofHashing: backup.proofHashing === "allowed",
      proofBatchSize: 1,
      reduceAnimations: backup.animationMode === "minimal",
      useStoreForward: backup.routeMode === "store_forward",
      safeMode: backup.safeMode,
      operatorAlert: backup.reason,
      finalTruth: backup.finalTruth,
    };
  }
}

export function shouldStartBleScan(
  decision: BleHardwareRuntimeDecision
): boolean {
  return decision.allowScan && !decision.safeMode;
}

export function shouldAdvertiseBle(
  decision: BleHardwareRuntimeDecision
): boolean {
  return decision.allowAdvertise;
}

export function getBleRetryLimit(
  decision: BleHardwareRuntimeDecision
): number {
  return decision.maxRetries;
}
