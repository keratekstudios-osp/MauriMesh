#!/usr/bin/env bash
set -e

echo "=================================================="
echo "MAURIMESH NATIVE BLE PROOF AUDIT — NO EAS BUILD"
echo "=================================================="

STAMP="$(date +%Y%m%d-%H%M%S)"
REPORT="docs/maurimesh-native-ble-proof-audit-$STAMP.md"
mkdir -p docs

echo "# MauriMesh Native BLE Proof Audit" > "$REPORT"
echo "" >> "$REPORT"
echo "Generated: $STAMP" >> "$REPORT"
echo "" >> "$REPORT"
echo "Purpose: identify existing BLE/native/proof files before restoring real wiring." >> "$REPORT"
echo "No files modified. No EAS build used." >> "$REPORT"
echo "" >> "$REPORT"

section() {
  echo "" | tee -a "$REPORT"
  echo "## $1" | tee -a "$REPORT"
  echo "" | tee -a "$REPORT"
}

section "1. Package Identity"

{
  echo '```txt'
  grep -R "namespace\|applicationId" android/app/build.gradle 2>/dev/null || true
  grep -R "package com.maurimesh.messenger" android/app/src/main/java 2>/dev/null || true
  npx expo config --type public | grep -E "name:|slug:|scheme:|package:|bundleIdentifier:" || true
  echo '```'
} | tee -a "$REPORT"

section "2. Android Manifest BLE Permissions"

{
  echo '```txt'
  grep -R "BLUETOOTH\|ACCESS_FINE_LOCATION\|ACCESS_COARSE_LOCATION\|NEARBY_WIFI_DEVICES\|FOREGROUND_SERVICE" android/app/src/main/AndroidManifest.xml android 2>/dev/null || true
  echo '```'
} | tee -a "$REPORT"

section "3. Native Android BLE / Proof Files"

{
  echo '```txt'
  find android/app/src/main/java android/app/src/main/kotlin android 2>/dev/null \
    -type f | grep -Ei "ble|bluetooth|maurimesh|proof|packet|ack|gatt|scan|advertis|receiver|transmit|relay" | sort || true
  echo '```'
} | tee -a "$REPORT"

section "4. TypeScript BLE / Mesh / Proof Files"

{
  echo '```txt'
  find app src scripts docs server 2>/dev/null \
    -type f | grep -Ei "ble|bluetooth|maurimesh|proof|packet|ack|gatt|scan|advertis|receiver|transmit|relay|mesh|route|ledger" | sort || true
  echo '```'
} | tee -a "$REPORT"

section "5. BLE Imports And Native Module References"

{
  echo '```txt'
  grep -RniE "react-native-ble-plx|BleManager|Bluetooth|NativeModules|TurboModule|MauriMeshBle|BLE|GATT|advertis|scan|ACK|TX_BLE|RX_BLE" app src android server scripts 2>/dev/null | head -300 || true
  echo '```'
} | tee -a "$REPORT"

section "6. Current Safe UI Route Markers"

{
  echo '```txt'
  grep -R "SAFE_HOME_DASHBOARD\|SAFE_DASHBOARD\|SAFE_BLE_PROOF_UI\|SAFE_PROOF_LEDGER\|API_FALLBACK_MESH_STATUS" app src 2>/dev/null || true
  echo '```'
} | tee -a "$REPORT"

section "7. Crash-Risk Scan"

{
  echo '```txt'
  if grep -R "unstable-native-tabs\|NativeTabs\|SplashScreen\|preventAutoHide\|hideAsync\|useFonts\|_layout.backup" app 2>/dev/null; then
    echo "FAIL: risky startup pattern found."
  else
    echo "PASS: no known risky startup patterns in app."
  fi
  echo '```'
} | tee -a "$REPORT"

section "8. TypeScript Check"

{
  echo '```txt'
  npx tsc --noEmit
  echo '```'
} | tee -a "$REPORT"

section "9. Clean Export Check"

{
  echo '```txt'
  rm -rf dist .expo
  npx expo export --platform android --clear
  echo '```'
} | tee -a "$REPORT"

echo ""
echo "=================================================="
echo "NATIVE BLE PROOF AUDIT COMPLETE — NO EAS BUILD USED"
echo "Report: $REPORT"
echo "=================================================="
