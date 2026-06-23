import {
  DeviceHardwareSample,
  HardwareLearningMemory,
  HardwareOptimisationDecision,
  HardwarePressure,
} from "./types";

function pressureValue(value: HardwarePressure): number {
  if (value === "low") return 0;
  if (value === "medium") return 12;
  if (value === "high") return 26;
  return 42;
}

function pressureFromScore(score: number): HardwarePressure {
  if (score >= 82) return "low";
  if (score >= 64) return "medium";
  if (score >= 42) return "high";
  return "critical";
}

function clamp(value: number) {
  return Math.max(0, Math.min(100, Math.round(value)));
}

export function createDefaultHardwareSample(): DeviceHardwareSample {
  return {
    batteryPercent: 68,
    isCharging: false,
    thermalRisk: "low",
    memoryPressure: "medium",
    storagePressure: "low",
    networkPressure: "medium",
    blePressure: "medium",
    appCrashRisk: "low",
    foreground: true,
    timestamp: Date.now(),
  };
}

export function analyseHardwareSample(
  sample: DeviceHardwareSample,
  memory?: HardwareLearningMemory
): HardwareOptimisationDecision {
  const batteryPenalty =
    sample.batteryPercent <= 8
      ? 38
      : sample.batteryPercent <= 15
        ? 28
        : sample.batteryPercent <= 25
          ? 14
          : 0;

  const chargingBonus = sample.isCharging ? 6 : 0;

  const pressurePenalty =
    pressureValue(sample.thermalRisk) +
    pressureValue(sample.memoryPressure) +
    pressureValue(sample.storagePressure) +
    pressureValue(sample.networkPressure) +
    pressureValue(sample.blePressure) +
    pressureValue(sample.appCrashRisk);

  const backgroundPenalty = sample.foreground ? 0 : 12;
  const repeatedFaultPenalty = memory?.repeatedFaults?.length
    ? Math.min(18, memory.repeatedFaults.length * 4)
    : 0;

  const deviceHealthScore = clamp(
    100 - batteryPenalty - pressurePenalty * 0.32 - backgroundPenalty - repeatedFaultPenalty + chargingBonus
  );

  const pressure = pressureFromScore(deviceHealthScore);
  const safeMode = pressure === "critical" || pressure === "high";

  const recommendations: string[] = [];

  if (sample.batteryPercent <= 15 && !sample.isCharging) {
    recommendations.push("Battery is low. Reduce BLE scanning and prefer store-and-forward.");
  }

  if (sample.thermalRisk === "high" || sample.thermalRisk === "critical") {
    recommendations.push("Thermal risk detected. Pause heavy proof tasks and reduce animations.");
  }

  if (sample.memoryPressure === "high" || sample.memoryPressure === "critical") {
    recommendations.push("Memory pressure detected. Reduce UI effects and clear non-critical queues.");
  }

  if (sample.storagePressure === "high" || sample.storagePressure === "critical") {
    recommendations.push("Storage pressure detected. Compress proof logs and rotate old telemetry.");
  }

  if (sample.blePressure === "high" || sample.blePressure === "critical") {
    recommendations.push("BLE pressure detected. Slow retry timing and avoid scan storms.");
  }

  if (sample.appCrashRisk === "high" || sample.appCrashRisk === "critical") {
    recommendations.push("Crash risk detected. Use safe mode and route user to Operator Console.");
  }

  if (!sample.foreground) {
    recommendations.push("App is backgrounded. Use low-energy background-safe behaviour.");
  }

  if (recommendations.length === 0) {
    recommendations.push("Device state looks stable. Maintain balanced runtime mode.");
  }

  return {
    deviceHealthScore,
    pressure,
    safeMode,
    scanIntensity:
      pressure === "critical"
        ? "off"
        : pressure === "high"
          ? "low"
          : pressure === "medium"
            ? "balanced"
            : "high",
    animationIntensity:
      pressure === "critical" || pressure === "high"
        ? "minimal"
        : pressure === "medium"
          ? "balanced"
          : "rich",
    proofTaskMode:
      pressure === "critical"
        ? "pause"
        : pressure === "high"
          ? "defer"
          : pressure === "medium"
            ? "normal"
            : "priority",
    routePreference:
      pressure === "critical"
        ? "store_forward"
        : pressure === "high"
          ? "low_energy"
          : pressure === "medium"
            ? "balanced"
            : "fastest",
    bleRetryPolicy:
      pressure === "critical"
        ? "pause"
        : pressure === "high"
          ? "slow_retry"
          : "normal_retry",
    recommendations,
    finalTruth:
      "MauriMesh can optimise its own app behaviour around device conditions. It cannot physically repair hardware or bypass Android system protections.",
  };
}

export function updateHardwareLearningMemory(
  previous: HardwareLearningMemory | undefined,
  sample: DeviceHardwareSample,
  decision: HardwareOptimisationDecision
): HardwareLearningMemory {
  const next: HardwareLearningMemory = previous || {
    samplesSeen: 0,
    lastScores: [],
    repeatedFaults: [],
    learnedNotes: [],
  };

  const faults: string[] = [];

  if (sample.thermalRisk === "high" || sample.thermalRisk === "critical") {
    faults.push("thermal_pressure");
  }

  if (sample.memoryPressure === "high" || sample.memoryPressure === "critical") {
    faults.push("memory_pressure");
  }

  if (sample.blePressure === "high" || sample.blePressure === "critical") {
    faults.push("ble_pressure");
  }

  if (sample.appCrashRisk === "high" || sample.appCrashRisk === "critical") {
    faults.push("crash_risk");
  }

  const lastScores = [...next.lastScores, decision.deviceHealthScore].slice(-12);
  const repeatedFaults = Array.from(new Set([...next.repeatedFaults, ...faults])).slice(-12);

  const learnedNotes = [
    ...next.learnedNotes,
    `Sample ${next.samplesSeen + 1}: score=${decision.deviceHealthScore}, pressure=${decision.pressure}, safeMode=${decision.safeMode}`,
  ].slice(-12);

  return {
    samplesSeen: next.samplesSeen + 1,
    lastScores,
    repeatedFaults,
    learnedNotes,
  };
}

export function runHardwareStabilizerDemo() {
  const sample = createDefaultHardwareSample();
  const decision = analyseHardwareSample(sample);
  const memory = updateHardwareLearningMemory(undefined, sample, decision);

  return {
    sample,
    decision,
    memory,
  };
}
