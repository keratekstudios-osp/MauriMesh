import { DeviceReadinessDecision } from "./types";

export function evaluateDeviceReadiness(input?: {
  uiComplete?: boolean;
  backupWiringComplete?: boolean;
  typeScriptPassed?: boolean;
  apkBuilt?: boolean;
  twoPhonesTested?: boolean;
  logcatProofCaptured?: boolean;
}): DeviceReadinessDecision {
  const uiComplete = input?.uiComplete ?? true;
  const backupWiringComplete = input?.backupWiringComplete ?? true;
  const typeScriptPassed = input?.typeScriptPassed ?? true;
  const apkBuilt = input?.apkBuilt ?? false;
  const twoPhonesTested = input?.twoPhonesTested ?? false;
  const logcatProofCaptured = input?.logcatProofCaptured ?? false;

  let readinessScore = 0;
  if (uiComplete) readinessScore += 22;
  if (backupWiringComplete) readinessScore += 18;
  if (typeScriptPassed) readinessScore += 20;
  if (apkBuilt) readinessScore += 15;
  if (twoPhonesTested) readinessScore += 15;
  if (logcatProofCaptured) readinessScore += 10;

  const requiredProof: string[] = [];

  if (!apkBuilt) requiredProof.push("Build installable APK.");
  if (!twoPhonesTested) requiredProof.push("Test Phone A to Phone B delivery.");
  if (!logcatProofCaptured) requiredProof.push("Capture TX/RX/ACK logcat proof.");

  return {
    readinessScore,
    requiredProof,
    readyForReplit: uiComplete && backupWiringComplete && typeScriptPassed,
    readyForApk: uiComplete && backupWiringComplete && typeScriptPassed,
    readyForRealBleProof: apkBuilt && twoPhonesTested && logcatProofCaptured,
  };
}
