#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH BUILD NATIVE GATT JAVA BRIDGE v6 APK"
echo "============================================================"
echo "Goal:"
echo "- Confirm v6 Java bridge patch exists"
echo "- Confirm duplicate Kotlin bridge files are gone"
echo "- Run JS/export gates again"
echo "- Start EAS Android APK cloud build"
echo "============================================================"
echo ""

STAMP="$(date +%Y%m%d-%H%M%S)"
DOC_DIR="docs/native-ble-gatt"
ARCHIVE_DIR="archives/native-ble-gatt"
mkdir -p "$DOC_DIR" "$ARCHIVE_DIR"

REPORT="$DOC_DIR/NATIVE_GATT_JAVA_BRIDGE_V6_EAS_BUILD_${STAMP}.md"
LATEST="$DOC_DIR/NATIVE_GATT_JAVA_BRIDGE_V6_EAS_BUILD_LATEST.md"

JAVA_MODULE="android/app/src/main/java/com/maurimesh/messenger/MauriMeshNativeBlePacketModule.java"
KT_MODULE="android/app/src/main/java/com/maurimesh/messenger/MauriMeshNativeBlePacketModule.kt"
KT_PACKAGE="android/app/src/main/java/com/maurimesh/messenger/MauriMeshNativeBlePacketPackage.kt"

echo "[1/7] Checking v6 bridge..."
if ! grep -q "MM_GATT_JAVA_BRIDGE_V6_BEGIN" "$JAVA_MODULE"; then
  echo "FAIL: v6 Java bridge marker missing."
  exit 1
fi

if ! grep -q "GATT_TRIGGER_NATIVE_METHOD_ENTERED" "$JAVA_MODULE"; then
  echo "FAIL: native trigger marker missing."
  exit 1
fi

echo "PASS: v6 Java bridge marker found."

echo ""
echo "[2/7] Checking duplicate Kotlin files..."
if [ -f "$KT_MODULE" ] || [ -f "$KT_PACKAGE" ]; then
  echo "FAIL: duplicate Kotlin bridge files still exist."
  ls -l "$KT_MODULE" "$KT_PACKAGE" 2>/dev/null || true
  exit 1
fi

echo "PASS: duplicate Kotlin bridge files are gone."

echo ""
echo "[3/7] Checking EAS config..."
if [ ! -f eas.json ]; then
  echo "FAIL: eas.json missing."
  exit 1
fi

cat eas.json | tee "$ARCHIVE_DIR/eas-json-before-v6-build-${STAMP}.txt"

PROFILE="$(node - <<'NODE'
const fs = require("fs");
const eas = JSON.parse(fs.readFileSync("eas.json", "utf8"));
const build = eas.build || {};
const names = Object.keys(build);

function isApkProfile(name) {
  const p = build[name] || {};
  const android = p.android || {};
  return android.buildType === "apk" || android.gradleCommand?.includes("assembleRelease");
}

const preferred =
  names.find(n => n.toLowerCase() === "preview" && isApkProfile(n)) ||
  names.find(n => n.toLowerCase().includes("apk") && isApkProfile(n)) ||
  names.find(n => isApkProfile(n)) ||
  names.find(n => n.toLowerCase() === "preview") ||
  names.find(n => n.toLowerCase() === "development") ||
  names[0];

if (!preferred) process.exit(1);
console.log(preferred);
NODE
)"

echo "Selected EAS profile: $PROFILE"

echo ""
echo "[4/7] Running TypeScript..."
npx tsc --noEmit

echo ""
echo "[5/7] Running Expo Android export..."
npx expo export --platform android

echo ""
echo "[6/7] Starting EAS Android build..."
echo "This is the native compile gate."

set +e
npx eas build --platform android --profile "$PROFILE" --non-interactive --wait 2>&1 | tee "$ARCHIVE_DIR/eas-native-gatt-java-bridge-v6-${STAMP}.log"
EAS_STATUS="${PIPESTATUS[0]}"
set -e

if [ "$EAS_STATUS" -ne 0 ]; then
  RESULT="EAS_BUILD_FAILED"
else
  RESULT="EAS_BUILD_COMMAND_COMPLETED"
fi

echo ""
echo "[7/7] Writing report..."
cat > "$REPORT" <<MD
# MauriMesh Native GATT Java Bridge v6 EAS Build

Timestamp: $STAMP

## Result

$RESULT

## Selected EAS Profile

\`\`\`
$PROFILE
\`\`\`

## Verified Before Build

- v6 Java bridge marker present.
- GATT_TRIGGER_NATIVE_METHOD_ENTERED marker present.
- Duplicate Kotlin bridge files absent.
- TypeScript gate completed.
- Expo Android export completed.

## Native Truth Rule

This build does not claim final native BLE/GATT packet-bound PASS.

Final PASS still requires physical-device logcat evidence containing same packetId with:

\`\`\`
GATT_TRIGGER_NATIVE_METHOD_ENTERED
GATT_CLIENT_WRITE_ATTEMPT
GATT_PACKET_PAYLOAD
GATT_SERVER_WRITE_RECEIVED
nativePacketBound=true
\`\`\`

## EAS Log

\`\`\`
$ARCHIVE_DIR/eas-native-gatt-java-bridge-v6-${STAMP}.log
\`\`\`
MD

cp "$REPORT" "$LATEST"

echo ""
echo "============================================================"
echo "BUILD SCRIPT COMPLETE"
echo "============================================================"
echo "Result: $RESULT"
echo "Report: $REPORT"
echo "Latest: $LATEST"
echo "EAS log: $ARCHIVE_DIR/eas-native-gatt-java-bridge-v6-${STAMP}.log"
echo "============================================================"

if [ "$RESULT" = "EAS_BUILD_FAILED" ]; then
  echo ""
  echo "FINAL VERDICT: BUILD_FAILED"
  echo "Paste the last EAS error section."
  exit 2
fi

echo ""
echo "FINAL VERDICT: CHECK_EAS_OUTPUT_FOR_APK_LINK"
echo "Next: download/install the new APK on A16, A06, S10."
echo "============================================================"
