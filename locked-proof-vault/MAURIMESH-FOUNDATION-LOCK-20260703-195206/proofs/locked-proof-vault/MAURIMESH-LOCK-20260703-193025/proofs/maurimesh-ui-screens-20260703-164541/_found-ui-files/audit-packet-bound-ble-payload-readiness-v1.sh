#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH PACKET-BOUND BLE PAYLOAD READINESS AUDIT v1"
echo "============================================================"
echo "Goal:"
echo "- Prepare next gate after native BLE callback proof"
echo "- Detect whether packetId can be placed into native BLE payload"
echo "- Check advertiser / GATT server / serviceData / manufacturerData support"
echo "- Keep native BLE/GATT final PASS locked until payload proof exists"
echo "- No app edits"
echo "- No proof claim"
echo "============================================================"

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT="$ROOT/docs/native-ble-gatt"
ARCHIVE="$ROOT/archives"
REPORT="$OUT/PACKET_BOUND_BLE_PAYLOAD_READINESS_$STAMP.md"
RAW="$OUT/PACKET_BOUND_BLE_PAYLOAD_READINESS_RAW_$STAMP.txt"
TSC_LOG="$OUT/PACKET_BOUND_BLE_PAYLOAD_TSC_$STAMP.log"

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

EXISTING_PATHS=()
for p in app src android tools docs; do
  if [ -e "$ROOT/$p" ]; then
    EXISTING_PATHS+=("$ROOT/$p")
  fi
done

grep_any() {
  local pattern="$1"
  if [ "${#EXISTING_PATHS[@]}" -eq 0 ]; then
    return 1
  fi
  grep -RInE "$pattern" "${EXISTING_PATHS[@]}" >/dev/null 2>&1
}

grep_show() {
  local title="$1"
  local pattern="$2"
  log ""
  log "---- $title ----"
  if [ "${#EXISTING_PATHS[@]}" -eq 0 ]; then
    log "No scan paths found."
    return 0
  fi
  grep -RInE "$pattern" "${EXISTING_PATHS[@]}" 2>/dev/null | tee -a "$RAW" || true
}

log ""
log "Generated: $STAMP"
log "Root: $ROOT"
log ""

log "Scan paths:"
for p in "${EXISTING_PATHS[@]}"; do
  log "- $p"
done

log ""
log "============================================================"
log "1. CURRENT NATIVE CALLBACK PROOF LAYER"
log "============================================================"

if [ -f "$ROOT/app/native-ble-gatt-proof.tsx" ]; then
  pass "Native BLE/GATT proof route exists: app/native-ble-gatt-proof.tsx"
else
  fail "Native BLE/GATT proof route missing: app/native-ble-gatt-proof.tsx"
fi

if grep_any "MAURIMESH_NATIVE_BLE_GATT"; then
  pass "MAURIMESH_NATIVE_BLE_GATT source/log marker exists"
else
  fail "MAURIMESH_NATIVE_BLE_GATT marker missing"
fi

if grep_any "BLE_SCAN_CALLBACK_DEVICE"; then
  pass "BLE scan callback marker exists"
else
  warn "BLE scan callback marker not found in source"
fi

if grep_any "nativePacketBound=false"; then
  pass "Truth lock nativePacketBound=false exists"
else
  warn "nativePacketBound=false truth marker not found"
fi

if grep_any "NATIVE_CALLBACK_ACTIVITY_SEEN_PACKET_BOUND_PENDING"; then
  pass "Callback-pending result label exists"
else
  warn "Callback-pending result label not found"
fi

log ""
log "============================================================"
log "2. PACKET-BOUND PAYLOAD CAPABILITY SEARCH"
log "============================================================"

if grep_any "BluetoothLeAdvertiser|startAdvertising|AdvertiseData|AdvertiseSettings"; then
  pass "Android BLE advertiser code found"
else
  pending "Android BLE advertiser code not found"
fi

if grep_any "BluetoothGattServer|openGattServer|addService|BluetoothGattCharacteristic|BluetoothGattService"; then
  pass "Android GATT server code found"
else
  pending "Android GATT server code not found"
fi

if grep_any "manufacturerData|setManufacturerData|serviceData|setServiceData|serviceUUID|serviceUuid"; then
  pass "BLE advertisement payload fields found"
else
  pending "BLE advertisement payload fields not found"
fi

if grep_any "writeCharacteristic|readCharacteristic|monitorCharacteristic|notifyCharacteristic|onCharacteristicWriteRequest|onCharacteristicReadRequest|onCharacteristicChanged"; then
  pass "GATT characteristic read/write/notify markers found"
else
  pending "GATT characteristic packet transport markers not found"
fi

if grep_any "packetId.*manufacturerData|manufacturerData.*packetId|packetId.*serviceData|serviceData.*packetId"; then
  pass "packetId appears tied to BLE advertisement payload source"
else
  pending "packetId is not yet tied to BLE advertisement payload source"
fi

if grep_any "packetId.*Characteristic|Characteristic.*packetId|packetId.*GATT|GATT.*packetId"; then
  pass "packetId appears tied to GATT characteristic source"
else
  pending "packetId is not yet tied to GATT characteristic source"
fi

log ""
log "============================================================"
log "3. FALSE PASS / TRUTH SAFETY CHECK"
log "============================================================"

ACTIVE_FINAL_PASS_MATCHES="$(
  grep -RInE \
    "nativePacketBound[[:space:]]*:[[:space:]]*true|nativeBleGattPacketBoundPass[[:space:]]*:[[:space:]]*true|verdict[[:space:]]*:[[:space:]]*['\"]PASS_NATIVE_PACKET_BOUND_BLE_GATT_PROOF['\"]|result[[:space:]]*:[[:space:]]*['\"]PASS_NATIVE_PACKET_BOUND_BLE_GATT_PROOF['\"]" \
    "$ROOT/app" "$ROOT/src" "$ROOT/android" 2>/dev/null || true
)"

if [ -n "$ACTIVE_FINAL_PASS_MATCHES" ]; then
  warn "Active native PASS-like source claim found. Review required."
  log "$ACTIVE_FINAL_PASS_MATCHES"
else
  pass "No active source final native BLE/GATT PASS claim found"
fi

if grep_any "PASS_NATIVE_PACKET_BOUND_BLE_GATT_PROOF_CANDIDATE_REVIEW_REQUIRED"; then
  pass "Candidate-review result label exists"
else
  warn "Candidate-review label not found"
fi

if grep_any "Native BLE/GATT packet-bound PASS.*not claimed|packet-bound PASS is not claimed|native BLE/GATT.*not claimed"; then
  pass "Native BLE/GATT not-claimed truth wording found"
else
  warn "Native BLE/GATT not-claimed truth wording not confirmed"
fi

log ""
log "============================================================"
log "4. SOURCE MATCHES FOR HUMAN REVIEW"
log "============================================================"

grep_show "Native BLE marker source" "MAURIMESH_NATIVE_BLE_GATT|BLE_SCAN_CALLBACK_DEVICE|nativePacketBound"
grep_show "Advertiser / advertisement payload source" "BluetoothLeAdvertiser|startAdvertising|AdvertiseData|manufacturerData|serviceData|setManufacturerData|setServiceData"
grep_show "GATT source" "BluetoothGattServer|BluetoothGattCharacteristic|BluetoothGattService|writeCharacteristic|readCharacteristic|notifyCharacteristic|onCharacteristic"
grep_show "Final PASS phrases" "PASS_NATIVE_PACKET_BOUND_BLE_GATT_PROOF|nativeBleGattPacketBoundPass|nativePacketBound"

log ""
log "============================================================"
log "5. TYPESCRIPT CHECK"
log "============================================================"

if npx tsc --noEmit > "$TSC_LOG" 2>&1; then
  pass "TypeScript passed"
else
  fail "TypeScript failed. See $TSC_LOG"
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
  RESULT="READY_TO_DESIGN_PACKET_BOUND_PAYLOAD_LAYER"
else
  RESULT="REPAIR_REQUIRED_BEFORE_PACKET_BOUND_PAYLOAD_LAYER"
fi

log "RESULT: $RESULT"

cat > "$REPORT" <<MD
# MauriMesh Packet-Bound BLE Payload Readiness v1

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

## Current Locked Milestone

Native BLE callback activity has been captured and locked.

Current valid result:

\`NATIVE_CALLBACK_ACTIVITY_SEEN_PACKET_BOUND_PENDING\`

This proves native BLE callback activity, but it does **not** prove final packet-bound native BLE/GATT transport.

## Next Engineering Gate

Upgrade from scan callback proof to packet-bound BLE payload proof.

Required path:

\`\`\`txt
packetId created
→ packetId inserted into native BLE payload
→ receiving phone reads same packetId from native BLE payload
→ native log records packetId from payload
→ ACK path records same packetId
→ only then nativePacketBound=true may be considered
\`\`\`

## Option A — BLE Advertising Payload

Put packetId into one of:

- manufacturer data
- service data
- advertised service UUID payload

Then receiver scan callback must log the same packetId extracted from the native advertisement payload.

## Option B — GATT Characteristic Payload

Create native GATT server/client flow:

- sender writes packetId to characteristic
- relay receives packetId
- receiver receives packetId
- ACK returns with same packetId
- native logs show same packetId inside GATT read/write/notify event

## Required Final PASS Rule

Final native BLE/GATT PASS is allowed only when:

- same packetId appears in APK workflow logs
- same packetId appears inside native BLE/GATT transport payload/logs
- physical devices are captured
- A06, S10, A16 roles are recorded
- ACK path is recorded
- nativePacketBound=true is justified by payload evidence

## Truth

Native BLE/GATT packet-bound PASS is still **not claimed**.

## Files

- Raw log: $RAW
- TypeScript log: $TSC_LOG
MD

tar -czf "$ARCHIVE/packet-bound-ble-payload-readiness-$STAMP.tar.gz" \
  "$REPORT" "$RAW" "$TSC_LOG" 2>/dev/null || true

echo ""
echo "============================================================"
echo "AUDIT COMPLETE"
echo "============================================================"
echo "Result: $RESULT"
echo "Report: $REPORT"
echo "Archive: $ARCHIVE/packet-bound-ble-payload-readiness-$STAMP.tar.gz"
echo "============================================================"

if [ "$FAIL" -eq 0 ]; then
  exit 0
else
  exit 1
fi
