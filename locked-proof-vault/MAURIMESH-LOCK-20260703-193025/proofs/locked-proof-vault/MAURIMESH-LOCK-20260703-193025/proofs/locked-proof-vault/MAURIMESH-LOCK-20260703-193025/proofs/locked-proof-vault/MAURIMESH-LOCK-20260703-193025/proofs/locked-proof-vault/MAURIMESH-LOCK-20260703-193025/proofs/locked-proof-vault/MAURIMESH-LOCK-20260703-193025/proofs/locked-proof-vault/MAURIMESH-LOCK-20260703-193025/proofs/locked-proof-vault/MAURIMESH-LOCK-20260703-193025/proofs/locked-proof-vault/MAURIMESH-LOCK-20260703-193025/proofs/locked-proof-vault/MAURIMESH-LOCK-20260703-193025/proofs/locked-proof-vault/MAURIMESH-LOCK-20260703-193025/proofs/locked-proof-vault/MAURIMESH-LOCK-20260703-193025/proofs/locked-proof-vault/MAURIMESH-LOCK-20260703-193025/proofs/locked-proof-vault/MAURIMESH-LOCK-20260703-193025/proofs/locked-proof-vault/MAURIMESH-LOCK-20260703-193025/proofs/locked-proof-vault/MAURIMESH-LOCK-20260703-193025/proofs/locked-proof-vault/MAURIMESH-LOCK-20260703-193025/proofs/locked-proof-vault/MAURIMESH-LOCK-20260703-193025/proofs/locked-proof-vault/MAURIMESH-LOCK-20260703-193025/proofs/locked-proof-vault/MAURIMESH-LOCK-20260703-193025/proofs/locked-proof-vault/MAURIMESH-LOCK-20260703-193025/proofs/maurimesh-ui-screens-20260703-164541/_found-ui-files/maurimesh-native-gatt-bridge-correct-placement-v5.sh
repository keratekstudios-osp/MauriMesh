#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH NATIVE GATT BRIDGE CORRECT PLACEMENT v5"
echo "============================================================"
echo "Purpose:"
echo "- Undo wrong @ReactMethod placement if it landed in MainApplication.kt"
echo "- Put GATT bridge inside a real React Native module"
echo "- Register module only if needed"
echo "- Run TypeScript/export"
echo "- Attempt Gradle native compile gate"
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
PKG_DIR="$ROOT/android/app/src/main/java/com/maurimesh/messenger"
DOC_DIR="$ROOT/docs/native-ble-gatt"
ARCHIVE_DIR="$ROOT/archives/native-ble-gatt"
mkdir -p "$DOC_DIR" "$ARCHIVE_DIR" "$PKG_DIR"

REPORT="$DOC_DIR/NATIVE_GATT_BRIDGE_CORRECT_PLACEMENT_V5_${STAMP}.md"
LATEST="$DOC_DIR/NATIVE_GATT_BRIDGE_CORRECT_PLACEMENT_V5_LATEST.md"

if [ ! -d "$ROOT/android/app/src/main/java" ]; then
  echo "FAIL: android/app/src/main/java missing. Run from Replit project root."
  exit 1
fi

if [ ! -f "$ROOT/package.json" ]; then
  echo "FAIL: package.json missing. Run from Replit project root."
  exit 1
fi

echo "[1/9] Restoring MainApplication.kt if v4 bridge was inserted there..."
MAIN="$PKG_DIR/MainApplication.kt"

if [ -f "$MAIN" ] && grep -q "MM_GATT_BRIDGE_V4_BEGIN" "$MAIN"; then
  BACKUP="$(ls -1t "$MAIN".backup-native-gatt-bridge-v4* 2>/dev/null | head -n 1 || true)"

  if [ -n "$BACKUP" ] && [ -f "$BACKUP" ]; then
    cp "$MAIN" "$ARCHIVE_DIR/MainApplication.bad-v4-${STAMP}.kt"
    cp "$BACKUP" "$MAIN"
    echo "PASS: restored MainApplication.kt from backup:"
    echo "$BACKUP"
  else
    echo "WARN: MainApplication contains v4 bridge but no backup was found."
    echo "Attempting surgical removal."
    python3 - <<'PY'
from pathlib import Path
p = Path("android/app/src/main/java/com/maurimesh/messenger/MainApplication.kt")
t = p.read_text(errors="ignore")
start = t.find("  // MM_GATT_BRIDGE_V4_BEGIN")
end = t.find("  // MM_GATT_BRIDGE_V4_END")
if start != -1 and end != -1:
    end2 = t.find("\n", end)
    if end2 != -1:
        t = t[:start] + t[end2+1:]
        p.write_text(t)
        print("PASS: removed v4 bridge block surgically")
    else:
        print("FAIL: could not find end newline")
else:
    print("FAIL: markers not found for surgical removal")
PY
  fi
else
  echo "PASS: MainApplication.kt does not contain misplaced v4 bridge."
fi

echo ""
echo "[2/9] Creating dedicated native module + package..."
cat > "$PKG_DIR/MauriMeshNativeBlePacketModule.kt" <<'KOTLIN'
package com.maurimesh.messenger

import android.content.Context
import android.util.Log
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import java.lang.reflect.Modifier

class MauriMeshNativeBlePacketModule(
  private val reactContext: ReactApplicationContext
) : ReactContextBaseJavaModule(reactContext) {

  override fun getName(): String = "MauriMeshNativeBlePacket"

  @ReactMethod
  fun triggerGattPacketPayloadProof(packetId: String, promise: Promise) {
    val cleanPacketId = packetId.trim().ifEmpty { "MMN-NO-PACKET-ID" }

    Log.i(
      "MAURIMESH_NATIVE_BLE_GATT",
      "GATT_TRIGGER_NATIVE_METHOD_ENTERED | packetId=$cleanPacketId | module=MauriMeshNativeBlePacket | finalPassClaimed=false"
    )

    val result = Arguments.createMap()
    result.putString("packetId", cleanPacketId)
    result.putString("module", "MauriMeshNativeBlePacket")
    result.putString("method", "triggerGattPacketPayloadProof")
    result.putBoolean("nativeMethodEntered", true)
    result.putBoolean("finalPassClaimed", false)

    val helperResult = tryCallMauriMeshGattPacketProofHelper(cleanPacketId)
    result.putString("helperResult", helperResult)

    Log.i(
      "MAURIMESH_NATIVE_BLE_GATT",
      "GATT_TRIGGER_NATIVE_METHOD_RESULT | packetId=$cleanPacketId | helperResult=$helperResult | finalPassClaimed=false"
    )

    promise.resolve(result)
  }

  @ReactMethod
  fun triggerNativeGattPacketPayload(packetId: String, promise: Promise) {
    triggerGattPacketPayloadProof(packetId, promise)
  }

  @ReactMethod
  fun triggerGattPacketPayload(packetId: String, promise: Promise) {
    triggerGattPacketPayloadProof(packetId, promise)
  }

  @ReactMethod
  fun writeGattPacketProof(packetId: String, promise: Promise) {
    triggerGattPacketPayloadProof(packetId, promise)
  }

  @ReactMethod
  fun sendGattPacketProof(packetId: String, promise: Promise) {
    triggerGattPacketPayloadProof(packetId, promise)
  }

  @ReactMethod
  fun runGattPacketProof(packetId: String, promise: Promise) {
    triggerGattPacketPayloadProof(packetId, promise)
  }

  private fun tryCallMauriMeshGattPacketProofHelper(packetId: String): String {
    return try {
      val helperClass = Class.forName("com.maurimesh.messenger.MauriMeshGattPacketProof")

      val preferredNames = setOf(
        "triggerGattPacketPayloadProof",
        "triggerNativeGattPacketPayload",
        "triggerGattPacketPayload",
        "startGattPacketProof",
        "writeGattPacketProof",
        "sendGattPacketProof",
        "runGattPacketProof",
        "emitGattPacketPayloadProof",
        "emitGattPacketPayload",
        "emitRawPacketProofEvent",
        "logGattPacketPayload",
        "recordGattPacketPayload",
        "proveGattPacketPayload"
      )

      val preferredMethods = helperClass.declaredMethods
        .filter { method -> preferredNames.contains(method.name) }
        .sortedWith(compareBy({ it.parameterTypes.size }, { it.name }))

      val fallbackMethods = helperClass.declaredMethods
        .filter { method ->
          val lower = method.name.lowercase()
          (
            lower.contains("gatt") ||
              lower.contains("packet") ||
              lower.contains("payload") ||
              lower.contains("proof")
            ) && !preferredNames.contains(method.name)
        }
        .sortedWith(compareBy({ it.parameterTypes.size }, { it.name }))

      val methods = preferredMethods + fallbackMethods

      if (methods.isEmpty()) {
        val available = helperClass.declaredMethods
          .map { method -> method.name + "/" + method.parameterTypes.size }
          .distinct()
          .sorted()
          .joinToString(",")

        Log.w(
          "MAURIMESH_NATIVE_BLE_GATT",
          "GATT_HELPER_METHOD_MISSING | packetId=$packetId | availableMethods=$available | nativePacketBound=false"
        )

        return "HELPER_FOUND_METHOD_MISSING:$available"
      }

      val instance = getHelperInstance(helperClass)
      var lastError = ""

      for (method in methods) {
        try {
          method.isAccessible = true

          val target = if (Modifier.isStatic(method.modifiers)) {
            null
          } else {
            instance
          }

          if (target == null && !Modifier.isStatic(method.modifiers)) {
            lastError = "No usable INSTANCE/constructor for non-static method ${method.name}"
            continue
          }

          val args = buildArgsForMethod(method.parameterTypes, packetId) ?: continue
          method.invoke(target, *args)

          Log.i(
            "MAURIMESH_NATIVE_BLE_GATT",
            "GATT_HELPER_METHOD_CALLED | packetId=$packetId | helper=${method.name}/${method.parameterTypes.size} | nativePacketBound=false"
          )

          return "HELPER_CALLED:${method.name}/${method.parameterTypes.size}"
        } catch (error: Throwable) {
          lastError = error.message ?: error.toString()

          Log.w(
            "MAURIMESH_NATIVE_BLE_GATT",
            "GATT_HELPER_METHOD_CALL_ERROR | packetId=$packetId | helper=${method.name}/${method.parameterTypes.size} | error=$lastError | nativePacketBound=false"
          )
        }
      }

      Log.w(
        "MAURIMESH_NATIVE_BLE_GATT",
        "GATT_HELPER_CALL_FAILED | packetId=$packetId | lastError=$lastError | nativePacketBound=false"
      )

      "HELPER_CALL_FAILED:$lastError"
    } catch (error: Throwable) {
      val msg = error.message ?: error.toString()

      Log.w(
        "MAURIMESH_NATIVE_BLE_GATT",
        "GATT_HELPER_CLASS_UNAVAILABLE | packetId=$packetId | error=$msg | nativePacketBound=false"
      )

      "HELPER_CLASS_UNAVAILABLE:$msg"
    }
  }

  private fun getHelperInstance(helperClass: Class<*>): Any? {
    return try {
      helperClass.getField("INSTANCE").get(null)
    } catch (_: Throwable) {
      try {
        val constructor = helperClass.getDeclaredConstructor()
        constructor.isAccessible = true
        constructor.newInstance()
      } catch (_: Throwable) {
        null
      }
    }
  }

  private fun buildArgsForMethod(parameterTypes: Array<Class<*>>, packetId: String): Array<Any>? {
    val args = ArrayList<Any>()

    for ((index, type) in parameterTypes.withIndex()) {
      val typeName = type.name

      when {
        type == String::class.java -> {
          val value = when (index) {
            0 -> packetId
            1 -> "BUTTON_NATIVE_GATT_TRIGGER"
            2 -> "MauriMeshNativeBlePacket"
            else -> "MauriMesh"
          }
          args.add(value)
        }

        typeName == "android.content.Context" ||
          typeName == "com.facebook.react.bridge.ReactApplicationContext" ||
          Context::class.java.isAssignableFrom(type) -> {
          args.add(reactContext)
        }

        type == Boolean::class.javaPrimitiveType ||
          type == java.lang.Boolean::class.java -> {
          args.add(false)
        }

        type == Int::class.javaPrimitiveType ||
          type == java.lang.Integer::class.java -> {
          args.add(0)
        }

        type == Long::class.javaPrimitiveType ||
          type == java.lang.Long::class.java -> {
          args.add(System.currentTimeMillis())
        }

        else -> {
          return null
        }
      }
    }

    return args.toTypedArray()
  }
}
KOTLIN

cat > "$PKG_DIR/MauriMeshNativeBlePacketPackage.kt" <<'KOTLIN'
package com.maurimesh.messenger

import com.facebook.react.ReactPackage
import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.uimanager.ViewManager

class MauriMeshNativeBlePacketPackage : ReactPackage {
  override fun createNativeModules(reactContext: ReactApplicationContext): List<NativeModule> {
    return listOf(MauriMeshNativeBlePacketModule(reactContext))
  }

  override fun createViewManagers(reactContext: ReactApplicationContext): List<ViewManager<*, *>> {
    return emptyList()
  }
}
KOTLIN

echo "PASS: created:"
echo "$PKG_DIR/MauriMeshNativeBlePacketModule.kt"
echo "$PKG_DIR/MauriMeshNativeBlePacketPackage.kt"

echo ""
echo "[3/9] Registering package in MainApplication.kt..."
python3 - <<'PY'
from pathlib import Path
import shutil
import re
import sys

p = Path("android/app/src/main/java/com/maurimesh/messenger/MainApplication.kt")
if not p.exists():
    print("FAIL: MainApplication.kt missing")
    sys.exit(1)

t = p.read_text(errors="ignore")

if "MauriMeshNativeBlePacketPackage()" in t:
    print("PASS: MauriMeshNativeBlePacketPackage already registered")
    sys.exit(0)

backup = p.with_name(p.name + ".backup-register-native-ble-packet-package")
shutil.copy2(p, backup)

patterns = [
    r"(PackageList\(this\)\.packages\.apply\s*\{\s*)",
    r"(PackageList\(this\)\.packages\s*)",
]

patched = None

if "PackageList(this).packages.apply" in t:
    patched = re.sub(
        r"(PackageList\(this\)\.packages\.apply\s*\{\s*)",
        r"\1\n            add(MauriMeshNativeBlePacketPackage())\n",
        t,
        count=1,
    )
elif "PackageList(this).packages" in t:
    patched = t.replace(
        "PackageList(this).packages",
        "PackageList(this).packages.apply {\n            add(MauriMeshNativeBlePacketPackage())\n          }",
        1,
    )

if patched is None or patched == t:
    # Fallback for common RN MainApplication format.
    needle = "val packages = PackageList(this).packages"
    if needle in t:
        patched = t.replace(
            needle,
            needle + "\n          packages.add(MauriMeshNativeBlePacketPackage())",
            1,
        )

if patched is None or patched == t:
    print("FAIL: Could not auto-register package in MainApplication.kt.")
    print("Open MainApplication.kt and add MauriMeshNativeBlePacketPackage() to packages list.")
    sys.exit(2)

p.write_text(patched)
print("PASS: registered MauriMeshNativeBlePacketPackage()")
print(f"BACKUP: {backup}")
PY

echo ""
echo "[4/9] Checking for duplicate module registration risk..."
DUP_COUNT="$(grep -R "getName().*MauriMeshNativeBlePacket\|getName(): String = \"MauriMeshNativeBlePacket\"\|return \"MauriMeshNativeBlePacket\"" -n android/app/src/main/java | wc -l | tr -d ' ')"
echo "MauriMeshNativeBlePacket getName references: $DUP_COUNT"
grep -R "MauriMeshNativeBlePacket" -n android/app/src/main/java | tee "$ARCHIVE_DIR/native-ble-packet-references-${STAMP}.txt" || true

echo ""
echo "[5/9] Running TypeScript..."
npx tsc --noEmit

echo ""
echo "[6/9] Running Expo Android export..."
npx expo export --platform android

echo ""
echo "[7/9] Attempting native Android Gradle compile gate..."
GRADLE_STATUS="NOT_RUN"
GRADLE_LOG="$ARCHIVE_DIR/gradle-native-compile-${STAMP}.log"

if [ -d android ] && [ -f android/gradlew ]; then
  (
    cd android
    chmod +x ./gradlew
    ./gradlew :app:compileDebugKotlin :app:compileDebugJavaWithJavac --no-daemon
  ) > "$GRADLE_LOG" 2>&1 && GRADLE_STATUS="PASS" || GRADLE_STATUS="FAIL"
elif [ -d android ] && command -v gradle >/dev/null 2>&1; then
  (
    cd android
    gradle :app:compileDebugKotlin :app:compileDebugJavaWithJavac --no-daemon
  ) > "$GRADLE_LOG" 2>&1 && GRADLE_STATUS="PASS" || GRADLE_STATUS="FAIL"
else
  echo "WARN: Gradle wrapper not found. Skipping native compile gate."
  echo "Gradle wrapper not found." > "$GRADLE_LOG"
fi

echo "Gradle native compile gate: $GRADLE_STATUS"
if [ "$GRADLE_STATUS" = "FAIL" ]; then
  echo ""
  echo "Gradle failed. Last 80 lines:"
  tail -n 80 "$GRADLE_LOG" || true
  echo ""
  echo "Do not EAS build until this is fixed."
else
  echo "Gradle log: $GRADLE_LOG"
fi

echo ""
echo "[8/9] Creating Mac proof test script..."
MAC_TEST="$DOC_DIR/MAC_TEST_NATIVE_GATT_BRIDGE_V5_AFTER_INSTALL_${STAMP}.sh"

cat > "$MAC_TEST" <<'MAC'
#!/usr/bin/env bash
set -euo pipefail

A16="192.168.1.2:5555"
A06="192.168.1.5:5555"
S10="192.168.1.6:5555"
PKG="com.maurimesh.messenger"
OUT="$HOME/Desktop/maurimesh-gatt-bridge-v5-test-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$OUT"

echo ""
echo "============================================================"
echo "MAURIMESH NATIVE GATT BRIDGE v5 PHONE TEST"
echo "============================================================"
echo "Run on Mac Terminal after installing the new APK."
echo "Then press Reset Packet and Trigger Native GATT Packet Payload."
echo "============================================================"
echo ""

adb connect "$A16" || true
adb connect "$A06" || true
adb connect "$S10" || true
adb devices -l | tee "$OUT/adb-devices.txt"

for D in "$A16" "$A06" "$S10"; do
  adb -s "$D" logcat -c || true
done

adb -s "$A16" logcat -v time | grep -E "ReactNativeJS|MAURIMESH_NATIVE_BLE_GATT|BUTTON_PRESS|GATT_TRIGGER|GATT_HELPER|GATT_PACKET_PAYLOAD|GATT_CLIENT_WRITE_ATTEMPT|GATT_SERVER_WRITE_RECEIVED|nativePacketBound|AndroidRuntime|FATAL|Exception" | tee "$OUT/a16.log" &
adb -s "$A06" logcat -v time | grep -E "ReactNativeJS|MAURIMESH_NATIVE_BLE_GATT|BUTTON_PRESS|GATT_TRIGGER|GATT_HELPER|GATT_PACKET_PAYLOAD|GATT_CLIENT_WRITE_ATTEMPT|GATT_SERVER_WRITE_RECEIVED|nativePacketBound|AndroidRuntime|FATAL|Exception" | tee "$OUT/a06.log" &
adb -s "$S10" logcat -v time | grep -E "ReactNativeJS|MAURIMESH_NATIVE_BLE_GATT|BUTTON_PRESS|GATT_TRIGGER|GATT_HELPER|GATT_PACKET_PAYLOAD|GATT_CLIENT_WRITE_ATTEMPT|GATT_SERVER_WRITE_RECEIVED|nativePacketBound|AndroidRuntime|FATAL|Exception" | tee "$OUT/s10.log" &

echo ""
echo "Output: $OUT"
echo ""
echo "Now on phone:"
echo "1. Open Native BLE/GATT Truth Gate"
echo "2. Press Reset Packet"
echo "3. Press Trigger Native GATT Packet Payload"
echo ""
echo "After pressing, inspect:"
echo "grep -R \"BUTTON_PRESS\\|GATT_TRIGGER\\|GATT_HELPER\\|GATT_PACKET_PAYLOAD\\|GATT_CLIENT_WRITE_ATTEMPT\\|GATT_SERVER_WRITE_RECEIVED\\|nativePacketBound\" \"$OUT\""
echo ""

sleep 2
jobs || true
MAC

chmod +x "$MAC_TEST"

echo "Mac test script:"
echo "$MAC_TEST"

echo ""
echo "[9/9] Writing report..."
cat > "$REPORT" <<MD
# MauriMesh Native GATT Bridge Correct Placement v5

Timestamp: $STAMP

## Status

READY_CHECKED_WITH_NATIVE_COMPILE_GATE_ATTEMPTED

## Critical Correction

The previous v4 patch inserted React Native bridge methods into:

\`\`\`
MainApplication.kt
\`\`\`

That is usually the wrong location for \`@ReactMethod\`.

This v5 repair restores MainApplication if needed and places the bridge into a proper React Native native module:

\`\`\`
MauriMeshNativeBlePacketModule.kt
\`\`\`

Registered through:

\`\`\`
MauriMeshNativeBlePacketPackage.kt
\`\`\`

## Native Module Name

\`\`\`
MauriMeshNativeBlePacket
\`\`\`

## Methods Exposed

\`\`\`
triggerGattPacketPayloadProof
triggerNativeGattPacketPayload
triggerGattPacketPayload
writeGattPacketProof
sendGattPacketProof
runGattPacketProof
\`\`\`

## Expected Logcat After APK Install

Minimum bridge marker:

\`\`\`
GATT_TRIGGER_NATIVE_METHOD_ENTERED
\`\`\`

Helper marker:

\`\`\`
GATT_HELPER_METHOD_CALLED
\`\`\`

Final target markers:

\`\`\`
GATT_CLIENT_WRITE_ATTEMPT
GATT_PACKET_PAYLOAD
GATT_SERVER_WRITE_RECEIVED
nativePacketBound=true
\`\`\`

## Truth Rule

Final native BLE/GATT packet-bound PASS is not claimed by this patch.

Final PASS requires same packetId inside native BLE/GATT transport payload/log evidence across the physical device path.

## Gates

- TypeScript: PASS if command completed above.
- Expo Android export: PASS if command completed above.
- Gradle native compile gate: $GRADLE_STATUS

Gradle log:

\`\`\`
$GRADLE_LOG
\`\`\`

## Mac Test Script After APK Install

\`\`\`
$MAC_TEST
\`\`\`
MD

cp "$REPORT" "$LATEST"

echo ""
echo "============================================================"
echo "NATIVE GATT BRIDGE v5 COMPLETE"
echo "============================================================"
echo "Report: $REPORT"
echo "Latest: $LATEST"
echo "Gradle status: $GRADLE_STATUS"
echo "Mac test: $MAC_TEST"
echo "============================================================"

if [ "$GRADLE_STATUS" = "FAIL" ]; then
  echo ""
  echo "FINAL VERDICT: STOP_BEFORE_EAS_BUILD"
  echo "Reason: native Gradle compile failed."
  exit 3
fi

echo ""
echo "FINAL VERDICT: READY_FOR_EAS_APK_BUILD_IF_GRADLE_NOT_BLOCKED"
echo "Next:"
echo "1. Build new APK."
echo "2. Install on A16, A06, S10."
echo "3. Run Mac test script."
echo "4. Press Trigger Native GATT Packet Payload."
echo "============================================================"
