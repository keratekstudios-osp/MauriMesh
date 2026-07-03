#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "INSTALL MAURIMESH NATIVE HARDWARE BLE PROOF"
echo "Adds real Android BluetoothLeScanner foreground service,"
echo "JS native bridge, permissions, route, and proof screen."
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$ROOT/backup-before-native-hardware-ble-$STAMP"

ANDROID="$ROOT/android"
APP_MAIN="$ANDROID/app/src/main"
MANIFEST="$APP_MAIN/AndroidManifest.xml"

PKG_DIR="$APP_MAIN/java/com/maurimesh/messenger/maurimesh/blehardware"
MAIN_APP="$APP_MAIN/java/com/maurimesh/messenger/MainApplication.kt"

mkdir -p "$BACKUP" "$PKG_DIR" "$ROOT/app" "$ROOT/src/components" "$ROOT/src/native" "$ROOT/docs"

if [ ! -f "$ROOT/package.json" ]; then
  echo "ERROR: package.json not found. Run from /home/runner/workspace"
  exit 1
fi

if [ ! -d "$ANDROID" ]; then
  echo "ERROR: android folder not found."
  echo "Run: npx expo prebuild --platform android"
  exit 1
fi

backup_file() {
  local file="$1"
  if [ -f "$file" ]; then
    local rel="${file#$ROOT/}"
    mkdir -p "$BACKUP/$(dirname "$rel")"
    cp "$file" "$BACKUP/$rel"
  fi
}

backup_file "$MANIFEST"
backup_file "$MAIN_APP"
backup_file "$ROOT/app/dashboard.tsx"
backup_file "$ROOT/src/lib/uiBackupRoutes.ts"
backup_file "$ROOT/src/maurimesh/test-layer/MauriMeshFullTestEngine.ts"

# ============================================================
# 1. KOTLIN NATIVE MODULE
# ============================================================

cat > "$PKG_DIR/MauriMeshHardwareBleModule.kt" <<'KT'
package com.maurimesh.messenger.maurimesh.blehardware

import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import android.util.Log
import androidx.core.content.ContextCompat
import com.facebook.react.bridge.*

class MauriMeshHardwareBleModule(
  private val reactContext: ReactApplicationContext
) : ReactContextBaseJavaModule(reactContext) {

  override fun getName(): String = "MauriMeshHardwareBle"

  private fun hasPermission(permission: String): Boolean {
    return ContextCompat.checkSelfPermission(
      reactContext,
      permission
    ) == PackageManager.PERMISSION_GRANTED
  }

  private fun bluetoothAdapter(): BluetoothAdapter? {
    val manager = reactContext.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
    return manager?.adapter
  }

  @ReactMethod
  fun getStatus(promise: Promise) {
    try {
      val adapter = bluetoothAdapter()
      val map = Arguments.createMap()

      map.putString("module", "MauriMeshHardwareBle")
      map.putBoolean("nativeModule", true)
      map.putBoolean("bluetoothAdapterPresent", adapter != null)
      map.putBoolean("bluetoothEnabled", adapter?.isEnabled == true)
      map.putBoolean("scanPermission", if (Build.VERSION.SDK_INT >= 31) hasPermission(Manifest.permission.BLUETOOTH_SCAN) else true)
      map.putBoolean("connectPermission", if (Build.VERSION.SDK_INT >= 31) hasPermission(Manifest.permission.BLUETOOTH_CONNECT) else true)
      map.putBoolean("fineLocationPermission", hasPermission(Manifest.permission.ACCESS_FINE_LOCATION))
      map.putBoolean("postNotificationsPermission", if (Build.VERSION.SDK_INT >= 33) hasPermission(Manifest.permission.POST_NOTIFICATIONS) else true)
      map.putBoolean("serviceRunning", MauriMeshHardwareBleScanService.isRunning)
      map.putInt("discoveredCount", MauriMeshHardwareBleScanService.discoveredCount)
      map.putString("lastDeviceName", MauriMeshHardwareBleScanService.lastDeviceName ?: "")
      map.putString("lastDeviceAddress", MauriMeshHardwareBleScanService.lastDeviceAddress ?: "")
      map.putInt("lastRssi", MauriMeshHardwareBleScanService.lastRssi)
      map.putString("truth", "NATIVE_ANDROID_HARDWARE_BLE_STATUS")
      map.putString("proofMarker", "MAURIMESH_NATIVE_HARDWARE_BLE_STATUS_OK")

      Log.i("MauriMeshHardwareBle", "MAURIMESH_NATIVE_HARDWARE_BLE_STATUS_OK serviceRunning=${MauriMeshHardwareBleScanService.isRunning} discovered=${MauriMeshHardwareBleScanService.discoveredCount}")

      promise.resolve(map)
    } catch (e: Exception) {
      Log.e("MauriMeshHardwareBle", "MAURIMESH_NATIVE_HARDWARE_BLE_STATUS_ERROR ${e.message}", e)
      promise.reject("MAURIMESH_NATIVE_HARDWARE_BLE_STATUS_ERROR", e)
    }
  }

  @ReactMethod
  fun startScan(promise: Promise) {
    try {
      val adapter = bluetoothAdapter()

      if (adapter == null) {
        promise.reject("NO_BLUETOOTH_ADAPTER", "Bluetooth adapter not found")
        return
      }

      if (!adapter.isEnabled) {
        promise.reject("BLUETOOTH_DISABLED", "Bluetooth is disabled")
        return
      }

      if (Build.VERSION.SDK_INT >= 31 && !hasPermission(Manifest.permission.BLUETOOTH_SCAN)) {
        promise.reject("MISSING_BLUETOOTH_SCAN_PERMISSION", "BLUETOOTH_SCAN permission missing")
        return
      }

      if (Build.VERSION.SDK_INT >= 31 && !hasPermission(Manifest.permission.BLUETOOTH_CONNECT)) {
        promise.reject("MISSING_BLUETOOTH_CONNECT_PERMISSION", "BLUETOOTH_CONNECT permission missing")
        return
      }

      val intent = Intent(reactContext, MauriMeshHardwareBleScanService::class.java)
      intent.action = MauriMeshHardwareBleScanService.ACTION_START

      if (Build.VERSION.SDK_INT >= 26) {
        reactContext.startForegroundService(intent)
      } else {
        reactContext.startService(intent)
      }

      Log.i("MauriMeshHardwareBle", "MAURIMESH_NATIVE_HARDWARE_BLE_START_REQUESTED")

      val map = Arguments.createMap()
      map.putBoolean("started", true)
      map.putString("proofMarker", "MAURIMESH_NATIVE_HARDWARE_BLE_START_REQUESTED")
      map.putString("truth", "Foreground service requested. Android scan history should show MauriMesh after real screen-off scanning.")
      promise.resolve(map)
    } catch (e: Exception) {
      Log.e("MauriMeshHardwareBle", "MAURIMESH_NATIVE_HARDWARE_BLE_START_ERROR ${e.message}", e)
      promise.reject("MAURIMESH_NATIVE_HARDWARE_BLE_START_ERROR", e)
    }
  }

  @ReactMethod
  fun stopScan(promise: Promise) {
    try {
      val intent = Intent(reactContext, MauriMeshHardwareBleScanService::class.java)
      intent.action = MauriMeshHardwareBleScanService.ACTION_STOP
      reactContext.startService(intent)

      Log.i("MauriMeshHardwareBle", "MAURIMESH_NATIVE_HARDWARE_BLE_STOP_REQUESTED")

      val map = Arguments.createMap()
      map.putBoolean("stopped", true)
      map.putString("proofMarker", "MAURIMESH_NATIVE_HARDWARE_BLE_STOP_REQUESTED")
      promise.resolve(map)
    } catch (e: Exception) {
      Log.e("MauriMeshHardwareBle", "MAURIMESH_NATIVE_HARDWARE_BLE_STOP_ERROR ${e.message}", e)
      promise.reject("MAURIMESH_NATIVE_HARDWARE_BLE_STOP_ERROR", e)
    }
  }

  @ReactMethod
  fun openBluetoothSettings(promise: Promise) {
    try {
      val intent = Intent(Settings.ACTION_BLUETOOTH_SETTINGS)
      intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
      reactContext.startActivity(intent)
      promise.resolve(true)
    } catch (e: Exception) {
      promise.reject("OPEN_BLUETOOTH_SETTINGS_FAILED", e)
    }
  }
}
KT

# ============================================================
# 2. REACT PACKAGE
# ============================================================

cat > "$PKG_DIR/MauriMeshHardwareBlePackage.kt" <<'KT'
package com.maurimesh.messenger.maurimesh.blehardware

import com.facebook.react.ReactPackage
import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.uimanager.ViewManager

class MauriMeshHardwareBlePackage : ReactPackage {
  override fun createNativeModules(reactContext: ReactApplicationContext): List<NativeModule> {
    return listOf(MauriMeshHardwareBleModule(reactContext))
  }

  override fun createViewManagers(reactContext: ReactApplicationContext): List<ViewManager<*, *>> {
    return emptyList()
  }
}
KT

# ============================================================
# 3. FOREGROUND BLE SCAN SERVICE
# ============================================================

cat > "$PKG_DIR/MauriMeshHardwareBleScanService.kt" <<'KT'
package com.maurimesh.messenger.maurimesh.blehardware

import android.Manifest
import android.app.*
import android.bluetooth.BluetoothManager
import android.bluetooth.le.*
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat

class MauriMeshHardwareBleScanService : Service() {

  companion object {
    const val ACTION_START = "com.maurimesh.messenger.MAURIMESH_HARDWARE_BLE_START"
    const val ACTION_STOP = "com.maurimesh.messenger.MAURIMESH_HARDWARE_BLE_STOP"
    const val CHANNEL_ID = "maurimesh_ble_hardware_scan"
    const val NOTIFICATION_ID = 7001

    @Volatile var isRunning: Boolean = false
    @Volatile var discoveredCount: Int = 0
    @Volatile var lastDeviceName: String? = null
    @Volatile var lastDeviceAddress: String? = null
    @Volatile var lastRssi: Int = 0
  }

  private var scanner: BluetoothLeScanner? = null

  private val callback = object : ScanCallback() {
    override fun onScanResult(callbackType: Int, result: ScanResult) {
      discoveredCount += 1
      lastRssi = result.rssi

      try {
        if (Build.VERSION.SDK_INT < 31 || hasPermission(Manifest.permission.BLUETOOTH_CONNECT)) {
          lastDeviceName = result.device?.name ?: "unknown"
          lastDeviceAddress = result.device?.address ?: "unknown"
        } else {
          lastDeviceName = "permission_required"
          lastDeviceAddress = "permission_required"
        }
      } catch (_: SecurityException) {
        lastDeviceName = "security_exception"
        lastDeviceAddress = "security_exception"
      }

      Log.i(
        "MauriMeshHardwareBle",
        "MAURIMESH_NATIVE_BLE_SCAN_RESULT count=$discoveredCount rssi=$lastRssi name=$lastDeviceName address=$lastDeviceAddress"
      )
    }

    override fun onBatchScanResults(results: MutableList<ScanResult>) {
      Log.i("MauriMeshHardwareBle", "MAURIMESH_NATIVE_BLE_BATCH_RESULTS size=${results.size}")
      results.forEach { onScanResult(ScanSettings.CALLBACK_TYPE_ALL_MATCHES, it) }
    }

    override fun onScanFailed(errorCode: Int) {
      Log.e("MauriMeshHardwareBle", "MAURIMESH_NATIVE_BLE_SCAN_FAILED errorCode=$errorCode")
    }
  }

  override fun onCreate() {
    super.onCreate()
    createNotificationChannel()
    Log.i("MauriMeshHardwareBle", "MAURIMESH_NATIVE_BLE_SERVICE_CREATED")
  }

  override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
    when (intent?.action) {
      ACTION_STOP -> {
        stopBleScan()
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
        return START_NOT_STICKY
      }
      else -> {
        startForeground(NOTIFICATION_ID, buildNotification("MauriMesh BLE hardware scan running"))
        startBleScan()
        return START_STICKY
      }
    }
  }

  override fun onBind(intent: Intent?): IBinder? = null

  override fun onDestroy() {
    stopBleScan()
    Log.i("MauriMeshHardwareBle", "MAURIMESH_NATIVE_BLE_SERVICE_DESTROYED")
    super.onDestroy()
  }

  private fun startBleScan() {
    try {
      if (isRunning) {
        Log.i("MauriMeshHardwareBle", "MAURIMESH_NATIVE_BLE_SCAN_ALREADY_RUNNING")
        return
      }

      if (Build.VERSION.SDK_INT >= 31 && !hasPermission(Manifest.permission.BLUETOOTH_SCAN)) {
        Log.e("MauriMeshHardwareBle", "MAURIMESH_NATIVE_BLE_SCAN_BLOCKED_MISSING_BLUETOOTH_SCAN")
        return
      }

      val manager = getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
      val adapter = manager?.adapter

      if (adapter == null || !adapter.isEnabled) {
        Log.e("MauriMeshHardwareBle", "MAURIMESH_NATIVE_BLE_SCAN_BLOCKED_ADAPTER_OFF_OR_MISSING")
        return
      }

      scanner = adapter.bluetoothLeScanner

      val settings = ScanSettings.Builder()
        .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
        .setReportDelay(0)
        .build()

      scanner?.startScan(null, settings, callback)
      isRunning = true

      Log.i("MauriMeshHardwareBle", "MAURIMESH_NATIVE_BLE_SCAN_STARTED")
    } catch (se: SecurityException) {
      Log.e("MauriMeshHardwareBle", "MAURIMESH_NATIVE_BLE_SCAN_SECURITY_EXCEPTION ${se.message}", se)
    } catch (e: Exception) {
      Log.e("MauriMeshHardwareBle", "MAURIMESH_NATIVE_BLE_SCAN_START_ERROR ${e.message}", e)
    }
  }

  private fun stopBleScan() {
    try {
      if (scanner != null) {
        if (Build.VERSION.SDK_INT < 31 || hasPermission(Manifest.permission.BLUETOOTH_SCAN)) {
          scanner?.stopScan(callback)
        }
      }
    } catch (e: Exception) {
      Log.e("MauriMeshHardwareBle", "MAURIMESH_NATIVE_BLE_SCAN_STOP_ERROR ${e.message}", e)
    } finally {
      isRunning = false
      scanner = null
      Log.i("MauriMeshHardwareBle", "MAURIMESH_NATIVE_BLE_SCAN_STOPPED")
    }
  }

  private fun hasPermission(permission: String): Boolean {
    return ContextCompat.checkSelfPermission(this, permission) == PackageManager.PERMISSION_GRANTED
  }

  private fun createNotificationChannel() {
    if (Build.VERSION.SDK_INT >= 26) {
      val channel = NotificationChannel(
        CHANNEL_ID,
        "MauriMesh BLE Hardware Scan",
        NotificationManager.IMPORTANCE_LOW
      )
      channel.description = "MauriMesh foreground Bluetooth hardware scan proof"
      val manager = getSystemService(NotificationManager::class.java)
      manager.createNotificationChannel(channel)
    }
  }

  private fun buildNotification(text: String): Notification {
    val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
    val pendingIntent = PendingIntent.getActivity(
      this,
      0,
      launchIntent,
      PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
    )

    return NotificationCompat.Builder(this, CHANNEL_ID)
      .setContentTitle("MauriMesh hardware BLE proof")
      .setContentText(text)
      .setSmallIcon(android.R.drawable.stat_sys_data_bluetooth)
      .setOngoing(true)
      .setContentIntent(pendingIntent)
      .build()
  }
}
KT

# ============================================================
# 4. PATCH MAINAPPLICATION.KT
# ============================================================

if [ ! -f "$MAIN_APP" ]; then
  echo "ERROR: MainApplication.kt not found at:"
  echo "$MAIN_APP"
  exit 1
fi

python3 <<'PY'
from pathlib import Path
import re

p = Path("android/app/src/main/java/com/maurimesh/messenger/MainApplication.kt")
src = p.read_text()

import_line = "import com.maurimesh.messenger.maurimesh.blehardware.MauriMeshHardwareBlePackage\n"

if "MauriMeshHardwareBlePackage" not in src:
    # insert after package/import area
    lines = src.splitlines()
    insert_at = 0
    for i, line in enumerate(lines):
        if line.startswith("import "):
            insert_at = i + 1
    lines.insert(insert_at, import_line.rstrip())
    src = "\n".join(lines) + "\n"

# If package is imported but not added, patch common PackageList patterns.
if "MauriMeshHardwareBlePackage()" not in src:
    # Pattern: val packages = PackageList(this).packages
    src = re.sub(
        r"(val\s+packages\s*=\s*PackageList\(this\)\.packages)",
        r"\1\n          packages.add(MauriMeshHardwareBlePackage())",
        src,
        count=1,
    )

if "MauriMeshHardwareBlePackage()" not in src:
    # Pattern: return PackageList(this).packages
    src = re.sub(
        r"return\s+PackageList\(this\)\.packages",
        "return PackageList(this).packages.apply {\n          add(MauriMeshHardwareBlePackage())\n        }",
        src,
        count=1,
    )

if "MauriMeshHardwareBlePackage()" not in src:
    # Pattern: PackageList(this).packages.apply { ... }
    src = re.sub(
        r"(PackageList\(this\)\.packages\.apply\s*\{)",
        r"\1\n          add(MauriMeshHardwareBlePackage())",
        src,
        count=1,
    )

if "MauriMeshHardwareBlePackage()" not in src:
    # Last fallback: inject comment marker, fail later with clear message.
    src += "\n// MAURIMESH_HARDWARE_BLE_PACKAGE_NOT_AUTO_INSERTED\n"

p.write_text(src)
PY

if grep -q "MAURIMESH_HARDWARE_BLE_PACKAGE_NOT_AUTO_INSERTED" "$MAIN_APP"; then
  echo ""
  echo "ERROR: Could not auto-insert MauriMeshHardwareBlePackage into MainApplication.kt"
  echo "Open MainApplication.kt and add:"
  echo "  import com.maurimesh.messenger.maurimesh.blehardware.MauriMeshHardwareBlePackage"
  echo "and inside getPackages():"
  echo "  packages.add(MauriMeshHardwareBlePackage())"
  exit 1
fi

# ============================================================
# 5. PATCH ANDROID MANIFEST
# ============================================================

if [ ! -f "$MANIFEST" ]; then
  echo "ERROR: AndroidManifest.xml not found"
  exit 1
fi

python3 <<'PY'
from pathlib import Path

p = Path("android/app/src/main/AndroidManifest.xml")
src = p.read_text()

permissions = [
    '<uses-permission android:name="android.permission.BLUETOOTH" />',
    '<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />',
    '<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />',
    '<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />',
    '<uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE" />',
    '<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />',
    '<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />',
    '<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />',
    '<uses-permission android:name="android.permission.FOREGROUND_SERVICE_CONNECTED_DEVICE" />',
    '<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />',
]

insert = ""
for perm in permissions:
    name = perm.split('android:name="', 1)[1].split('"', 1)[0]
    if name not in src:
        insert += "    " + perm + "\n"

if insert:
    src = src.replace("<manifest", "<manifest", 1)
    first_app = src.find("<application")
    if first_app != -1:
        src = src[:first_app] + insert + src[first_app:]

service = '''
        <service
            android:name=".maurimesh.blehardware.MauriMeshHardwareBleScanService"
            android:enabled="true"
            android:exported="false"
            android:foregroundServiceType="connectedDevice" />
'''

if "MauriMeshHardwareBleScanService" not in src:
    src = src.replace("</application>", service + "\n    </application>", 1)

p.write_text(src)
PY

# ============================================================
# 6. JS NATIVE BRIDGE
# ============================================================

cat > "$ROOT/src/native/MauriMeshHardwareBle.ts" <<'TS'
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
TS

# ============================================================
# 7. PROOF SCREEN
# ============================================================

cat > "$ROOT/src/components/HardwareBleProofPanel.tsx" <<'TSX'
import React, { useEffect, useState } from "react";
import { Alert, ScrollView, StyleSheet, Text, View } from "react-native";
import {
  getMauriMeshHardwareBleStatus,
  openMauriMeshBluetoothSettings,
  requestMauriMeshHardwareBlePermissions,
  startMauriMeshHardwareBleScan,
  stopMauriMeshHardwareBleScan,
} from "../native/MauriMeshHardwareBle";
import { MaoriProtocolPanel } from "./MaoriProtocolPanel";
import { MauriButton } from "./MauriButton";

const C = {
  bg: "#020403",
  panel: "rgba(2,12,8,0.92)",
  border: "rgba(0,208,132,0.32)",
  green: "#00D084",
  blue: "#38BDF8",
  white: "#FFFFFF",
  muted: "rgba(255,255,255,0.72)",
  warn: "#F59E0B",
  danger: "#FB7185",
};

export function HardwareBleProofPanel() {
  const [status, setStatus] = useState<any>({});
  const [lastAction, setLastAction] = useState("WAITING");

  const refresh = async () => {
    const next = await getMauriMeshHardwareBleStatus();
    setStatus(next);
  };

  useEffect(() => {
    refresh();
    const t = setInterval(refresh, 2500);
    return () => clearInterval(t);
  }, []);

  const requestPermissions = async () => {
    const res = await requestMauriMeshHardwareBlePermissions();
    setLastAction(`PERMISSIONS: ${JSON.stringify(res)}`);
    await refresh();
  };

  const start = async () => {
    try {
      const res = await startMauriMeshHardwareBleScan();
      setLastAction(`START: ${JSON.stringify(res)}`);
      Alert.alert(
        "MauriMesh BLE scan started",
        "Leave MauriMesh open, turn the screen off for 2–5 minutes, then check Android Bluetooth scan history.",
      );
    } catch (e: any) {
      setLastAction(`START_ERROR: ${String(e?.message || e)}`);
      Alert.alert("Start scan failed", String(e?.message || e));
    }
    await refresh();
  };

  const stop = async () => {
    const res = await stopMauriMeshHardwareBleScan();
    setLastAction(`STOP: ${JSON.stringify(res)}`);
    await refresh();
  };

  return (
    <ScrollView style={styles.root} contentContainerStyle={styles.content}>
      <View style={styles.header}>
        <Text style={styles.kicker}>MAURIMESH NATIVE HARDWARE BLE</Text>
        <Text style={styles.title}>Hardware BLE Proof</Text>
        <Text style={styles.subtitle}>
          Real Android BluetoothLeScanner foreground-service proof. This is the layer
          that should make MauriMesh appear in Android Bluetooth scan history after
          screen-off scanning.
        </Text>
      </View>

      <MaoriProtocolPanel screen="Hardware BLE Proof" compact />

      <View style={styles.panel}>
        <Text style={styles.sectionTitle}>Native Status</Text>
        <Text style={styles.line}>Native module: {String(status.nativeModule)}</Text>
        <Text style={styles.line}>Bluetooth adapter: {String(status.bluetoothAdapterPresent)}</Text>
        <Text style={styles.line}>Bluetooth enabled: {String(status.bluetoothEnabled)}</Text>
        <Text style={styles.line}>BLUETOOTH_SCAN: {String(status.scanPermission)}</Text>
        <Text style={styles.line}>BLUETOOTH_CONNECT: {String(status.connectPermission)}</Text>
        <Text style={styles.line}>Location permission: {String(status.fineLocationPermission)}</Text>
        <Text style={styles.line}>Post notifications: {String(status.postNotificationsPermission)}</Text>
        <Text style={styles.line}>Service running: {String(status.serviceRunning)}</Text>
        <Text style={styles.line}>Discovered count: {String(status.discoveredCount || 0)}</Text>
        <Text style={styles.line}>Last device: {String(status.lastDeviceName || "none")}</Text>
        <Text style={styles.line}>Last address: {String(status.lastDeviceAddress || "none")}</Text>
        <Text style={styles.line}>Last RSSI: {String(status.lastRssi || 0)}</Text>
        <Text style={styles.marker}>{String(status.proofMarker || "NO_MARKER")}</Text>
      </View>

      <View style={styles.panel}>
        <Text style={styles.sectionTitle}>Actions</Text>
        <MauriButton title="Request BLE Permissions" onPress={requestPermissions} />
        <MauriButton title="Start Native Hardware BLE Scan" onPress={start} />
        <MauriButton title="Stop Native Hardware BLE Scan" onPress={stop} />
        <MauriButton title="Refresh Status" onPress={refresh} />
        <MauriButton title="Open Bluetooth Settings" onPress={openMauriMeshBluetoothSettings} />
      </View>

      <View style={styles.panel}>
        <Text style={styles.sectionTitle}>Android Scan History Test</Text>
        <Text style={styles.step}>1. Press Request BLE Permissions.</Text>
        <Text style={styles.step}>2. Press Start Native Hardware BLE Scan.</Text>
        <Text style={styles.step}>3. Confirm service running = true.</Text>
        <Text style={styles.step}>4. Leave MauriMesh open.</Text>
        <Text style={styles.step}>5. Turn screen off for 2–5 minutes.</Text>
        <Text style={styles.step}>6. Turn screen on.</Text>
        <Text style={styles.step}>7. Open Android Bluetooth scan history.</Text>
        <Text style={styles.step}>8. MauriMesh should appear there if native scan ran while screen was off.</Text>
      </View>

      <View style={styles.panel}>
        <Text style={styles.sectionTitle}>Logcat Markers</Text>
        <Text style={styles.marker}>MAURIMESH_NATIVE_HARDWARE_BLE_START_REQUESTED</Text>
        <Text style={styles.marker}>MAURIMESH_NATIVE_BLE_SERVICE_CREATED</Text>
        <Text style={styles.marker}>MAURIMESH_NATIVE_BLE_SCAN_STARTED</Text>
        <Text style={styles.marker}>MAURIMESH_NATIVE_BLE_SCAN_RESULT</Text>
        <Text style={styles.marker}>MAURIMESH_NATIVE_BLE_SCAN_STOPPED</Text>
      </View>

      <View style={styles.panel}>
        <Text style={styles.sectionTitle}>Last Action</Text>
        <Text style={styles.truth}>{lastAction}</Text>
      </View>

      <View style={styles.panel}>
        <Text style={styles.sectionTitle}>Truth Boundary</Text>
        <Text style={styles.truth}>
          This proves native Android BLE scanning when the service starts and Android records scan activity.
          It still does not prove message delivery, receiver ACK, relay, or 3-hop mesh until packet TX/RX/ACK logs exist.
        </Text>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: C.bg },
  content: { padding: 18, gap: 14, paddingBottom: 42 },
  header: { gap: 8 },
  kicker: { color: C.blue, fontSize: 12, fontWeight: "900", letterSpacing: 1 },
  title: { color: C.white, fontSize: 34, fontWeight: "900", letterSpacing: -1 },
  subtitle: { color: C.muted, fontSize: 15, lineHeight: 22 },
  panel: {
    borderWidth: 1,
    borderColor: C.border,
    borderRadius: 22,
    backgroundColor: C.panel,
    padding: 15,
    gap: 8,
  },
  sectionTitle: { color: C.white, fontSize: 20, fontWeight: "900" },
  line: { color: C.muted, fontSize: 14, lineHeight: 20 },
  step: { color: C.muted, fontSize: 13, lineHeight: 20 },
  marker: { color: C.green, fontSize: 12, lineHeight: 18, fontFamily: "monospace" },
  truth: { color: C.warn, fontSize: 12, lineHeight: 18 },
});
TSX

cat > "$ROOT/app/hardware-ble-proof.tsx" <<'TSX'
import React from "react";
import { HardwareBleProofPanel } from "../src/components/HardwareBleProofPanel";

export default function HardwareBleProofScreen() {
  return <HardwareBleProofPanel />;
}
TSX

# ============================================================
# 8. DASHBOARD / ROUTE REGISTRY MARKERS
# ============================================================

if [ -f "$ROOT/app/dashboard.tsx" ] && ! grep -q "/hardware-ble-proof" "$ROOT/app/dashboard.tsx"; then
  python3 <<'PY'
from pathlib import Path

p = Path("app/dashboard.tsx")
src = p.read_text()

button = '<MauriButton title="Hardware BLE Proof" onPress={() => router.push("/hardware-ble-proof")} />'

markers = [
    '<MauriButton title="Full Mesh Test Report" onPress={() => router.push("/full-mesh-test-report")} />',
    '<MauriButton title="MauriCore Android BLE Runtime" onPress={() => router.push("/mauricore-ble-runtime")} />',
    '<MauriButton title="Device Proof" onPress={() => router.push("/device-proof")} />',
]

inserted = False
for marker in markers:
    if marker in src:
        src = src.replace(marker, marker + "\n        " + button, 1)
        inserted = True
        break

if not inserted:
    src += '\n\n// MauriMesh Hardware BLE Proof route: /hardware-ble-proof\n'

p.write_text(src)
PY
fi

if [ -f "$ROOT/src/lib/uiBackupRoutes.ts" ] && ! grep -q "/hardware-ble-proof" "$ROOT/src/lib/uiBackupRoutes.ts"; then
  cat >> "$ROOT/src/lib/uiBackupRoutes.ts" <<'TS'

// MauriMesh Hardware BLE Proof backup route
export const MAURIMESH_HARDWARE_BLE_PROOF_ROUTE = "/hardware-ble-proof";
TS
fi

ENGINE="$ROOT/src/maurimesh/test-layer/MauriMeshFullTestEngine.ts"
if [ -f "$ENGINE" ] && ! grep -q '"/hardware-ble-proof"' "$ENGINE"; then
  python3 <<'PY'
from pathlib import Path
p = Path("src/maurimesh/test-layer/MauriMeshFullTestEngine.ts")
src = p.read_text()
for marker in ['  "/mauricore-ble-runtime",', '  "/device-proof",', '  "/full-mesh-test-report",']:
    if marker in src:
        src = src.replace(marker, marker + '\n  "/hardware-ble-proof",', 1)
        break
else:
    src += '\n\n// MauriMesh Hardware BLE Proof required route: /hardware-ble-proof\n'
p.write_text(src)
PY
fi

# ============================================================
# 9. CHECKER
# ============================================================

cat > "$ROOT/check-maurimesh-native-hardware-ble-proof.sh" <<'EOF_CHECK'
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
REPORT="$ROOT/docs/maurimesh-native-hardware-ble-proof-$STAMP.md"
LATEST="$ROOT/docs/maurimesh-native-hardware-ble-proof-latest.md"
EXPORT_DIR="$ROOT/.maurimesh-native-hardware-ble-export-$STAMP"

mkdir -p "$ROOT/docs"
: > "$REPORT"

TOTAL=0
PASS=0
FAIL=0

check_file() {
  local label="$1"
  local file="$2"
  TOTAL=$((TOTAL+1))
  if [ -f "$ROOT/$file" ]; then
    echo "- [x] $label exists: $file" >> "$REPORT"
    PASS=$((PASS+1))
  else
    echo "- [ ] MISSING: $label: $file" >> "$REPORT"
    FAIL=$((FAIL+1))
  fi
}

check_contains() {
  local label="$1"
  local file="$2"
  local needle="$3"
  TOTAL=$((TOTAL+1))
  if [ -f "$ROOT/$file" ] && grep -q "$needle" "$ROOT/$file"; then
    echo "- [x] $label" >> "$REPORT"
    PASS=$((PASS+1))
  else
    echo "- [ ] MISSING: $label" >> "$REPORT"
    FAIL=$((FAIL+1))
  fi
}

{
  echo "# MauriMesh Native Hardware BLE Proof Install Check"
  echo ""
  echo "Generated: $STAMP"
  echo ""
  echo "## Files"
} >> "$REPORT"

check_file "Native BLE module" "android/app/src/main/java/com/maurimesh/messenger/maurimesh/blehardware/MauriMeshHardwareBleModule.kt"
check_file "Native BLE package" "android/app/src/main/java/com/maurimesh/messenger/maurimesh/blehardware/MauriMeshHardwareBlePackage.kt"
check_file "Native BLE foreground scan service" "android/app/src/main/java/com/maurimesh/messenger/maurimesh/blehardware/MauriMeshHardwareBleScanService.kt"
check_file "JS native bridge" "src/native/MauriMeshHardwareBle.ts"
check_file "Hardware BLE proof panel" "src/components/HardwareBleProofPanel.tsx"
check_file "Hardware BLE proof route" "app/hardware-ble-proof.tsx"

{
  echo ""
  echo "## Native Wiring"
} >> "$REPORT"

check_contains "MainApplication package import/wiring" "android/app/src/main/java/com/maurimesh/messenger/MainApplication.kt" "MauriMeshHardwareBlePackage"
check_contains "Manifest BLUETOOTH_SCAN permission" "android/app/src/main/AndroidManifest.xml" "android.permission.BLUETOOTH_SCAN"
check_contains "Manifest BLUETOOTH_CONNECT permission" "android/app/src/main/AndroidManifest.xml" "android.permission.BLUETOOTH_CONNECT"
check_contains "Manifest foreground service permission" "android/app/src/main/AndroidManifest.xml" "android.permission.FOREGROUND_SERVICE"
check_contains "Manifest connected device foreground service permission" "android/app/src/main/AndroidManifest.xml" "android.permission.FOREGROUND_SERVICE_CONNECTED_DEVICE"
check_contains "Manifest service registered" "android/app/src/main/AndroidManifest.xml" "MauriMeshHardwareBleScanService"
check_contains "BluetoothLeScanner used" "android/app/src/main/java/com/maurimesh/messenger/maurimesh/blehardware/MauriMeshHardwareBleScanService.kt" "BluetoothLeScanner"
check_contains "Native scan started marker" "android/app/src/main/java/com/maurimesh/messenger/maurimesh/blehardware/MauriMeshHardwareBleScanService.kt" "MAURIMESH_NATIVE_BLE_SCAN_STARTED"
check_contains "Native scan result marker" "android/app/src/main/java/com/maurimesh/messenger/maurimesh/blehardware/MauriMeshHardwareBleScanService.kt" "MAURIMESH_NATIVE_BLE_SCAN_RESULT"

{
  echo ""
  echo "## UI Wiring"
} >> "$REPORT"

check_contains "Route uses HardwareBleProofPanel" "app/hardware-ble-proof.tsx" "HardwareBleProofPanel"
check_contains "Panel calls start scan" "src/components/HardwareBleProofPanel.tsx" "startMauriMeshHardwareBleScan"
check_contains "Panel requests permissions" "src/components/HardwareBleProofPanel.tsx" "requestMauriMeshHardwareBlePermissions"
check_contains "Dashboard references /hardware-ble-proof" "app/dashboard.tsx" "/hardware-ble-proof"
check_contains "Backup registry references /hardware-ble-proof" "src/lib/uiBackupRoutes.ts" "/hardware-ble-proof"

{
  echo ""
  echo "## TypeScript"
} >> "$REPORT"

TOTAL=$((TOTAL+1))
if npx tsc --noEmit >> "$REPORT" 2>&1; then
  echo "- [x] TypeScript passed" >> "$REPORT"
  PASS=$((PASS+1))
else
  echo "- [ ] TypeScript failed" >> "$REPORT"
  FAIL=$((FAIL+1))
fi

{
  echo ""
  echo "## Expo Android Export"
} >> "$REPORT"

TOTAL=$((TOTAL+1))
rm -rf "$EXPORT_DIR"
if NODE_ENV=production npx expo export --platform android --output-dir "$EXPORT_DIR" >> "$REPORT" 2>&1; then
  echo "- [x] Expo Android export passed" >> "$REPORT"
  PASS=$((PASS+1))
else
  echo "- [ ] Expo Android export failed" >> "$REPORT"
  FAIL=$((FAIL+1))
fi

SCORE=$(( PASS * 100 / TOTAL ))
STATUS="COMPLETE"
if [ "$FAIL" -gt 0 ]; then
  STATUS="FAILED"
fi

{
  echo ""
  echo "## Summary"
  echo ""
  echo "- Total: $TOTAL"
  echo "- Complete: $PASS"
  echo "- Missing/failed: $FAIL"
  echo "- Score: $SCORE%"
  echo "- Status: **$STATUS**"
  echo ""
  echo "## Final Truth"
  echo ""
  echo "Native Android BLE hardware scan bridge is installed in source."
  echo "It is not active inside the installed APK until EAS rebuilds the native Android binary."
  echo "After rebuilding/installing, open /hardware-ble-proof, request permissions, start scan, turn screen off, then check Android Bluetooth scan history."
} >> "$REPORT"

cp "$REPORT" "$LATEST"
cat "$REPORT"

echo ""
echo "============================================================"
echo "NATIVE HARDWARE BLE PROOF CHECK COMPLETE"
echo "Status: $STATUS"
echo "Score: $SCORE%"
echo "Report: $LATEST"
echo "============================================================"

if [ "$STATUS" != "COMPLETE" ]; then
  exit 1
fi
EOF_CHECK

chmod +x "$ROOT/check-maurimesh-native-hardware-ble-proof.sh"

# ============================================================
# 10. RUN CHECKS
# ============================================================

./check-maurimesh-native-hardware-ble-proof.sh

echo ""
echo "============================================================"
echo "DONE: MAURIMESH NATIVE HARDWARE BLE PROOF INSTALLED"
echo "============================================================"
echo "Backup:"
echo "  $BACKUP"
echo ""
echo "Open after rebuild:"
echo "  /hardware-ble-proof"
echo ""
echo "Report:"
echo "  docs/maurimesh-native-hardware-ble-proof-latest.md"
echo ""
echo "Next build:"
echo "  npx eas-cli build --platform android --profile preview-apk --clear-cache"
echo "============================================================"
