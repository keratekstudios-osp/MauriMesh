#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
DOCS="$ROOT/docs"
mkdir -p "$DOCS"

REPORT="$DOCS/maurimesh-native-telemetry-report-$STAMP.md"
LATEST="$DOCS/maurimesh-native-telemetry-report-latest.md"

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

line "# MauriMesh Native Telemetry Bridge Report"
line ""
line "Generated: $STAMP"
line ""

line "## Files"
if has_file "src/maurimesh/device-hardware/NativeHardwareTelemetry.ts"; then pass "NativeHardwareTelemetry.ts exists"; else fail "NativeHardwareTelemetry.ts missing"; fi
if has_file "src/components/NativeTelemetryPanel.tsx"; then pass "NativeTelemetryPanel.tsx exists"; else fail "NativeTelemetryPanel.tsx missing"; fi
if has_file "app/native-telemetry.tsx"; then pass "app/native-telemetry.tsx exists"; else fail "app/native-telemetry.tsx missing"; fi

line ""
line "## Capabilities"
for token in getNativeHardwareTelemetry telemetryToHardwareSample NativeModules MauriMeshHardwareTelemetry JS_FALLBACK NATIVE_ANDROID batteryPercent memoryPressure storagePressure bleEnabled; do
  if grep -R "$token" "$ROOT/src/maurimesh/device-hardware/NativeHardwareTelemetry.ts" "$ROOT/src/components/NativeTelemetryPanel.tsx" >/dev/null 2>&1; then
    pass "Capability found: $token"
  else
    fail "Capability missing: $token"
  fi
done

line ""
line "## Route Wiring"
if has_text "app/dashboard.tsx" "/native-telemetry"; then pass "Dashboard has /native-telemetry"; else fail "Dashboard missing /native-telemetry"; fi
if has_text "src/lib/uiBackupRoutes.ts" "/native-telemetry"; then pass "Backup registry has /native-telemetry"; else warn "Backup registry missing /native-telemetry"; fi
if has_text "app/native-telemetry.tsx" "NativeTelemetryPanel"; then pass "Screen uses NativeTelemetryPanel"; else fail "Screen missing NativeTelemetryPanel"; fi

line ""
line "## Truth Protection"
if has_text "src/maurimesh/device-hardware/NativeHardwareTelemetry.ts" "cannot physically repair hardware"; then
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
echo "MAURIMESH NATIVE TELEMETRY CHECK COMPLETE"
echo "Status: $STATUS"
echo "Score:  $SCORE%"
echo "Report: $LATEST"
echo "============================================================"
echo ""

if [ "$FAIL" -gt 0 ]; then exit 1; fi
