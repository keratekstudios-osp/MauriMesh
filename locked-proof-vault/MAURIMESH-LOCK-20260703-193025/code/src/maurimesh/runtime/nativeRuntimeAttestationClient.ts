import { NativeModules, Platform } from "react-native";

export const TASK_223_ROOT_NATIVE_ATTESTATION_CLIENT_MARKER =
  "TASK_223_ROOT_NATIVE_ATTESTATION_CLIENT_20260608_A";

export async function readRootNativeProofFeatures() {
  if (Platform.OS !== "android") {
    return {
      marker: TASK_223_ROOT_NATIVE_ATTESTATION_CLIENT_MARKER,
      nativeModulePresent: false,
      features: [],
      reason: "android_only",
    };
  }

  const native = NativeModules.MauriMeshBle as
    | {
        getStatus?: () => Promise<any>;
        getScanProofStatus?: () => Promise<any>;
      }
    | undefined;

  if (!native) {
    return {
      marker: TASK_223_ROOT_NATIVE_ATTESTATION_CLIENT_MARKER,
      nativeModulePresent: false,
      features: [],
      reason: "MauriMeshBle missing",
    };
  }

  const status =
    native.getScanProofStatus
      ? await native.getScanProofStatus()
      : native.getStatus
      ? await native.getStatus()
      : { modulePresent: true };

  const features = new Set<string>();

  if (status.modulePresent ?? true) features.add("native_bridge");
  if (status.blePermissions) features.add("ble_permissions");
  if (status.scanActive || Number(status.discoveredCount || 0) > 0) {
    features.add("ble_scan");
  }

  return {
    marker: TASK_223_ROOT_NATIVE_ATTESTATION_CLIENT_MARKER,
    nativeModulePresent: Boolean(status.modulePresent ?? true),
    permissionsGranted: Boolean(status.blePermissions),
    scanActive: Boolean(status.scanActive),
    discoveredCount: Number(status.discoveredCount || 0),
    features: Array.from(features),
    status,
  };
}
