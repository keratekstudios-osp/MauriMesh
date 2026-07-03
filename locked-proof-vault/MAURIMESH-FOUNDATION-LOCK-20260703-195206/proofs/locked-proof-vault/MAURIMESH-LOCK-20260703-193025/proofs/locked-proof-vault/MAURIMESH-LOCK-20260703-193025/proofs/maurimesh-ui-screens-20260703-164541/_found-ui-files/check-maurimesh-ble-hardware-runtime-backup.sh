#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
DOCS="$ROOT/docs"
mkdir -p "$DOCS"

REPORT="$DOCS/maurimesh-ble-hardware-runtime-backup-report-$STAMP.md"
LATEST="$DOCS/maurimesh-ble-hardware-runtime-backup-report-latest.md"

PASS=0
FAIL=0
WARN=0

line(){ echo "$1" | tee -a "$REPORT"; }
pass(){ PASS=$((PASS+1)); line "- [x] $1"; }
fail(){ FAIL=$((FAIL+1)); line "- [ ] MISSING: $1"; }
warn(){ WARN=$((WARN+1)); line "- [!] PARTIAL: $1"; }

has_file(){ [ -f "$ROOT/$1" ]; }
has_text(){ [ -f "$ROOT/$1" ] && grep -Fq "$2" "$ROOT/$1"; }

: > "$REPORT"

line "# MauriMesh BLE Hardware Runtime Backup Report"
line ""
line "Generated: $STAMP"
line ""

line "## Files"
for file in \
  "src/maurimesh/ble-runtime/BleHardwareBackupPolicy.ts" \
  "src/maurimesh/ble-runtime/BleHardwareRuntimeAdapter.ts" \
  "src/maurimesh/ble-runtime/index.ts" \
  "src/components/BleHardwareRuntimePanel.tsx" \
  "app/ble-hardware-runtime.tsx"
do
  if has_file "$file"; then pass "$file exists"; else fail "$file missing"; fi
done

line ""
line "## Capabilities"
for token in \
  "evaluateBleHardwareRuntime" \
  "createBleHardwareBackupPolicy" \
  "shouldStartBleScan" \
  "shouldAdvertiseBle" \
  "getBleRetryLimit" \
  "BACKUP_CONTROLLED" \
  "NATIVE_CONTROLLED" \
  "JS_FALLBACK_CONTROLLED" \
  "scanCooldownMs" \
  "maxRetries" \
  "allowProofHashing"
do
  if grep -R "$token" "$ROOT/src/maurimesh/ble-runtime" "$ROOT/src/components/BleHardwareRuntimePanel.tsx" >/dev/null 2>&1; then
    pass "Capability found: $token"
  else
    fail "Capability missing: $token"
  fi
done

line ""
line "## Route + Backup Wiring"
if has_text "app/dashboard.tsx" "/ble-hardware-runtime"; then pass "Dashboard has /ble-hardware-runtime"; else fail "Dashboard missing /ble-hardware-runtime"; fi
if has_text "src/lib/uiBackupRoutes.ts" "/ble-hardware-runtime"; then pass "Backup registry has /ble-hardware-runtime"; else fail "Backup registry missing /ble-hardware-runtime"; fi
if has_text "app/ble-hardware-runtime.tsx" "BleHardwareRuntimePanel"; then pass "Screen uses BleHardwareRuntimePanel"; else fail "Screen missing panel"; fi

if has_file "app/mauricore-ble-runtime.tsx"; then
  if has_text "app/mauricore-ble-runtime.tsx" "BleHardwareRuntimePanel"; then
    pass "MauriCore BLE Runtime includes hardware runtime panel"
  else
    warn "MauriCore BLE Runtime route exists but panel not embedded"
  fi
else
  warn "MauriCore BLE Runtime screen not found, standalone /ble-hardware-runtime still exists"
fi

line ""
line "## Truth Protection"
if has_text "src/maurimesh/ble-runtime/BleHardwareRuntimeAdapter.ts" "Real BLE delivery still requires APK TX/RX/ACK logcat proof"; then
  pass "BLE truth boundary present"
else
  warn "BLE truth boundary not confirmed"
fi

line ""
line "## TypeScript"
if npx tsc --noEmit >> "$REPORT" 2>&1; then
  pass "TypeScript passed"
else
  fail "TypeScript failed"
fi

TOTAL=$((PASS + FAIL + WARN))
if [ "$TOTAL" -gt 0 ]; then SCORE=$((PASS * 100 / TOTAL)); else SCORE=0; fi

if [ "$FAIL" -eq 0 ] && [ "$WARN" -eq 0 ]; then
  STATUS="COMPLETE"
elif [ "$FAIL" -eq 0 ]; then
  STATUS="COMPLETE_WITH_WARNINGS"
else
  STATUS="INCOMPLETE"
fi

line ""
line "## Summary"
line ""
line "- Total: $TOTAL"
line "- Complete: $PASS"
line "- Partial: $WARN"
line "- Missing/failed: $FAIL"
line "- Score: $SCORE%"
line "- Status: **$STATUS**"

cp "$REPORT" "$LATEST"

echo ""
echo "============================================================"
echo "BLE HARDWARE RUNTIME BACKUP CHECK COMPLETE"
echo "Status: $STATUS"
echo "Score:  $SCORE%"
echo "Report: $LATEST"
echo "============================================================"
echo ""

if [ "$FAIL" -gt 0 ]; then exit 1; fi
