/**
 * useBleReadiness — Android BLE permission + hardware status hook.
 *
 * Design decisions after inspection:
 *  - PermissionsAndroid is used for all permission checks (no BleManager needed).
 *  - Hardware state (BT on/off, supported) uses a TRANSIENT BleManager:
 *    create → read state → destroy immediately.  This avoids leaving a second
 *    persistent manager alongside useBleTransport's own manager.
 *  - "BLE transport active" is read directly from useMeshStore.transportStatus
 *    which useBleTransport writes when BT is PoweredOn + permissions granted.
 *  - Android SDK < 31 uses ACCESS_FINE_LOCATION instead of the newer trio;
 *    the hook reports SCAN/CONNECT/ADVERTISE as "n/a" on those devices.
 *  - Safe on web / Expo Go: all values stay "unknown" / null, no crash.
 */

import { useCallback, useEffect, useState } from "react";
import { PermissionsAndroid, Platform } from "react-native";
import { useMeshStore } from "@/lib/store/meshStore";

export type PermStatus = "granted" | "denied" | "na" | "unknown";

export interface BlePermissions {
  bluetoothScan:      PermStatus;  // Android 12+ (SDK 31+)
  bluetoothConnect:   PermStatus;  // Android 12+ (SDK 31+)
  bluetoothAdvertise: PermStatus;  // Android 12+ (SDK 31+)
  fineLocation:       PermStatus;  // Android < 12
}

export interface BleReadiness {
  permissions:          BlePermissions;
  bluetoothOn:          boolean | null;   // null = unknown / not checked yet
  bleSupported:         boolean | null;   // null = unknown
  transportActive:      boolean;          // from useMeshStore (set by useBleTransport)
  isAndroid12Plus:      boolean;
  loading:              boolean;
  requestPermissions:   () => Promise<void>;
  refresh:              () => Promise<void>;
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

function getSdkVersion(): number {
  if (Platform.OS !== "android") return 0;
  return typeof Platform.Version === "number"
    ? Platform.Version
    : parseInt(Platform.Version as string, 10);
}

async function checkPermissions(sdk: number): Promise<BlePermissions> {
  if (Platform.OS !== "android") {
    return { bluetoothScan: "unknown", bluetoothConnect: "unknown", bluetoothAdvertise: "unknown", fineLocation: "unknown" };
  }
  try {
    if (sdk >= 31) {
      const [scan, connect, advertise] = await Promise.all([
        PermissionsAndroid.check(PermissionsAndroid.PERMISSIONS.BLUETOOTH_SCAN),
        PermissionsAndroid.check(PermissionsAndroid.PERMISSIONS.BLUETOOTH_CONNECT),
        PermissionsAndroid.check(PermissionsAndroid.PERMISSIONS.BLUETOOTH_ADVERTISE),
      ]);
      return {
        bluetoothScan:      scan      ? "granted" : "denied",
        bluetoothConnect:   connect   ? "granted" : "denied",
        bluetoothAdvertise: advertise ? "granted" : "denied",
        fineLocation:       "na",
      };
    }
    // SDK < 31: only ACCESS_FINE_LOCATION is the BLE gate
    const loc = await PermissionsAndroid.check(
      PermissionsAndroid.PERMISSIONS.ACCESS_FINE_LOCATION
    );
    return {
      bluetoothScan:      "na",
      bluetoothConnect:   "na",
      bluetoothAdvertise: "na",
      fineLocation:       loc ? "granted" : "denied",
    };
  } catch {
    return { bluetoothScan: "unknown", bluetoothConnect: "unknown", bluetoothAdvertise: "unknown", fineLocation: "unknown" };
  }
}

async function requestPermissions(sdk: number): Promise<BlePermissions> {
  if (Platform.OS !== "android") {
    return { bluetoothScan: "unknown", bluetoothConnect: "unknown", bluetoothAdvertise: "unknown", fineLocation: "unknown" };
  }
  try {
    if (sdk >= 31) {
      const result = await PermissionsAndroid.requestMultiple([
        PermissionsAndroid.PERMISSIONS.BLUETOOTH_SCAN,
        PermissionsAndroid.PERMISSIONS.BLUETOOTH_CONNECT,
        PermissionsAndroid.PERMISSIONS.BLUETOOTH_ADVERTISE,
      ]);
      const G = PermissionsAndroid.RESULTS.GRANTED;
      return {
        bluetoothScan:      result[PermissionsAndroid.PERMISSIONS.BLUETOOTH_SCAN]       === G ? "granted" : "denied",
        bluetoothConnect:   result[PermissionsAndroid.PERMISSIONS.BLUETOOTH_CONNECT]    === G ? "granted" : "denied",
        bluetoothAdvertise: result[PermissionsAndroid.PERMISSIONS.BLUETOOTH_ADVERTISE]  === G ? "granted" : "denied",
        fineLocation:       "na",
      };
    }
    const granted = await PermissionsAndroid.request(
      PermissionsAndroid.PERMISSIONS.ACCESS_FINE_LOCATION
    );
    return {
      bluetoothScan:      "na",
      bluetoothConnect:   "na",
      bluetoothAdvertise: "na",
      fineLocation:       granted === PermissionsAndroid.RESULTS.GRANTED ? "granted" : "denied",
    };
  } catch {
    return { bluetoothScan: "denied", bluetoothConnect: "denied", bluetoothAdvertise: "denied", fineLocation: "denied" };
  }
}

/**
 * Read BLE hardware state using a TRANSIENT BleManager.
 * The manager is destroyed immediately after the state is read to avoid
 * leaving a second persistent manager alongside useBleTransport's own.
 */
async function readHardwareState(): Promise<{ on: boolean | null; supported: boolean | null }> {
  if (Platform.OS === "web") return { on: null, supported: null };
  try {
    // eslint-disable-next-line @typescript-eslint/no-require-imports
    const { BleManager, State } = require("react-native-ble-plx") as typeof import("react-native-ble-plx");
    const mgr = new BleManager();
    const state = await mgr.state();
    mgr.destroy(); // Always destroy — do not persist
    if (state === State.Unsupported) return { on: false,  supported: false };
    if (state === State.PoweredOn)   return { on: true,   supported: true  };
    if (state === State.PoweredOff)  return { on: false,  supported: true  };
    return { on: null, supported: true };
  } catch {
    return { on: null, supported: null };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hook
// ─────────────────────────────────────────────────────────────────────────────

const INIT_PERMS: BlePermissions = {
  bluetoothScan:      "unknown",
  bluetoothConnect:   "unknown",
  bluetoothAdvertise: "unknown",
  fineLocation:       "unknown",
};

export function useBleReadiness(): BleReadiness {
  // Ground-truth transport state — set by useBleTransport when BT PoweredOn + perms OK
  const transportActive = useMeshStore((s) => s.transportStatus.bleReady);

  const [permissions,  setPermissions]  = useState<BlePermissions>(INIT_PERMS);
  const [bluetoothOn,  setBluetoothOn]  = useState<boolean | null>(null);
  const [bleSupported, setBleSupported] = useState<boolean | null>(null);
  const [loading,      setLoading]      = useState(true);

  const sdk = getSdkVersion();

  const refresh = useCallback(async () => {
    setLoading(true);
    const [perms, hw] = await Promise.all([
      checkPermissions(sdk),
      readHardwareState(),
    ]);
    setPermissions(perms);
    setBluetoothOn(hw.on);
    setBleSupported(hw.supported);
    setLoading(false);
  }, [sdk]);

  useEffect(() => { void refresh(); }, [refresh]);

  const doRequestPermissions = useCallback(async () => {
    setLoading(true);
    const [perms, hw] = await Promise.all([
      requestPermissions(sdk),
      readHardwareState(),
    ]);
    setPermissions(perms);
    setBluetoothOn(hw.on);
    setBleSupported(hw.supported);
    setLoading(false);
  }, [sdk]);

  return {
    permissions,
    bluetoothOn,
    bleSupported,
    transportActive,
    isAndroid12Plus: sdk >= 31,
    loading,
    requestPermissions: doRequestPermissions,
    refresh,
  };
}
