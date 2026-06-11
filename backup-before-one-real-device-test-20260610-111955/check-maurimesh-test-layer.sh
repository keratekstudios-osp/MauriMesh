#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
REPORT="$ROOT/docs/maurimesh-test-layer-report-$STAMP.md"
LATEST="$ROOT/docs/maurimesh-test-layer-report-latest.md"

mkdir -p "$ROOT/docs"

TOTAL=0
PASS=0
WARN=0
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

: > "$REPORT"

{
  echo "# MauriMesh Test Layer Report"
  echo ""
  echo "Generated: $STAMP"
  echo ""
  echo "## Files"
} >> "$REPORT"

check_file "Test types" "src/maurimesh/test-layer/MauriMeshTestTypes.ts"
check_file "Test engine" "src/maurimesh/test-layer/MauriMeshFullTestEngine.ts"
check_file "Test index" "src/maurimesh/test-layer/index.ts"
check_file "Test panel" "src/components/MauriMeshTestLayerPanel.tsx"
check_file "Test route" "app/test-layer.tsx"

{
  echo ""
  echo "## One Button Test Capability"
} >> "$REPORT"

check_contains "One-button run function exists" "src/maurimesh/test-layer/MauriMeshFullTestEngine.ts" "runMauriMeshFullAppTest"
check_contains "Messaging beginning-to-end test exists" "src/maurimesh/test-layer/MauriMeshFullTestEngine.ts" "simulateMessagingBeginningToEndTest"
check_contains "3-hop BLE proof plan exists" "src/maurimesh/test-layer/MauriMeshFullTestEngine.ts" "THREE_HOP_BLE_PROOF_PLAN"
check_contains "Phone A sender required" "src/maurimesh/test-layer/MauriMeshFullTestEngine.ts" "PHONE_A_SENDER"
check_contains "Phone B relay required" "src/maurimesh/test-layer/MauriMeshFullTestEngine.ts" "PHONE_B_RELAY"
check_contains "Phone C receiver required" "src/maurimesh/test-layer/MauriMeshFullTestEngine.ts" "PHONE_C_RECEIVER"
check_contains "Strict ACK required" "src/maurimesh/test-layer/MauriMeshFullTestEngine.ts" "STRICT_ACK_REQUIRED"
check_contains "Relay ACK required" "src/maurimesh/test-layer/MauriMeshFullTestEngine.ts" "PHONE_B_RELAY_ACK_TO_A"
check_contains "Proof ledger hash required" "src/maurimesh/test-layer/MauriMeshFullTestEngine.ts" "PROOF_LEDGER_HASH_WRITTEN"
check_contains "Raw 32K false truth included" "src/maurimesh/test-layer/MauriMeshFullTestEngine.ts" "RAW_32K_LIVE_FALSE"
check_contains "Native Android proof required" "src/maurimesh/test-layer/MauriMeshFullTestEngine.ts" "NATIVE_ANDROID_REQUIRED"

{
  echo ""
  echo "## UI Wiring"
} >> "$REPORT"

check_contains "Route screen uses test panel" "app/test-layer.tsx" "MauriMeshTestLayerPanel"
check_contains "Dashboard has /test-layer marker" "app/dashboard.tsx" "/test-layer"
check_contains "Backup registry has /test-layer marker" "src/lib/uiBackupRoutes.ts" "/test-layer"
check_contains "Button label exists" "src/components/MauriMeshTestLayerPanel.tsx" "RUN FULL MAURIMESH TEST"
check_contains "PASS/WARN/FAIL result exists" "src/components/MauriMeshTestLayerPanel.tsx" "PASSED_WITH_WARNINGS"

{
  echo ""
  echo "## Existing Important Integration Markers"
} >> "$REPORT"

check_file "Message fallback engine" "src/maurimesh/message-fallback/MessageAckFallbackEngine.ts"
check_file "Hybrid Wi-Fi BLE engine" "src/maurimesh/hybrid-wifi-ble-mesh/BackupHybridWifiBleMeshEngine.ts"
check_file "BLE runtime adapter" "src/maurimesh/ble-runtime/BleHardwareRuntimeAdapter.ts"
check_file "Native telemetry bridge" "src/maurimesh/device-hardware/NativeHardwareTelemetry.ts"
check_file "Pixel calling backup" "src/maurimesh/pixel-calling/PixelCallingBackupFallback.ts"
check_file "AI pixel reconstruction" "src/maurimesh/pixel-calling/AiPixelReconstructionEngine.ts"

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

SCORE=$(( PASS * 100 / TOTAL ))
STATUS="COMPLETE"
if [ "$FAIL" -gt 0 ]; then
  STATUS="FAILED"
elif [ "$WARN" -gt 0 ]; then
  STATUS="COMPLETE_WITH_WARNINGS"
fi

{
  echo ""
  echo "## Summary"
  echo ""
  echo "- Total: $TOTAL"
  echo "- Complete: $PASS"
  echo "- Warnings: $WARN"
  echo "- Missing/failed: $FAIL"
  echo "- Score: $SCORE%"
  echo "- Status: **$STATUS**"
  echo ""
  echo "## Final Truth"
  echo ""
  echo "This test layer provides one-button in-app process testing for MauriMesh."
  echo "It validates known UI, route, messaging, ACK, 3-hop BLE proof requirements,"
  echo "Pixel Calling fallback, AI pixel reconstruction truth labels, and APK proof gates."
  echo ""
  echo "It does not fake real BLE pass. Real 3-hop BLE pass requires physical phones and APK/logcat evidence."
} >> "$REPORT"

cp "$REPORT" "$LATEST"

cat "$REPORT"

echo ""
echo "============================================================"
echo "MAURIMESH TEST LAYER CHECK COMPLETE"
echo "Status: $STATUS"
echo "Score:  $SCORE%"
echo "Report: $LATEST"
echo "============================================================"
