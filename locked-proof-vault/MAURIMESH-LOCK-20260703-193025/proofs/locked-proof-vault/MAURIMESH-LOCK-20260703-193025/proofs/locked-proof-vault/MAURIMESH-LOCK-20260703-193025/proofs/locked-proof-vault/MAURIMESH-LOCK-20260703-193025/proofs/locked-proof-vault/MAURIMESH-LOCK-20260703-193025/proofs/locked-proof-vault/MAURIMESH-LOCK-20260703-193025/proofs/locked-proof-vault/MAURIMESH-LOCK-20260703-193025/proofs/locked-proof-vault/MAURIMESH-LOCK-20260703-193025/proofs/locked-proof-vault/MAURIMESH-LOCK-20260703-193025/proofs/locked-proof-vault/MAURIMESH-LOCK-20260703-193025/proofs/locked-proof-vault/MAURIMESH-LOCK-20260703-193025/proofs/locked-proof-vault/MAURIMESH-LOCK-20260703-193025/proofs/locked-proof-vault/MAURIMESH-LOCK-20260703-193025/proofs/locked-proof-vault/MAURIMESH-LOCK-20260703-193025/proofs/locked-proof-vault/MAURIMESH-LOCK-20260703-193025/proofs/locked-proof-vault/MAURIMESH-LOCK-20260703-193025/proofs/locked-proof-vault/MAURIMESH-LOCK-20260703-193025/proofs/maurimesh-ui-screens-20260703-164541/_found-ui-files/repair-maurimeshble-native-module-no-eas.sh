#!/usr/bin/env bash
set -e

echo "=================================================="
echo "REPAIR MAURIMESH BLE NATIVE MODULE — NO EAS BUILD"
echo "Read-only getStatus bridge only"
echo "=================================================="

BACKUP="$HOME/maurimesh-router-backups/backup-before-maurimeshble-native-module-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP"
cp -R android "$BACKUP/android-current" 2>/dev/null || true

BASE="android/app/src/main/java/com/maurimesh/messenger"
MAIN="$BASE/MainApplication.kt"

if [ ! -f "$MAIN" ]; then
  echo "ERROR: MainApplication.kt not found at $MAIN"
  echo "Find it with:"
  echo "find android/app/src/main -name MainApplication.kt -print"
  exit 1
fi

mkdir -p "$BASE"

echo ""
echo "1. Create read-only MauriMeshBleModule.kt"

cat > "$BASE/MauriMeshBleModule.kt" <<'KT'
package com.maurimesh.messenger

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod

class MauriMeshBleModule(
  private val reactContext: ReactApplicationContext
) : ReactContextBaseJavaModule(reactContext) {

  override fun getName(): String {
    return "MauriMeshBle"
  }

  @ReactMethod
  fun getStatus(promise: Promise) {
    try {
      val status = Arguments.createMap()
      status.putString("module", "MauriMeshBle")
      status.putString("mode", "read_only")
      status.putBoolean("modulePresent", true)
      status.putBoolean("liveBleActive", false)
      status.putString(
        "truth",
        "Native module is registered. This method does not scan, advertise, connect, send, receive, ACK, or relay."
      )
      promise.resolve(status)
    } catch (error: Exception) {
      promise.reject("MAURIMESH_BLE_STATUS_ERROR", error)
    }
  }
}
KT

echo ""
echo "2. Create MauriMeshBlePackage.kt"

cat > "$BASE/MauriMeshBlePackage.kt" <<'KT'
package com.maurimesh.messenger

import com.facebook.react.ReactPackage
import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.uimanager.ViewManager

class MauriMeshBlePackage : ReactPackage {
  override fun createNativeModules(reactContext: ReactApplicationContext): List<NativeModule> {
    return listOf(MauriMeshBleModule(reactContext))
  }

  override fun createViewManagers(reactContext: ReactApplicationContext): List<ViewManager<*, *>> {
    return emptyList()
  }
}
KT

echo ""
echo "3. Register package in MainApplication.kt"

python3 <<'PY'
from pathlib import Path

main = Path("android/app/src/main/java/com/maurimesh/messenger/MainApplication.kt")
text = main.read_text()

if "MauriMeshBlePackage()" in text:
    print("MauriMeshBlePackage already registered.")
    raise SystemExit(0)

old = "PackageList(this).packages"
if old in text:
    text = text.replace(
        "PackageList(this).packages",
        "PackageList(this).packages.apply {\n        add(MauriMeshBlePackage())\n      }",
        1
    )
else:
    marker = "return packages"
    if marker in text:
        text = text.replace(
            marker,
            "packages.add(MauriMeshBlePackage())\n      return packages",
            1
        )
    else:
        raise SystemExit("ERROR: Could not find package registration block in MainApplication.kt")

main.write_text(text)
print("Registered MauriMeshBlePackage in MainApplication.kt")
PY

echo ""
echo "4. Verify native files"
grep -RniE "class MauriMeshBleModule|class MauriMeshBlePackage|getName\\(\\).*MauriMeshBle|MauriMeshBlePackage\\(\\)" android/app/src/main/java/com/maurimesh/messenger 2>/dev/null || true

echo ""
echo "5. Verify MainApplication package registration"
grep -n "PackageList(this).packages\|MauriMeshBlePackage" "$MAIN"

echo ""
echo "6. Verify Android permissions still exist"
grep -RniE "BLUETOOTH_SCAN|BLUETOOTH_CONNECT|BLUETOOTH_ADVERTISE|ACCESS_FINE_LOCATION|ACCESS_COARSE_LOCATION" android/app/src/main/AndroidManifest.xml android 2>/dev/null || true

echo ""
echo "7. JS/TypeScript check"
npx tsc --noEmit

echo ""
echo "8. Clean export check"
rm -rf dist .expo
npx expo export --platform android --clear

echo ""
echo "=================================================="
echo "MAURIMESH BLE NATIVE MODULE REPAIR READY — NO EAS BUILD USED"
echo "Backup: $BACKUP"
echo "Expected next APK result: Native Module PRESENT"
echo "=================================================="
