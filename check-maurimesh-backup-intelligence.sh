#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
DOCS="$ROOT/docs"
mkdir -p "$DOCS"

REPORT="$DOCS/maurimesh-backup-intelligence-report-$STAMP.md"
LATEST="$DOCS/maurimesh-backup-intelligence-report-latest.md"

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

line "# MauriMesh Backup Intelligence Report"
line ""
line "Generated: $STAMP"
line ""

line "## Backup Intelligence Files"

for file in \
  "src/maurimesh/intelligence/BackupIntelligence.ts" \
  "src/components/BackupIntelligencePanel.tsx" \
  "app/backup-intelligence.tsx"
do
  if has_file "$file"; then pass "$file exists"; else fail "$file missing"; fi
done

line ""
line "## Backup Capabilities"

for token in \
  "generateBackupIntelligenceReport" \
  "generateProtectedIntelligenceReport" \
  "forceBackupIntelligence" \
  "getBackupProtectionSummary" \
  "fallbackRoute" \
  "fallbackProof" \
  "fallbackGovernance" \
  "fallbackSelfHealing" \
  "fallbackDeviceReadiness"
do
  if grep -R "$token" "$ROOT/src/maurimesh/intelligence/BackupIntelligence.ts" >/dev/null 2>&1; then
    pass "Capability found: $token"
  else
    fail "Capability missing: $token"
  fi
done

line ""
line "## Route Wiring"

if has_text "app/dashboard.tsx" "/backup-intelligence"; then pass "Dashboard has /backup-intelligence"; else fail "Dashboard missing /backup-intelligence"; fi
if has_text "src/lib/uiBackupRoutes.ts" "/backup-intelligence"; then pass "Backup registry has /backup-intelligence"; else warn "Backup registry missing /backup-intelligence"; fi
if has_text "app/backup-intelligence.tsx" "BackupIntelligencePanel"; then pass "Screen uses BackupIntelligencePanel"; else fail "Screen missing BackupIntelligencePanel"; fi

line ""
line "## Truth Protection"

if has_text "src/maurimesh/intelligence/BackupIntelligence.ts" "does not prove real BLE"; then
  pass "Truth label protects against fake BLE claim"
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
echo "MAURIMESH BACKUP INTELLIGENCE CHECK COMPLETE"
echo "Status: $STATUS"
echo "Score:  $SCORE%"
echo "Report: $LATEST"
echo "============================================================"
echo ""

if [ "$FAIL" -gt 0 ]; then exit 1; fi
