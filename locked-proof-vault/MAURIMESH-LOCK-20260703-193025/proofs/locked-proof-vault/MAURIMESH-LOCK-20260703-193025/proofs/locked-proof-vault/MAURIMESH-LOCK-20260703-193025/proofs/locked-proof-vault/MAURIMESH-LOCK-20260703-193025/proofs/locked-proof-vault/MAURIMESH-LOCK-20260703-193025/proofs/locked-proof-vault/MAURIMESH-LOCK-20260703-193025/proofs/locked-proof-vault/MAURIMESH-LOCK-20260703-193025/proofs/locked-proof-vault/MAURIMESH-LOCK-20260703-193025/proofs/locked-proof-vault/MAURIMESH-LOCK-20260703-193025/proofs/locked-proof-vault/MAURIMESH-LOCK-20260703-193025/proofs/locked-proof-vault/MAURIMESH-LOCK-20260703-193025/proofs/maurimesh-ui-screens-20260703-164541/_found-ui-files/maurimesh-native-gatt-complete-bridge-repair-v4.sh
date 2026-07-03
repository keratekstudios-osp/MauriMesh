#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH NATIVE GATT COMPLETE BRIDGE REPAIR v4"
echo "============================================================"
echo "Goal:"
echo "- Keep proof truth honest"
echo "- Expose missing Android native GATT trigger method"
echo "- Preserve existing code"
echo "- Add aliases React Native can call"
echo "- Produce build-gate report"
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
DOC_DIR="$ROOT/docs/native-ble-gatt"
ARCHIVE_DIR="$ROOT/archives/native-ble-gatt"
mkdir -p "$DOC_DIR" "$ARCHIVE_DIR" tools

REPORT="$DOC_DIR/NATIVE_GATT_COMPLETE_BRIDGE_REPAIR_V4_${STAMP}.md"
REPORT_LATEST="$DOC_DIR/NATIVE_GATT_COMPLETE_BRIDGE_REPAIR_V4_LATEST.md"
MAC_TEST="$DOC_DIR/MAC_TEST_AFTER_NATIVE_GATT_BRIDGE_INSTALL_${STAMP}.sh"

echo "[1/8] Checking project root..."
if [ ! -d "$ROOT/android/app/src/main/java" ]; then
  echo "FAIL: android/app/src/main/java not found."
  echo "You must run this in the Replit project root."
  exit 1
fi

if [ ! -f "$ROOT/package.json" ]; then
  echo "FAIL: package.json not found."
  echo "You must run this in the Replit project root."
  exit 1
fi

echo "PASS: project root looks valid: $ROOT"
echo ""

echo "[2/8] Patching Android native bridge..."
cat > /tmp/maurimesh_patch_native_gatt_bridge_v4.py <<'PY'
from pathlib import Path
import shutil
import sys

ROOT = Path(".").resolve()
JAVA_ROOT = ROOT / "android" / "app" / "src" / "main" / "java"

LOG = []

def read(p: Path) -> str:
    return p.read_text(encoding="utf-8", errors="ignore")

def write(p: Path, text: str) -> None:
    p.write_text(text, encoding="utf-8")

def find_module_file() -> Path | None:
    strong = []
    weak = []

    for p in JAVA_ROOT.rglob("*.kt"):
        t = read(p)
        if "MauriMeshNativeBlePacket" in t and "ReactContextBaseJavaModule" in t:
            strong.append(p)
        elif "MauriMeshNativeBlePacket" in t:
            weak.append(p)

    if strong:
        return strong[0]
    if weak:
        return weak[0]
    return None

target = find_module_file()
if target is None:
    print("FAIL: Could not find Kotlin module containing MauriMeshNativeBlePacket")
    print("Run this in Replit to inspect:")
    print('grep -R "MauriMeshNativeBlePacket" -n android/app/src/main/java')
    sys.exit(2)

text = read(target)

if "MM_GATT_BRIDGE_V4_BEGIN" in text:
    print(f"SKIP: v4 bridge already installed in {target}")
    print(f"TARGET={target}")
    sys.exit(0)

backup = target.with_name(target.name + ".backup-native-gatt-bridge-v4")
shutil.copy2(target, backup)

required_imports = [
    "import android.content.Context",
    "import android.util.Log",
    "import com.facebook.react.bridge.Arguments",
    "import com.facebook.react.bridge.Promise",
    "import com.facebook.react.bridge.ReactMethod",
    "import java.lang.reflect.Modifier",
]

lines = text.splitlines()
existing = {line.strip() for line in lines}
missing_imports = [imp for imp in required_imports if imp not in existing]

if missing_imports:
    package_index = -1
    last_import_index = -1

    for i, line in enumerate(lines):
        if line.startswith("package "):
            package_index = i
        if line.startswith("import "):
            last_import_index = i

    insert_at = last_import_index + 1 if last_import_index >= 0 else package_index + 1
    if insert_at < 0:
        insert_at = 0

    for imp in reversed(missing_imports):
        lines.insert(insert_at, imp)

text = "\n".join(lines)

method_block = r'''

  // MM_GATT_BRIDGE_V4_BEGIN
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
          args.add(reactApplicationContext)
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
  // MM_GATT_BRIDGE_V4_END
'''

insert_pos = text.rfind("\n}")
if insert_pos == -1:
    print(f"FAIL: Could not find final class brace in {target}")
    sys.exit(3)

patched = text[:insert_pos] + method_block + text[insert_pos:]
write(target, patched)

print(f"PATCHED={target}")
print(f"BACKUP={backup}")
PY

python3 /tmp/maurimesh_patch_native_gatt_bridge_v4.py | tee "$ARCHIVE_DIR/native-gatt-bridge-patch-${STAMP}.txt"

echo ""
echo "[3/8] Checking patched bridge markers..."
grep -R "MM_GATT_BRIDGE_V4_BEGIN\|triggerGattPacketPayloadProof\|GATT_TRIGGER_NATIVE_METHOD_ENTERED\|GATT_HELPER_METHOD_CALLED" -n android/app/src/main/java | tee "$ARCHIVE_DIR/native-gatt-bridge-grep-${STAMP}.txt" || true

echo ""
echo "[4/8] Checking Native BLE/GATT screen trigger names..."
if [ -f app/native-ble-gatt-proof.tsx ]; then
  grep -n "Trigger Native GATT Packet Payload\|BUTTON_PRESS_NATIVE_GATT_TRIGGER\|triggerGattPacketPayloadProof\|triggerNativeGattPacketPayload\|triggerGattPacketPayload" app/native-ble-gatt-proof.tsx || true
else
  echo "WARN: app/native-ble-gatt-proof.tsx not found"
fi

echo ""
echo "[5/8] Creating Mac test script for after APK install..."
cat > "$MAC_TEST" <<'MAC'
#!/usr/bin/env bash
set -euo pipefail

A16="192.168.1.2:5555"
A06="192.168.1.5:5555"
S10="192.168.1.6:5555"
PKG="com.maurimesh.messenger"

echo ""
echo "============================================================"
echo "MAURIMESH MAC TEST AFTER NATIVE GATT BRIDGE INSTALL"
echo "============================================================"
echo "Run this in Mac Terminal after installing the new APK."
echo "Then press: Trigger Native GATT Packet Payload"
echo "============================================================"
echo ""

adb connect "$A16" || true
adb connect "$A06" || true
adb connect "$S10" || true
adb devices -l

mkdir -p "$HOME/Desktop/maurimesh-gatt-bridge-test"

for D in "$A16" "$A06" "$S10"; do
  adb -s "$D" logcat -c || true
done

adb -s "$A16" logcat -v time | grep -E "ReactNativeJS|MAURIMESH_NATIVE_BLE_GATT|BUTTON_PRESS|GATT_TRIGGER|GATT_HELPER|GATT_PACKET_PAYLOAD|GATT_CLIENT_WRITE_ATTEMPT|GATT_SERVER_WRITE_RECEIVED|nativePacketBound|AndroidRuntime|FATAL|Exception" | tee "$HOME/Desktop/maurimesh-gatt-bridge-test/a16.log" &
adb -s "$A06" logcat -v time | grep -E "ReactNativeJS|MAURIMESH_NATIVE_BLE_GATT|BUTTON_PRESS|GATT_TRIGGER|GATT_HELPER|GATT_PACKET_PAYLOAD|GATT_CLIENT_WRITE_ATTEMPT|GATT_SERVER_WRITE_RECEIVED|nativePacketBound|AndroidRuntime|FATAL|Exception" | tee "$HOME/Desktop/maurimesh-gatt-bridge-test/a06.log" &
adb -s "$S10" logcat -v time | grep -E "ReactNativeJS|MAURIMESH_NATIVE_BLE_GATT|BUTTON_PRESS|GATT_TRIGGER|GATT_HELPER|GATT_PACKET_PAYLOAD|GATT_CLIENT_WRITE_ATTEMPT|GATT_SERVER_WRITE_RECEIVED|nativePacketBound|AndroidRuntime|FATAL|Exception" | tee "$HOME/Desktop/maurimesh-gatt-bridge-test/s10.log" &

echo ""
echo "Now on phone:"
echo "1. Open Native BLE/GATT Truth Gate."
echo "2. Press Reset Packet once."
echo "3. Press Trigger Native GATT Packet Payload once."
echo ""
echo "Expected minimum:"
echo "- BUTTON_PRESS_NATIVE_GATT_TRIGGER"
echo "- GATT_TRIGGER_NATIVE_METHOD_ENTERED"
echo ""
echo "Final target:"
echo "- GATT_CLIENT_WRITE_ATTEMPT"
echo "- GATT_PACKET_PAYLOAD"
echo "- GATT_SERVER_WRITE_RECEIVED"
echo ""

sleep 2
jobs || true

echo ""
echo "To inspect:"
echo 'grep -R "GATT_TRIGGER\|GATT_HELPER\|GATT_PACKET_PAYLOAD\|GATT_CLIENT_WRITE_ATTEMPT\|GATT_SERVER_WRITE_RECEIVED\|BUTTON_PRESS\|nativePacketBound" "$HOME/Desktop/maurimesh-gatt-bridge-test"'
MAC

chmod +x "$MAC_TEST"

echo "Mac test script created:"
echo "$MAC_TEST"

echo ""
echo "[6/8] Running TypeScript gate..."
npx tsc --noEmit

echo ""
echo "[7/8] Running Expo Android export gate..."
npx expo export --platform android

echo ""
echo "[8/8] Writing report..."
cat > "$REPORT" <<MD
# MauriMesh Native GATT Complete Bridge Repair v4

Timestamp: $STAMP

## Result

READY_FOR_NATIVE_GATT_BRIDGE_APK_BUILD

## What This Patch Fixes

The React Native layer previously reached:

\`\`\`
GATT_TRIGGER_MODULE_FOUND module=MauriMeshNativeBlePacket
GATT_TRIGGER_NATIVE_METHOD_MISSING
\`\`\`

This repair exposes the missing Android native bridge methods on the native module named:

\`\`\`
MauriMeshNativeBlePacket
\`\`\`

## Methods Added

\`\`\`
triggerGattPacketPayloadProof(packetId, promise)
triggerNativeGattPacketPayload(packetId, promise)
triggerGattPacketPayload(packetId, promise)
writeGattPacketProof(packetId, promise)
sendGattPacketProof(packetId, promise)
runGattPacketProof(packetId, promise)
\`\`\`

## Expected New Logcat Marker

\`\`\`
GATT_TRIGGER_NATIVE_METHOD_ENTERED
\`\`\`

## Helper Reflection

The bridge attempts to call:

\`\`\`
com.maurimesh.messenger.MauriMeshGattPacketProof
\`\`\`

and searches for helper methods related to:

\`\`\`
Gatt
Packet
Payload
Proof
\`\`\`

## Truth Rule Preserved

This patch does not fake final native BLE/GATT packet-bound PASS.

Final PASS still requires physical-device logcat evidence containing the same packetId with:

\`\`\`
GATT_CLIENT_WRITE_ATTEMPT
GATT_PACKET_PAYLOAD
GATT_SERVER_WRITE_RECEIVED
nativePacketBound=true
\`\`\`

## Validation Commands Run

\`\`\`
npx tsc --noEmit
npx expo export --platform android
\`\`\`

## Mac Test Script

After building and installing the new APK on A16, A06, and S10, run this in Mac Terminal:

\`\`\`
$MAC_TEST
\`\`\`

MD

cp "$REPORT" "$REPORT_LATEST"

echo ""
echo "============================================================"
echo "READY_FOR_NATIVE_GATT_BRIDGE_APK_BUILD"
echo "============================================================"
echo "Report:"
echo "$REPORT"
echo ""
echo "Latest:"
echo "$REPORT_LATEST"
echo ""
echo "Mac test script:"
echo "$MAC_TEST"
echo ""
echo "NEXT:"
echo "1. Build new APK with EAS."
echo "2. Install APK on A16, A06, S10."
echo "3. Run the Mac test script from Mac Terminal."
echo "4. Press Trigger Native GATT Packet Payload."
echo "============================================================"
