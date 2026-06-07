import { AppState, type AppStateStatus } from "react-native";
import * as Battery from "expo-battery";

export type ScanDutyCycle = "HIGH" | "LOW_POWER";

type DutyCycleListener = (cycle: ScanDutyCycle) => void;

let currentCycle: ScanDutyCycle = "HIGH";
const listeners = new Set<DutyCycleListener>();
let batteryLevel = 1.0;
let appState: AppStateStatus = "active";

// Trigger LOW_POWER when backgrounded OR battery < 20 %.
// The "no peers for 120 s" trigger is handled inside useBleTransport
// which calls forceNoPeersDutyCycle() directly.
function computeCycle(): ScanDutyCycle {
  if (appState !== "active") return "LOW_POWER";
  if (batteryLevel < 0.2) return "LOW_POWER";
  return "HIGH";
}

/** Called by useBleTransport when no peers have been seen for 120 s. */
export function forceNoPeersDutyCycle(): void {
  if (currentCycle !== "LOW_POWER") {
    currentCycle = "LOW_POWER";
    listeners.forEach((cb) => cb("LOW_POWER"));
  }
}

/** Called by useBleTransport when a peer is (re)discovered. */
export function clearNoPeersDutyCycle(): void {
  const next = computeCycle();
  if (next !== currentCycle) {
    currentCycle = next;
    listeners.forEach((cb) => cb(next));
  }
}

function update() {
  const next = computeCycle();
  if (next !== currentCycle) {
    currentCycle = next;
    listeners.forEach((cb) => cb(next));
  }
}

export function getScanDutyCycle(): ScanDutyCycle {
  return currentCycle;
}

export function onScanDutyCycleChange(cb: DutyCycleListener): () => void {
  listeners.add(cb);
  return () => listeners.delete(cb);
}

export function startPowerManager(): () => void {
  const appStateSub = AppState.addEventListener("change", (state) => {
    appState = state;
    update();
  });

  Battery.getBatteryLevelAsync()
    .then((level) => {
      batteryLevel = level;
      update();
    })
    .catch(() => {});

  let batterySubUnsub: (() => void) | null = null;

  try {
    const batterySub = Battery.addBatteryLevelListener(
      ({ batteryLevel: level }) => {
        batteryLevel = level;
        update();
      }
    );
    batterySubUnsub = () => batterySub.remove();
  } catch {
    // expo-battery may be unavailable in some environments
  }

  return () => {
    appStateSub.remove();
    batterySubUnsub?.();
  };
}

/** Pause between scans. 0 = continuous. */
export function scanRestMs(cycle: ScanDutyCycle): number {
  switch (cycle) {
    case "HIGH":      return 2_000; // 2 s scan, 2 s rest (normal mode)
    case "LOW_POWER": return 9_000; // 1 s scan, 9 s rest (10 s total cycle)
  }
}

/** How long each scan window lasts. 0 = use rest only (no scan). */
export function scanWindowMs(cycle: ScanDutyCycle): number {
  switch (cycle) {
    case "HIGH":      return 2_000;
    case "LOW_POWER": return 1_000;
  }
}
