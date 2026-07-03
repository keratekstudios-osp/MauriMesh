#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "FIX NATIVE BLE/GATT WARNING CLEAN v1"
echo "============================================================"
echo "Goal:"
echo "- Remove active source claim nativeBleGattPacketBoundPass: true"
echo "- Keep docs/tool detector phrases safe"
echo "- Create cleaner warning report"
echo "- Run TypeScript"
echo "============================================================"

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
TARGET="$ROOT/src/maurimesh/intelligence/proof/proofVerdict.ts"
BACKUP="$ROOT/backup-before-fix-native-ble-gatt-warning-clean-v1-$STAMP"
REPORT_DIR="$ROOT/docs/intelligence"
REPORT="$REPORT_DIR/FIX_NATIVE_BLE_GATT_WARNING_CLEAN_V1_$STAMP.md"
RAW="$REPORT_DIR/FIX_NATIVE_BLE_GATT_WARNING_CLEAN_RAW_$STAMP.txt"

mkdir -p "$BACKUP" "$REPORT_DIR" "$ROOT/archives"
: > "$RAW"

echo ""
echo "============================================================"
echo "CURRENT MATCHES"
echo "============================================================" | tee -a "$RAW"

grep -RIn \
  "nativeBleGattPacketBoundPass.*true\|PASS_NATIVE_PACKET_BOUND_BLE_GATT_PROOF\|NATIVE_PACKET_BOUND_PASS=true" \
  app src docs tools \
  2>/dev/null | tee -a "$RAW" || true

if [ -f "$TARGET" ]; then
  mkdir -p "$BACKUP/src/maurimesh/intelligence/proof"
  cp "$TARGET" "$BACKUP/src/maurimesh/intelligence/proof/proofVerdict.ts"

  python3 - <<'PY'
from pathlib import Path

path = Path("src/maurimesh/intelligence/proof/proofVerdict.ts")
text = path.read_text()
original = text

# Never allow the intelligence verdict source to emit a final native BLE/GATT PASS
# until physical packet-bound native logs have been captured and reviewed.
text = text.replace("nativeBleGattPacketBoundPass: true,", "nativeBleGattPacketBoundPass: false,")
text = text.replace("nativeBleGattPacketBoundPass:true,", "nativeBleGattPacketBoundPass:false,")

text = text.replace(
    '"PASS_NATIVE_PACKET_BOUND_BLE_GATT_PROOF"',
    '"PASS_NATIVE_PACKET_BOUND_BLE_GATT_PROOF_CANDIDATE_REVIEW_REQUIRED"'
)
text = text.replace(
    "'PASS_NATIVE_PACKET_BOUND_BLE_GATT_PROOF'",
    "'PASS_NATIVE_PACKET_BOUND_BLE_GATT_PROOF_CANDIDATE_REVIEW_REQUIRED'"
)

if text != original:
    path.write_text(text)
    print("PASS: proofVerdict.ts patched to block final native BLE/GATT PASS.")
else:
    print("INFO: proofVerdict.ts did not need direct replacement.")
PY
else
  echo "WARN: $TARGET not found" | tee -a "$RAW"
fi

echo ""
echo "============================================================"
echo "ACTIVE SOURCE CLAIM CHECK"
echo "============================================================" | tee -a "$RAW"

ACTIVE_SOURCE_MATCHES="$(grep -RIn \
  "nativeBleGattPacketBoundPass[[:space:]]*:[[:space:]]*true\|nativeBleGattPacketBoundPass:true\|verdict[[:space:]]*:[[:space:]]*['\"]PASS_NATIVE_PACKET_BOUND_BLE_GATT_PROOF['\"]\|result[[:space:]]*:[[:space:]]*['\"]PASS_NATIVE_PACKET_BOUND_BLE_GATT_PROOF['\"]" \
  app src \
  2>/dev/null || true)"

if [ -n "$ACTIVE_SOURCE_MATCHES" ]; then
  echo "$ACTIVE_SOURCE_MATCHES" | tee -a "$RAW"
  ACTIVE_RESULT="WARN_ACTIVE_SOURCE_CLAIM_REMAINS"
else
  echo "PASS: no active source final native BLE/GATT PASS claim found" | tee -a "$RAW"
  ACTIVE_RESULT="PASS_NO_ACTIVE_SOURCE_NATIVE_PASS_CLAIM"
fi

echo ""
echo "============================================================"
echo "SAFE DOC / TOOL REFERENCES"
echo "============================================================" | tee -a "$RAW"

grep -RIn \
  "nativeBleGattPacketBoundPass=true\|PASS_NATIVE_PACKET_BOUND_BLE_GATT_PROOF\|NATIVE_PACKET_BOUND_PASS=true" \
  docs tools app/proof-vault-health.tsx app/native-ble-gatt-proof.tsx \
  2>/dev/null | tee -a "$RAW" || true

echo ""
echo "============================================================"
echo "TYPESCRIPT CHECK"
echo "============================================================" | tee -a "$RAW"

TSC_LOG="$REPORT_DIR/FIX_NATIVE_BLE_GATT_WARNING_TSC_$STAMP.log"

if npx tsc --noEmit > "$TSC_LOG" 2>&1; then
  TSC_RESULT="PASS"
  echo "PASS: TypeScript check passed" | tee -a "$RAW"
else
  TSC_RESULT="FAIL"
  echo "FAIL: TypeScript check failed. See $TSC_LOG" | tee -a "$RAW"
fi

cat > "$REPORT" <<MD
# Fix Native BLE/GATT Warning Clean v1

Generated: $STAMP

## Result

- Active source check: **$ACTIVE_RESULT**
- TypeScript: **$TSC_RESULT**

## Meaning

MauriMesh may keep native BLE/GATT PASS phrases inside:
- documentation
- detector tools
- proof vault wording
- candidate review rules

But active app/source logic must not emit a final native BLE/GATT PASS while physical packet-bound native logs are pending.

## Truth

Native BLE/GATT packet-bound PASS remains **PENDING** until the same packetId appears inside native BLE/GATT transport logs from physical phones.

## Backup

$BACKUP

## Raw

$RAW

## TypeScript Log

$TSC_LOG
MD

tar -czf "$ROOT/archives/fix-native-ble-gatt-warning-clean-v1-$STAMP.tar.gz" \
  "$REPORT" "$RAW" "$TSC_LOG" "$BACKUP" 2>/dev/null || true

echo ""
echo "============================================================"
echo "FIX COMPLETE"
echo "============================================================"
echo "Active source check: $ACTIVE_RESULT"
echo "TypeScript: $TSC_RESULT"
echo "Report: $REPORT"
echo "Archive: $ROOT/archives/fix-native-ble-gatt-warning-clean-v1-$STAMP.tar.gz"
echo "============================================================"

if [ "$TSC_RESULT" != "PASS" ]; then
  exit 1
fi
