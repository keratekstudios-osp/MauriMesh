export const TASK_223_RUNTIME_TRUTH_MARKER =
  "TASK_223_RUNTIME_TRUTH_ENGINE_AUTO_NATIVE_20260608_A";

export type RuntimeTruthFeature =
  | "native_bridge"
  | "ble_scan"
  | "ble_advertise"
  | "ble_connect"
  | "ble_tx"
  | "ble_rx"
  | "ack"
  | "relay"
  | string;

export type RuntimeMode =
  | "simulation"
  | "native_status"
  | "real_native";

export type NativeRuntimeAttestation = {
  marker?: string;
  source: string;
  platform: string;
  appPackage?: string;
  nativeModulePresent: boolean;
  permissionsGranted?: boolean;
  scanActive?: boolean;
  discoveredCount?: number;
  features: RuntimeTruthFeature[];
  createdAt?: string;
  deviceModel?: string;
  buildId?: string;
};

export type RuntimeTruthState = {
  marker: string;
  mode: RuntimeMode;
  proofCapable: boolean;
  verifiedFeatures: RuntimeTruthFeature[];
  lastAttestation?: NativeRuntimeAttestation;
  updatedAt: string;
  truthBoundary: string;
};

const verifiedFeatures = new Set<RuntimeTruthFeature>();
let mode: RuntimeMode = "simulation";
let lastAttestation: NativeRuntimeAttestation | undefined;

function hasRealNativeMinimum(attestation: NativeRuntimeAttestation): boolean {
  return Boolean(
    attestation &&
      attestation.source !== "simulation" &&
      attestation.platform === "android" &&
      attestation.nativeModulePresent === true &&
      Array.isArray(attestation.features) &&
      attestation.features.includes("native_bridge")
  );
}

export class RuntimeTruthEngine {
  verify(feature: RuntimeTruthFeature): RuntimeTruthState {
    verifiedFeatures.add(feature);
    if (verifiedFeatures.has("native_bridge")) {
      mode = "real_native";
    }
    return this.getState();
  }

  markRealNative(features: RuntimeTruthFeature[], attestation?: NativeRuntimeAttestation): RuntimeTruthState {
    if (attestation && !hasRealNativeMinimum(attestation)) {
      return this.getState();
    }

    for (const feature of features || []) {
      if (feature && feature !== "simulation") {
        verifiedFeatures.add(feature);
      }
    }

    verifiedFeatures.add("native_bridge");
    mode = "real_native";

    if (attestation) {
      lastAttestation = {
        ...attestation,
        createdAt: attestation.createdAt || new Date().toISOString(),
      };
    }

    return this.getState();
  }

  acceptNativeAttestation(attestation: NativeRuntimeAttestation): RuntimeTruthState {
    if (!hasRealNativeMinimum(attestation)) {
      return this.getState();
    }

    const safeFeatures = attestation.features.filter(
      (feature) => feature && feature !== "simulation"
    );

    return this.markRealNative(safeFeatures, attestation);
  }

  isProofCapable(): boolean {
    return mode === "real_native" && verifiedFeatures.has("native_bridge");
  }

  getState(): RuntimeTruthState {
    return {
      marker: TASK_223_RUNTIME_TRUTH_MARKER,
      mode,
      proofCapable: this.isProofCapable(),
      verifiedFeatures: Array.from(verifiedFeatures),
      lastAttestation,
      updatedAt: new Date().toISOString(),
      truthBoundary:
        "Only real Android native module attestation can promote events to proof scope. Simulation events remain simulation and cannot be mislabelled as physical BLE proof.",
    };
  }
}

export const runtimeTruthEngine = new RuntimeTruthEngine();

export function markRealNative(features: RuntimeTruthFeature[], attestation?: NativeRuntimeAttestation) {
  return runtimeTruthEngine.markRealNative(features, attestation);
}

export function isProofCapable() {
  return runtimeTruthEngine.isProofCapable();
}

export function getRuntimeTruthState() {
  return runtimeTruthEngine.getState();
}
