#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH NATIVE GATT REGISTRATION DIAGNOSTICS v7"
echo "============================================================"
echo "Purpose:"
echo "- Prove whether MainApplication loads MauriMeshNativeBlePacketPackage"
echo "- Add runtime registration logs"
echo "- Add package createNativeModules logs"
echo "- Add module constructor/getName logs"
echo "- Keep v6 trigger bridge"
echo "- Produce EAS-ready build gate"
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
PKG_DIR="$ROOT/android/app/src/main/java/com/maurimesh/messenger"
DOC_DIR="$ROOT/docs/native-ble-gatt"
ARCHIVE_DIR="$ROOT/archives/native-ble-gatt"
mkdir -p "$DOC_DIR" "$ARCHIVE_DIR"

MAIN="$PKG_DIR/MainApplication.kt"
JAVA_MODULE="$PKG_DIR/MauriMeshNativeBlePacketModule.java"
JAVA_PACKAGE="$PKG_DIR/MauriMeshNativeBlePacketPackage.java"

REPORT="$DOC_DIR/NATIVE_GATT_REGISTRATION_DIAGNOSTICS_V7_${STAMP}.md"
LATEST="$DOC_DIR/NATIVE_GATT_REGISTRATION_DIAGNOSTICS_V7_LATEST.md"

echo "[1/8] Checking required files..."
for f in "$MAIN" "$JAVA_MODULE" "$JAVA_PACKAGE"; do
  if [ ! -f "$f" ]; then
    echo "FAIL: missing $f"
    exit 1
  fi
  echo "PASS: $f"
done

echo ""
echo "[2/8] Backing up files..."
cp "$MAIN" "$ARCHIVE_DIR/MainApplication.kt.before-registration-v7-${STAMP}.bak"
cp "$JAVA_MODULE" "$ARCHIVE_DIR/MauriMeshNativeBlePacketModule.java.before-registration-v7-${STAMP}.bak"
cp "$JAVA_PACKAGE" "$ARCHIVE_DIR/MauriMeshNativeBlePacketPackage.java.before-registration-v7-${STAMP}.bak"

echo ""
echo "[3/8] Patching MainApplication.kt with explicit registration + log..."
python3 - <<'PY'
from pathlib import Path
import re
import sys

p = Path("android/app/src/main/java/com/maurimesh/messenger/MainApplication.kt")
t = p.read_text(errors="ignore")

if "MM_GATT_REGISTRATION_V7" not in t:
    if "import android.util.Log" not in t:
        lines = t.splitlines()
        insert_at = 0
        for i, line in enumerate(lines):
            if line.startswith("import "):
                insert_at = i + 1
        lines.insert(insert_at, "import android.util.Log")
        t = "\n".join(lines)

# Remove obvious duplicate add lines if any.
t = re.sub(r'\n\s*add\(MauriMeshNativeBlePacketPackage\(\)\)\s*', '\n', t)
t = re.sub(r'\n\s*packages\.add\(MauriMeshNativeBlePacketPackage\(\)\)\s*', '\n', t)

if "MauriMeshNativeBlePacketPackage()" in t and "MM_GATT_REGISTRATION_V7" in t:
    p.write_text(t)
    print("SKIP: v7 registration already present.")
    sys.exit(0)

# Preferred RN/Expo Kotlin pattern:
# PackageList(this).packages.apply { ... }
if "PackageList(this).packages.apply" in t:
    t = re.sub(
        r'(PackageList\(this\)\.packages\.apply\s*\{\s*)',
        r'\1\n            Log.i("MAURIMESH_NATIVE_BLE_GATT", "GATT_PACKAGE_REGISTRATION_V7 | source=MainApplication | action=add_package | module=MauriMeshNativeBlePacket | finalPassClaimed=false")\n            add(MauriMeshNativeBlePacketPackage())\n',
        t,
        count=1,
    )
elif "PackageList(this).packages" in t:
    # Converts PackageList(this).packages into PackageList(this).packages.apply { add(...) }
    t = t.replace(
        "PackageList(this).packages",
        'PackageList(this).packages.apply {\n            Log.i("MAURIMESH_NATIVE_BLE_GATT", "GATT_PACKAGE_REGISTRATION_V7 | source=MainApplication | action=add_package | module=MauriMeshNativeBlePacket | finalPassClaimed=false")\n            add(MauriMeshNativeBlePacketPackage())\n          }',
        1,
    )
else:
    print("FAIL: Could not find PackageList(this).packages pattern in MainApplication.kt")
    print("Print file manually:")
    print("sed -n '1,160p' android/app/src/main/java/com/maurimesh/messenger/MainApplication.kt")
    sys.exit(2)

p.write_text(t)
print("PASS: MainApplication v7 registration patch written.")
PY

echo ""
echo "[4/8] Rewriting Java package with diagnostic logs..."
cat > "$JAVA_PACKAGE" <<'JAVA'
package com.maurimesh.messenger;

import android.util.Log;
import com.facebook.react.ReactPackage;
import com.facebook.react.bridge.NativeModule;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.uimanager.ViewManager;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public class MauriMeshNativeBlePacketPackage implements ReactPackage {
  @Override
  public List<NativeModule> createNativeModules(ReactApplicationContext reactContext) {
    Log.i(
      "MAURIMESH_NATIVE_BLE_GATT",
      "GATT_PACKAGE_CREATE_NATIVE_MODULES_V7 | package=MauriMeshNativeBlePacketPackage | module=MauriMeshNativeBlePacket | finalPassClaimed=false"
    );

    List<NativeModule> modules = new ArrayList<>();
    modules.add(new MauriMeshNativeBlePacketModule(reactContext));

    Log.i(
      "MAURIMESH_NATIVE_BLE_GATT",
      "GATT_PACKAGE_MODULE_ADDED_V7 | package=MauriMeshNativeBlePacketPackage | count=" + modules.size() + " | module=MauriMeshNativeBlePacket | finalPassClaimed=false"
    );

    return modules;
  }

  @Override
  public List<ViewManager> createViewManagers(ReactApplicationContext reactContext) {
    return Collections.emptyList();
  }
}
JAVA

echo "PASS: Java package rewritten with v7 logs."

echo ""
echo "[5/8] Patching Java module constructor/getName diagnostics while preserving v6 bridge..."
python3 - <<'PY'
from pathlib import Path
import re
import sys

p = Path("android/app/src/main/java/com/maurimesh/messenger/MauriMeshNativeBlePacketModule.java")
t = p.read_text(errors="ignore")

if "import android.util.Log;" not in t:
    t = t.replace("package com.maurimesh.messenger;", "package com.maurimesh.messenger;\n\nimport android.util.Log;", 1)

if "MM_GATT_JAVA_BRIDGE_V6_BEGIN" not in t:
    print("FAIL: v6 trigger bridge marker missing from Java module. Do not continue.")
    sys.exit(1)

# Add constructor log after super(reactContext); if not already present.
if "GATT_MODULE_CONSTRUCTOR_V7" not in t:
    t = re.sub(
        r'(super\s*\(\s*reactContext\s*\)\s*;)',
        r'\1\n    Log.i("MAURIMESH_NATIVE_BLE_GATT", "GATT_MODULE_CONSTRUCTOR_V7 | module=MauriMeshNativeBlePacket | finalPassClaimed=false");',
        t,
        count=1,
    )

# Patch getName method to log, handling common one-line return.
if "GATT_MODULE_GET_NAME_V7" not in t:
    # Pattern: public String getName() { return "MauriMeshNativeBlePacket"; }
    t2 = re.sub(
        r'public\s+String\s+getName\s*\(\s*\)\s*\{\s*return\s+"MauriMeshNativeBlePacket"\s*;\s*\}',
        'public String getName() {\n    Log.i("MAURIMESH_NATIVE_BLE_GATT", "GATT_MODULE_GET_NAME_V7 | module=MauriMeshNativeBlePacket | finalPassClaimed=false");\n    return "MauriMeshNativeBlePacket";\n  }',
        t,
        count=1,
        flags=re.S,
    )
    if t2 == t:
        # Pattern: return line inside method.
        t2 = t.replace(
            'return "MauriMeshNativeBlePacket";',
            'Log.i("MAURIMESH_NATIVE_BLE_GATT", "GATT_MODULE_GET_NAME_V7 | module=MauriMeshNativeBlePacket | finalPassClaimed=false");\n    return "MauriMeshNativeBlePacket";',
            1,
        )
    t = t2

p.write_text(t)
print("PASS: Java module v7 diagnostics patched.")
PY

echo ""
echo "[6/8] Verifying v7 markers..."
grep -R "GATT_PACKAGE_REGISTRATION_V7\|GATT_PACKAGE_CREATE_NATIVE_MODULES_V7\|GATT_MODULE_CONSTRUCTOR_V7\|GATT_MODULE_GET_NAME_V7\|GATT_TRIGGER_NATIVE_METHOD_ENTERED" -n \
  "$MAIN" "$JAVA_PACKAGE" "$JAVA_MODULE" || true

echo ""
echo "[7/8] Running JS gates..."
npx tsc --noEmit
npx expo export --platform android

echo ""
echo "[8/8] Writing report + Mac runtime test..."
MAC_TEST="$DOC_DIR/MAC_TEST_NATIVE_GATT_REGISTRATION_V7_AFTER_INSTALL_${STAMP}.sh"

cat > "$MAC_TEST" <<'MAC'
#!/usr/bin/env bash
set -euo pipefail

PKG="com.maurimesh.messenger"
A16="${1:-RF8Y303XPFM}"
OUT="$HOME/Desktop/maurimesh-gatt-registration-v7-test-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$OUT"

echo ""
echo "============================================================"
echo "MAURIMESH GATT REGISTRATION v7 A16 TEST"
echo "============================================================"
echo "Device: $A16"
echo "Output: $OUT"
echo "============================================================"

adb devices -l | tee "$OUT/adb-devices.txt"

adb -s "$A16" shell am force-stop "$PKG" || true
adb -s "$A16" logcat -c || true
adb -s "$A16" shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 >/dev/null

sleep 3

LOG="$OUT/a16-registration-v7.log"

adb -s "$A16" logcat -v time | grep -E "ReactNativeJS|MAURIMESH_NATIVE_BLE_GATT|GATT_PACKAGE_REGISTRATION_V7|GATT_PACKAGE_CREATE_NATIVE_MODULES_V7|GATT_PACKAGE_MODULE_ADDED_V7|GATT_MODULE_CONSTRUCTOR_V7|GATT_MODULE_GET_NAME_V7|BUTTON_PRESS|GATT_TRIGGER|GATT_HELPER|NATIVE_GATT_TRIGGER_UNAVAILABLE|NativeModules|GATT_PACKET_PAYLOAD|GATT_CLIENT_WRITE_ATTEMPT|GATT_SERVER_WRITE_RECEIVED|nativePacketBound|AndroidRuntime|FATAL|Exception" | tee "$LOG" &
PID=$!

echo ""
echo "ACTION NOW:"
echo "1. Open Native BLE/GATT Truth Gate"
echo "2. Press Reset Packet"
echo "3. Press Trigger Native GATT Packet Payload"
echo "4. Wait 5 seconds"
echo "5. Press ENTER here"
read -r _

sleep 2
kill "$PID" 2>/dev/null || true

echo ""
echo "============================================================"
echo "REGISTRATION v7 RESULT"
echo "============================================================"
grep -E "GATT_PACKAGE_REGISTRATION_V7|GATT_PACKAGE_CREATE_NATIVE_MODULES_V7|GATT_PACKAGE_MODULE_ADDED_V7|GATT_MODULE_CONSTRUCTOR_V7|GATT_MODULE_GET_NAME_V7|BUTTON_PRESS|GATT_TRIGGER|GATT_HELPER|NATIVE_GATT_TRIGGER_UNAVAILABLE|NativeModules|GATT_PACKET_PAYLOAD|GATT_CLIENT_WRITE_ATTEMPT|GATT_SERVER_WRITE_RECEIVED|nativePacketBound" "$LOG" || true

echo ""
echo "Counts:"
echo "REGISTRATION: $(grep -c 'GATT_PACKAGE_REGISTRATION_V7' "$LOG" 2>/dev/null || echo 0)"
echo "CREATE_MODULES: $(grep -c 'GATT_PACKAGE_CREATE_NATIVE_MODULES_V7' "$LOG" 2>/dev/null || echo 0)"
echo "MODULE_CONSTRUCTOR: $(grep -c 'GATT_MODULE_CONSTRUCTOR_V7' "$LOG" 2>/dev/null || echo 0)"
echo "GET_NAME: $(grep -c 'GATT_MODULE_GET_NAME_V7' "$LOG" 2>/dev/null || echo 0)"
echo "TRIGGER_ENTERED: $(grep -c 'GATT_TRIGGER_NATIVE_METHOD_ENTERED' "$LOG" 2>/dev/null || echo 0)"
echo "UNAVAILABLE: $(grep -c 'NATIVE_GATT_TRIGGER_UNAVAILABLE\|Native GATT trigger unavailable' "$LOG" 2>/dev/null || echo 0)"

echo ""
if grep -q "GATT_TRIGGER_NATIVE_METHOD_ENTERED" "$LOG"; then
  echo "VERDICT: NATIVE_MODULE_REGISTERED_AND_TRIGGER_ENTERED"
elif grep -q "GATT_PACKAGE_CREATE_NATIVE_MODULES_V7" "$LOG"; then
  echo "VERDICT: PACKAGE_LOADED_BUT_JS_STILL_NOT_CALLING_MODULE"
elif grep -q "GATT_PACKAGE_REGISTRATION_V7" "$LOG"; then
  echo "VERDICT: MAINAPPLICATION_ADDED_PACKAGE_BUT_CREATE_MODULES_NOT_SEEN"
else
  echo "VERDICT: MAINAPPLICATION_REGISTRATION_NOT_RUNNING_OR_WRONG_APK"
fi

echo "Log: $LOG"
echo "Output: $OUT"
echo "============================================================"
MAC

chmod +x "$MAC_TEST"

cat > "$REPORT" <<MD
# MauriMesh Native GATT Registration Diagnostics v7

Timestamp: $STAMP

## Result

REGISTRATION_DIAGNOSTICS_PATCHED

## Why v7 exists

The installed APK contains v6 native bridge strings, but the runtime log still reports:

\`\`\`
NATIVE_GATT_TRIGGER_UNAVAILABLE
NativeModules=
\`\`\`

This means the next target is native module registration/loading, not another UI button patch.

## New expected log markers

\`\`\`
GATT_PACKAGE_REGISTRATION_V7
GATT_PACKAGE_CREATE_NATIVE_MODULES_V7
GATT_PACKAGE_MODULE_ADDED_V7
GATT_MODULE_CONSTRUCTOR_V7
GATT_MODULE_GET_NAME_V7
GATT_TRIGGER_NATIVE_METHOD_ENTERED
\`\`\`

## Truth Rule

Final native BLE/GATT packet-bound PASS is still not claimed.

Final PASS requires same packetId inside native GATT transport markers:

\`\`\`
GATT_CLIENT_WRITE_ATTEMPT
GATT_PACKET_PAYLOAD
GATT_SERVER_WRITE_RECEIVED
nativePacketBound=true
\`\`\`

## Mac test after APK install

\`\`\`
$MAC_TEST
\`\`\`
MD

cp "$REPORT" "$LATEST"

echo ""
echo "============================================================"
echo "NATIVE GATT REGISTRATION DIAGNOSTICS v7 COMPLETE"
echo "============================================================"
echo "Report: $REPORT"
echo "Latest: $LATEST"
echo "Mac test: $MAC_TEST"
echo "============================================================"
echo "FINAL VERDICT: READY_FOR_EAS_BUILD_V7_REGISTRATION_DIAGNOSTICS"
echo "Next:"
echo "1. Build EAS APK."
echo "2. Install on A16."
echo "3. Run Mac test script."
echo "4. Read v7 verdict."
echo "============================================================"
