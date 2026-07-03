#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH GATT PACKET PAYLOAD PREBUILD GATE v1"
echo "============================================================"
echo "Goal:"
echo "- Verify GATT payload instrumentation before EAS build"
echo "- Check Kotlin marker wiring"
echo "- Check no false native BLE/GATT PASS claim"
echo "- Run TypeScript"
echo "- Run Expo export"
echo "- Try local Gradle Kotlin compile if available"
echo "============================================================"

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT="$ROOT/docs/native-ble-gatt"
ARCHIVE="$ROOT/archives"
REPORT="$OUT/GATT_PACKET_PAYLOAD_PREBUILD_GATE_$STAMP.md"
RAW="$OUT/GATT_PACKET_PAYLOAD_PREBUILD_GATE_RAW_$STAMP.txt"
TSC_LOG="$OUT/GATT_PACKET_PAYLOAD_PREBUILD_TSC_$STAMP.log"
EXPORT_LOG="$OUT/GATT_PACKET_PAYLOAD_PREBUILD_EXPORT_$STAMP.log"
GRADLE_LOG="$OUT/GATT_PACKET_PAYLOAD_PREBUILD_GRADLE_$STAMP.log"

mkdir -p "$OUT" "$ARCHIVE"
: > "$RAW"

PASS=0
WARN=0
FAIL=0
PENDING=0

log(){ echo "$*" | tee -a "$RAW"; }
pass(){ PASS=$((PASS+1)); log "PASS: $1"; }
warn(){ WARN=$((WARN+1)); log "WARN: $1"; }
fail(){ FAIL=$((FAIL+1)); log "FAIL: $1"; }
pending(){ PENDING=$((PENDING+1)); log "PENDING: $1"; }

LOGGER="android/app/src/main/java/com/maurimesh/messenger/MauriMeshGattPacketProof.kt"
CLIENT="android/app/src/main/java/com/maurimesh/messenger/MeshCentralClient.kt"
SERVER="android/app/src/main/java/com/maurimesh/messenger/MeshRawPacketGattServer.kt"
CAPTURE="tools/capture-gatt-packet-payload-proof-v1.sh"

log ""
log "Generated: $STAMP"
log "Root: $ROOT"
log ""

log "============================================================"
log "1. REQUIRED FILES"
log "============================================================"

for f in "$LOGGER" "$CLIENT" "$SERVER" "$CAPTURE" "app/native-ble-gatt-proof.tsx" "app/dashboard.tsx"; do
  if [ -f "$f" ]; then
    pass "$f exists"
  else
    fail "$f missing"
  fi
done

log ""
log "============================================================"
log "2. GATT PAYLOAD MARKER CHECK"
log "============================================================"

if grep -RIn "GATT_PACKET_PAYLOAD" "$LOGGER" "$CLIENT" "$SERVER" 2>/dev/null | tee -a "$RAW"; then
  pass "GATT_PACKET_PAYLOAD marker found"
else
  fail "GATT_PACKET_PAYLOAD marker missing"
fi

if grep -RIn "GATT_CLIENT_WRITE_ATTEMPT" "$CLIENT" "$LOGGER" 2>/dev/null | tee -a "$RAW"; then
  pass "GATT_CLIENT_WRITE_ATTEMPT marker found"
else
  fail "GATT_CLIENT_WRITE_ATTEMPT marker missing"
fi

if grep -RIn "GATT_SERVER_WRITE_RECEIVED" "$SERVER" "$LOGGER" 2>/dev/null | tee -a "$RAW"; then
  pass "GATT_SERVER_WRITE_RECEIVED marker found"
else
  fail "GATT_SERVER_WRITE_RECEIVED marker missing"
fi

if grep -RIn "nativePacketBoundCandidate" "$LOGGER" "$CAPTURE" 2>/dev/null | tee -a "$RAW"; then
  pass "nativePacketBoundCandidate marker found"
else
  fail "nativePacketBoundCandidate marker missing"
fi

if grep -RIn "nativePacketBound=false" "$LOGGER" "$CAPTURE" app src android 2>/dev/null | tee -a "$RAW"; then
  pass "nativePacketBound=false truth lock found"
else
  warn "nativePacketBound=false truth lock not confirmed"
fi

log ""
log "============================================================"
log "3. FALSE FINAL PASS CHECK"
log "============================================================"

ACTIVE_FALSE_PASS="$(
  grep -RInE \
    "nativeBleGattPacketBoundPass[[:space:]]*:[[:space:]]*true|result[[:space:]]*:[[:space:]]*['\"]PASS_NATIVE_PACKET_BOUND_BLE_GATT_PROOF['\"]|verdict[[:space:]]*:[[:space:]]*['\"]PASS_NATIVE_PACKET_BOUND_BLE_GATT_PROOF['\"]|nativePacketBound[[:space:]]*=[[:space:]]*true|nativePacketBound[[:space:]]*:[[:space:]]*true" \
    app src android 2>/dev/null || true
)"

if [ -n "$ACTIVE_FALSE_PASS" ]; then
  warn "Potential active final native BLE/GATT PASS-like source found. Review:"
  log "$ACTIVE_FALSE_PASS"
else
  pass "No active final native BLE/GATT PASS claim found"
fi

log ""
log "============================================================"
log "4. TYPESCRIPT CHECK"
log "============================================================"

if npx tsc --noEmit > "$TSC_LOG" 2>&1; then
  pass "TypeScript passed"
else
  fail "TypeScript failed. See $TSC_LOG"
fi

log ""
log "============================================================"
log "5. EXPO EXPORT CHECK"
log "============================================================"

rm -rf dist-gatt-prebuild-v1 2>/dev/null || true

if npx expo export --platform android --output-dir dist-gatt-prebuild-v1 > "$EXPORT_LOG" 2>&1; then
  pass "Expo Android export passed"
else
  fail "Expo Android export failed. See $EXPORT_LOG"
fi

log ""
log "============================================================"
log "6. OPTIONAL LOCAL GRADLE KOTLIN COMPILE"
log "============================================================"

if [ -x "$ROOT/android/gradlew" ]; then
  log "Running local Gradle Kotlin compile. This may take a while..."
  (
    cd "$ROOT/android"
    ./gradlew :app:compileDebugKotlin --no-daemon
  ) > "$GRADLE_LOG" 2>&1 && pass "Local Gradle Kotlin compile passed" || warn "Local Gradle Kotlin compile failed or environment missing dependencies. See $GRADLE_LOG"
else
  pending "android/gradlew not executable or unavailable; EAS will be native compile gate"
fi

log ""
log "============================================================"
log "SUMMARY"
log "============================================================"
log "PASS: $PASS"
log "WARN: $WARN"
log "FAIL: $FAIL"
log "PENDING: $PENDING"

if [ "$FAIL" -eq 0 ]; then
  RESULT="READY_FOR_FRESH_GATT_PAYLOAD_APK_BUILD"
else
  RESULT="FIX_REQUIRED_BEFORE_GATT_PAYLOAD_APK_BUILD"
fi

log "RESULT: $RESULT"

cat > "$REPORT" <<MD
# MauriMesh GATT Packet Payload Prebuild Gate v1

Generated: $STAMP

## Result

**$RESULT**

## Counts

| Status | Count |
|---|---:|
| PASS | $PASS |
| WARN | $WARN |
| FAIL | $FAIL |
| PENDING | $PENDING |

## Meaning

This gate checks whether the GATT packet payload instrumentation is ready for a fresh APK build.

## Truth

This does not claim final native BLE/GATT packet-bound PASS.

Final PASS still requires physical-device logcat proof showing the same packetId inside required native GATT payload stages.

## Files

- Raw log: $RAW
- TypeScript log: $TSC_LOG
- Expo export log: $EXPORT_LOG
- Gradle log: $GRADLE_LOG
MD

tar -czf "$ARCHIVE/gatt-packet-payload-prebuild-gate-v1-$STAMP.tar.gz" \
  "$REPORT" "$RAW" "$TSC_LOG" "$EXPORT_LOG" "$GRADLE_LOG" 2>/dev/null || true

echo ""
echo "============================================================"
echo "PREBUILD GATE COMPLETE"
echo "============================================================"
echo "Result: $RESULT"
echo "Report: $REPORT"
echo "Archive: $ARCHIVE/gatt-packet-payload-prebuild-gate-v1-$STAMP.tar.gz"
echo "============================================================"

if [ "$FAIL" -eq 0 ]; then
  exit 0
else
  exit 1
fi
