import { MauriMeshResilienceResult } from "../types";

export function mauriMeshSelfHealingPlan(input: {
  adbOnline?: boolean;
  appOpened?: boolean;
  dashboardStable?: boolean;
  vaultStable?: boolean;
  packetIdMatched?: boolean;
  nativeBleGattSeen?: boolean;
  routeGlitch?: boolean;
}): MauriMeshResilienceResult {
  const issues: string[] = [];
  const recoveryPlan: string[] = [];

  if (!input.adbOnline) {
    issues.push("ADB/device link not confirmed.");
    recoveryPlan.push("Reconnect USB/Wi-Fi ADB, verify adb devices -l.");
  }

  if (!input.appOpened) {
    issues.push("APK open not confirmed.");
    recoveryPlan.push("Launch app with monkey/logcat and inspect AndroidRuntime.");
  }

  if (!input.dashboardStable) {
    issues.push("Dashboard route unstable.");
    recoveryPlan.push("Use Safe Dashboard dependency-light fallback.");
  }

  if (!input.vaultStable) {
    issues.push("Proof vault route unstable.");
    recoveryPlan.push("Use Proof Vault Health / Storage Reader and guard route separation.");
  }

  if (!input.packetIdMatched) {
    issues.push("Packet ID chain incomplete.");
    recoveryPlan.push("Do not claim PASS; rerun proof and require same packetId across required events.");
  }

  if (!input.nativeBleGattSeen) {
    issues.push("Native BLE/GATT packet-bound evidence missing.");
    recoveryPlan.push("Require packetId inside native BLE/GATT callback/log transport before native PASS.");
  }

  if (input.routeGlitch) {
    issues.push("Route button glitch/double tap risk.");
    recoveryPlan.push("Enable dashboard route debounce.");
  }

  const health = issues.length === 0 ? "GREEN" : issues.length <= 2 ? "AMBER" : "RED";

  return {
    health,
    issues,
    recoveryPlan,
    selfHealAllowed: health !== "GREEN",
  };
}
