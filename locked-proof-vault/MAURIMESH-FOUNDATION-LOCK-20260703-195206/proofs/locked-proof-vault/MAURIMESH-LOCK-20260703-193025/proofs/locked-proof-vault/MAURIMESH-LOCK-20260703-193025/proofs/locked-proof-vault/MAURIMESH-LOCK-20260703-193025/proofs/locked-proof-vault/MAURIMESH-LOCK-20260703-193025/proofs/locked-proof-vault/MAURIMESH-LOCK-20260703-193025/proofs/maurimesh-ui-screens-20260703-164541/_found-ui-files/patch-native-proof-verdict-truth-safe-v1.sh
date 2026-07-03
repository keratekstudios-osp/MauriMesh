#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "PATCH NATIVE PROOF VERDICT TRUTH SAFE v1"
echo "============================================================"
echo "Goal:"
echo "- Remove active nativeBleGattPacketBoundPass=true from proof verdict logic"
echo "- Keep PASS phrase only as a candidate/review rule, not a claimed result"
echo "- Preserve proof architecture"
echo "- Backup before change"
echo "- Run TypeScript"
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
TARGET="$ROOT/src/maurimesh/intelligence/proof/proofVerdict.ts"
BACKUP_DIR="$ROOT/backup-before-native-proof-verdict-truth-safe-v1-$STAMP"
REPORT_DIR="$ROOT/docs/intelligence"
REPORT="$REPORT_DIR/NATIVE_PROOF_VERDICT_TRUTH_SAFE_V1_$STAMP.md"
RAW="$REPORT_DIR/NATIVE_PROOF_VERDICT_TRUTH_SAFE_RAW_$STAMP.txt"

mkdir -p "$BACKUP_DIR/src/maurimesh/intelligence/proof" "$REPORT_DIR" "$ROOT/archives"
: > "$RAW"

if [ ! -f "$TARGET" ]; then
  echo "FAIL: $TARGET not found" | tee -a "$RAW"
  exit 1
fi

cp "$TARGET" "$BACKUP_DIR/src/maurimesh/intelligence/proof/proofVerdict.ts"

echo "Before context:" | tee -a "$RAW"
grep -n -C 8 "nativeBleGattPacketBoundPass.*true" "$TARGET" | tee -a "$RAW" || true

python3 - <<'PY'
from pathlib import Path

path = Path("src/maurimesh/intelligence/proof/proofVerdict.ts")
text = path.read_text()

original = text

# Truth lock:
# Native BLE/GATT packet-bound PASS must not be emitted by intelligence proof logic
# until physical native transport log evidence exists and has been reviewed.
text = text.replace(
    "nativeBleGattPacketBoundPass: true,",
    "nativeBleGattPacketBoundPass: false,"
)

text = text.replace(
    'verdict: "PASS_NATIVE_PACKET_BOUND_BLE_GATT_PROOF",',
    'verdict: "PASS_NATIVE_PACKET_BOUND_BLE_GATT_PROOF_CANDIDATE_REVIEW_REQUIRED",'
)

text = text.replace(
    "verdict: 'PASS_NATIVE_PACKET_BOUND_BLE_GATT_PROOF',",
    "verdict: 'PASS_NATIVE_PACKET_BOUND_BLE_GATT_PROOF_CANDIDATE_REVIEW_REQUIRED',"
)

text = text.replace(
    'result: "PASS_NATIVE_PACKET_BOUND_BLE_GATT_PROOF",',
    'result: "PASS_NATIVE_PACKET_BOUND_BLE_GATT_PROOF_CANDIDATE_REVIEW_REQUIRED",'
)

text = text.replace(
    "result: 'PASS_NATIVE_PACKET_BOUND_BLE_GATT_PROOF',",
    "result: 'PASS_NATIVE_PACKET_BOUND_BLE_GATT_PROOF_CANDIDATE_REVIEW_REQUIRED',"
)

if original == text:
    print("WARN: no direct source replacement was needed or pattern not found.")
else:
    path.write_text(text)
    print("PASS: source truth patch applied.")
PY

echo "" | tee -a "$RAW"
echo "After context:" | tee -a "$RAW"
grep -n -C 8 "nativeBleGattPacketBoundPass\|PASS_NATIVE_PACKET_BOUND_BLE_GATT_PROOF" "$TARGET" | tee -a "$RAW" || true

echo "" | tee -a "$RAW"
echo "Running TypeScript..." | tee -a "$RAW"

TSC_LOG="$REPORT_DIR/NATIVE_PROOF_VERDICT_TSC_$STAMP.log"
if npx tsc --noEmit > "$TSC_LOG" 2>&1; then
  TSC_RESULT="PASS"
  echo "PASS: TypeScript check passed" | tee -a "$RAW"
else
  TSC_RESULT="FAIL"
  echo "FAIL: TypeScript check failed. See $TSC_LOG" | tee -a "$RAW"
fi

echo "" | tee -a "$RAW"
echo "Rechecking active true claims..." | tee -a "$RAW"

ACTIVE_TRUE_SOURCE="$(grep -RIn "nativeBleGattPacketBoundPass.*true" src/maurimesh/intelligence/proof app src tools 2>/dev/null || true)"
echo "$ACTIVE_TRUE_SOURCE" | tee -a "$RAW"

if echo "$ACTIVE_TRUE_SOURCE" | grep -q "src/maurimesh/intelligence/proof/proofVerdict.ts"; then
  SOURCE_TRUE_RESULT="WARN_SOURCE_TRUE_REMAINS"
else
  SOURCE_TRUE_RESULT="PASS_NO_SOURCE_TRUE_IN_PROOF_VERDICT"
fi

cat > "$REPORT" <<MD
# MauriMesh Native Proof Verdict Truth Safe v1

Generated: $STAMP

## Result

- TypeScript: $TSC_RESULT
- Source true check: $SOURCE_TRUE_RESULT

## Patched File

src/maurimesh/intelligence/proof/proofVerdict.ts

## Truth Rule

Native BLE/GATT packet-bound PASS is not claimed until the same packetId appears inside native BLE/GATT transport logs from physical devices.

## What Changed

Any active \`nativeBleGattPacketBoundPass: true\` inside proof verdict logic was changed to \`false\`.

Any direct final verdict string \`PASS_NATIVE_PACKET_BOUND_BLE_GATT_PROOF\` inside proof verdict logic was downgraded to:

\`PASS_NATIVE_PACKET_BOUND_BLE_GATT_PROOF_CANDIDATE_REVIEW_REQUIRED\`

This preserves future proof review without making a false final claim.

## Backup

$BACKUP_DIR

## Raw

$RAW

## TypeScript Log

$TSC_LOG
MD

tar -czf "$ROOT/archives/native-proof-verdict-truth-safe-v1-$STAMP.tar.gz" \
  "$REPORT" "$RAW" "$TSC_LOG" "$BACKUP_DIR" 2>/dev/null || true

echo ""
echo "============================================================"
echo "PATCH COMPLETE"
echo "============================================================"
echo "TypeScript: $TSC_RESULT"
echo "Source true check: $SOURCE_TRUE_RESULT"
echo "Report: $REPORT"
echo "Backup: $BACKUP_DIR"
echo "Archive: $ROOT/archives/native-proof-verdict-truth-safe-v1-$STAMP.tar.gz"
echo "============================================================"

if [ "$TSC_RESULT" != "PASS" ]; then
  exit 1
fi
