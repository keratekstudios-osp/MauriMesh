#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH EAS NATIVE BLE/GATT READINESS GATE"
echo "============================================================"
echo "Goal:"
echo "- Check project build readiness before spending EAS build"
echo "- Confirm EAS/app config exists"
echo "- Confirm native BLE/GATT logger files exist"
echo "- Confirm proof reports exist"
echo "- Run TypeScript check"
echo "- Create readiness report"
echo ""
echo "Protection:"
echo "- No EAS build"
echo "- No git push"
echo "- No install"
echo "- No delete"
echo "- No source mutation"
echo "- Native BLE/GATT packet-bound PASS is NOT claimed"
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +"%Y%m%d-%H%M%S")"
GATE_ID="MM-EAS-NATIVE-BLE-GATT-READINESS-$STAMP"

if [ ! -f "$ROOT/package.json" ]; then
  echo "ERROR: package.json not found. Run this from /home/runner/workspace."
  exit 1
fi

mkdir -p \
  "$ROOT/docs/build-gates" \
  "$ROOT/docs/native-proof" \
  "$ROOT/archives"

REPORT="$ROOT/docs/build-gates/MAURIMESH_EAS_NATIVE_BLE_GATT_READINESS_$STAMP.md"
JSON_REPORT="$ROOT/docs/build-gates/MAURIMESH_EAS_NATIVE_BLE_GATT_READINESS_$STAMP.json"
TSC_OUT="$ROOT/docs/build-gates/typecheck-eas-native-ble-gatt-readiness-$STAMP.txt"
TREE_OUT="$ROOT/docs/build-gates/native-ble-gatt-readiness-tree-$STAMP.txt"
GIT_OUT="$ROOT/docs/build-gates/git-status-eas-native-ble-gatt-readiness-$STAMP.txt"

PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0

pass() {
  echo "PASS: $1"
  PASS_COUNT=$((PASS_COUNT + 1))
}

warn() {
  echo "WARN: $1"
  WARN_COUNT=$((WARN_COUNT + 1))
}

fail() {
  echo "FAIL: $1"
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

section() {
  echo ""
  echo "------------------------------------------------------------"
  echo "$1"
  echo "------------------------------------------------------------"
}

section "[1/10] Core project files"

[ -f "$ROOT/package.json" ] && pass "package.json found" || fail "package.json missing"
[ -f "$ROOT/eas.json" ] && pass "eas.json found" || warn "eas.json missing"
[ -f "$ROOT/app.json" ] && pass "app.json found" || warn "app.json missing"
[ -f "$ROOT/app.config.js" ] && pass "app.config.js found" || true
[ -f "$ROOT/app.config.ts" ] && pass "app.config.ts found" || true

if [ ! -f "$ROOT/app.json" ] && [ ! -f "$ROOT/app.config.js" ] && [ ! -f "$ROOT/app.config.ts" ]; then
  fail "No Expo app config found"
fi

section "[2/10] Android native tree"

if [ -d "$ROOT/android/app/src/main/java" ]; then
  pass "Android native Java/Kotlin tree found"
else
  fail "Android native tree missing"
fi

if [ -f "$ROOT/android/app/build.gradle" ]; then
  pass "android/app/build.gradle found"
else
  fail "android/app/build.gradle missing"
fi

if [ -f "$ROOT/android/build.gradle" ]; then
  pass "android/build.gradle found"
else
  fail "android/build.gradle missing"
fi

section "[3/10] Native BLE/GATT packet logger"

LOGGER="$ROOT/android/app/src/main/java/com/maurimesh/messenger/MauriMeshNativeBlePacketLogger.kt"

if [ -f "$LOGGER" ]; then
  pass "MauriMeshNativeBlePacketLogger.kt found"
else
  fail "MauriMeshNativeBlePacketLogger.kt missing"
fi

ACTUAL_LOGGER_CALLS="$(grep -RIn "MauriMeshNativeBlePacketLogger\." "$ROOT/android/app/src/main/java" 2>/dev/null | grep -v "MauriMeshNativeBlePacketLogger.kt" | wc -l | tr -d ' ' || echo 0)"

if [ "$ACTUAL_LOGGER_CALLS" -ge 1 ]; then
  pass "Actual native logger calls found: $ACTUAL_LOGGER_CALLS"
else
  fail "No actual native logger calls found outside helper"
fi

section "[4/10] Required native packet stages"

check_stage() {
  local label="$1"
  local pattern="$2"

  if grep -RIn "$pattern" "$ROOT/android/app/src/main/java" 2>/dev/null | grep -v "MauriMeshNativeBlePacketLogger.kt" >/dev/null 2>&1; then
    pass "$label wired in actual native code"
    echo "$label=WIRED" >> "$TREE_OUT"
  else
    warn "$label missing actual native usage"
    echo "$label=MISSING_ACTUAL_USAGE" >> "$TREE_OUT"
  fi
}

: > "$TREE_OUT"

check_stage "advertise_start_packetId" "MauriMeshNativeBlePacketLogger\.advertiseStart"
check_stage "scan_result_packetId" "MauriMeshNativeBlePacketLogger\.scanResult"
check_stage "gatt_write_packetId" "MauriMeshNativeBlePacketLogger\.gattWrite"
check_stage "gatt_read_packetId" "MauriMeshNativeBlePacketLogger\.gattRead"
check_stage "characteristic_changed_packetId" "MauriMeshNativeBlePacketLogger\.characteristicChanged"
check_stage "relay_packetId" "MauriMeshNativeBlePacketLogger\.relay"
check_stage "ack_packetId" "MauriMeshNativeBlePacketLogger\.ack"

section "[5/10] Native proof docs"

LATEST_STATIC_AUDIT="$(ls -t "$ROOT/docs/native-proof"/STATIC_NATIVE_BLE_GATT_WIRING_AUDIT_*.md 2>/dev/null | head -1 || true)"
LATEST_JAVA17_REPORT="$(ls -t "$ROOT/docs/native-proof"/JAVA17_NATIVE_BLE_GATT_CHECK_*.md 2>/dev/null | head -1 || true)"
LATEST_SDK_REPORT="$(ls -t "$ROOT/docs/native-proof"/ANDROID_SDK_PATH_AND_NATIVE_GRADLE_RETEST_V2_*.md 2>/dev/null | head -1 || true)"
LATEST_WIRING_REPORT="$(ls -t "$ROOT/docs/native-proof"/MAURIMESH_NATIVE_BLE_GATT_PACKETID_WIRING_REPORT_*.md 2>/dev/null | head -1 || true)"
LATEST_CONTRACT="$(ls -t "$ROOT/docs/native-proof"/MAURIMESH_NATIVE_BLE_GATT_PACKET_BOUND_LOGGING_GATE_*.md 2>/dev/null | head -1 || true)"

[ -n "$LATEST_STATIC_AUDIT" ] && pass "Latest static audit found: $LATEST_STATIC_AUDIT" || warn "Static audit report missing"
[ -n "$LATEST_JAVA17_REPORT" ] && pass "Latest Java17 report found: $LATEST_JAVA17_REPORT" || warn "Java17 report missing"
[ -n "$LATEST_SDK_REPORT" ] && pass "Latest Android SDK report found: $LATEST_SDK_REPORT" || warn "Android SDK report missing"
[ -n "$LATEST_WIRING_REPORT" ] && pass "Latest wiring report found: $LATEST_WIRING_REPORT" || warn "Wiring report missing"
[ -n "$LATEST_CONTRACT" ] && pass "Native packet-bound contract found: $LATEST_CONTRACT" || warn "Native packet-bound contract missing"

section "[6/10] EAS config"

if [ -f "$ROOT/eas.json" ]; then
  if grep -q '"build"' "$ROOT/eas.json"; then
    pass "eas.json has build section"
  else
    warn "eas.json exists but build section not obvious"
  fi

  if grep -q '"android"' "$ROOT/eas.json"; then
    pass "eas.json has android config"
  else
    warn "eas.json android config not obvious"
  fi
else
  warn "Cannot inspect eas.json because it is missing"
fi

section "[7/10] App identity"

APP_ID_FOUND="no"

if grep -R "com.maurimesh.messenger" "$ROOT/app.json" "$ROOT/app.config.js" "$ROOT/app.config.ts" "$ROOT/android/app/build.gradle" 2>/dev/null >/dev/null; then
  APP_ID_FOUND="yes"
fi

if [ "$APP_ID_FOUND" = "yes" ]; then
  pass "App identity com.maurimesh.messenger found"
else
  warn "App identity com.maurimesh.messenger not found in common config files"
fi

section "[8/10] TypeScript check"

if [ -f "$ROOT/tsconfig.json" ]; then
  if npx tsc --noEmit > "$TSC_OUT" 2>&1; then
    pass "TypeScript check passed"
  else
    fail "TypeScript check failed"
    echo ""
    echo "Last TypeScript lines:"
    tail -80 "$TSC_OUT" || true
  fi
else
  warn "tsconfig.json missing; TypeScript check skipped"
  echo "tsconfig.json missing; skipped" > "$TSC_OUT"
fi

section "[9/10] Git status"

if command -v git >/dev/null 2>&1 && [ -d "$ROOT/.git" ]; then
  git status --short > "$GIT_OUT" || true
  pass "git status captured"
else
  warn "git not available or repo has no .git folder"
  echo "git unavailable or no .git" > "$GIT_OUT"
fi

section "[10/10] Final readiness decision"

READINESS="BLOCKED"

if [ "$FAIL_COUNT" -eq 0 ]; then
  READINESS="READY_FOR_EAS_COMPILE_CHECK"
else
  READINESS="BLOCKED_FIX_FAILURES_FIRST"
fi

cat > "$REPORT" <<MD
# MauriMesh EAS Native BLE/GATT Readiness Gate

Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")

## Gate ID

\`\`\`txt
$GATE_ID
\`\`\`

## Final Decision

\`\`\`txt
$READINESS
\`\`\`

## Counts

| Type | Count |
|---|---:|
| PASS | $PASS_COUNT |
| WARN | $WARN_COUNT |
| FAIL | $FAIL_COUNT |

## Current Truth

Native BLE/GATT packet-bound PASS is **NOT CLAIMED**.

This readiness gate does **not** start an EAS build.

Replit local native compile is blocked because Android SDK is missing, but Java 17 was found in the previous gate.

## Current Native Logger Coverage

Actual logger calls excluding helper:

\`\`\`txt
$ACTUAL_LOGGER_CALLS
\`\`\`

Stage coverage file:

\`\`\`txt
$TREE_OUT
\`\`\`

## Latest Native Proof Reports

\`\`\`txt
Static audit: $LATEST_STATIC_AUDIT
Java17 report: $LATEST_JAVA17_REPORT
Android SDK report: $LATEST_SDK_REPORT
Wiring report: $LATEST_WIRING_REPORT
Contract: $LATEST_CONTRACT
\`\`\`

## TypeScript Output

\`\`\`txt
$TSC_OUT
\`\`\`

## Git Status Output

\`\`\`txt
$GIT_OUT
\`\`\`

## EAS Build Rule

Only trigger EAS build if final decision is:

\`\`\`txt
READY_FOR_EAS_COMPILE_CHECK
\`\`\`

## Expected EAS Purpose

The next EAS build is not a final proof build.

It is a **cloud native compile check** to confirm whether the patched native Kotlin compiles in an Android SDK environment.

## Native Proof Rule

Even if EAS build succeeds, native BLE/GATT packet-bound PASS is still not claimed until real device logs show the same packetId across:

\`\`\`txt
advertise_start_packetId
scan_result_packetId
gatt_write_packetId
gatt_read_packetId
characteristic_changed_packetId
relay_packetId
ack_packetId
\`\`\`
MD

cat > "$JSON_REPORT" <<JSON
{
  "gateId": "$GATE_ID",
  "generatedAt": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "readiness": "$READINESS",
  "passCount": $PASS_COUNT,
  "warnCount": $WARN_COUNT,
  "failCount": $FAIL_COUNT,
  "actualLoggerCallsExcludingHelper": $ACTUAL_LOGGER_CALLS,
  "nativeBleGattPacketBoundPassClaimed": false,
  "startsEasBuild": false,
  "replitAndroidSdkMissing": true,
  "nextPurpose": "EAS cloud native compile check only"
}
JSON

ARCHIVE="$ROOT/archives/maurimesh-eas-native-ble-gatt-readiness-$STAMP.tar.gz"
tar -czf "$ARCHIVE" \
  -C "$ROOT" \
  "docs/build-gates" \
  "docs/native-proof" \
  >/dev/null 2>&1 || true

echo ""
echo "============================================================"
echo "MAURIMESH EAS NATIVE BLE/GATT READINESS GATE COMPLETE"
echo "============================================================"
echo "Gate ID:"
echo "$GATE_ID"
echo ""
echo "Decision:"
echo "$READINESS"
echo ""
echo "PASS:"
echo "$PASS_COUNT"
echo ""
echo "WARN:"
echo "$WARN_COUNT"
echo ""
echo "FAIL:"
echo "$FAIL_COUNT"
echo ""
echo "Actual logger calls excluding helper:"
echo "$ACTUAL_LOGGER_CALLS"
echo ""
echo "Report:"
echo "$REPORT"
echo ""
echo "JSON:"
echo "$JSON_REPORT"
echo ""
echo "Archive:"
echo "$ARCHIVE"
echo ""
echo "FINAL TRUTH:"
echo "No EAS build was started."
echo "Native BLE/GATT packet-bound PASS is NOT claimed."
echo "============================================================"
