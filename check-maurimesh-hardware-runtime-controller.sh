#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
DOCS="$ROOT/docs"
mkdir -p "$DOCS"

REPORT="$DOCS/maurimesh-hardware-runtime-controller-report-$STAMP.md"
LATEST="$DOCS/maurimesh-hardware-runtime-controller-report-latest.md"

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

line "# MauriMesh Hardware Runtime Controller Report"
line ""
line "Generated: $STAMP"
line ""

line "## Files"
for file in \
  "src/maurimesh/device-hardware/HardwareRuntimeController.ts" \
  "src/hooks/useHardwareRuntimeController.ts" \
  "src/components/HardwareRuntimeControllerPanel.tsx" \
  "app/hardware-runtime.tsx"
do
  if has_file "$file"; then pass "$file exists"; else fail "$file missing"; fi
done

line ""
line "## Capabilities"
for token in \
  "evaluateHardwareRuntimeController" \
  "createBleRuntimeTuning" \
  "createProofRuntimeTuning" \
  "shouldThrottleBle" \
  "shouldThrottleProof" \
  "shouldReduceAnimations" \
  "shouldUseStoreForward" \
  "runtimeMode" \
  "NATIVE_ANDROID" \
  "JS_FALLBACK"
do
  if grep -R "$token" "$ROOT/src/maurimesh/device-hardware/HardwareRuntimeController.ts" "$ROOT/src/components/HardwareRuntimeControllerPanel.tsx" "$ROOT/src/hooks/useHardwareRuntimeController.ts" >/dev/null 2>&1; then
    pass "Capability found: $token"
  else
    fail "Capability missing: $token"
  fi
done

line ""
line "## Route Wiring"
if has_text "app/dashboard.tsx" "/hardware-runtime"; then pass "Dashboard has /hardware-runtime"; else fail "Dashboard missing /hardware-runtime"; fi
if has_text "src/lib/uiBackupRoutes.ts" "/hardware-runtime"; then pass "Backup registry has /hardware-runtime"; else warn "Backup registry missing /hardware-runtime"; fi
if has_text "app/hardware-runtime.tsx" "HardwareRuntimeControllerPanel"; then pass "Screen uses HardwareRuntimeControllerPanel"; else fail "Screen missing panel"; fi

line ""
line "## Truth Protection"
if has_text "src/maurimesh/device-hardware/HardwareRuntimeController.ts" "cannot repair physical hardware"; then
  pass "Truth boundary present"
else
  warn "Truth boundary not confirmed"
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
echo "HARDWARE RUNTIME CONTROLLER CHECK COMPLETE"
echo "Status: $STATUS"
echo "Score:  $SCORE%"
echo "Report: $LATEST"
echo "============================================================"
echo ""

if [ "$FAIL" -gt 0 ]; then exit 1; fi
