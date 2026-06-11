#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
DOCS="$ROOT/docs"
mkdir -p "$DOCS"

REPORT="$DOCS/maurimesh-device-hardware-report-$STAMP.md"
LATEST="$DOCS/maurimesh-device-hardware-report-latest.md"

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

line "# MauriMesh Device Hardware Stabilizer Report"
line ""
line "Generated: $STAMP"
line ""

line "## Hardware Engine Files"

for file in \
  "src/maurimesh/device-hardware/types.ts" \
  "src/maurimesh/device-hardware/DeviceHardwareStabilizer.ts" \
  "src/maurimesh/device-hardware/HardwareRuntimePolicy.ts" \
  "src/maurimesh/device-hardware/index.ts"
do
  if has_file "$file"; then pass "$file exists"; else fail "$file missing"; fi
done

line ""
line "## UI Files"

if has_file "src/components/DeviceHardwarePanel.tsx"; then pass "DeviceHardwarePanel exists"; else fail "DeviceHardwarePanel missing"; fi
if has_file "app/device-hardware.tsx"; then pass "Device Hardware screen exists"; else fail "app/device-hardware.tsx missing"; fi

line ""
line "## Hardware Capabilities"

for token in \
  "analyseHardwareSample" \
  "updateHardwareLearningMemory" \
  "createRuntimePolicy" \
  "runHardwareStabilizerDemo" \
  "safeMode" \
  "scanIntensity" \
  "bleRetryPolicy" \
  "routePreference"
do
  if grep -R "$token" "$ROOT/src/maurimesh/device-hardware" >/dev/null 2>&1; then
    pass "Capability found: $token"
  else
    fail "Capability missing: $token"
  fi
done

line ""
line "## Route Wiring"

if has_text "app/dashboard.tsx" "/device-hardware"; then pass "Dashboard has /device-hardware"; else fail "Dashboard missing /device-hardware"; fi
if has_text "src/lib/uiBackupRoutes.ts" "/device-hardware"; then pass "Backup registry has /device-hardware"; else warn "Backup registry missing /device-hardware"; fi
if has_text "app/device-hardware.tsx" "DeviceHardwarePanel"; then pass "Screen uses DeviceHardwarePanel"; else fail "Screen missing DeviceHardwarePanel"; fi

line ""
line "## Truth Protection"

if has_text "src/maurimesh/device-hardware/DeviceHardwareStabilizer.ts" "cannot physically repair hardware"; then
  pass "Truth label prevents fake hardware repair claim"
else
  warn "Truth label not confirmed"
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

STATUS="INCOMPLETE"
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
echo "MAURIMESH DEVICE HARDWARE CHECK COMPLETE"
echo "Status: $STATUS"
echo "Score:  $SCORE%"
echo "Report: $LATEST"
echo "============================================================"
echo ""

if [ "$FAIL" -gt 0 ]; then exit 1; fi
