import { HardwareOptimisationDecision } from "./types";

export type MauriMeshRuntimePolicy = {
  allowBleScan: boolean;
  allowBleAdvertise: boolean;
  allowProofHashing: boolean;
  allowHeavyAnimation: boolean;
  maxBleRetries: number;
  routeMode: "store_forward" | "low_energy" | "balanced" | "fastest";
  operatorMessage: string;
};

export function createRuntimePolicy(
  decision: HardwareOptimisationDecision
): MauriMeshRuntimePolicy {
  if (decision.pressure === "critical") {
    return {
      allowBleScan: false,
      allowBleAdvertise: false,
      allowProofHashing: false,
      allowHeavyAnimation: false,
      maxBleRetries: 0,
      routeMode: "store_forward",
      operatorMessage:
        "Critical hardware pressure. MauriMesh safe mode active. BLE scanning paused.",
    };
  }

  if (decision.pressure === "high") {
    return {
      allowBleScan: true,
      allowBleAdvertise: true,
      allowProofHashing: false,
      allowHeavyAnimation: false,
      maxBleRetries: 1,
      routeMode: "low_energy",
      operatorMessage:
        "High hardware pressure. MauriMesh reduced scan intensity and delayed heavy proof tasks.",
    };
  }

  if (decision.pressure === "medium") {
    return {
      allowBleScan: true,
      allowBleAdvertise: true,
      allowProofHashing: true,
      allowHeavyAnimation: false,
      maxBleRetries: 2,
      routeMode: "balanced",
      operatorMessage:
        "Medium hardware pressure. MauriMesh using balanced runtime behaviour.",
    };
  }

  return {
    allowBleScan: true,
    allowBleAdvertise: true,
    allowProofHashing: true,
    allowHeavyAnimation: true,
    maxBleRetries: 3,
    routeMode: "fastest",
    operatorMessage:
      "Device stable. MauriMesh can use full UI and normal runtime behaviour.",
  };
}
