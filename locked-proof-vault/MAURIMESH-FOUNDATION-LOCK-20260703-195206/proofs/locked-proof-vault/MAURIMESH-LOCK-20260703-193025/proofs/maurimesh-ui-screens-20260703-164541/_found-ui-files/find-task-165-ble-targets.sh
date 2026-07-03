#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo "#165 TARGET FINDER — MeshCentralClient / BLE transport files"
echo "NO SOURCE CHANGES"
echo "============================================================"

echo ""
echo "1. Exact file search"
find . -type f \( \
  -name "MeshCentralClient.kt" -o \
  -name "*CentralClient*.kt" -o \
  -name "*BleClient*.kt" -o \
  -name "*BLEClient*.kt" -o \
  -name "*Gatt*.kt" -o \
  -name "*GATT*.kt" -o \
  -name "MauriMeshBleModule.kt" -o \
  -name "MeshBleEventEmitter.kt" \
\) -not -path "./node_modules/*" -not -path "./dist/*" | sort

echo ""
echo "2. Search Kotlin files for scan/client/write methods"
grep -RniE "class .*Central|class .*Client|startScan|stopScan|BluetoothGatt|writeCharacteristic|ScanCallback|BluetoothLeScanner|sendRawPacket|broadcastRawPacket" \
  android artifacts src 2>/dev/null | head -300 || true

echo ""
echo "3. Search plugin android-src folders"
find . -type d -path "*android-src*" -print | sort || true

echo ""
echo "4. Search BLE package folders"
find . -type d \( -iname "*ble*" -o -iname "*bluetooth*" -o -iname "*mesh*" \) \
  -not -path "./node_modules/*" -not -path "./dist/*" | sort | head -200

echo ""
echo "5. Confirm current proven native module"
grep -RniE "class MauriMeshBleModule|startScanProof|stopScanProof|getScanProofStatus|MauriMeshBlePackage" \
  android artifacts src 2>/dev/null | head -200 || true

echo ""
echo "============================================================"
echo "TARGET FIND COMPLETE"
echo "Paste this output back before running #165 patch."
echo "============================================================"
