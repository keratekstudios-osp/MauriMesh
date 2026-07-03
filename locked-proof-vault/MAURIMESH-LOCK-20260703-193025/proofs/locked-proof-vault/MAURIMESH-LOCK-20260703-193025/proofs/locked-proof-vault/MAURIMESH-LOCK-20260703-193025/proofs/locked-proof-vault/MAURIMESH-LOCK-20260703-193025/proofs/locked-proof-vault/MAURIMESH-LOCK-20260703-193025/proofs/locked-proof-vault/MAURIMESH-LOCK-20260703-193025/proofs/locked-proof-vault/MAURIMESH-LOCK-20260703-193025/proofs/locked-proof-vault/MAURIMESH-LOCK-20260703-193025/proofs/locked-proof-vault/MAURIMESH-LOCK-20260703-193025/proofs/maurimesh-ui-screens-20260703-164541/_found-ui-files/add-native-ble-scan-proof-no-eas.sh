#!/usr/bin/env bash
set -e

echo "=================================================="
echo "ADD NATIVE BLE SCAN PROOF — CONTROLLED LIVE RADIO"
echo "NO TX, NO RX, NO ACK, NO RELAY"
echo "=================================================="

BACKUP="$HOME/maurimesh-router-backups/backup-before-native-ble-scan-proof-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP"

BASE="android/app/src/main/java/com/maurimesh/messenger"
MODULE="$BASE/MauriMeshBleModule.kt"
DASH="app/dashboard.tsx"
SCAN_SCREEN="app/native-ble-scan-proof.tsx"

cp "$MODULE" "$BACKUP/MauriMeshBleModule.kt" 2>/dev/null || true
cp "$DASH" "$BACKUP/dashboard.tsx" 2>/dev/null || true

if [ ! -f "$MODULE" ]; then
  echo "ERROR: Missing $MODULE"
  exit 1
fi

echo ""
echo "1. Patch AndroidManifest permissions safely"
python3 <<'PY'
from pathlib import Path

manifest = Path("android/app/src/main/AndroidManifest.xml")
text = manifest.read_text()

permissions = [
    'android.permission.BLUETOOTH',
    'android.permission.BLUETOOTH_ADMIN',
    'android.permission.BLUETOOTH_SCAN',
    'android.permission.BLUETOOTH_CONNECT',
    'android.permission.BLUETOOTH_ADVERTISE',
    'android.permission.ACCESS_FINE_LOCATION',
    'android.permission.ACCESS_COARSE_LOCATION',
]

insert = []
for p in permissions:
    if p not in text:
        insert.append(f'    <uses-permission android:name="{p}" />')

if insert:
    text = text.replace("<manifest", "<manifest", 1)
    app_index = text.find("<application")
    if app_index == -1:
        raise SystemExit("ERROR: <application not found in AndroidManifest.xml")
    text = text[:app_index] + "\n".join(insert) + "\n" + text[app_index:]
    manifest.write_text(text)
    print("Manifest permissions added:", len(insert))
else:
    print("Manifest permissions already present")
PY

echo ""
echo "2. Replace MauriMeshBleModule.kt with getStatus + scan proof methods"

cat > "$MODULE" <<'KT'
package com.maurimesh.messenger

import android.Manifest
import android.bluetooth.BluetoothManager
import android.bluetooth.le.BluetoothLeScanner
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod

class MauriMeshBleModule(
  private val reactContext: ReactApplicationContext
) : ReactContextBaseJavaModule(reactContext) {

  private var scanner: BluetoothLeScanner? = null
  private var scanCallback: ScanCallback? = null
  private var scanActive: Boolean = false
  private var discoveredCount: Int = 0
  private var scanStartTimeMs: Double = 0.0
  private var lastError: String = ""
  private var lastDeviceName: String = ""
  private var lastDeviceAddress: String = ""

  override fun getName(): String {
    return "MauriMeshBle"
  }

  private fun hasPermission(permission: String): Boolean {
    return reactContext.checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED
  }

  private fun hasBleRuntimePermissions(): Boolean {
    return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
      hasPermission(Manifest.permission.BLUETOOTH_SCAN) &&
        hasPermission(Manifest.permission.BLUETOOTH_CONNECT)
    } else {
      hasPermission(Manifest.permission.ACCESS_FINE_LOCATION)
    }
  }

  private fun baseStatusMap() = Arguments.createMap().apply {
    putString("module", "MauriMeshBle")
    putBoolean("modulePresent", true)
    putBoolean("liveBleActive", scanActive)
    putBoolean("scanActive", scanActive)
    putInt("discoveredCount", discoveredCount)
    putDouble("scanStartTimeMs", scanStartTimeMs)
    putString("lastError", lastError)
    putString("lastDeviceName", lastDeviceName)
    putString("lastDeviceAddress", lastDeviceAddress)
    putString("truth", "Native module is registered. Scan proof methods only scan and stop scan. They do not advertise, connect, send, receive, ACK, or relay.")
  }

  @ReactMethod
  fun getStatus(promise: Promise) {
    try {
      val status = baseStatusMap()
      status.putString("mode", "read_only")
      status.putBoolean("blePermissions", hasBleRuntimePermissions())
      promise.resolve(status)
    } catch (error: Exception) {
      promise.reject("MAURIMESH_BLE_STATUS_ERROR", error)
    }
  }

  @ReactMethod
  fun getScanProofStatus(promise: Promise) {
    try {
      val status = baseStatusMap()
      status.putString("mode", "scan_proof_status")
      status.putBoolean("blePermissions", hasBleRuntimePermissions())
      promise.resolve(status)
    } catch (error: Exception) {
      promise.reject("MAURIMESH_BLE_SCAN_STATUS_ERROR", error)
    }
  }

  @ReactMethod
  fun startScanProof(promise: Promise) {
    try {
      lastError = ""

      if (!hasBleRuntimePermissions()) {
        lastError = "Missing Android BLE runtime permissions."
        val status = baseStatusMap()
        status.putString("mode", "scan_proof_permission_denied")
        status.putBoolean("started", false)
        promise.resolve(status)
        return
      }

      if (scanActive) {
        val status = baseStatusMap()
        status.putString("mode", "scan_proof_already_active")
        status.putBoolean("started", true)
        promise.resolve(status)
        return
      }

      val bluetoothManager =
        reactContext.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager

      val adapter = bluetoothManager?.adapter

      if (adapter == null) {
        lastError = "Bluetooth adapter unavailable."
        val status = baseStatusMap()
        status.putString("mode", "scan_proof_no_adapter")
        status.putBoolean("started", false)
        promise.resolve(status)
        return
      }

      if (!adapter.isEnabled) {
        lastError = "Bluetooth adapter disabled."
        val status = baseStatusMap()
        status.putString("mode", "scan_proof_adapter_disabled")
        status.putBoolean("started", false)
        promise.resolve(status)
        return
      }

      scanner = adapter.bluetoothLeScanner

      if (scanner == null) {
        lastError = "BluetoothLeScanner unavailable."
        val status = baseStatusMap()
        status.putString("mode", "scan_proof_no_scanner")
        status.putBoolean("started", false)
        promise.resolve(status)
        return
      }

      discoveredCount = 0
      lastDeviceName = ""
      lastDeviceAddress = ""
      scanStartTimeMs = System.currentTimeMillis().toDouble()

      scanCallback = object : ScanCallback() {
        override fun onScanResult(callbackType: Int, result: ScanResult) {
          discoveredCount += 1
          lastDeviceName = result.device?.name ?: "unknown"
          lastDeviceAddress = result.device?.address ?: "unknown"
        }

        override fun onBatchScanResults(results: MutableList<ScanResult>) {
          discoveredCount += results.size
          val last = results.lastOrNull()
          if (last != null) {
            lastDeviceName = last.device?.name ?: "unknown"
            lastDeviceAddress = last.device?.address ?: "unknown"
          }
        }

        override fun onScanFailed(errorCode: Int) {
          lastError = "Scan failed with errorCode=$errorCode"
          scanActive = false
        }
      }

      val settings = ScanSettings.Builder()
        .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
        .build()

      scanner?.startScan(null, settings, scanCallback)
      scanActive = true

      val status = baseStatusMap()
      status.putString("mode", "scan_proof_started")
      status.putBoolean("started", true)
      promise.resolve(status)
    } catch (error: Exception) {
      lastError = error.message ?: error.toString()
      scanActive = false
      promise.reject("MAURIMESH_BLE_SCAN_START_ERROR", error)
    }
  }

  @ReactMethod
  fun stopScanProof(promise: Promise) {
    try {
      val cb = scanCallback
      if (cb != null) {
        try {
          scanner?.stopScan(cb)
        } catch (error: Exception) {
          lastError = error.message ?: error.toString()
        }
      }

      scanCallback = null
      scanActive = false

      val status = baseStatusMap()
      status.putString("mode", "scan_proof_stopped")
      status.putBoolean("stopped", true)
      promise.resolve(status)
    } catch (error: Exception) {
      lastError = error.message ?: error.toString()
      scanActive = false
      promise.reject("MAURIMESH_BLE_SCAN_STOP_ERROR", error)
    }
  }
}
KT

echo ""
echo "3. Create Native BLE Scan Proof UI screen"

cat > "$SCAN_SCREEN" <<'TSX'
import React, { useEffect, useState } from "react";
import {
  NativeModules,
  PermissionsAndroid,
  Platform,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from "react-native";

const MARKER = "NATIVE_BLE_SCAN_PROOF_20260607_A";

type ScanStatus = {
  module?: string;
  mode?: string;
  modulePresent?: boolean;
  liveBleActive?: boolean;
  scanActive?: boolean;
  discoveredCount?: number;
  lastError?: string;
  lastDeviceName?: string;
  lastDeviceAddress?: string;
  truth?: string;
};

type PermissionState = {
  scan: string;
  connect: string;
  location: string;
};

const emptyStatus: ScanStatus = {
  module: "MauriMeshBle",
  mode: "not_started",
  modulePresent: false,
  liveBleActive: false,
  scanActive: false,
  discoveredCount: 0,
  truth: "Scan proof not started.",
};

async function checkPermissions(): Promise<PermissionState> {
  if (Platform.OS !== "android") {
    return { scan: "not_android", connect: "not_android", location: "not_android" };
  }

  const scan = await PermissionsAndroid.check(
    PermissionsAndroid.PERMISSIONS.BLUETOOTH_SCAN as any
  );

  const connect = await PermissionsAndroid.check(
    PermissionsAndroid.PERMISSIONS.BLUETOOTH_CONNECT as any
  );

  const location = await PermissionsAndroid.check(
    PermissionsAndroid.PERMISSIONS.ACCESS_FINE_LOCATION
  );

  return {
    scan: scan ? "granted" : "denied",
    connect: connect ? "granted" : "denied",
    location: location ? "granted" : "denied",
  };
}

async function callNative(method: string): Promise<ScanStatus> {
  const mod = NativeModules.MauriMeshBle;

  if (!mod) {
    return {
      ...emptyStatus,
      mode: "missing_module",
      modulePresent: false,
      lastError: "NativeModules.MauriMeshBle not found.",
    };
  }

  if (typeof mod[method] !== "function") {
    return {
      ...emptyStatus,
      mode: "missing_method",
      modulePresent: true,
      lastError: `MauriMeshBle.${method}() not found in this APK.`,
    };
  }

  const result = await mod[method]();

  return {
    module: String(result?.module ?? "MauriMeshBle"),
    mode: String(result?.mode ?? method),
    modulePresent: Boolean(result?.modulePresent),
    liveBleActive: Boolean(result?.liveBleActive),
    scanActive: Boolean(result?.scanActive),
    discoveredCount: Number(result?.discoveredCount ?? 0),
    lastError: String(result?.lastError ?? ""),
    lastDeviceName: String(result?.lastDeviceName ?? ""),
    lastDeviceAddress: String(result?.lastDeviceAddress ?? ""),
    truth: String(result?.truth ?? ""),
  };
}

function Card({
  title,
  children,
  warning,
}: {
  title: string;
  children: React.ReactNode;
  warning?: boolean;
}) {
  return (
    <View style={[styles.card, warning && styles.warningCard]}>
      <Text style={styles.cardTitle}>{title}</Text>
      {children}
    </View>
  );
}

export default function NativeBleScanProofScreen() {
  const [permissions, setPermissions] = useState<PermissionState>({
    scan: "checking",
    connect: "checking",
    location: "checking",
  });

  const [status, setStatus] = useState<ScanStatus>(emptyStatus);
  const [busy, setBusy] = useState(false);

  async function refresh() {
    const [perm, native] = await Promise.all([
      checkPermissions(),
      callNative("getScanProofStatus"),
    ]);
    setPermissions(perm);
    setStatus(native);
  }

  async function startScan() {
    setBusy(true);
    try {
      const native = await callNative("startScanProof");
      setStatus(native);
      setPermissions(await checkPermissions());
    } finally {
      setBusy(false);
    }
  }

  async function stopScan() {
    setBusy(true);
    try {
      const native = await callNative("stopScanProof");
      setStatus(native);
      setPermissions(await checkPermissions());
    } finally {
      setBusy(false);
    }
  }

  useEffect(() => {
    refresh();
    const timer = setInterval(refresh, 2000);
    return () => clearInterval(timer);
  }, []);

  const scanActive = status.scanActive === true;

  return (
    <ScrollView style={styles.page} contentContainerStyle={styles.content}>
      <Text style={styles.brand}>MauriMesh</Text>
      <Text style={styles.title}>Native BLE Scan Proof</Text>
      <Text style={styles.marker}>{MARKER}</Text>

      <Card title="Truth Boundary" warning>
        <Text style={styles.body}>
          Controlled scan proof only. This screen may start and stop BLE scanning.
          It does not advertise, connect, send, receive, ACK, relay, or claim mesh delivery.
        </Text>
      </Card>

      <Card title="Native Module">
        <Text style={status.modulePresent ? styles.good : styles.bad}>
          {status.modulePresent ? "PRESENT" : "NOT CONFIRMED"}
        </Text>
        <Text style={styles.body}>Module name: {status.module}</Text>
      </Card>

      <Card title="Scan State">
        <Text style={scanActive ? styles.good : styles.bad}>
          {scanActive ? "SCAN ACTIVE" : "SCAN STOPPED"}
        </Text>
        <Text style={styles.body}>Mode: {status.mode}</Text>
        <Text style={styles.body}>
          Discovered count: {String(status.discoveredCount ?? 0)}
        </Text>
        <Text style={styles.body}>
          Last device name: {status.lastDeviceName || "none"}
        </Text>
        <Text style={styles.body}>
          Last device address: {status.lastDeviceAddress || "none"}
        </Text>
        {status.lastError ? <Text style={styles.error}>{status.lastError}</Text> : null}
      </Card>

      <Card title="Android Permissions">
        <Text style={styles.body}>BLUETOOTH_SCAN: {permissions.scan}</Text>
        <Text style={styles.body}>BLUETOOTH_CONNECT: {permissions.connect}</Text>
        <Text style={styles.body}>ACCESS_FINE_LOCATION: {permissions.location}</Text>
      </Card>

      <TouchableOpacity
        disabled={busy}
        style={[styles.button, scanActive && styles.stopButton]}
        onPress={scanActive ? stopScan : startScan}
      >
        <Text style={styles.buttonText}>
          {busy ? "Working..." : scanActive ? "Stop Scan Proof" : "Start Scan Proof"}
        </Text>
      </TouchableOpacity>

      <TouchableOpacity disabled={busy} style={styles.secondaryButton} onPress={refresh}>
        <Text style={styles.secondaryButtonText}>Refresh Status</Text>
      </TouchableOpacity>

      <Card title="Native Truth">
        <Text style={styles.body}>{status.truth}</Text>
      </Card>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  page: { flex: 1, backgroundColor: "#050816" },
  content: { padding: 24, paddingTop: 56, paddingBottom: 80 },
  brand: {
    color: "#00D084",
    fontSize: 42,
    fontWeight: "900",
    marginBottom: 24,
  },
  title: {
    color: "#FFFFFF",
    fontSize: 30,
    fontWeight: "900",
    marginBottom: 12,
  },
  marker: {
    color: "#4FC3F7",
    fontSize: 14,
    fontWeight: "900",
    letterSpacing: 1.5,
    marginBottom: 28,
  },
  card: {
    borderWidth: 1,
    borderColor: "rgba(0, 208, 132, 0.28)",
    borderRadius: 20,
    padding: 22,
    marginBottom: 18,
    backgroundColor: "rgba(255,255,255,0.035)",
  },
  warningCard: {
    borderColor: "rgba(245, 158, 11, 0.55)",
    backgroundColor: "rgba(245, 158, 11, 0.055)",
  },
  cardTitle: {
    color: "#FFFFFF",
    fontSize: 22,
    fontWeight: "900",
    marginBottom: 16,
  },
  body: {
    color: "rgba(255,255,255,0.74)",
    fontSize: 17,
    lineHeight: 27,
    marginBottom: 6,
  },
  good: {
    color: "#00D084",
    fontSize: 30,
    fontWeight: "900",
    letterSpacing: 1.5,
    marginBottom: 12,
  },
  bad: {
    color: "#FF4D5E",
    fontSize: 30,
    fontWeight: "900",
    letterSpacing: 1.5,
    marginBottom: 12,
  },
  error: {
    color: "#F59E0B",
    fontSize: 16,
    lineHeight: 24,
    marginTop: 8,
  },
  button: {
    backgroundColor: "#00D084",
    borderRadius: 18,
    padding: 20,
    alignItems: "center",
    marginBottom: 14,
  },
  stopButton: {
    backgroundColor: "#FF4D5E",
  },
  buttonText: {
    color: "#03120C",
    fontSize: 18,
    fontWeight: "900",
  },
  secondaryButton: {
    borderWidth: 1,
    borderColor: "rgba(0, 208, 132, 0.5)",
    borderRadius: 18,
    padding: 18,
    alignItems: "center",
    marginBottom: 20,
  },
  secondaryButtonText: {
    color: "#00D084",
    fontSize: 17,
    fontWeight: "900",
  },
});
TSX

echo ""
echo "4. Rebuild dashboard with scan proof button"

cat > "$DASH" <<'TSX'
import React from "react";
import { useRouter } from "expo-router";
import {
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from "react-native";

const MARKER = "SAFE_DASHBOARD_SCAN_PROOF_BUTTONS_20260607_A";

const routes = [
  ["Settings", "/settings"],
  ["Chat", "/chat"],
  ["Living Mesh", "/living-mesh"],
  ["Mesh Status", "/mesh-status"],
  ["Add Friend", "/add-friend"],
  ["Pixel Calling", "/pixel-calling"],
  ["BLE Proof UI", "/ble-proof"],
  ["Proof Ledger", "/proof-ledger"],
  ["Native BLE Audit", "/native-ble-audit"],
  ["Native BLE Status", "/native-ble-status"],
  ["Native BLE Scan Proof", "/native-ble-scan-proof"],
] as const;

export default function Dashboard() {
  const router = useRouter();

  return (
    <ScrollView style={styles.page} contentContainerStyle={styles.content}>
      <Text style={styles.brand}>MauriMesh</Text>
      <Text style={styles.title}>Dashboard</Text>
      <Text style={styles.marker}>{MARKER}</Text>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>System Status</Text>
        <Text style={styles.body}>APK shell: PASS</Text>
        <Text style={styles.body}>Package: com.maurimesh.messenger</Text>
        <Text style={styles.body}>Router: safe Stack only</Text>
        <Text style={styles.body}>Native bridge: PRESENT</Text>
        <Text style={styles.body}>BLE scan proof: isolated test only</Text>
      </View>

      {routes.map(([label, route]) => (
        <TouchableOpacity
          key={route}
          style={styles.button}
          onPress={() => router.push(route as any)}
        >
          <Text style={styles.buttonText}>{label}</Text>
        </TouchableOpacity>
      ))}

      <TouchableOpacity style={styles.homeButton} onPress={() => router.push("/")}>
        <Text style={styles.homeButtonText}>Back Home</Text>
      </TouchableOpacity>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  page: {
    flex: 1,
    backgroundColor: "#050816",
  },
  content: {
    padding: 24,
    paddingTop: 56,
    paddingBottom: 80,
  },
  brand: {
    color: "#00D084",
    fontSize: 42,
    fontWeight: "900",
    marginBottom: 24,
  },
  title: {
    color: "#FFFFFF",
    fontSize: 30,
    fontWeight: "900",
    marginBottom: 10,
  },
  marker: {
    color: "#4FC3F7",
    fontSize: 14,
    fontWeight: "900",
    letterSpacing: 1.2,
    marginBottom: 26,
  },
  card: {
    borderWidth: 1,
    borderColor: "rgba(0, 208, 132, 0.28)",
    borderRadius: 20,
    padding: 22,
    marginBottom: 20,
    backgroundColor: "rgba(255,255,255,0.035)",
  },
  cardTitle: {
    color: "#FFFFFF",
    fontSize: 21,
    fontWeight: "900",
    marginBottom: 14,
  },
  body: {
    color: "rgba(255,255,255,0.76)",
    fontSize: 17,
    lineHeight: 26,
  },
  button: {
    backgroundColor: "rgba(0, 208, 132, 0.12)",
    borderWidth: 1,
    borderColor: "rgba(0, 208, 132, 0.32)",
    borderRadius: 18,
    padding: 20,
    marginBottom: 14,
  },
  buttonText: {
    color: "#FFFFFF",
    fontSize: 18,
    fontWeight: "900",
  },
  homeButton: {
    backgroundColor: "#00D084",
    borderRadius: 18,
    padding: 20,
    marginTop: 18,
    alignItems: "center",
  },
  homeButtonText: {
    color: "#03120C",
    fontSize: 18,
    fontWeight: "900",
  },
});
TSX

echo ""
echo "5. Validate source markers"
grep -Rni "NATIVE_BLE_SCAN_PROOF_20260607_A" app/native-ble-scan-proof.tsx
grep -Rni "SAFE_DASHBOARD_SCAN_PROOF_BUTTONS_20260607_A" app/dashboard.tsx
grep -RniE "startScanProof|stopScanProof|getScanProofStatus" "$MODULE" app/native-ble-scan-proof.tsx

echo ""
echo "6. Validate package JSON"
node -e "JSON.parse(require('fs').readFileSync('package.json','utf8')); console.log('package.json OK')"
node -e "JSON.parse(require('fs').readFileSync('eas.json','utf8')); console.log('eas.json OK')"

echo ""
echo "7. TypeScript"
npx tsc --noEmit

echo ""
echo "8. Export"
rm -rf dist .expo
npx expo export --platform android --clear

echo ""
echo "=================================================="
echo "NATIVE BLE SCAN PROOF READY — NO EAS USED"
echo "Backup: $BACKUP"
echo "Next APK expected marker: NATIVE_BLE_SCAN_PROOF_20260607_A"
echo "=================================================="
