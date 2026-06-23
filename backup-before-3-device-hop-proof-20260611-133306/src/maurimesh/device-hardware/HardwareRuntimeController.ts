import {
  analyseHardwareSample,
  getNativeHardwareTelemetry,
  telemetryToHardwareSample,
  updateHardwareLearningMemory,
} from ".";
import { createRuntimePolicy, MauriMeshRuntimePolicy } from "./HardwareRuntimePolicy";
import {
  DeviceHardwareSample,
  HardwareLearningMemory,
  HardwareOptimisationDecision,
} from "./types";

export type HardwareRuntimeControllerState = {
  source: "NATIVE_ANDROID" | "JS_FALLBACK" | "CONTROLLER_FALLBACK";
  sample: DeviceHardwareSample;
  decision: HardwareOptimisationDecision;
  policy: MauriMeshRuntimePolicy;
  memory: HardwareLearningMemory;
  runtimeMode: "full" | "balanced" | "reduced" | "safe_mode";
  shouldThrottleBle: boolean;
  shouldThrottleProof: boolean;
  shouldReduceAnimations: boolean;
  shouldUseStoreForward: boolean;
  operatorAlert: string;
  finalTruth: string;
};

let controllerMemory: HardwareLearningMemory | undefined;

function modeFromDecision(
  decision: HardwareOptimisationDecision
): HardwareRuntimeControllerState["runtimeMode"] {
  if (decision.pressure === "critical") return "safe_mode";
  if (decision.pressure === "high") return "reduced";
  if (decision.pressure === "medium") return "balanced";
  return "full";
}

function fallbackSample(): DeviceHardwareSample {
  return {
    batteryPercent: 50,
    isCharging: false,
    thermalRisk: "medium",
    memoryPressure: "medium",
    storagePressure: "medium",
    networkPressure: "medium",
    blePressure: "medium",
    appCrashRisk: "low",
    foreground: true,
    timestamp: Date.now(),
  };
}

export async function evaluateHardwareRuntimeController(): Promise<HardwareRuntimeControllerState> {
  try {
    const reading = await getNativeHardwareTelemetry();
    const sample = telemetryToHardwareSample(reading);
    const decision = analyseHardwareSample(sample, controllerMemory);
    const policy = createRuntimePolicy(decision);

    controllerMemory = updateHardwareLearningMemory(
      controllerMemory,
      sample,
      decision
    );

    return {
      source: reading.source,
      sample,
      decision,
      policy,
      memory: controllerMemory,
      runtimeMode: modeFromDecision(decision),
      shouldThrottleBle:
        !policy.allowBleScan ||
        policy.maxBleRetries <= 1 ||
        decision.bleRetryPolicy !== "normal_retry",
      shouldThrottleProof: !policy.allowProofHashing,
      shouldReduceAnimations: !policy.allowHeavyAnimation,
      shouldUseStoreForward: policy.routeMode === "store_forward",
      operatorAlert: policy.operatorMessage,
      finalTruth:
        "Hardware Runtime Controller adapts MauriMesh app behaviour using telemetry. It cannot repair physical hardware, bypass Android protections, or prove BLE delivery without TX/RX/ACK logs.",
    };
  } catch {
    const sample = fallbackSample();
    const decision = analyseHardwareSample(sample, controllerMemory);
    const policy = createRuntimePolicy(decision);

    controllerMemory = updateHardwareLearningMemory(
      controllerMemory,
      sample,
      decision
    );

    return {
      source: "CONTROLLER_FALLBACK",
      sample,
      decision,
      policy,
      memory: controllerMemory,
      runtimeMode: modeFromDecision(decision),
      shouldThrottleBle: true,
      shouldThrottleProof: false,
      shouldReduceAnimations: true,
      shouldUseStoreForward: false,
      operatorAlert:
        "Controller fallback active. Hardware telemetry was unavailable, so MauriMesh is using balanced-safe behaviour.",
      finalTruth:
        "Controller fallback protects the app when telemetry fails. It does not prove native readings.",
    };
  }
}

export function resetHardwareRuntimeMemory() {
  controllerMemory = undefined;
}

export function getHardwareRuntimeMemory() {
  return controllerMemory;
}

export type BleRuntimeTuning = {
  scanWindowMs: number;
  scanCooldownMs: number;
  maxRetries: number;
  allowAdvertise: boolean;
  allowScan: boolean;
  reason: string;
};

export function createBleRuntimeTuning(
  state: HardwareRuntimeControllerState
): BleRuntimeTuning {
  if (state.runtimeMode === "safe_mode") {
    return {
      scanWindowMs: 0,
      scanCooldownMs: 30000,
      maxRetries: 0,
      allowAdvertise: false,
      allowScan: false,
      reason: "Safe mode: BLE paused to protect device stability.",
    };
  }

  if (state.runtimeMode === "reduced") {
    return {
      scanWindowMs: 2500,
      scanCooldownMs: 15000,
      maxRetries: 1,
      allowAdvertise: state.policy.allowBleAdvertise,
      allowScan: state.policy.allowBleScan,
      reason: "Reduced mode: BLE scan storms prevented.",
    };
  }

  if (state.runtimeMode === "balanced") {
    return {
      scanWindowMs: 5000,
      scanCooldownMs: 8000,
      maxRetries: 2,
      allowAdvertise: state.policy.allowBleAdvertise,
      allowScan: state.policy.allowBleScan,
      reason: "Balanced mode: normal low-risk BLE cadence.",
    };
  }

  return {
    scanWindowMs: 8000,
    scanCooldownMs: 4000,
    maxRetries: 3,
    allowAdvertise: true,
    allowScan: true,
    reason: "Full mode: device is stable enough for normal BLE cadence.",
  };
}

export type ProofRuntimeTuning = {
  allowProofHashing: boolean;
  allowLedgerWrite: boolean;
  proofBatchSize: number;
  reason: string;
};

export function createProofRuntimeTuning(
  state: HardwareRuntimeControllerState
): ProofRuntimeTuning {
  if (state.runtimeMode === "safe_mode") {
    return {
      allowProofHashing: false,
      allowLedgerWrite: true,
      proofBatchSize: 1,
      reason: "Safe mode: proof hashing paused, lightweight ledger writes allowed.",
    };
  }

  if (state.runtimeMode === "reduced") {
    return {
      allowProofHashing: false,
      allowLedgerWrite: true,
      proofBatchSize: 2,
      reason: "Reduced mode: proof hashing deferred until device pressure drops.",
    };
  }

  if (state.runtimeMode === "balanced") {
    return {
      allowProofHashing: true,
      allowLedgerWrite: true,
      proofBatchSize: 5,
      reason: "Balanced mode: proof tasks allowed at moderate batch size.",
    };
  }

  return {
    allowProofHashing: true,
    allowLedgerWrite: true,
    proofBatchSize: 10,
    reason: "Full mode: device stable for normal proof throughput.",
  };
}
