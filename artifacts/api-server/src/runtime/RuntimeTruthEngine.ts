export const TASK_223_RUNTIME_TRUTH_MARKER =
  "TASK_223_RUNTIME_TRUTH_ENGINE_AUTO_NATIVE_20260608_A";

export type RuntimeTruthFeature =
  | "native_bridge"
  | "ble_permissions"
  | "ble_scan"
  | "ble_advertise"
  | "ble_connect"
  | "ble_tx"
  | "ble_rx"
  | "ack"
  | "relay"
  | string;

export type RuntimeMode = "simulation" | "native_status" | "real_native";

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
  detail?: Record<string, unknown>;
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

function isRealAndroidNativeAttestation(attestation: NativeRuntimeAttestation): boolean {
  return Boolean(
    attestation &&
      attestation.source !== "simulation" &&
      attestation.platform === "android" &&
      attestation.nativeModulePresent === true &&
      Array.isArray(attestation.features) &&
      attestation.features.includes("native_bridge")
  );
}

function sanitizeFeatures(features: RuntimeTruthFeature[]): RuntimeTruthFeature[] {
  return Array.from(
    new Set(
      (features || [])
        .map((feature) => String(feature || "").trim())
        .filter((feature) => feature && feature !== "simulation" && feature !== "mock")
    )
  );
}

export class RuntimeTruthEngine {
  verify(feature: RuntimeTruthFeature): RuntimeTruthState {
    const safe = sanitizeFeatures([feature]);
    for (const item of safe) verifiedFeatures.add(item);

    if (verifiedFeatures.has("native_bridge")) {
      mode = "real_native";
    }

    return this.getState();
  }

  markRealNative(
    features: RuntimeTruthFeature[],
    attestation?: NativeRuntimeAttestation
  ): RuntimeTruthState {
    if (attestation && !isRealAndroidNativeAttestation(attestation)) {
      return this.getState();
    }

    for (const feature of sanitizeFeatures(features)) {
      verifiedFeatures.add(feature);
    }

    verifiedFeatures.add("native_bridge");
    mode = "real_native";

    if (attestation) {
      lastAttestation = {
        ...attestation,
        createdAt: attestation.createdAt || new Date().toISOString(),
        features: sanitizeFeatures(attestation.features),
      };
    }

    return this.getState();
  }

  acceptNativeAttestation(attestation: NativeRuntimeAttestation): RuntimeTruthState {
    if (!isRealAndroidNativeAttestation(attestation)) {
      return this.getState();
    }

    return this.markRealNative(attestation.features, attestation);
  }

  isProofCapable(feature?: RuntimeTruthFeature): boolean {
    if (mode !== "real_native") return false;
    if (!verifiedFeatures.has("native_bridge")) return false;
    if (!feature) return true;
    return verifiedFeatures.has(feature);
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
        "Only a real Android native bridge attestation can promote events to proof scope. Simulation, mock, and static UI events remain labelled as simulation and cannot be mislabelled as physical BLE proof.",
    };
  }
}

export const runtimeTruthEngine = new RuntimeTruthEngine();

export function markRealNative(
  features: RuntimeTruthFeature[],
  attestation?: NativeRuntimeAttestation
) {
  return runtimeTruthEngine.markRealNative(features, attestation);
}

export function acceptNativeAttestation(attestation: NativeRuntimeAttestation) {
  return runtimeTruthEngine.acceptNativeAttestation(attestation);
}

export function isProofCapable(feature?: RuntimeTruthFeature) {
  return runtimeTruthEngine.isProofCapable(feature);
}

export function getRuntimeTruthState() {
  return runtimeTruthEngine.getState();
}
