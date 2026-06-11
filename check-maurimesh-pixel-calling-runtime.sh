#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
DOCS="$ROOT/docs"
mkdir -p "$DOCS"

REPORT="$DOCS/maurimesh-pixel-calling-runtime-report-$STAMP.md"
LATEST="$DOCS/maurimesh-pixel-calling-runtime-report-latest.md"

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

line "# MauriMesh Pixel Calling Runtime Report"
line ""
line "Generated: $STAMP"
line ""

line "## Files"
for file in \
  "src/maurimesh/pixel-calling/PixelCallingTypes.ts" \
  "src/maurimesh/pixel-calling/PixelCallingRuntime.ts" \
  "src/maurimesh/pixel-calling/index.ts" \
  "src/components/PixelCallingRuntimePanel.tsx" \
  "app/pixel-calling.tsx"
do
  if has_file "$file"; then pass "$file exists"; else fail "$file missing"; fi
done

line ""
line "## Call Runtime Capabilities"
for token in \
  "CALL_RINGING" \
  "CALL_ACCEPTED" \
  "CALL_CONNECTED" \
  "STREAMING_READY" \
  "PUSH_TO_TALK_FALLBACK" \
  "VOICE_NOTE_FALLBACK" \
  "TEXT_FALLBACK" \
  "STORE_FORWARD_FALLBACK" \
  "CALL_FAILED_SAFE" \
  "BLE_CONTROL" \
  "WIFI_LOCAL_AUDIO" \
  "INTERNET_GATEWAY_AUDIO" \
  "createPixelCallFallbackOrder" \
  "decidePixelCallingRuntime" \
  "CALL_CONNECTED_PROOF" \
  "CALL_FALLBACK_PROOF"
do
  if grep -R "$token" "$ROOT/src/maurimesh/pixel-calling" "$ROOT/src/components/PixelCallingRuntimePanel.tsx" >/dev/null 2>&1; then
    pass "Capability found: $token"
  else
    fail "Capability missing: $token"
  fi
done

line ""
line "## Route Wiring"
if has_text "app/dashboard.tsx" "/pixel-calling"; then pass "Dashboard has /pixel-calling"; else fail "Dashboard missing /pixel-calling"; fi
if has_text "src/lib/uiBackupRoutes.ts" "/pixel-calling"; then pass "Backup registry has /pixel-calling"; else fail "Backup registry missing /pixel-calling"; fi
if has_text "app/pixel-calling.tsx" "PixelCallingRuntimePanel"; then pass "Screen uses PixelCallingRuntimePanel"; else fail "Screen missing runtime panel"; fi

line ""
line "## Embedded Wiring"
if has_text "app/device-proof.tsx" "PixelCallingRuntimePanel"; then pass "Device Proof includes PixelCallingRuntimePanel"; else warn "Device Proof embed not confirmed"; fi
if has_text "app/proof-ledger.tsx" "PixelCallingRuntimePanel"; then pass "Proof Ledger includes PixelCallingRuntimePanel"; else warn "Proof Ledger embed not confirmed"; fi
if has_text "app/message-fallback.tsx" "PixelCallingRuntimePanel"; then pass "Message Fallback includes PixelCallingRuntimePanel"; else warn "Message Fallback embed not confirmed"; fi

line ""
line "## Truth Protection"
if has_text "src/maurimesh/pixel-calling/PixelCallingRuntime.ts" "real audio calling is only proven by installed APK device logs"; then
  pass "Pixel Calling truth boundary present"
else
  warn "Pixel Calling truth boundary not confirmed"
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
echo "PIXEL CALLING RUNTIME CHECK COMPLETE"
echo "Status: $STATUS"
echo "Score:  $SCORE%"
echo "Report: $LATEST"
echo "============================================================"
echo ""

if [ "$FAIL" -gt 0 ]; then exit 1; fi
