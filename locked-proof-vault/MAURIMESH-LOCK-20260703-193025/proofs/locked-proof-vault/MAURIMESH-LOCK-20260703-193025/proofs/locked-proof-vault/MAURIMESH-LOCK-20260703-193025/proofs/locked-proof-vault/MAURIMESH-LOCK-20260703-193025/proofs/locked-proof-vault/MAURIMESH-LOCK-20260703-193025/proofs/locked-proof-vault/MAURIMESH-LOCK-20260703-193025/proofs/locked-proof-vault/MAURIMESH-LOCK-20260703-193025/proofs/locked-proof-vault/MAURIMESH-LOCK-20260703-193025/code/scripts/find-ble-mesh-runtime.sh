#!/usr/bin/env bash
set -euo pipefail

echo "=================================================="
echo "MauriMesh BLEMeshRuntime Finder"
echo "=================================================="

echo ""
echo "1. Exact class/name search"
grep -RIn --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=dist --exclude-dir=build \
  "BLEMeshRuntime\|BleMeshRuntime\|bleMeshRuntime" . || true

echo ""
echo "2. BLE + runtime keyword search"
grep -RIn --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=dist --exclude-dir=build \
  "BLE.*Runtime\|Runtime.*BLE\|Bluetooth.*Runtime\|Gatt.*Runtime\|Mesh.*Runtime" . || true

echo ""
echo "3. Candidate files"
find . -type f \
  \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" -o -name "*.kt" -o -name "*.swift" \) \
  | grep -Ei "ble|bluetooth|mesh|runtime|gatt|advertis|scanner" \
  | sort

echo ""
echo "4. Existing new runtime files"
find src -type f 2>/dev/null | grep -Ei "bluetoothMeshSuperEngine|mauri155|mauriAi|evolution|routing|governance|storeForward|jumpCode|ble" | sort || true

echo "=================================================="
