import { NativeModules, PermissionsAndroid, Platform } from "react-native";

type HardwareBleStatus = {
  module?: string;
  nativeModule?: boolean;
  bluetoothAdapterPresent?: boolean;
  bluetoothEnabled?: boolean;
  scanPermission?: boolean;
  connectPermission?: boolean;
  fineLocationPermission?: boolean;
  postNotificationsPermission?: boolean;
  serviceRunning?: boolean;
  discoveredCount?: number;
  lastDeviceName?: string;
  lastDeviceAddress?: string;
  lastRssi?: number;
  truth?: string;
  proofMarker?: string;
};

const NativeBle = NativeModules.MauriMeshHardwareBle;

export async function requestMauriMeshHardwareBlePermissions() {
  if (Platform.OS !== "android") {
    return {
      ok: false,
      reason: "ANDROID_ONLY",
    };
  }

  const permissions: string[] = [];

  if (Platform.Version >= 31) {
    permissions.push(
      PermissionsAndroid.PERMISSIONS.BLUETOOTH_SCAN,
      PermissionsAndroid.PERMISSIONS.BLUETOOTH_CONNECT,
      PermissionsAndroid.PERMISSIONS.BLUETOOTH_ADVERTISE,
    );
  }

  permissions.push(
    PermissionsAndroid.PERMISSIONS.ACCESS_FINE_LOCATION,
    PermissionsAndroid.PERMISSIONS.ACCESS_COARSE_LOCATION,
  );

  if (Platform.Version >= 33) {
    permissions.push(PermissionsAndroid.PERMISSIONS.POST_NOTIFICATIONS);
  }

  const result = await PermissionsAndroid.requestMultiple(permissions as any);

  return {
    ok: Object.values(result).every((value) => value === PermissionsAndroid.RESULTS.GRANTED),
    result,
  };
}

export async function getMauriMeshHardwareBleStatus(): Promise<HardwareBleStatus> {
  if (!NativeBle) {
    return {
      nativeModule: false,
      truth: "NATIVE_MODULE_MISSING",
      proofMarker: "MAURIMESH_NATIVE_HARDWARE_BLE_MODULE_MISSING",
    };
  }

  try {
    return await NativeBle.getStatus();
  } catch (error: any) {
    return {
      nativeModule: true,
      truth: "NATIVE_MODULE_STATUS_ERROR",
      proofMarker: "MAURIMESH_NATIVE_HARDWARE_BLE_STATUS_ERROR",
      lastDeviceName: String(error?.message || error),
    };
  }
}

export async function startMauriMeshHardwareBleScan() {
  if (!NativeBle) {
    return {
      started: false,
      proofMarker: "MAURIMESH_NATIVE_HARDWARE_BLE_MODULE_MISSING",
    };
  }

  return NativeBle.startScan();
}

export async function stopMauriMeshHardwareBleScan() {
  if (!NativeBle) {
    return {
      stopped: false,
      proofMarker: "MAURIMESH_NATIVE_HARDWARE_BLE_MODULE_MISSING",
    };
  }

  return NativeBle.stopScan();
}

export async function openMauriMeshBluetoothSettings() {
  if (!NativeBle) return false;
  return NativeBle.openBluetoothSettings();
}
