import { NativeModules, Platform } from "react-native";

export const TASK_223_NATIVE_ATTESTATION_CLIENT_MARKER =
  "TASK_223_NATIVE_ATTESTATION_CLIENT_20260608_A";

type NativeBleStatus = {
  module?: string;
  mode?: string;
  modulePresent?: boolean;
  blePermissions?: boolean;
  scanActive?: boolean;
  discoveredCount?: number;
  liveBleActive?: boolean;
  lastError?: string;
};

type NativeBleModule = {
  getStatus?: () => Promise<NativeBleStatus>;
  getScanProofStatus?: () => Promise<NativeBleStatus>;
};

export type NativeAttestationResult = {
  ok: boolean;
  accepted?: boolean;
  proofCapable?: boolean;
  error?: string;
};

function getApiBase(): string {
  const globalAny = globalThis as any;

  return (
    globalAny.__MAURIMESH_API_BASE__ ||
    globalAny.EXPO_PUBLIC_API_URL ||
    globalAny.MAURIMESH_API_URL ||
    ""
  );
}

async function readNativeBleStatus(): Promise<NativeBleStatus> {
  const native = NativeModules.MauriMeshBle as NativeBleModule | undefined;

  if (!native) {
    return {
      module: "MauriMeshBle",
      mode: "native_module_missing",
      modulePresent: false,
      blePermissions: false,
      scanActive: false,
      discoveredCount: 0,
    };
  }

  if (native.getScanProofStatus) {
    return native.getScanProofStatus();
  }

  if (native.getStatus) {
    return native.getStatus();
  }

  return {
    module: "MauriMeshBle",
    mode: "module_present_status_unavailable",
    modulePresent: true,
    blePermissions: false,
    scanActive: false,
    discoveredCount: 0,
  };
}

export async function sendNativeRuntimeAttestation(): Promise<NativeAttestationResult> {
  if (Platform.OS !== "android") {
    return {
      ok: false,
      error: "Native runtime attestation is Android-only.",
    };
  }

  const apiBase = getApiBase();

  if (!apiBase) {
    return {
      ok: false,
      error:
        "API base unavailable. Set __MAURIMESH_API_BASE__, EXPO_PUBLIC_API_URL, or MAURIMESH_API_URL.",
    };
  }

  const status = await readNativeBleStatus();

  const features = new Set<string>();
  if (status.modulePresent) features.add("native_bridge");
  if (status.blePermissions) features.add("ble_permissions");
  if (status.scanActive || Number(status.discoveredCount || 0) > 0) {
    features.add("ble_scan");
  }

  const payload = {
    marker: TASK_223_NATIVE_ATTESTATION_CLIENT_MARKER,
    source: "physical_android_apk",
    platform: "android",
    appPackage: "com.maurimesh.messenger",
    nativeModulePresent: Boolean(status.modulePresent),
    permissionsGranted: Boolean(status.blePermissions),
    scanActive: Boolean(status.scanActive),
    discoveredCount: Number(status.discoveredCount || 0),
    features: Array.from(features),
    createdAt: new Date().toISOString(),
    detail: {
      module: status.module,
      mode: status.mode,
      liveBleActive: status.liveBleActive,
      lastError: status.lastError,
    },
  };

  try {
    const response = await fetch(`${apiBase.replace(/\/$/, "")}/api/runtime/verify`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json",
      },
      body: JSON.stringify(payload),
    });

    const json = await response.json().catch(() => ({}));

    return {
      ok: response.ok,
      accepted: Boolean(json.accepted),
      proofCapable: Boolean(json.proofCapable),
      error: response.ok ? undefined : JSON.stringify(json),
    };
  } catch (error) {
    return {
      ok: false,
      error: error instanceof Error ? error.message : String(error),
    };
  }
}
