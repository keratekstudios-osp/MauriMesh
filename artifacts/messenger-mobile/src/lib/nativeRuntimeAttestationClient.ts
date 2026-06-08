import { NativeModules, Platform } from "react-native";

export const TASK_223_NATIVE_ATTESTATION_CLIENT_MARKER =
  "TASK_223_NATIVE_ATTESTATION_CLIENT_20260608_A";

type AttestationResult = {
  ok: boolean;
  accepted?: boolean;
  proofCapable?: boolean;
  error?: string;
};

type NativeBleStatus = {
  modulePresent?: boolean;
  blePermissions?: boolean;
  scanActive?: boolean;
  discoveredCount?: number;
  mode?: string;
  module?: string;
};

type NativeBleModule = {
  getStatus?: () => Promise<NativeBleStatus>;
  getScanProofStatus?: () => Promise<NativeBleStatus>;
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
      modulePresent: false,
      blePermissions: false,
      scanActive: false,
      discoveredCount: 0,
      mode: "native_module_missing",
    };
  }

  if (native.getScanProofStatus) {
    return native.getScanProofStatus();
  }

  if (native.getStatus) {
    return native.getStatus();
  }

  return {
    modulePresent: true,
    blePermissions: false,
    scanActive: false,
    discoveredCount: 0,
    mode: "native_module_present_status_unavailable",
  };
}

export async function sendNativeRuntimeAttestation(): Promise<AttestationResult> {
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

  const features = ["native_bridge"];

  if (status.modulePresent) features.push("native_bridge");
  if (status.blePermissions) features.push("ble_permissions");
  if (status.scanActive || Number(status.discoveredCount || 0) > 0) {
    features.push("ble_scan");
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
    features: Array.from(new Set(features)),
    createdAt: new Date().toISOString(),
    detail: {
      mode: status.mode,
      module: status.module,
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
