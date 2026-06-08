#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "#182 — MAURIMESH ANDROID FOREGROUND SERVICE"
echo "Keeps MauriMesh alive when screen locks"
echo "Adds START_STICKY service + persistent notification + heartbeat"
echo "NO eject. NO project reset. NO deletion."
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$HOME/maurimesh-router-backups/task-182-foreground-service-$STAMP"

DOCS="$ROOT/docs"
SCRIPTS="$ROOT/scripts"

mkdir -p "$BACKUP" "$DOCS" "$SCRIPTS"

echo ""
echo "1. Locate Android app source"

ANDROID_DIR=""

if [ -d "$ROOT/android/app/src/main" ]; then
  ANDROID_DIR="$ROOT/android/app/src/main"
elif [ -d "$ROOT/artifacts/messenger-mobile/android/app/src/main" ]; then
  ANDROID_DIR="$ROOT/artifacts/messenger-mobile/android/app/src/main"
else
  echo "ERROR: Could not find android/app/src/main."
  echo "Do not run eject yet."
  echo "First find Android folders:"
  echo "find . -path '*/android/app/src/main' -type d -print"
  exit 1
fi

MANIFEST="$ANDROID_DIR/AndroidManifest.xml"

if [ ! -f "$MANIFEST" ]; then
  echo "ERROR: AndroidManifest.xml not found at $MANIFEST"
  exit 1
fi

echo "Android main: $ANDROID_DIR"
echo "Manifest: $MANIFEST"

echo ""
echo "2. Detect package path"

PACKAGE_NAME="$(grep -oE 'package="[^"]+"' "$MANIFEST" | head -1 | cut -d'"' -f2 || true)"

if [ -z "$PACKAGE_NAME" ]; then
  PACKAGE_NAME="com.maurimesh.messenger"
fi

PACKAGE_PATH="$(echo "$PACKAGE_NAME" | tr '.' '/')"
JAVA_DIR="$ANDROID_DIR/java/$PACKAGE_PATH"

if [ ! -d "$JAVA_DIR" ]; then
  echo "WARN: Package path not found: $JAVA_DIR"
  echo "Searching for MainApplication.kt..."
  MAIN_APP="$(find "$ANDROID_DIR/java" -name MainApplication.kt | head -1 || true)"
  if [ -n "$MAIN_APP" ]; then
    JAVA_DIR="$(dirname "$MAIN_APP")"
    PACKAGE_NAME="$(grep -oE '^package .+' "$MAIN_APP" | head -1 | awk '{print $2}')"
    PACKAGE_PATH="$(echo "$PACKAGE_NAME" | tr '.' '/')"
  else
    mkdir -p "$JAVA_DIR"
  fi
fi

echo "Package: $PACKAGE_NAME"
echo "Java dir: $JAVA_DIR"

mkdir -p "$JAVA_DIR"

SERVICE="$JAVA_DIR/MauriMeshForegroundService.kt"
MODULE="$JAVA_DIR/MauriMeshBackgroundRuntimeModule.kt"
PACKAGE_FILE="$JAVA_DIR/MauriMeshBackgroundRuntimePackage.kt"
MAIN_APP="$JAVA_DIR/MainApplication.kt"

echo ""
echo "3. Backup native targets"

cp "$MANIFEST" "$BACKUP/AndroidManifest.xml" 2>/dev/null || true
cp "$SERVICE" "$BACKUP/MauriMeshForegroundService.kt" 2>/dev/null || true
cp "$MODULE" "$BACKUP/MauriMeshBackgroundRuntimeModule.kt" 2>/dev/null || true
cp "$PACKAGE_FILE" "$BACKUP/MauriMeshBackgroundRuntimePackage.kt" 2>/dev/null || true
cp "$MAIN_APP" "$BACKUP/MainApplication.kt" 2>/dev/null || true

echo "Backup: $BACKUP"

echo ""
echo "4. Install MauriMeshForegroundService.kt"

cat > "$SERVICE" <<KT
package $PACKAGE_NAME

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class MauriMeshForegroundService : Service() {
  companion object {
    const val CHANNEL_ID = "maurimesh_mesh_active"
    const val NOTIFICATION_ID = 182
    const val ACTION_START = "com.maurimesh.messenger.START_MESH_FOREGROUND"
    const val ACTION_STOP = "com.maurimesh.messenger.STOP_MESH_FOREGROUND"
    const val MARKER = "TASK_182_MAURIMESH_FOREGROUND_SERVICE_20260608_A"
  }

  private val handler = Handler(Looper.getMainLooper())
  private var startedAtMs: Long = 0L

  private val heartbeatRunnable = object : Runnable {
    override fun run() {
      writeHeartbeat()
      handler.postDelayed(this, 120_000L)
    }
  }

  override fun onCreate() {
    super.onCreate()
    startedAtMs = System.currentTimeMillis()
    createNotificationChannel()
    Log.i("MauriMeshForeground", "onCreate marker=\$MARKER")
  }

  override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
    if (intent?.action == ACTION_STOP) {
      stopForegroundService()
      return START_NOT_STICKY
    }

    startForeground(NOTIFICATION_ID, buildNotification())
    writeHeartbeat()
    handler.removeCallbacks(heartbeatRunnable)
    handler.postDelayed(heartbeatRunnable, 120_000L)

    Log.i("MauriMeshForeground", "START_STICKY active marker=\$MARKER")
    return START_STICKY
  }

  override fun onDestroy() {
    handler.removeCallbacks(heartbeatRunnable)
    writeHeartbeat("destroyed")
    Log.w("MauriMeshForeground", "onDestroy marker=\$MARKER")
    super.onDestroy()
  }

  override fun onBind(intent: Intent?): IBinder? = null

  private fun stopForegroundService() {
    handler.removeCallbacks(heartbeatRunnable)
    writeHeartbeat("stopped")
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
      stopForeground(STOP_FOREGROUND_REMOVE)
    } else {
      @Suppress("DEPRECATION")
      stopForeground(true)
    }
    stopSelf()
  }

  private fun createNotificationChannel() {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
      val channel = NotificationChannel(
        CHANNEL_ID,
        "MauriMesh Mesh Runtime",
        NotificationManager.IMPORTANCE_LOW
      )
      channel.description = "Keeps MauriMesh peer discovery and mesh runtime alive."
      val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
      manager.createNotificationChannel(channel)
    }
  }

  private fun buildNotification(): Notification {
    return NotificationCompat.Builder(this, CHANNEL_ID)
      .setContentTitle("MauriMesh Mesh Active")
      .setContentText("Offline mesh runtime is protected while the screen is locked.")
      .setSmallIcon(android.R.drawable.stat_sys_data_bluetooth)
      .setOngoing(true)
      .setOnlyAlertOnce(true)
      .setPriority(NotificationCompat.PRIORITY_LOW)
      .setCategory(NotificationCompat.CATEGORY_SERVICE)
      .build()
  }

  private fun writeHeartbeat(state: String = "active") {
    try {
      val timestamp = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSZ", Locale.US).format(Date())
      val uptimeMs = System.currentTimeMillis() - startedAtMs

      val json = """{
        "marker":"\$MARKER",
        "subsystem":"background-runtime",
        "severity":"info",
        "code":"FOREGROUND_SERVICE_HEARTBEAT",
        "message":"MauriMesh foreground service heartbeat",
        "state":"\$state",
        "createdAt":"\$timestamp",
        "uptimeMs":\$uptimeMs
      }""".trimIndent()

      val dir = File(filesDir, "maurimesh-runtime-ledger")
      if (!dir.exists()) dir.mkdirs()

      File(dir, "foreground-service-heartbeat.json").writeText(json)
      File(dir, "foreground-service-heartbeat.log").appendText(json + "\\n")

      Log.i("MauriMeshForeground", json)
    } catch (error: Throwable) {
      Log.e("MauriMeshForeground", "heartbeat write failed", error)
    }
  }
}
KT

echo ""
echo "5. Install React Native module for foreground service control"

cat > "$MODULE" <<KT
package $PACKAGE_NAME

import android.content.Intent
import android.os.Build
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import java.io.File

class MauriMeshBackgroundRuntimeModule(
  private val reactContext: ReactApplicationContext
) : ReactContextBaseJavaModule(reactContext) {

  override fun getName(): String = "MauriMeshBackgroundRuntime"

  @ReactMethod
  fun startForegroundMeshRuntime(promise: Promise) {
    try {
      val intent = Intent(reactContext, MauriMeshForegroundService::class.java)
      intent.action = MauriMeshForegroundService.ACTION_START

      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        reactContext.startForegroundService(intent)
      } else {
        reactContext.startService(intent)
      }

      promise.resolve(true)
    } catch (error: Throwable) {
      promise.reject("MAURIMESH_FOREGROUND_START_FAILED", error)
    }
  }

  @ReactMethod
  fun stopForegroundMeshRuntime(promise: Promise) {
    try {
      val intent = Intent(reactContext, MauriMeshForegroundService::class.java)
      intent.action = MauriMeshForegroundService.ACTION_STOP
      reactContext.startService(intent)
      promise.resolve(true)
    } catch (error: Throwable) {
      promise.reject("MAURIMESH_FOREGROUND_STOP_FAILED", error)
    }
  }

  @ReactMethod
  fun getForegroundMeshRuntimeStatus(promise: Promise) {
    try {
      val heartbeat = File(
        reactContext.filesDir,
        "maurimesh-runtime-ledger/foreground-service-heartbeat.json"
      )

      val map = com.facebook.react.bridge.Arguments.createMap()
      map.putString("marker", MauriMeshForegroundService.MARKER)
      map.putBoolean("heartbeatPresent", heartbeat.exists())
      map.putString("heartbeat", if (heartbeat.exists()) heartbeat.readText() else "")
      map.putString("capability", "real_native")
      map.putString(
        "truth",
        "Foreground service exists and heartbeat file proves native service execution. Screen-off survival still requires physical phone proof."
      )

      promise.resolve(map)
    } catch (error: Throwable) {
      promise.reject("MAURIMESH_FOREGROUND_STATUS_FAILED", error)
    }
  }
}
KT

cat > "$PACKAGE_FILE" <<KT
package $PACKAGE_NAME

import com.facebook.react.ReactPackage
import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.uimanager.ViewManager

class MauriMeshBackgroundRuntimePackage : ReactPackage {
  override fun createNativeModules(reactContext: ReactApplicationContext): List<NativeModule> {
    return listOf(MauriMeshBackgroundRuntimeModule(reactContext))
  }

  override fun createViewManagers(
    reactContext: ReactApplicationContext
  ): List<ViewManager<*, *>> {
    return emptyList()
  }
}
KT

echo ""
echo "6. Register package in MainApplication.kt"

if [ -f "$MAIN_APP" ]; then
python3 <<PY
from pathlib import Path

path = Path("$MAIN_APP")
text = path.read_text()

if "MauriMeshBackgroundRuntimePackage" in text:
    print("MainApplication already registers MauriMeshBackgroundRuntimePackage")
else:
    if "packages.add(" in text:
        text = text.replace(
            "packages.add(",
            "packages.add(MauriMeshBackgroundRuntimePackage())\n            packages.add(",
            1,
        )
    elif "return packages" in text:
        text = text.replace(
            "return packages",
            "packages.add(MauriMeshBackgroundRuntimePackage())\n            return packages",
            1,
        )
    elif "PackageList(this).packages" in text:
        text = text.replace(
            "PackageList(this).packages",
            "PackageList(this).packages.apply { add(MauriMeshBackgroundRuntimePackage()) }",
            1,
        )
    else:
        print("WARN: Could not auto-register package in MainApplication.kt")

    path.write_text(text)
    print("MainApplication package registration attempted")
PY
else
  echo "WARN: MainApplication.kt not found at package path. Package created but not registered."
fi

echo ""
echo "7. Patch AndroidManifest permissions and service"

python3 <<PY
from pathlib import Path
import re

path = Path("$MANIFEST")
text = path.read_text()
original = text

permissions = [
    '<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />',
    '<uses-permission android:name="android.permission.FOREGROUND_SERVICE_CONNECTED_DEVICE" />',
    '<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />',
    '<uses-permission android:name="android.permission.WAKE_LOCK" />',
]

for perm in permissions:
    name = re.search(r'android:name="([^"]+)"', perm).group(1)
    if name not in text:
        text = text.replace("<application", perm + "\n    <application", 1)

service = '''        <service
            android:name=".MauriMeshForegroundService"
            android:enabled="true"
            android:exported="false"
            android:foregroundServiceType="connectedDevice" />
'''

if "MauriMeshForegroundService" not in text:
    text = text.replace("</application>", service + "\n    </application>", 1)

if text != original:
    path.write_text(text)
    print("AndroidManifest patched")
else:
    print("AndroidManifest already patched")
PY

echo ""
echo "8. Create JS bridge client"

mkdir -p "$ROOT/src/maurimesh/background"

cat > "$ROOT/src/maurimesh/background/foregroundRuntimeClient.ts" <<'TS'
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
TS

echo ""
echo "9. Create foreground runtime proof screen"

cat > "$ROOT/app/foreground-runtime-proof.tsx" <<'TSX'
import React, { useEffect, useState } from "react";
import {
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from "react-native";
import {
  getMauriMeshForegroundRuntimeStatus,
  startMauriMeshForegroundRuntime,
  stopMauriMeshForegroundRuntime,
} from "../src/maurimesh/background/foregroundRuntimeClient";

const MARKER = "TASK_182_FOREGROUND_RUNTIME_PROOF_UI_20260608_A";

export default function ForegroundRuntimeProofScreen() {
  const [status, setStatus] = useState<any>({});
  const [working, setWorking] = useState(false);

  async function refresh() {
    const next = await getMauriMeshForegroundRuntimeStatus();
    setStatus(next);
  }

  async function start() {
    setWorking(true);
    try {
      await startMauriMeshForegroundRuntime();
      await refresh();
    } finally {
      setWorking(false);
    }
  }

  async function stop() {
    setWorking(true);
    try {
      await stopMauriMeshForegroundRuntime();
      await refresh();
    } finally {
      setWorking(false);
    }
  }

  useEffect(() => {
    refresh();
    const timer = setInterval(refresh, 5000);
    return () => clearInterval(timer);
  }, []);

  return (
    <ScrollView style={styles.page} contentContainerStyle={styles.content}>
      <Text style={styles.brand}>MauriMesh</Text>
      <Text style={styles.title}>Foreground Runtime Proof</Text>
      <Text style={styles.marker}>{MARKER}</Text>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Native Runtime</Text>
        <Line label="Capability" value={status.capability || "unknown"} />
        <Line label="Heartbeat present" value={Boolean(status.heartbeatPresent)} />
        <Line label="Native marker" value={status.marker || "none"} />
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Heartbeat</Text>
        <Text style={styles.body}>{status.heartbeat || "No heartbeat yet."}</Text>
      </View>

      <View style={styles.warningCard}>
        <Text style={styles.cardTitle}>Truth Boundary</Text>
        <Text style={styles.body}>
          This proves native foreground service execution when heartbeat appears.
          Real screen-lock survival still requires physical phone proof: start service,
          lock screen for 10+ minutes, unlock, verify heartbeat advanced and BLE scan still works.
        </Text>
      </View>

      <TouchableOpacity style={styles.button} disabled={working} onPress={start}>
        <Text style={styles.buttonText}>{working ? "Working..." : "Start Mesh Foreground Service"}</Text>
      </TouchableOpacity>

      <TouchableOpacity style={styles.secondaryButton} disabled={working} onPress={stop}>
        <Text style={styles.secondaryButtonText}>Stop Service</Text>
      </TouchableOpacity>

      <TouchableOpacity style={styles.secondaryButton} disabled={working} onPress={refresh}>
        <Text style={styles.secondaryButtonText}>Refresh Status</Text>
      </TouchableOpacity>
    </ScrollView>
  );
}

function Line({ label, value }: { label: string; value: string | number | boolean }) {
  return (
    <Text style={styles.body}>
      <Text style={styles.label}>{label}: </Text>
      {String(value)}
    </Text>
  );
}

const styles = StyleSheet.create({
  page: { flex: 1, backgroundColor: "#050816" },
  content: { padding: 24, paddingTop: 56, paddingBottom: 80 },
  brand: { color: "#00D084", fontSize: 42, fontWeight: "900", marginBottom: 20 },
  title: { color: "#FFFFFF", fontSize: 28, fontWeight: "900", marginBottom: 10 },
  marker: { color: "#4FC3F7", fontSize: 12, fontWeight: "900", letterSpacing: 1, marginBottom: 24 },
  card: {
    borderWidth: 1,
    borderColor: "rgba(0, 208, 132, 0.32)",
    borderRadius: 20,
    padding: 20,
    marginBottom: 16,
    backgroundColor: "rgba(255,255,255,0.035)",
  },
  warningCard: {
    borderWidth: 1,
    borderColor: "rgba(245, 158, 11, 0.55)",
    borderRadius: 20,
    padding: 20,
    marginBottom: 16,
    backgroundColor: "rgba(245, 158, 11, 0.055)",
  },
  cardTitle: { color: "#FFFFFF", fontSize: 21, fontWeight: "900", marginBottom: 12 },
  body: { color: "rgba(255,255,255,0.76)", fontSize: 15, lineHeight: 24, marginBottom: 6 },
  label: { color: "#FFFFFF", fontWeight: "900" },
  button: {
    backgroundColor: "#00D084",
    borderRadius: 18,
    padding: 18,
    alignItems: "center",
    marginTop: 6,
    marginBottom: 12,
  },
  buttonText: { color: "#03120C", fontSize: 16, fontWeight: "900" },
  secondaryButton: {
    borderWidth: 1,
    borderColor: "rgba(0, 208, 132, 0.5)",
    borderRadius: 18,
    padding: 16,
    alignItems: "center",
    marginBottom: 12,
  },
  secondaryButtonText: { color: "#00D084", fontSize: 15, fontWeight: "900" },
});
TSX

echo ""
echo "10. Wire dashboard route if possible"

if [ -f "$ROOT/app/dashboard.tsx" ]; then
python3 <<'PY'
from pathlib import Path
import re

path = Path("app/dashboard.tsx")
text = path.read_text()
original = text

if "/foreground-runtime-proof" not in text:
    if "] as const;" in text:
        text = text.replace(
            "] as const;",
            '  ["Foreground Runtime Proof", "/foreground-runtime-proof"],\n] as const;',
            1,
        )
    elif "Native BLE Scan Proof" in text:
        text = text.replace(
            '["Native BLE Scan Proof", "/native-ble-scan-proof"],',
            '["Native BLE Scan Proof", "/native-ble-scan-proof"],\n  ["Foreground Runtime Proof", "/foreground-runtime-proof"],',
            1,
        )
    else:
        print("WARN: Could not auto-wire dashboard route.")

if "SAFE_DASHBOARD_FOREGROUND_RUNTIME_20260608_A" not in text:
    text = re.sub(
        r'const MARKER = "[^"]+";',
        'const MARKER = "SAFE_DASHBOARD_FOREGROUND_RUNTIME_20260608_A";',
        text,
        count=1,
    )

if text != original:
    path.write_text(text)
    print("Dashboard route wired")
else:
    print("Dashboard already wired or unchanged")
PY
else
  echo "WARN: app/dashboard.tsx missing; proof screen still created."
fi

echo ""
echo "11. Update BackgroundRuntimeContract if present"

CONTRACT="$ROOT/artifacts/messenger-mobile/src/maurimesh/production-engines/BackgroundRuntimeContract.ts"

if [ -f "$CONTRACT" ]; then
  cp "$CONTRACT" "$BACKUP/BackgroundRuntimeContract.ts" 2>/dev/null || true
python3 <<'PY'
from pathlib import Path
import re

path = Path("artifacts/messenger-mobile/src/maurimesh/production-engines/BackgroundRuntimeContract.ts")
text = path.read_text()
original = text

text = text.replace("foreground_service: \"unavailable\"", "foreground_service: \"real_native\"")
text = text.replace("foregroundService: \"unavailable\"", "foregroundService: \"real_native\"")
text = text.replace("foreground_service_capability: \"unavailable\"", "foreground_service_capability: \"real_native\"")
text = text.replace("FOREGROUND_SERVICE_UNAVAILABLE", "FOREGROUND_SERVICE_REAL_NATIVE")

if "TASK_182_BACKGROUND_RUNTIME_CONTRACT_REAL_NATIVE" not in text:
    text += '\n\nexport const TASK_182_BACKGROUND_RUNTIME_CONTRACT_REAL_NATIVE = "TASK_182_BACKGROUND_RUNTIME_CONTRACT_REAL_NATIVE_20260608_A";\n'

if text != original:
    path.write_text(text)
    print("BackgroundRuntimeContract updated to real_native")
else:
    print("BackgroundRuntimeContract found but no known unavailable marker replaced")
PY
else
  echo "WARN: BackgroundRuntimeContract.ts not found; skipping contract update."
fi

echo ""
echo "12. Create Android permission grant helper"

cat > "$SCRIPTS/grant-task-182-background-permissions.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail

PKG="${1:-com.maurimesh.messenger}"

echo "Granting background runtime permissions for $PKG"

adb shell pm grant "$PKG" android.permission.POST_NOTIFICATIONS 2>/dev/null || true
adb shell pm grant "$PKG" android.permission.ACCESS_FINE_LOCATION 2>/dev/null || true
adb shell pm grant "$PKG" android.permission.BLUETOOTH_SCAN 2>/dev/null || true
adb shell pm grant "$PKG" android.permission.BLUETOOTH_CONNECT 2>/dev/null || true
adb shell pm grant "$PKG" android.permission.BLUETOOTH_ADVERTISE 2>/dev/null || true

adb shell appops set "$PKG" POST_NOTIFICATION allow 2>/dev/null || true
adb shell appops set "$PKG" FINE_LOCATION allow 2>/dev/null || true
adb shell appops set "$PKG" BLUETOOTH_SCAN allow 2>/dev/null || true
adb shell appops set "$PKG" BLUETOOTH_CONNECT allow 2>/dev/null || true
adb shell appops set "$PKG" BLUETOOTH_ADVERTISE allow 2>/dev/null || true

adb shell am force-stop "$PKG"
adb shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1

echo "Done. Open Dashboard -> Foreground Runtime Proof."
SH

chmod +x "$SCRIPTS/grant-task-182-background-permissions.sh"

echo ""
echo "13. Create physical proof script"

cat > "$SCRIPTS/task-182-screen-lock-proof-logcat.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail

PKG="${1:-com.maurimesh.messenger}"

echo "============================================================"
echo "#182 Screen-lock foreground service proof"
echo "Package: $PKG"
echo "============================================================"

adb logcat -c

echo "Launch app"
adb shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1

echo ""
echo "Now on phone:"
echo "1. Dashboard -> Foreground Runtime Proof"
echo "2. Press Start Mesh Foreground Service"
echo "3. Confirm notification says MauriMesh Mesh Active"
echo "4. Lock screen for 10+ minutes"
echo "5. Unlock and press Refresh Status"
echo ""
echo "Capturing current relevant logs..."
sleep 5

adb logcat -d | grep -E "MauriMeshForeground|FOREGROUND_SERVICE_HEARTBEAT|TASK_182|AndroidRuntime|FATAL EXCEPTION" | tail -250 || true
SH

chmod +x "$SCRIPTS/task-182-screen-lock-proof-logcat.sh"

echo ""
echo "14. Create docs"

cat > "$DOCS/task-182-maurimesh-foreground-service.md" <<'MD'
# Task #182 — MauriMesh Foreground Service

Marker: `TASK_182_MAURIMESH_FOREGROUND_SERVICE_20260608_A`

## Installed

- `MauriMeshForegroundService.kt`
- `MauriMeshBackgroundRuntimeModule.kt`
- `MauriMeshBackgroundRuntimePackage.kt`
- Android manifest service declaration
- Foreground permissions
- JS client: `src/maurimesh/background/foregroundRuntimeClient.ts`
- Proof screen: `/foreground-runtime-proof`
- Permission helper: `scripts/grant-task-182-background-permissions.sh`
- Logcat proof helper: `scripts/task-182-screen-lock-proof-logcat.sh`

## Native behavior

- Calls `startForeground()`
- Persistent notification: `MauriMesh Mesh Active`
- Returns `START_STICKY`
- Writes heartbeat every 2 minutes
- Exposes status through React Native bridge

## Truth boundary

This installs the native foreground runtime layer.

Real completion requires physical proof:

1. Build and install APK.
2. Open Dashboard → Foreground Runtime Proof.
3. Press Start Mesh Foreground Service.
4. Confirm Android notification is visible.
5. Lock phone screen for 10+ minutes.
6. Unlock.
7. Confirm heartbeat advanced.
8. Confirm BLE scan still starts after screen lock.
9. Run two-phone screen-off discovery/ACK proof after advertise/connect phases exist.
MD

echo ""
echo "15. Validate files and markers"

grep -RniE "TASK_182|MauriMeshForegroundService|MauriMeshBackgroundRuntime|foregroundServiceType|FOREGROUND_SERVICE" \
  "$ANDROID_DIR" app src artifacts docs scripts 2>/dev/null || true

echo ""
echo "16. TypeScript check"
npx tsc --noEmit

echo ""
echo "17. Expo export check"
rm -rf dist .expo
npx expo export --platform android --clear

echo ""
echo "============================================================"
echo "#182 FOREGROUND SERVICE INSTALLED"
echo "Backup: $BACKUP"
echo ""
echo "Next:"
echo "1. Build APK with EAS"
echo "2. Install APK"
echo "3. Run: bash scripts/grant-task-182-background-permissions.sh com.maurimesh.messenger"
echo "4. Open Dashboard -> Foreground Runtime Proof"
echo "5. Start service and confirm notification"
echo "6. Lock screen for 10+ minutes and verify heartbeat"
echo "============================================================"
