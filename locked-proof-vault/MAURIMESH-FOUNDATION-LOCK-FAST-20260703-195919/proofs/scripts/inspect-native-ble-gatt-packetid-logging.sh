#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo ""
echo "============================================================"
echo "MAURIMESH NATIVE BLE/GATT PACKET-ID LOGGING INSPECTION"
echo "============================================================"

echo ""
echo "[1] Logger helper:"
find "$ROOT/android/app/src/main" -type f -name "MauriMeshNativeBlePacketLogger.kt" -print 2>/dev/null || true

echo ""
echo "[2] Native logger usages:"
grep -RIn "MauriMeshNativeBlePacketLogger" "$ROOT/android/app/src/main" 2>/dev/null || true

echo ""
echo "[3] Required stage source references:"
for stage in \
  advertise_start_packetId \
  scan_result_packetId \
  gatt_write_packetId \
  gatt_read_packetId \
  characteristic_changed_packetId \
  relay_packetId \
  ack_packetId
do
  echo ""
  echo "Stage: $stage"
  grep -RIn "$stage" "$ROOT/android/app/src/main" "$ROOT/src" "$ROOT/app" 2>/dev/null || true
done

echo ""
echo "[4] BLE/GATT candidate files:"
find "$ROOT/android/app/src/main" -type f \( -name "*.kt" -o -name "*.java" \) 2>/dev/null | while read -r f; do
  if grep -E "BluetoothGatt|BluetoothLeAdvertiser|BluetoothLeScanner|ScanCallback|startAdvertising|onScanResult|writeCharacteristic|readCharacteristic|onCharacteristicChanged" "$f" >/dev/null 2>&1; then
    echo "$f"
  fi
done

echo ""
echo "============================================================"
echo "Inspection complete."
echo "============================================================"
