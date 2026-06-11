#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
DOCS="$ROOT/docs"
mkdir -p "$DOCS"

REPORT="$DOCS/maurimesh-pixel-calling-backup-fallback-report-$STAMP.md"
LATEST="$DOCS/maurimesh-pixel-calling-backup-fallback-report-latest.md"

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

line "# MauriMesh Pixel Calling Backup Fallback Report"
line ""
line "Generated: $STAMP"
line ""

line "## Files"
for file in \
  "src/maurimesh/pixel-calling/PixelCallingBackupTypes.ts" \
  "src/maurimesh/pixel-calling/PixelCallingBackupFallback.ts" \
  "src/components/PixelCallingBackupFallbackPanel.tsx" \
  "app/pixel-calling-backup.tsx"
do
  if has_file "$file"; then pass "$file exists"; else fail "$file missing"; fi
done

line ""
line "## Backup Fallback Capabilities"
for token in \
  "PRIMARY_CALL_RUNTIME" \
  "BACKUP_CALL_CONTROL" \
  "PUSH_TO_TALK_BACKUP" \
  "VOICE_NOTE_BACKUP" \
  "TEXT_MESSAGE_BACKUP" \
  "STORE_FORWARD_BACKUP" \
  "SAFE_CALL_HOLD" \
  "PRIMARY_RUNTIME_FAILED" \
  "NO_STRICT_ACK" \
  "NO_AUDIO_PERMISSION" \
  "HARDWARE_PRESSURE" \
  "NO_LIVE_TRANSPORT" \
  "createPixelCallingFallbackBackupOrder" \
  "decidePixelCallingBackupFallback" \
  "runPixelCallingBackupFallbackDemo"
do
  if grep -R "$token" "$ROOT/src/maurimesh/pixel-calling" "$ROOT/src/components/PixelCallingBackupFallbackPanel.tsx" >/dev/null 2>&1; then
    pass "Capability found: $token"
  else
    fail "Capability missing: $token"
  fi
done

line ""
line "## Route + Backup Wiring"
if has_text "app/dashboard.tsx" "/pixel-calling-backup"; then pass "Dashboard has /pixel-calling-backup"; else fail "Dashboard missing /pixel-calling-backup"; fi
if has_text "src/lib/uiBackupRoutes.ts" "/pixel-calling-backup"; then pass "Backup registry has /pixel-calling-backup"; else fail "Backup registry missing /pixel-calling-backup"; fi
if has_text "app/pixel-calling-backup.tsx" "PixelCallingBackupFallbackPanel"; then pass "Backup screen uses PixelCallingBackupFallbackPanel"; else fail "Backup screen missing panel"; fi
if has_text "app/pixel-calling.tsx" "PixelCallingBackupFallbackPanel"; then pass "Pixel Calling screen embeds backup fallback panel"; else warn "Pixel Calling screen embed not confirmed"; fi

line ""
line "## Embedded Proof Wiring"
if has_text "app/device-proof.tsx" "PixelCallingBackupFallbackPanel"; then pass "Device Proof includes PixelCallingBackupFallbackPanel"; else warn "Device Proof embed not confirmed"; fi
if has_text "app/proof-ledger.tsx" "PixelCallingBackupFallbackPanel"; then pass "Proof Ledger includes PixelCallingBackupFallbackPanel"; else warn "Proof Ledger embed not confirmed"; fi
if has_text "app/message-fallback.tsx" "PixelCallingBackupFallbackPanel"; then pass "Message Fallback includes PixelCallingBackupFallbackPanel"; else warn "Message Fallback embed not confirmed"; fi

line ""
line "## Truth Protection"
if has_text "src/maurimesh/pixel-calling/PixelCallingBackupFallback.ts" "does not claim a live call without installed APK audio proof and strict device ACK"; then
  pass "Pixel Calling backup truth boundary present"
else
  warn "Pixel Calling backup truth boundary not confirmed"
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
echo "PIXEL CALLING BACKUP FALLBACK CHECK COMPLETE"
echo "Status: $STATUS"
echo "Score:  $SCORE%"
echo "Report: $LATEST"
echo "============================================================"
echo ""

if [ "$FAIL" -gt 0 ]; then exit 1; fi
