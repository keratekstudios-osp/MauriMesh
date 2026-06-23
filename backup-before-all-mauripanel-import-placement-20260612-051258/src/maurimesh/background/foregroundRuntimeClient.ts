import { NativeModules, Platform } from "react-native";

export const TASK_182_FOREGROUND_RUNTIME_CLIENT_MARKER =
  "TASK_182_FOREGROUND_RUNTIME_CLIENT_20260608_A";

type ForegroundStatus = {
  marker?: string;
  heartbeatPresent?: boolean;
  heartbeat?: string;
  capability?: string;
  truth?: string;
};

type NativeBackgroundRuntime = {
  startForegroundMeshRuntime?: () => Promise<boolean>;
  stopForegroundMeshRuntime?: () => Promise<boolean>;
  getForegroundMeshRuntimeStatus?: () => Promise<ForegroundStatus>;
};

function getNative(): NativeBackgroundRuntime | null {
  return (NativeModules.MauriMeshBackgroundRuntime as NativeBackgroundRuntime | undefined) || null;
}

export async function startMauriMeshForegroundRuntime(): Promise<boolean> {
  if (Platform.OS !== "android") return false;
  const native = getNative();
  if (!native?.startForegroundMeshRuntime) return false;
  return Boolean(await native.startForegroundMeshRuntime());
}

export async function stopMauriMeshForegroundRuntime(): Promise<boolean> {
  if (Platform.OS !== "android") return false;
  const native = getNative();
  if (!native?.stopForegroundMeshRuntime) return false;
  return Boolean(await native.stopForegroundMeshRuntime());
}

export async function getMauriMeshForegroundRuntimeStatus(): Promise<ForegroundStatus> {
  if (Platform.OS !== "android") {
    return {
      marker: TASK_182_FOREGROUND_RUNTIME_CLIENT_MARKER,
      heartbeatPresent: false,
      capability: "unavailable",
      truth: "Foreground runtime is Android-only.",
    };
  }

  const native = getNative();

  if (!native?.getForegroundMeshRuntimeStatus) {
    return {
      marker: TASK_182_FOREGROUND_RUNTIME_CLIENT_MARKER,
      heartbeatPresent: false,
      capability: "native_module_missing",
      truth: "MauriMeshBackgroundRuntime native module is not available.",
    };
  }

  return native.getForegroundMeshRuntimeStatus();
}
