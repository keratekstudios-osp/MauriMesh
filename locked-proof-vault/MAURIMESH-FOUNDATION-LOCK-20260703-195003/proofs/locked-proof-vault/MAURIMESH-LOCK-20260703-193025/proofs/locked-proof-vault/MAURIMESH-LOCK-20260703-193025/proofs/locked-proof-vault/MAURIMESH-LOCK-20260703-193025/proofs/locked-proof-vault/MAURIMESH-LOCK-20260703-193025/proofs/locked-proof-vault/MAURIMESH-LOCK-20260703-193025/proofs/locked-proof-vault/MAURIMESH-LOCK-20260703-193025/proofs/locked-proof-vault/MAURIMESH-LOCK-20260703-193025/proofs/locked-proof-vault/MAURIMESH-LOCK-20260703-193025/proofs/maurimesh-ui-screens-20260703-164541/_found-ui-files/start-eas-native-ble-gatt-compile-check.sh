#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH EAS NATIVE BLE/GATT CLOUD COMPILE CHECK"
echo "============================================================"
echo "WARNING:"
echo "- This can spend one EAS build."
echo "- Purpose is cloud native compile check only."
echo "- This does NOT prove native BLE/GATT packet-bound transport."
echo "- Native BLE/GATT PASS is still NOT claimed."
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +"%Y%m%d-%H%M%S")"
BUILD_ID="MM-EAS-NATIVE-BLE-GATT-COMPILE-$STAMP"

mkdir -p \
  "$ROOT/docs/build-gates" \
  "$ROOT/docs/native-proof" \
  "$ROOT/archives"

REPORT="$ROOT/docs/build-gates/MAURIMESH_EAS_NATIVE_BLE_GATT_COMPILE_CHECK_$STAMP.md"
LOG="$ROOT/docs/build-gates/eas-native-ble-gatt-compile-check-$STAMP.log"
PRECHECK="$ROOT/docs/build-gates/eas-native-ble-gatt-compile-precheck-$STAMP.txt"
GIT_OUT="$ROOT/docs/build-gates/git-status-before-eas-compile-$STAMP.txt"

echo "[1/8] Checking project root..."

if [ ! -f "$ROOT/package.json" ]; then
  echo "ERROR: package.json not found. Run from /home/runner/workspace."
  exit 1
fi

if [ ! -f "$ROOT/eas.json" ]; then
  echo "ERROR: eas.json missing. Cannot start EAS build safely."
  exit 1
fi

echo "Project root OK."

echo ""
echo "[2/8] Checking latest readiness gate..."

LATEST_JSON="$(ls -t "$ROOT/docs/build-gates"/MAURIMESH_EAS_NATIVE_BLE_GATT_READINESS_*.json 2>/dev/null | head -1 || true)"

if [ -z "$LATEST_JSON" ]; then
  echo "ERROR: No EAS readiness JSON found."
  echo "Run eas-native-ble-gatt-readiness-gate.sh first."
  exit 1
fi

READINESS="$(python3 - <<PY
import json
p="$LATEST_JSON"
with open(p) as f:
    data=json.load(f)
print(data.get("readiness","UNKNOWN"))
PY
)"

echo "Latest readiness JSON:"
echo "$LATEST_JSON"
echo "Readiness:"
echo "$READINESS"

if [ "$READINESS" != "READY_FOR_EAS_COMPILE_CHECK" ]; then
  echo "ERROR: Latest readiness gate is not ready."
  echo "Refusing to spend EAS build."
  exit 1
fi

echo ""
echo "[3/8] Capturing git status..."

if command -v git >/dev/null 2>&1 && [ -d "$ROOT/.git" ]; then
  git status --short > "$GIT_OUT" || true
else
  echo "git unavailable or no .git" > "$GIT_OUT"
fi

cat "$GIT_OUT"

echo ""
echo "[4/8] Selecting EAS build profile..."

PROFILE="$(python3 - <<'PY'
import json
from pathlib import Path

p = Path("eas.json")
data = json.loads(p.read_text())
build = data.get("build", {})

preferred = ["preview", "development", "production"]
for name in preferred:
    if name in build:
        print(name)
        break
else:
    if build:
        print(next(iter(build.keys())))
    else:
        print("")
PY
)"

if [ -z "$PROFILE" ]; then
  echo "ERROR: No build profile found in eas.json."
  exit 1
fi

echo "Selected EAS profile:"
echo "$PROFILE"

echo ""
echo "[5/8] Checking EAS CLI availability..."

EAS_CMD=""

if command -v eas >/dev/null 2>&1; then
  EAS_CMD="eas"
elif [ -x "$ROOT/node_modules/.bin/eas" ]; then
  EAS_CMD="$ROOT/node_modules/.bin/eas"
else
  echo "No local eas command found."
  echo "Trying npx eas-cli. This may download/use EAS CLI."
  EAS_CMD="npx eas-cli"
fi

{
  echo "Build ID: $BUILD_ID"
  echo "Selected profile: $PROFILE"
  echo "EAS command: $EAS_CMD"
  echo "Readiness JSON: $LATEST_JSON"
  echo ""
  echo "EAS version:"
  $EAS_CMD --version || true
} > "$PRECHECK" 2>&1 || true

cat "$PRECHECK"

echo ""
echo "[6/8] Final truth before build..."

echo "This build is compile-check only."
echo "Native BLE/GATT packet-bound PASS is NOT claimed."
echo "Missing actual native logger stages may still remain."
echo ""

echo "[7/8] Starting EAS Android build..."
echo "Command:"
echo "$EAS_CMD build --platform android --profile $PROFILE --non-interactive"
echo ""

set +e
$EAS_CMD build --platform android --profile "$PROFILE" --non-interactive 2>&1 | tee "$LOG"
BUILD_CODE="${PIPESTATUS[0]}"
set -e

if [ "$BUILD_CODE" -eq 0 ]; then
  BUILD_STATUS="EAS_COMMAND_COMPLETED"
else
  BUILD_STATUS="EAS_COMMAND_FAILED"
fi

echo ""
echo "[8/8] Writing compile check report..."

BUILD_URLS="$(grep -Eo 'https://[^ ]*expo.dev[^ ]*|https://[^ ]*eas[^ ]*' "$LOG" | sort -u | tr '\n' ' ' || true)"

cat > "$REPORT" <<MD
# MauriMesh EAS Native BLE/GATT Cloud Compile Check

Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")

## Build ID

\`\`\`txt
$BUILD_ID
\`\`\`

## EAS Command Status

\`\`\`txt
$BUILD_STATUS
\`\`\`

Exit code:

\`\`\`txt
$BUILD_CODE
\`\`\`

## Profile

\`\`\`txt
$PROFILE
\`\`\`

## Purpose

This EAS build is a **cloud native compile check**.

It is not a final native BLE/GATT packet-bound proof.

## Build Links Found In Log

\`\`\`txt
$BUILD_URLS
\`\`\`

## Files

Precheck:

\`\`\`txt
$PRECHECK
\`\`\`

Log:

\`\`\`txt
$LOG
\`\`\`

Git status before build:

\`\`\`txt
$GIT_OUT
\`\`\`

Readiness gate:

\`\`\`txt
$LATEST_JSON
\`\`\`

## Native Proof Truth

Native BLE/GATT packet-bound PASS is **NOT CLAIMED**.

A PASS can only be claimed after real device logs show the same packetId across:

\`\`\`txt
advertise_start_packetId
scan_result_packetId
gatt_write_packetId
gatt_read_packetId
characteristic_changed_packetId
relay_packetId
ack_packetId
\`\`\`

## Next Step

If EAS build succeeds:
1. Download/install APK.
2. Run the native BLE/GATT packet-bound validator on device logs.
3. Do not claim PASS unless packetId appears in required native stages.

If EAS build fails:
1. Read EAS failure lines.
2. Patch only the exact failing native/Kotlin/config issue.
3. Re-run readiness gate before another build.
MD

ARCHIVE="$ROOT/archives/maurimesh-eas-native-ble-gatt-compile-check-$STAMP.tar.gz"
tar -czf "$ARCHIVE" \
  -C "$ROOT" \
  "docs/build-gates" \
  "docs/native-proof" \
  >/dev/null 2>&1 || true

echo ""
echo "============================================================"
echo "MAURIMESH EAS NATIVE BLE/GATT COMPILE CHECK COMPLETE"
echo "============================================================"
echo "Build ID:"
echo "$BUILD_ID"
echo ""
echo "EAS command status:"
echo "$BUILD_STATUS"
echo ""
echo "Exit code:"
echo "$BUILD_CODE"
echo ""
echo "Profile:"
echo "$PROFILE"
echo ""
echo "Build links found:"
echo "$BUILD_URLS"
echo ""
echo "Log:"
echo "$LOG"
echo ""
echo "Report:"
echo "$REPORT"
echo ""
echo "Archive:"
echo "$ARCHIVE"
echo ""
echo "FINAL TRUTH:"
echo "EAS compile check was attempted."
echo "Native BLE/GATT packet-bound PASS is NOT claimed."
echo "============================================================"
