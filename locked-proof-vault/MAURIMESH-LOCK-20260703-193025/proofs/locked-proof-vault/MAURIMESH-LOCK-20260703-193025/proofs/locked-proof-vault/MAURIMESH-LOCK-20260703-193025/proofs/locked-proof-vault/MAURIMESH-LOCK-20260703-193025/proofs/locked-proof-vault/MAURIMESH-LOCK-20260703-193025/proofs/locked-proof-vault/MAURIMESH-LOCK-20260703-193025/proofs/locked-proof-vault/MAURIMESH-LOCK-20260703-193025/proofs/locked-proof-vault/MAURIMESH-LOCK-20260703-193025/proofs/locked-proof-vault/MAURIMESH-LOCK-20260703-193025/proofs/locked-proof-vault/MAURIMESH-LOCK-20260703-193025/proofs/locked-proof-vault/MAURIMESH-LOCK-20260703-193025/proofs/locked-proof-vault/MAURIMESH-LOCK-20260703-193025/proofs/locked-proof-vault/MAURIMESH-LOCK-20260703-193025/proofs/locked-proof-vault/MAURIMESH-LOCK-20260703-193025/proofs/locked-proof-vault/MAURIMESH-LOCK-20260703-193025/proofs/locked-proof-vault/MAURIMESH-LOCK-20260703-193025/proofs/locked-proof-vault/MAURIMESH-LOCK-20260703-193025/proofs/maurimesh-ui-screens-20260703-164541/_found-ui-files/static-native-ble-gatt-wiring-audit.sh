#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH STATIC NATIVE BLE/GATT WIRING AUDIT"
echo "============================================================"
echo "Goal:"
echo "- Static audit patched native Kotlin files"
echo "- Check logger package visibility"
echo "- Show patched line context"
echo "- Check missing native packet stages"
echo "- Do NOT build"
echo "- Do NOT claim native BLE/GATT pass"
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +"%Y%m%d-%H%M%S")"
OUT_DIR="$ROOT/docs/native-proof"
mkdir -p "$OUT_DIR" "$ROOT/archives"

REPORT="$OUT_DIR/STATIC_NATIVE_BLE_GATT_WIRING_AUDIT_$STAMP.md"
DETAILS="$OUT_DIR/static-native-ble-gatt-wiring-details-$STAMP.txt"

LOGGER="$ROOT/android/app/src/main/java/com/maurimesh/messenger/MauriMeshNativeBlePacketLogger.kt"

FILES=(
  "$ROOT/android/app/src/main/java/com/maurimesh/mesh/MeshEngine.kt"
  "$ROOT/android/app/src/main/java/com/maurimesh/messenger/MauriMeshBleModule.kt"
  "$ROOT/android/app/src/main/java/com/maurimesh/messenger/MeshCentralClient.kt"
  "$ROOT/android/app/src/main/java/com/maurimesh/messenger/MeshRawPacketGattServer.kt"
  "$ROOT/android/app/src/main/java/com/maurimesh/messenger/maurimesh/blehardware/MauriMeshHardwareBleScanService.kt"
)

echo "[1/5] Checking logger helper..."

{
  echo "Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  echo ""
  echo "Logger file:"
  echo "$LOGGER"
  echo ""

  if [ -f "$LOGGER" ]; then
    echo "LOGGER_FOUND=yes"
    echo ""
    head -40 "$LOGGER"
  else
    echo "LOGGER_FOUND=no"
  fi
} > "$DETAILS"

echo "[2/5] Checking package/import visibility..."

{
  echo ""
  echo "============================================================"
  echo "PACKAGE + IMPORT CHECK"
  echo "============================================================"
} >> "$DETAILS"

for f in "${FILES[@]}"; do
  if [ -f "$f" ]; then
    PKG="$(grep -E '^package ' "$f" | head -1 | sed 's/package //')"
    USES="$(grep -n 'MauriMeshNativeBlePacketLogger' "$f" || true)"
    IMPORTS="$(grep -n 'import com.maurimesh.messenger.MauriMeshNativeBlePacketLogger' "$f" || true)"

    {
      echo ""
      echo "FILE: $f"
      echo "PACKAGE: ${PKG:-none}"
      echo "USES_LOGGER:"
      if [ -n "$USES" ]; then echo "$USES"; else echo "no"; fi
      echo "IMPORT_LOGGER:"
      if [ -n "$IMPORTS" ]; then echo "$IMPORTS"; else echo "no"; fi

      if [ -n "$USES" ] && [ "$PKG" != "com.maurimesh.messenger" ] && [ -z "$IMPORTS" ]; then
        echo "ISSUE: uses logger from different package but import is missing"
      else
        echo "PACKAGE_VISIBILITY: ok_or_not_needed"
      fi
    } >> "$DETAILS"
  fi
done

echo "[3/5] Showing patched logger context..."

{
  echo ""
  echo "============================================================"
  echo "PATCHED LOGGER CONTEXT"
  echo "============================================================"
} >> "$DETAILS"

grep -RIn "MauriMeshNativeBlePacketLogger\." "$ROOT/android/app/src/main/java" 2>/dev/null \
  | grep -v "MauriMeshNativeBlePacketLogger.kt" \
  | while IFS=: read -r file line rest; do
      echo "" >> "$DETAILS"
      echo "FILE: $file" >> "$DETAILS"
      echo "LINE: $line" >> "$DETAILS"
      START=$((line-5)); if [ "$START" -lt 1 ]; then START=1; fi
      END=$((line+5))
      sed -n "${START},${END}p" "$file" >> "$DETAILS"
      echo "------------------------------------------------------------" >> "$DETAILS"
    done || true

echo "[4/5] Checking actual stage coverage..."

{
  echo ""
  echo "============================================================"
  echo "ACTUAL STAGE COVERAGE"
  echo "============================================================"
} >> "$DETAILS"

check_stage() {
  local label="$1"
  local pattern="$2"

  if grep -RIn "$pattern" "$ROOT/android/app/src/main/java" 2>/dev/null | grep -v "MauriMeshNativeBlePacketLogger.kt" >/dev/null 2>&1; then
    echo "$label: WIRED" >> "$DETAILS"
  else
    echo "$label: MISSING_ACTUAL_USAGE" >> "$DETAILS"
  fi
}

check_stage "advertise_start_packetId" "MauriMeshNativeBlePacketLogger\.advertiseStart"
check_stage "scan_result_packetId" "MauriMeshNativeBlePacketLogger\.scanResult"
check_stage "gatt_write_packetId" "MauriMeshNativeBlePacketLogger\.gattWrite"
check_stage "gatt_read_packetId" "MauriMeshNativeBlePacketLogger\.gattRead"
check_stage "characteristic_changed_packetId" "MauriMeshNativeBlePacketLogger\.characteristicChanged"
check_stage "relay_packetId" "MauriMeshNativeBlePacketLogger\.relay"
check_stage "ack_packetId" "MauriMeshNativeBlePacketLogger\.ack"

echo "[5/5] Writing final audit report..."

MISSING_IMPORT_COUNT="$(grep -c 'ISSUE: uses logger from different package but import is missing' "$DETAILS" || true)"
LOGGER_USE_COUNT="$(grep -RIn "MauriMeshNativeBlePacketLogger\." "$ROOT/android/app/src/main/java" 2>/dev/null | grep -v "MauriMeshNativeBlePacketLogger.kt" | wc -l | tr -d ' ')"

cat > "$REPORT" <<MD
# MauriMesh Static Native BLE/GATT Wiring Audit

Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")

## Result

Static audit complete.

## Summary

- Logger helper exists: $([ -f "$LOGGER" ] && echo YES || echo NO)
- Actual logger call count excluding helper: $LOGGER_USE_COUNT
- Missing import/package visibility issues: $MISSING_IMPORT_COUNT

## Details

\`\`\`txt
$DETAILS
\`\`\`

## Current Truth

Native BLE/GATT packet-bound PASS is **NOT CLAIMED**.

Replit local Gradle compile is blocked because Android SDK is missing.

This audit only checks source wiring shape before EAS/cloud/native compile.

## Known Current Actual Coverage

Run details file for exact result:

\`\`\`txt
$DETAILS
\`\`\`

## Next Step

If missing import count is 0, next safe step is an EAS cloud build compile check.

If missing import count is greater than 0, patch imports first.

## Required Native Packet-Bound PASS Stages

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

ARCHIVE="$ROOT/archives/maurimesh-static-native-ble-gatt-wiring-audit-$STAMP.tar.gz"
tar -czf "$ARCHIVE" -C "$ROOT" "docs/native-proof" >/dev/null 2>&1 || true

echo ""
echo "============================================================"
echo "MAURIMESH STATIC NATIVE BLE/GATT WIRING AUDIT COMPLETE"
echo "============================================================"
echo "Logger call count excluding helper:"
echo "$LOGGER_USE_COUNT"
echo ""
echo "Missing import/package issues:"
echo "$MISSING_IMPORT_COUNT"
echo ""
echo "Details:"
echo "$DETAILS"
echo ""
echo "Report:"
echo "$REPORT"
echo ""
echo "Archive:"
echo "$ARCHIVE"
echo ""
echo "FINAL TRUTH:"
echo "Static audit only."
echo "Native BLE/GATT packet-bound PASS is NOT claimed."
echo "============================================================"
