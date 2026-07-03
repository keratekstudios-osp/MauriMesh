export type BleHardwareBackupPolicy = {
  source: "BACKUP_POLICY";
  allowScan: boolean;
  allowAdvertise: boolean;
  scanWindowMs: number;
  scanCooldownMs: number;
  maxRetries: number;
  routeMode: "store_forward" | "low_energy" | "balanced";
  proofHashing: "paused" | "deferred" | "allowed";
  animationMode: "minimal" | "balanced";
  safeMode: boolean;
  reason: string;
  finalTruth: string;
};

export function createBleHardwareBackupPolicy(
  reason = "Hardware controller unavailable"
): BleHardwareBackupPolicy {
  return {
    source: "BACKUP_POLICY",
    allowScan: true,
    allowAdvertise: true,
    scanWindowMs: 2500,
    scanCooldownMs: 15000,
    maxRetries: 1,
    routeMode: "low_energy",
    proofHashing: "deferred",
    animationMode: "minimal",
    safeMode: true,
    reason:
      `${reason}. Using conservative BLE tuning to prevent scan storms, battery drain, thermal pressure, and crash loops.`,
    finalTruth:
      "Backup BLE policy protects app behaviour only. It does not prove BLE delivery, repair hardware, or bypass Android restrictions.",
  };
}
