#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "INSTALL MAURIMESH ANDROID KOTLIN TELEMETRY MODULE"
echo "Adds native Android module: MauriMeshHardwareTelemetry"
echo "Feeds real APK battery/memory/storage/BLE data into JS bridge."
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$ROOT/backup-before-android-kotlin-telemetry-$STAMP"
ANDROID="$ROOT/android"
APP="$ANDROID/app"
DOCS="$ROOT/docs"

mkdir -p "$BACKUP" "$DOCS"

if [ ! -f "$ROOT/package.json" ]; then
  echo "ERROR: package.json not found. Run from Replit project root."
  exit 1
fi

if [ ! -d "$ANDROID" ]; then
  echo "ERROR: android/ folder not found."
  echo "You need native Android files first:"
  echo "  npx expo prebuild --platform android"
  exit 1
fi

backup_file() {
  local file="$1"
  if [ -f "$ROOT/$file" ]; then
    mkdir -p "$BACKUP/$(dirname "$file")"
    cp "$ROOT/$file" "$BACKUP/$file"
  fi
}

MAIN_KT="$(find "$APP/src/main" -name "MainApplication.kt" | head -1 || true)"
MAIN_JAVA="$(find "$APP/src/main" -name "MainApplication.java" | head -1 || true)"

if [ -z "$MAIN_KT" ] && [ -z "$MAIN_JAVA" ]; then
  echo "ERROR: MainApplication.kt/java not found under android/app/src/main"
  exit 1
fi

MAIN_FILE="${MAIN_KT:-$MAIN_JAVA}"
REL_MAIN="${MAIN_FILE#$ROOT/}"
backup_file "$REL_MAIN"

APP_PACKAGE="$(grep -E '^package ' "$MAIN_FILE" | head -1 | sed 's/package //g' | tr -d ';' | tr -d ' ')"

if [ -z "$APP_PACKAGE" ]; then
  echo "ERROR: Could not detect Android package from MainApplication."
  exit 1
fi

TELEMETRY_PACKAGE="$APP_PACKAGE.maurimesh.telemetry"
PKG_PATH="$(echo "$TELEMETRY_PACKAGE" | tr '.' '/')"
MODULE_DIR="$APP/src/main/java/$PKG_PATH"

mkdir -p "$MODULE_DIR"

MODULE_FILE="$MODULE_DIR/MauriMeshHardwareTelemetryModule.kt"
PACKAGE_FILE="$MODULE_DIR/MauriMeshHardwareTelemetryPackage.kt"

backup_file "${MODULE_FILE#$ROOT/}"
backup_file "${PACKAGE_FILE#$ROOT/}"

echo "App package:       $APP_PACKAGE"
echo "Telemetry package: $TELEMETRY_PACKAGE"
echo "Module dir:        $MODULE_DIR"
echo "MainApplication:   $MAIN_FILE"
echo "Backup:            $BACKUP"

# ============================================================
# 1. Native module
# ============================================================

cat > "$MODULE_FILE" <<KT
package $TELEMETRY_PACKAGE

import android.app.ActivityManager
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Build
import android.os.Environment
import android.os.PowerManager
import android.os.StatFs
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.WritableMap
import com.facebook.react.bridge.Arguments

class MauriMeshHardwareTelemetryModule(
  private val reactContext: ReactApplicationContext
) : ReactContextBaseJavaModule(reactContext) {

  override fun getName(): String {
    return "MauriMeshHardwareTelemetry"
  }

  @ReactMethod
  fun getHardwareTelemetry(promise: Promise) {
    try {
      val map = Arguments.createMap()

      val battery = readBattery()
      val memory = readMemory()
      val storage = readStorage()
      val thermalRisk = readThermalRisk()
      val ble = readBleState()

      map.putString("source", "NATIVE_ANDROID")
      map.putString("platform", "android")

      map.putDouble("batteryPercent", battery.percent.toDouble())
      map.putBoolean("isCharging", battery.isCharging)

      map.putDouble("memoryUsedMb", memory.usedMb.toDouble())
      map.putDouble("memoryTotalMb", memory.totalMb.toDouble())
      map.putString("memoryPressure", pressureFromMemory(memory.usedMb, memory.totalMb))

      map.putDouble("storageFreeMb", storage.freeMb.toDouble())
      map.putDouble("storageTotalMb", storage.totalMb.toDouble())
      map.putString("storagePressure", pressureFromStorage(storage.freeMb, storage.totalMb))

      map.putString("thermalRisk", thermalRisk)

      map.putBoolean("bleAvailable", ble.available)
      map.putBoolean("bleEnabled", ble.enabled)
      map.putString("blePressure", if (ble.available && ble.enabled) "low" else "medium")

      map.putString("appCrashRisk", "low")
      map.putBoolean("foreground", true)
      map.putDouble("timestamp", System.currentTimeMillis().toDouble())

      promise.resolve(map)
    } catch (error: Exception) {
      promise.reject("MAURIMESH_TELEMETRY_ERROR", error.message, error)
    }
  }

  private data class BatteryState(
    val percent: Int,
    val isCharging: Boolean
  )

  private data class MemoryState(
    val usedMb: Long,
    val totalMb: Long
  )

  private data class StorageState(
    val freeMb: Long,
    val totalMb: Long
  )

  private data class BleState(
    val available: Boolean,
    val enabled: Boolean
  )

  private fun readBattery(): BatteryState {
    val intent = reactContext.registerReceiver(
      null,
      IntentFilter(Intent.ACTION_BATTERY_CHANGED)
    )

    val level = intent?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
    val scale = intent?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1

    val percent =
      if (level >= 0 && scale > 0) ((level.toFloat() / scale.toFloat()) * 100).toInt()
      else 50

    val status = intent?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1

    val charging =
      status == BatteryManager.BATTERY_STATUS_CHARGING ||
        status == BatteryManager.BATTERY_STATUS_FULL

    return BatteryState(percent.coerceIn(0, 100), charging)
  }

  private fun readMemory(): MemoryState {
    val activityManager =
      reactContext.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager

    val info = ActivityManager.MemoryInfo()
    activityManager.getMemoryInfo(info)

    val totalMb = bytesToMb(info.totalMem)
    val availMb = bytesToMb(info.availMem)
    val usedMb = (totalMb - availMb).coerceAtLeast(0)

    return MemoryState(usedMb, totalMb.coerceAtLeast(1))
  }

  private fun readStorage(): StorageState {
    val path = Environment.getDataDirectory()
    val stat = StatFs(path.path)

    val blockSize = stat.blockSizeLong
    val totalBlocks = stat.blockCountLong
    val freeBlocks = stat.availableBlocksLong

    val totalMb = bytesToMb(totalBlocks * blockSize).coerceAtLeast(1)
    val freeMb = bytesToMb(freeBlocks * blockSize).coerceAtLeast(0)

    return StorageState(freeMb, totalMb)
  }

  private fun readThermalRisk(): String {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
      return "medium"
    }

    return try {
      val powerManager =
        reactContext.getSystemService(Context.POWER_SERVICE) as PowerManager

      when (powerManager.currentThermalStatus) {
        PowerManager.THERMAL_STATUS_NONE -> "low"
        PowerManager.THERMAL_STATUS_LIGHT -> "low"
        PowerManager.THERMAL_STATUS_MODERATE -> "medium"
        PowerManager.THERMAL_STATUS_SEVERE -> "high"
        PowerManager.THERMAL_STATUS_CRITICAL -> "critical"
        PowerManager.THERMAL_STATUS_EMERGENCY -> "critical"
        PowerManager.THERMAL_STATUS_SHUTDOWN -> "critical"
        else -> "medium"
      }
    } catch (_: Exception) {
      "medium"
    }
  }

  private fun readBleState(): BleState {
    return try {
      val manager =
        reactContext.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager

      val adapter: BluetoothAdapter? = manager.adapter

      BleState(
        available = adapter != null,
        enabled = adapter?.isEnabled == true
      )
    } catch (_: Exception) {
      BleState(available = false, enabled = false)
    }
  }

  private fun pressureFromMemory(usedMb: Long, totalMb: Long): String {
    if (totalMb <= 0) return "medium"

    val ratio = usedMb.toDouble() / totalMb.toDouble()

    return when {
      ratio >= 0.94 -> "critical"
      ratio >= 0.84 -> "high"
      ratio >= 0.68 -> "medium"
      else -> "low"
    }
  }

  private fun pressureFromStorage(freeMb: Long, totalMb: Long): String {
    if (totalMb <= 0) return "medium"

    val ratio = freeMb.toDouble() / totalMb.toDouble()

    return when {
      ratio <= 0.04 -> "critical"
      ratio <= 0.10 -> "high"
      ratio <= 0.22 -> "medium"
      else -> "low"
    }
  }

  private fun bytesToMb(value: Long): Long {
    return value / 1024L / 1024L
  }
}
KT

# ============================================================
# 2. Native package
# ============================================================

cat > "$PACKAGE_FILE" <<KT
package $TELEMETRY_PACKAGE

import com.facebook.react.ReactPackage
import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.uimanager.ViewManager

class MauriMeshHardwareTelemetryPackage : ReactPackage {
  override fun createNativeModules(
    reactContext: ReactApplicationContext
  ): MutableList<NativeModule> {
    return mutableListOf(MauriMeshHardwareTelemetryModule(reactContext))
  }

  override fun createViewManagers(
    reactContext: ReactApplicationContext
  ): MutableList<ViewManager<*, *>> {
    return mutableListOf()
  }
}
KT

# ============================================================
# 3. Patch MainApplication.kt/java
# ============================================================

if [ -n "$MAIN_KT" ]; then
  python3 <<PY
from pathlib import Path

path = Path("$MAIN_KT")
src = path.read_text()
import_line = "import $TELEMETRY_PACKAGE.MauriMeshHardwareTelemetryPackage"

if import_line not in src:
    lines = src.splitlines()
    insert_at = 0
    for i, line in enumerate(lines):
        if line.startswith("import "):
            insert_at = i + 1
    lines.insert(insert_at, import_line)
    src = "\\n".join(lines) + "\\n"

if "MauriMeshHardwareTelemetryPackage()" not in src:
    patterns = [
        "val packages = PackageList(this).packages",
        "val packages = PackageList(this).packages.apply",
        "val packages = PackageList(this).packages.toMutableList()",
    ]

    patched = False

    if "val packages = PackageList(this).packages" in src:
        src = src.replace(
            "val packages = PackageList(this).packages",
            "val packages = PackageList(this).packages\\n          packages.add(MauriMeshHardwareTelemetryPackage())"
        )
        patched = True

    if not patched and "PackageList(this).packages.apply" in src:
        src = src.replace(
            "PackageList(this).packages.apply {",
            "PackageList(this).packages.apply {\\n          add(MauriMeshHardwareTelemetryPackage())"
        )
        patched = True

    if not patched:
        marker = "return packages"
        if marker in src:
            src = src.replace(
                marker,
                "packages.add(MauriMeshHardwareTelemetryPackage())\\n          return packages"
            )
            patched = True

    if not patched:
        src += "\\n// TODO: Add MauriMeshHardwareTelemetryPackage() to getPackages() manually.\\n"

path.write_text(src)
PY
else
  python3 <<PY
from pathlib import Path

path = Path("$MAIN_JAVA")
src = path.read_text()
import_line = "import $TELEMETRY_PACKAGE.MauriMeshHardwareTelemetryPackage;"

if import_line not in src:
    lines = src.splitlines()
    insert_at = 0
    for i, line in enumerate(lines):
        if line.startswith("import "):
            insert_at = i + 1
    lines.insert(insert_at, import_line)
    src = "\\n".join(lines) + "\\n"

if "new MauriMeshHardwareTelemetryPackage()" not in src:
    if "packages.add(" in src or "List<ReactPackage> packages" in src:
        src = src.replace(
            "return packages;",
            "packages.add(new MauriMeshHardwareTelemetryPackage());\\n          return packages;"
        )
    else:
        src += "\\n// TODO: Add new MauriMeshHardwareTelemetryPackage() to getPackages() manually.\\n"

path.write_text(src)
PY
fi

# ============================================================
# 4. Checker
# ============================================================

cat > "$ROOT/check-maurimesh-android-kotlin-telemetry.sh" <<'CHECK'
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
DOCS="$ROOT/docs"
mkdir -p "$DOCS"

REPORT="$DOCS/maurimesh-android-kotlin-telemetry-report-$STAMP.md"
LATEST="$DOCS/maurimesh-android-kotlin-telemetry-report-latest.md"

PASS=0
FAIL=0
WARN=0

line(){ echo "$1" | tee -a "$REPORT"; }
pass(){ PASS=$((PASS+1)); line "- [x] $1"; }
fail(){ FAIL=$((FAIL+1)); line "- [ ] MISSING: $1"; }
warn(){ WARN=$((WARN+1)); line "- [!] PARTIAL: $1"; }

has_text_file(){ grep -R "$1" "$2" >/dev/null 2>&1; }

: > "$REPORT"

line "# MauriMesh Android Kotlin Telemetry Report"
line ""
line "Generated: $STAMP"
line ""

line "## Native Files"

MODULE_FILE="$(find "$ROOT/android/app/src/main" -name "MauriMeshHardwareTelemetryModule.kt" | head -1 || true)"
PACKAGE_FILE="$(find "$ROOT/android/app/src/main" -name "MauriMeshHardwareTelemetryPackage.kt" | head -1 || true)"
MAIN_FILE="$(find "$ROOT/android/app/src/main" \( -name "MainApplication.kt" -o -name "MainApplication.java" \) | head -1 || true)"

if [ -n "$MODULE_FILE" ]; then pass "Telemetry module exists: ${MODULE_FILE#$ROOT/}"; else fail "Telemetry module missing"; fi
if [ -n "$PACKAGE_FILE" ]; then pass "Telemetry package exists: ${PACKAGE_FILE#$ROOT/}"; else fail "Telemetry package missing"; fi
if [ -n "$MAIN_FILE" ]; then pass "MainApplication found: ${MAIN_FILE#$ROOT/}"; else fail "MainApplication missing"; fi

line ""
line "## Native Capabilities"

for token in \
  "MauriMeshHardwareTelemetry" \
  "getHardwareTelemetry" \
  "BatteryManager" \
  "ActivityManager" \
  "StatFs" \
  "PowerManager" \
  "BluetoothManager" \
  "memoryUsedMb" \
  "storageFreeMb" \
  "bleEnabled" \
  "thermalRisk"
do
  if [ -n "$MODULE_FILE" ] && has_text_file "$token" "$MODULE_FILE"; then
    pass "Capability found: $token"
  else
    fail "Capability missing: $token"
  fi
done

line ""
line "## Registration"

if [ -n "$MAIN_FILE" ] && has_text_file "MauriMeshHardwareTelemetryPackage" "$MAIN_FILE"; then
  pass "MainApplication references MauriMeshHardwareTelemetryPackage"
else
  warn "MainApplication registration not confirmed. Manual package add may be required."
fi

line ""
line "## JS Bridge Compatibility"

if has_text_file "MauriMeshHardwareTelemetry" "$ROOT/src/maurimesh/device-hardware/NativeHardwareTelemetry.ts"; then
  pass "JS bridge expects MauriMeshHardwareTelemetry"
else
  fail "JS bridge missing MauriMeshHardwareTelemetry"
fi

if has_text_file "NATIVE_ANDROID" "$ROOT/src/maurimesh/device-hardware/NativeHardwareTelemetry.ts"; then
  pass "JS bridge supports NATIVE_ANDROID source"
else
  fail "JS bridge missing NATIVE_ANDROID source"
fi

line ""
line "## TypeScript"

if npx tsc --noEmit >> "$REPORT" 2>&1; then
  pass "TypeScript passed"
else
  fail "TypeScript failed"
fi

TOTAL=$((PASS + FAIL + WARN))
if [ "$TOTAL" -gt 0 ]; then SCORE=$((PASS * 100 / TOTAL)); else SCORE=0; fi

if [ "$FAIL" -eq 0 ] && [ "$WARN" -eq 0 ]; then
  STATUS="COMPLETE"
elif [ "$FAIL" -eq 0 ]; then
  STATUS="COMPLETE_WITH_WARNINGS"
else
  STATUS="INCOMPLETE"
fi

line ""
line "## Summary"
line ""
line "- Total: $TOTAL"
line "- Complete: $PASS"
line "- Partial: $WARN"
line "- Missing/failed: $FAIL"
line "- Score: $SCORE%"
line "- Status: **$STATUS**"

cp "$REPORT" "$LATEST"

echo ""
echo "============================================================"
echo "ANDROID KOTLIN TELEMETRY CHECK COMPLETE"
echo "Status: $STATUS"
echo "Score:  $SCORE%"
echo "Report: $LATEST"
echo "============================================================"
echo ""

if [ "$FAIL" -gt 0 ]; then exit 1; fi
CHECK

chmod +x "$ROOT/check-maurimesh-android-kotlin-telemetry.sh"

# ============================================================
# 5. Docs
# ============================================================

cat > "$DOCS/maurimesh-android-kotlin-telemetry-$STAMP.md" <<MD
# MauriMesh Android Kotlin Telemetry Module

Generated: $STAMP

## Added

- MauriMeshHardwareTelemetryModule.kt
- MauriMeshHardwareTelemetryPackage.kt
- MainApplication registration patch
- Native battery telemetry
- Native memory telemetry
- Native storage telemetry
- Native thermal risk telemetry
- Native BLE adapter telemetry
- JS bridge compatibility with NativeHardwareTelemetry.ts

## Native module name

MauriMeshHardwareTelemetry

## JS method

getHardwareTelemetry()

## Truth

This reads device state from Android APIs.
It does not repair physical hardware.
It does not bypass Android restrictions.
It does not prove BLE message delivery by itself.
BLE proof still requires TX/RX/ACK logcat evidence.
MD

echo ""
echo "Running TypeScript..."
npx tsc --noEmit

echo ""
echo "Running Android Kotlin telemetry checker..."
./check-maurimesh-android-kotlin-telemetry.sh

echo ""
echo "============================================================"
echo "DONE: ANDROID KOTLIN TELEMETRY MODULE INSTALLED"
echo "============================================================"
echo "Backup:"
echo "  $BACKUP"
echo ""
echo "Created:"
echo "  $MODULE_FILE"
echo "  $PACKAGE_FILE"
echo "  check-maurimesh-android-kotlin-telemetry.sh"
echo ""
echo "Latest report:"
echo "  docs/maurimesh-android-kotlin-telemetry-report-latest.md"
echo ""
echo "Next APK proof:"
echo "  Build/install APK, open /native-telemetry, confirm source=NATIVE_ANDROID"
echo "============================================================"
