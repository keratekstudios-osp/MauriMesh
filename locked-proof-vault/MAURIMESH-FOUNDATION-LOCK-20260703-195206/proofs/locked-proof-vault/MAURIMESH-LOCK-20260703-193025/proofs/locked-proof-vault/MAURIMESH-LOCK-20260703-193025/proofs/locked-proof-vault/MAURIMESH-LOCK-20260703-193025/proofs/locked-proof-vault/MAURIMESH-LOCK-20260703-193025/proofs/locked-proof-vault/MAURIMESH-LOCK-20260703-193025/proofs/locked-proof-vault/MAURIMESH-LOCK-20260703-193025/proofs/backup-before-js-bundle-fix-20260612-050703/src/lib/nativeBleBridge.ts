import { NativeModules, PermissionsAndroid, Platform } from "react-native";

export type NativeBleBridgeStatus = {
  platform: string;
  modulePresent: boolean;
  moduleName: string;
  bluetoothScanPermission: "granted" | "denied" | "unavailable";
  bluetoothConnectPermission: "granted" | "denied" | "unavailable";
  fineLocationPermission: "granted" | "denied" | "unavailable";
  liveBleActive: false;
  truth: string;
};

function hasCallable(value: unknown): value is () => Promise<unknown> {
  return typeof value === "function";
}

async function checkPermission(permission: string | undefined) {
  if (Platform.OS !== "android" || !permission) return "unavailable" as const;

  try {
    const granted = await PermissionsAndroid.check(permission as any);
    return granted ? ("granted" as const) : ("denied" as const);
  } catch {
    return "unavailable" as const;
  }
}

export async function getNativeBleBridgeStatus(): Promise<NativeBleBridgeStatus> {
  const moduleName = "MauriMeshBle";
  const nativeModule = (NativeModules as any)[moduleName];

  const scanPermission =
    Platform.OS === "android"
      ? await checkPermission((PermissionsAndroid.PERMISSIONS as any).BLUETOOTH_SCAN)
      : "unavailable";

  const connectPermission =
    Platform.OS === "android"
      ? await checkPermission((PermissionsAndroid.PERMISSIONS as any).BLUETOOTH_CONNECT)
      : "unavailable";

  const fineLocationPermission =
    Platform.OS === "android"
      ? await checkPermission(PermissionsAndroid.PERMISSIONS.ACCESS_FINE_LOCATION)
      : "unavailable";

  let modulePresent = Boolean(nativeModule);

  if (nativeModule && hasCallable(nativeModule.getStatus)) {
    try {
      await nativeModule.getStatus();
      modulePresent = true;
    } catch {
      modulePresent = true;
    }
  }

  return {
    platform: Platform.OS,
    modulePresent,
    moduleName,
    bluetoothScanPermission: scanPermission,
    bluetoothConnectPermission: connectPermission,
    fineLocationPermission,
    liveBleActive: false,
    truth:
      "Read-only native BLE bridge status. This does not scan, advertise, connect, send, receive, or claim live BLE.",
  };
}
