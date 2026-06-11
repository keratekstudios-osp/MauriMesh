#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
DOCS="$ROOT/docs"
mkdir -p "$DOCS"

REPORT="$DOCS/maurimesh-message-ack-fallback-report-$STAMP.md"
LATEST="$DOCS/maurimesh-message-ack-fallback-report-latest.md"

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

line "# MauriMesh Message Queue + ACK Fallback Report"
line ""
line "Generated: $STAMP"
line ""

line "## Files"
for file in \
  "src/maurimesh/message-fallback/MessageFallbackTypes.ts" \
  "src/maurimesh/message-fallback/MessageFallbackQueue.ts" \
  "src/maurimesh/message-fallback/AckFallbackEngine.ts" \
  "src/maurimesh/message-fallback/MessageAckFallbackEngine.ts" \
  "src/maurimesh/message-fallback/index.ts" \
  "src/components/MessageFallbackPanel.tsx" \
  "app/message-fallback.tsx"
do
  if has_file "$file"; then pass "$file exists"; else fail "$file missing"; fi
done

line ""
line "## Delivery + ACK Capabilities"
for token in \
  "STORE_FORWARD_QUEUE" \
  "QUEUED_FOR_RETRY" \
  "RETRY_WAITING" \
  "DELIVERED_PENDING_ACK" \
  "DELIVERED_WITH_STRICT_ACK" \
  "DELIVERED_WITH_RELAY_ACK" \
  "DELIVERY_PENDING_PROOF" \
  "OFFLINE_HOLD" \
  "STRICT_ACK" \
  "DELAYED_ACK" \
  "RELAY_ACK" \
  "NO_ACK_YET" \
  "createRetryPlan" \
  "createMessageQueueRecord" \
  "decideAckFallback" \
  "decideMessageAckFallback"
do
  if grep -R "$token" "$ROOT/src/maurimesh/message-fallback" "$ROOT/src/components/MessageFallbackPanel.tsx" >/dev/null 2>&1; then
    pass "Capability found: $token"
  else
    fail "Capability missing: $token"
  fi
done

line ""
line "## Route Wiring"
if has_text "app/dashboard.tsx" "/message-fallback"; then pass "Dashboard has /message-fallback"; else fail "Dashboard missing /message-fallback"; fi
if has_text "src/lib/uiBackupRoutes.ts" "/message-fallback"; then pass "Backup registry has /message-fallback"; else fail "Backup registry missing /message-fallback"; fi
if has_text "app/message-fallback.tsx" "MessageFallbackPanel"; then pass "Screen uses MessageFallbackPanel"; else fail "Screen missing panel"; fi

line ""
line "## Embedded Wiring"
if has_text "app/mauricore-ble-runtime.tsx" "MessageFallbackPanel"; then pass "MauriCore BLE Runtime includes MessageFallbackPanel"; else warn "MauriCore BLE Runtime embed not confirmed"; fi
if has_text "app/ble-hardware-runtime.tsx" "MessageFallbackPanel"; then pass "BLE Hardware Runtime includes MessageFallbackPanel"; else warn "BLE Hardware Runtime embed not confirmed"; fi
if has_text "app/device-proof.tsx" "MessageFallbackPanel"; then pass "Device Proof includes MessageFallbackPanel"; else warn "Device Proof embed not confirmed"; fi
if has_text "app/proof-ledger.tsx" "MessageFallbackPanel"; then pass "Proof Ledger includes MessageFallbackPanel"; else warn "Proof Ledger embed not confirmed"; fi

line ""
line "## Truth Protection"
if has_text "src/maurimesh/message-fallback/MessageAckFallbackEngine.ts" "does not claim real delivery until strict device ACK proof exists"; then
  pass "ACK truth boundary present"
else
  warn "ACK truth boundary not confirmed"
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
echo "MESSAGE QUEUE + ACK FALLBACK CHECK COMPLETE"
echo "Status: $STATUS"
echo "Score:  $SCORE%"
echo "Report: $LATEST"
echo "============================================================"
echo ""

if [ "$FAIL" -gt 0 ]; then exit 1; fi
