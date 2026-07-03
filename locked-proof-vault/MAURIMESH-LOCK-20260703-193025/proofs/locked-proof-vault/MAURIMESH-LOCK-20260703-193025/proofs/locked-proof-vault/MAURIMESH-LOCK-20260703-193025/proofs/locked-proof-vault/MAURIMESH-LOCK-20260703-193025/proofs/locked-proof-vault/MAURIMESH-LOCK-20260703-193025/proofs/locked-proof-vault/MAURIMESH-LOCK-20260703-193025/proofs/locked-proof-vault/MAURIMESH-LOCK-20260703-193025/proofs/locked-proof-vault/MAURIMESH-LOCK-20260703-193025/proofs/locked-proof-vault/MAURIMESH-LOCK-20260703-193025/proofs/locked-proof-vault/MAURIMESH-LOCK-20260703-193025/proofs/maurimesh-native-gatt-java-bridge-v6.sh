#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH NATIVE GATT JAVA BRIDGE v6"
echo "============================================================"
echo "Purpose:"
echo "- Remove duplicate Kotlin bridge files created by v5"
echo "- Patch existing Java native module instead"
echo "- Preserve existing registration"
echo "- Keep truth rule honest"
echo "- Run TypeScript/export"
echo "- Attempt native compile only if Java exists"
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
PKG_DIR="$ROOT/android/app/src/main/java/com/maurimesh/messenger"
DOC_DIR="$ROOT/docs/native-ble-gatt"
ARCHIVE_DIR="$ROOT/archives/native-ble-gatt"
mkdir -p "$DOC_DIR" "$ARCHIVE_DIR"

JAVA_MODULE="$PKG_DIR/MauriMeshNativeBlePacketModule.java"
JAVA_PACKAGE="$PKG_DIR/MauriMeshNativeBlePacketPackage.java"
KT_MODULE="$PKG_DIR/MauriMeshNativeBlePacketModule.kt"
KT_PACKAGE="$PKG_DIR/MauriMeshNativeBlePacketPackage.kt"

REPORT="$DOC_DIR/NATIVE_GATT_JAVA_BRIDGE_V6_${STAMP}.md"
LATEST="$DOC_DIR/NATIVE_GATT_JAVA_BRIDGE_V6_LATEST.md"

echo "[1/8] Checking required Java native files..."
if [ ! -f "$JAVA_MODULE" ]; then
  echo "FAIL: Java module not found:"
  echo "$JAVA_MODULE"
  exit 1
fi

if [ ! -f "$JAVA_PACKAGE" ]; then
  echo "FAIL: Java package not found:"
  echo "$JAVA_PACKAGE"
  exit 1
fi

echo "PASS: existing Java native module/package found."
echo ""

echo "[2/8] Backing up/removing duplicate Kotlin files from v5..."
if [ -f "$KT_MODULE" ]; then
  cp "$KT_MODULE" "$ARCHIVE_DIR/MauriMeshNativeBlePacketModule.kt.duplicate-v5-${STAMP}.bak"
  rm "$KT_MODULE"
  echo "REMOVED duplicate Kotlin module: $KT_MODULE"
else
  echo "PASS: no duplicate Kotlin module found."
fi

if [ -f "$KT_PACKAGE" ]; then
  cp "$KT_PACKAGE" "$ARCHIVE_DIR/MauriMeshNativeBlePacketPackage.kt.duplicate-v5-${STAMP}.bak"
  rm "$KT_PACKAGE"
  echo "REMOVED duplicate Kotlin package: $KT_PACKAGE"
else
  echo "PASS: no duplicate Kotlin package found."
fi

echo ""
echo "[3/8] Patching Java native module with missing GATT trigger methods..."
python3 - <<'PY'
from pathlib import Path
import shutil
import sys

p = Path("android/app/src/main/java/com/maurimesh/messenger/MauriMeshNativeBlePacketModule.java")

text = p.read_text(errors="ignore")

if "MM_GATT_JAVA_BRIDGE_V6_BEGIN" in text:
    print("SKIP: Java bridge v6 already installed.")
    sys.exit(0)

backup = p.with_name(p.name + ".backup-java-gatt-bridge-v6")
shutil.copy2(p, backup)

imports = [
    "import android.content.Context;",
    "import android.util.Log;",
    "import com.facebook.react.bridge.Arguments;",
    "import com.facebook.react.bridge.Promise;",
    "import com.facebook.react.bridge.ReactMethod;",
    "import com.facebook.react.bridge.WritableMap;",
    "import java.lang.reflect.Constructor;",
    "import java.lang.reflect.Method;",
    "import java.lang.reflect.Modifier;",
    "import java.util.ArrayList;",
    "import java.util.Arrays;",
    "import java.util.HashSet;",
    "import java.util.List;",
    "import java.util.Set;",
]

existing = set(line.strip() for line in text.splitlines())
lines = text.splitlines()

last_import = -1
package_line = -1
for i, line in enumerate(lines):
    if line.startswith("package "):
        package_line = i
    if line.startswith("import "):
        last_import = i

insert_at = last_import + 1 if last_import >= 0 else package_line + 1
if insert_at < 0:
    insert_at = 0

missing = [imp for imp in imports if imp not in existing]
for imp in reversed(missing):
    lines.insert(insert_at, imp)

text = "\n".join(lines)

method_block = r'''

  // MM_GATT_JAVA_BRIDGE_V6_BEGIN
  @ReactMethod
  public void triggerGattPacketPayloadProof(String packetId, Promise promise) {
    String cleanPacketId = packetId == null ? "MMN-NO-PACKET-ID" : packetId.trim();
    if (cleanPacketId.length() == 0) {
      cleanPacketId = "MMN-NO-PACKET-ID";
    }

    Log.i(
      "MAURIMESH_NATIVE_BLE_GATT",
      "GATT_TRIGGER_NATIVE_METHOD_ENTERED | packetId=" + cleanPacketId + " | module=MauriMeshNativeBlePacket | finalPassClaimed=false"
    );

    WritableMap result = Arguments.createMap();
    result.putString("packetId", cleanPacketId);
    result.putString("module", "MauriMeshNativeBlePacket");
    result.putString("method", "triggerGattPacketPayloadProof");
    result.putBoolean("nativeMethodEntered", true);
    result.putBoolean("finalPassClaimed", false);

    String helperResult = tryCallMauriMeshGattPacketProofHelper(cleanPacketId);
    result.putString("helperResult", helperResult);

    Log.i(
      "MAURIMESH_NATIVE_BLE_GATT",
      "GATT_TRIGGER_NATIVE_METHOD_RESULT | packetId=" + cleanPacketId + " | helperResult=" + helperResult + " | finalPassClaimed=false"
    );

    promise.resolve(result);
  }

  @ReactMethod
  public void triggerNativeGattPacketPayload(String packetId, Promise promise) {
    triggerGattPacketPayloadProof(packetId, promise);
  }

  @ReactMethod
  public void triggerGattPacketPayload(String packetId, Promise promise) {
    triggerGattPacketPayloadProof(packetId, promise);
  }

  @ReactMethod
  public void writeGattPacketProof(String packetId, Promise promise) {
    triggerGattPacketPayloadProof(packetId, promise);
  }

  @ReactMethod
  public void sendGattPacketProof(String packetId, Promise promise) {
    triggerGattPacketPayloadProof(packetId, promise);
  }

  @ReactMethod
  public void runGattPacketProof(String packetId, Promise promise) {
    triggerGattPacketPayloadProof(packetId, promise);
  }

  private String tryCallMauriMeshGattPacketProofHelper(String packetId) {
    try {
      Class<?> helperClass = Class.forName("com.maurimesh.messenger.MauriMeshGattPacketProof");

      Set<String> preferredNames = new HashSet<>(
        Arrays.asList(
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
      );

      List<Method> methods = new ArrayList<>();

      for (Method method : helperClass.getDeclaredMethods()) {
        if (preferredNames.contains(method.getName())) {
          methods.add(method);
        }
      }

      for (Method method : helperClass.getDeclaredMethods()) {
        String lower = method.getName().toLowerCase();
        boolean looksRelevant =
          lower.contains("gatt") ||
          lower.contains("packet") ||
          lower.contains("payload") ||
          lower.contains("proof");

        if (looksRelevant && !preferredNames.contains(method.getName())) {
          methods.add(method);
        }
      }

      if (methods.size() == 0) {
        StringBuilder available = new StringBuilder();
        for (Method method : helperClass.getDeclaredMethods()) {
          if (available.length() > 0) {
            available.append(",");
          }
          available.append(method.getName()).append("/").append(method.getParameterTypes().length);
        }

        Log.w(
          "MAURIMESH_NATIVE_BLE_GATT",
          "GATT_HELPER_METHOD_MISSING | packetId=" + packetId + " | availableMethods=" + available + " | nativePacketBound=false"
        );

        return "HELPER_FOUND_METHOD_MISSING:" + available;
      }

      Object instance = getHelperInstance(helperClass);
      String lastError = "";

      for (Method method : methods) {
        try {
          method.setAccessible(true);

          Object target = Modifier.isStatic(method.getModifiers()) ? null : instance;
          if (target == null && !Modifier.isStatic(method.getModifiers())) {
            lastError = "No usable INSTANCE/constructor for non-static method " + method.getName();
            continue;
          }

          Object[] args = buildArgsForMethod(method.getParameterTypes(), packetId);
          if (args == null) {
            continue;
          }

          method.invoke(target, args);

          Log.i(
            "MAURIMESH_NATIVE_BLE_GATT",
            "GATT_HELPER_METHOD_CALLED | packetId=" + packetId + " | helper=" + method.getName() + "/" + method.getParameterTypes().length + " | nativePacketBound=false"
          );

          return "HELPER_CALLED:" + method.getName() + "/" + method.getParameterTypes().length;
        } catch (Throwable error) {
          lastError = error.getMessage() == null ? error.toString() : error.getMessage();

          Log.w(
            "MAURIMESH_NATIVE_BLE_GATT",
            "GATT_HELPER_METHOD_CALL_ERROR | packetId=" + packetId + " | helper=" + method.getName() + "/" + method.getParameterTypes().length + " | error=" + lastError + " | nativePacketBound=false"
          );
        }
      }

      Log.w(
        "MAURIMESH_NATIVE_BLE_GATT",
        "GATT_HELPER_CALL_FAILED | packetId=" + packetId + " | lastError=" + lastError + " | nativePacketBound=false"
      );

      return "HELPER_CALL_FAILED:" + lastError;
    } catch (Throwable error) {
      String msg = error.getMessage() == null ? error.toString() : error.getMessage();

      Log.w(
        "MAURIMESH_NATIVE_BLE_GATT",
        "GATT_HELPER_CLASS_UNAVAILABLE | packetId=" + packetId + " | error=" + msg + " | nativePacketBound=false"
      );

      return "HELPER_CLASS_UNAVAILABLE:" + msg;
    }
  }

  private Object getHelperInstance(Class<?> helperClass) {
    try {
      return helperClass.getField("INSTANCE").get(null);
    } catch (Throwable ignored) {
      try {
        Constructor<?> constructor = helperClass.getDeclaredConstructor();
        constructor.setAccessible(true);
        return constructor.newInstance();
      } catch (Throwable ignoredAgain) {
        return null;
      }
    }
  }

  private Object[] buildArgsForMethod(Class<?>[] parameterTypes, String packetId) {
    Object[] args = new Object[parameterTypes.length];

    for (int i = 0; i < parameterTypes.length; i++) {
      Class<?> type = parameterTypes[i];
      String typeName = type.getName();

      if (type == String.class) {
        if (i == 0) {
          args[i] = packetId;
        } else if (i == 1) {
          args[i] = "BUTTON_NATIVE_GATT_TRIGGER";
        } else if (i == 2) {
          args[i] = "MauriMeshNativeBlePacket";
        } else {
          args[i] = "MauriMesh";
        }
      } else if (
        typeName.equals("android.content.Context") ||
        typeName.equals("com.facebook.react.bridge.ReactApplicationContext") ||
        Context.class.isAssignableFrom(type)
      ) {
        args[i] = getReactApplicationContext();
      } else if (type == Boolean.TYPE || type == Boolean.class) {
        args[i] = false;
      } else if (type == Integer.TYPE || type == Integer.class) {
        args[i] = 0;
      } else if (type == Long.TYPE || type == Long.class) {
        args[i] = System.currentTimeMillis();
      } else {
        return null;
      }
    }

    return args;
  }
  // MM_GATT_JAVA_BRIDGE_V6_END
'''

insert_pos = text.rfind("\n}")
if insert_pos == -1:
    print("FAIL: Could not find final class brace in Java module.")
    sys.exit(2)

text = text[:insert_pos] + method_block + text[insert_pos:]
p.write_text(text)

print("PATCHED: " + str(p))
print("BACKUP: " + str(backup))
PY

echo ""
echo "[4/8] Verifying bridge placement..."
grep -R "MM_GATT_JAVA_BRIDGE_V6_BEGIN\|GATT_TRIGGER_NATIVE_METHOD_ENTERED\|triggerGattPacketPayloadProof" -n "$JAVA_MODULE" || true

echo ""
echo "[5/8] Checking duplicate class files are gone..."
find "$PKG_DIR" -maxdepth 1 \( -name "MauriMeshNativeBlePacketModule.*" -o -name "MauriMeshNativeBlePacketPackage.*" \) -print | sort

echo ""
echo "[6/8] Running TypeScript and Expo export..."
npx tsc --noEmit
npx expo export --platform android

echo ""
echo "[7/8] Attempting native compile only if Java exists..."
GRADLE_STATUS="SKIPPED_JAVA_NOT_AVAILABLE"
GRADLE_LOG="$ARCHIVE_DIR/gradle-java-bridge-v6-${STAMP}.log"

if command -v java >/dev/null 2>&1 && [ -x android/gradlew ]; then
  (
    cd android
    ./gradlew :app:compileDebugJavaWithJavac :app:compileDebugKotlin --no-daemon
  ) > "$GRADLE_LOG" 2>&1 && GRADLE_STATUS="PASS" || GRADLE_STATUS="FAIL"
else
  echo "Java/Gradle not available in this Replit runtime. EAS cloud build will be the native compile gate." | tee "$GRADLE_LOG"
fi

echo "Native compile status: $GRADLE_STATUS"

if [ "$GRADLE_STATUS" = "FAIL" ]; then
  echo ""
  echo "Gradle failed. Last 80 lines:"
  tail -n 80 "$GRADLE_LOG" || true
fi

echo ""
echo "[8/8] Writing report and Mac test script..."
MAC_TEST="$DOC_DIR/MAC_TEST_NATIVE_GATT_JAVA_BRIDGE_V6_AFTER_INSTALL_${STAMP}.sh"

cat > "$MAC_TEST" <<'MAC'
#!/usr/bin/env bash
set -euo pipefail

A16="192.168.1.2:5555"
A06="192.168.1.5:5555"
S10="192.168.1.6:5555"
PKG="com.maurimesh.messenger"
OUT="$HOME/Desktop/maurimesh-gatt-java-bridge-v6-test-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$OUT"

echo ""
echo "============================================================"
echo "MAURIMESH NATIVE GATT JAVA BRIDGE v6 PHONE TEST"
echo "============================================================"
echo "Run this in Mac Terminal after new APK install."
echo "============================================================"

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
echo "On phone:"
echo "1. Open Native BLE/GATT Truth Gate"
echo "2. Press Reset Packet"
echo "3. Press Trigger Native GATT Packet Payload"
echo ""
echo "Inspect after pressing:"
echo "grep -R \"BUTTON_PRESS\\|GATT_TRIGGER\\|GATT_HELPER\\|GATT_PACKET_PAYLOAD\\|GATT_CLIENT_WRITE_ATTEMPT\\|GATT_SERVER_WRITE_RECEIVED\\|nativePacketBound\" \"$OUT\""
echo ""

sleep 2
jobs || true
MAC

chmod +x "$MAC_TEST"

cat > "$REPORT" <<MD
# MauriMesh Native GATT Java Bridge v6

Timestamp: $STAMP

## Result

JAVA_NATIVE_MODULE_PATCHED

## Why v6 Was Required

v5 created Kotlin files with class names that already existed as Java files:

\`\`\`
MauriMeshNativeBlePacketModule.java
MauriMeshNativeBlePacketPackage.java
MauriMeshNativeBlePacketModule.kt
MauriMeshNativeBlePacketPackage.kt
\`\`\`

That is a duplicate-class risk.

v6 removes the duplicate Kotlin files and patches the existing Java module.

## Patched File

\`\`\`
$JAVA_MODULE
\`\`\`

## Expected New Marker After APK Install

\`\`\`
GATT_TRIGGER_NATIVE_METHOD_ENTERED
\`\`\`

## Final Target Markers

\`\`\`
GATT_CLIENT_WRITE_ATTEMPT
GATT_PACKET_PAYLOAD
GATT_SERVER_WRITE_RECEIVED
nativePacketBound=true
\`\`\`

## Truth Rule

Final native BLE/GATT packet-bound PASS is not claimed by this patch.

Final PASS requires the same packetId inside required native GATT payload/log evidence across the physical device path.

## Gates

- TypeScript: completed if script reached report.
- Expo Android export: completed if script reached report.
- Native compile: $GRADLE_STATUS
- Gradle log: $GRADLE_LOG

## Mac Test Script After APK Install

\`\`\`
$MAC_TEST
\`\`\`
MD

cp "$REPORT" "$LATEST"

echo ""
echo "============================================================"
echo "NATIVE GATT JAVA BRIDGE v6 COMPLETE"
echo "============================================================"
echo "Report: $REPORT"
echo "Latest: $LATEST"
echo "Native compile status: $GRADLE_STATUS"
echo "Mac test script: $MAC_TEST"
echo "============================================================"

if [ "$GRADLE_STATUS" = "FAIL" ]; then
  echo "FINAL VERDICT: STOP_BEFORE_EAS_BUILD"
  exit 3
fi

echo "FINAL VERDICT: READY_FOR_EAS_CLOUD_NATIVE_BUILD_GATE"
echo "Next: build APK with EAS, install on all phones, then run Mac test script."
echo "============================================================"
