#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
REPORT="$ROOT/docs/maurimesh-native-hardware-ble-proof-$STAMP.md"
LATEST="$ROOT/docs/maurimesh-native-hardware-ble-proof-latest.md"
EXPORT_DIR="$ROOT/.maurimesh-native-hardware-ble-export-$STAMP"

mkdir -p "$ROOT/docs"
: > "$REPORT"

TOTAL=0
PASS=0
FAIL=0

check_file() {
  local label="$1"
  local file="$2"
  TOTAL=$((TOTAL+1))
  if [ -f "$ROOT/$file" ]; then
    echo "- [x] $label exists: $file" >> "$REPORT"
    PASS=$((PASS+1))
  else
    echo "- [ ] MISSING: $label: $file" >> "$REPORT"
    FAIL=$((FAIL+1))
  fi
}

check_contains() {
  local label="$1"
  local file="$2"
  local needle="$3"
  TOTAL=$((TOTAL+1))
  if [ -f "$ROOT/$file" ] && grep -q "$needle" "$ROOT/$file"; then
    echo "- [x] $label" >> "$REPORT"
    PASS=$((PASS+1))
  else
    echo "- [ ] MISSING: $label" >> "$REPORT"
    FAIL=$((FAIL+1))
  fi
}

{
  echo "# MauriMesh Native Hardware BLE Proof Install Check"
  echo ""
  echo "Generated: $STAMP"
  echo ""
  echo "## Files"
} >> "$REPORT"

check_file "Native BLE module" "android/app/src/main/java/com/maurimesh/messenger/maurimesh/blehardware/MauriMeshHardwareBleModule.kt"
check_file "Native BLE package" "android/app/src/main/java/com/maurimesh/messenger/maurimesh/blehardware/MauriMeshHardwareBlePackage.kt"
check_file "Native BLE foreground scan service" "android/app/src/main/java/com/maurimesh/messenger/maurimesh/blehardware/MauriMeshHardwareBleScanService.kt"
check_file "JS native bridge" "src/native/MauriMeshHardwareBle.ts"
check_file "Hardware BLE proof panel" "src/components/HardwareBleProofPanel.tsx"
check_file "Hardware BLE proof route" "app/hardware-ble-proof.tsx"

{
  echo ""
  echo "## Native Wiring"
} >> "$REPORT"

check_contains "MainApplication package import/wiring" "android/app/src/main/java/com/maurimesh/messenger/MainApplication.kt" "MauriMeshHardwareBlePackage"
check_contains "Manifest BLUETOOTH_SCAN permission" "android/app/src/main/AndroidManifest.xml" "android.permission.BLUETOOTH_SCAN"
check_contains "Manifest BLUETOOTH_CONNECT permission" "android/app/src/main/AndroidManifest.xml" "android.permission.BLUETOOTH_CONNECT"
check_contains "Manifest foreground service permission" "android/app/src/main/AndroidManifest.xml" "android.permission.FOREGROUND_SERVICE"
check_contains "Manifest connected device foreground service permission" "android/app/src/main/AndroidManifest.xml" "android.permission.FOREGROUND_SERVICE_CONNECTED_DEVICE"
check_contains "Manifest service registered" "android/app/src/main/AndroidManifest.xml" "MauriMeshHardwareBleScanService"
check_contains "BluetoothLeScanner used" "android/app/src/main/java/com/maurimesh/messenger/maurimesh/blehardware/MauriMeshHardwareBleScanService.kt" "BluetoothLeScanner"
check_contains "Native scan started marker" "android/app/src/main/java/com/maurimesh/messenger/maurimesh/blehardware/MauriMeshHardwareBleScanService.kt" "MAURIMESH_NATIVE_BLE_SCAN_STARTED"
check_contains "Native scan result marker" "android/app/src/main/java/com/maurimesh/messenger/maurimesh/blehardware/MauriMeshHardwareBleScanService.kt" "MAURIMESH_NATIVE_BLE_SCAN_RESULT"

{
  echo ""
  echo "## UI Wiring"
} >> "$REPORT"

check_contains "Route uses HardwareBleProofPanel" "app/hardware-ble-proof.tsx" "HardwareBleProofPanel"
check_contains "Panel calls start scan" "src/components/HardwareBleProofPanel.tsx" "startMauriMeshHardwareBleScan"
check_contains "Panel requests permissions" "src/components/HardwareBleProofPanel.tsx" "requestMauriMeshHardwareBlePermissions"
check_contains "Dashboard references /hardware-ble-proof" "app/dashboard.tsx" "/hardware-ble-proof"
check_contains "Backup registry references /hardware-ble-proof" "src/lib/uiBackupRoutes.ts" "/hardware-ble-proof"

{
  echo ""
  echo "## TypeScript"
} >> "$REPORT"

TOTAL=$((TOTAL+1))
if npx tsc --noEmit >> "$REPORT" 2>&1; then
  echo "- [x] TypeScript passed" >> "$REPORT"
  PASS=$((PASS+1))
else
  echo "- [ ] TypeScript failed" >> "$REPORT"
  FAIL=$((FAIL+1))
fi

{
  echo ""
  echo "## Expo Android Export"
} >> "$REPORT"

TOTAL=$((TOTAL+1))
rm -rf "$EXPORT_DIR"
if NODE_ENV=production npx expo export --platform android --output-dir "$EXPORT_DIR" >> "$REPORT" 2>&1; then
  echo "- [x] Expo Android export passed" >> "$REPORT"
  PASS=$((PASS+1))
else
  echo "- [ ] Expo Android export failed" >> "$REPORT"
  FAIL=$((FAIL+1))
fi

SCORE=$(( PASS * 100 / TOTAL ))
STATUS="COMPLETE"
if [ "$FAIL" -gt 0 ]; then
  STATUS="FAILED"
fi

{
  echo ""
  echo "## Summary"
  echo ""
  echo "- Total: $TOTAL"
  echo "- Complete: $PASS"
  echo "- Missing/failed: $FAIL"
  echo "- Score: $SCORE%"
  echo "- Status: **$STATUS**"
  echo ""
  echo "## Final Truth"
  echo ""
  echo "Native Android BLE hardware scan bridge is installed in source."
  echo "It is not active inside the installed APK until EAS rebuilds the native Android binary."
  echo "After rebuilding/installing, open /hardware-ble-proof, request permissions, start scan, turn screen off, then check Android Bluetooth scan history."
} >> "$REPORT"

cp "$REPORT" "$LATEST"
cat "$REPORT"

echo ""
echo "============================================================"
echo "NATIVE HARDWARE BLE PROOF CHECK COMPLETE"
echo "Status: $STATUS"
echo "Score: $SCORE%"
echo "Report: $LATEST"
echo "============================================================"

if [ "$STATUS" != "COMPLETE" ]; then
  exit 1
fi
