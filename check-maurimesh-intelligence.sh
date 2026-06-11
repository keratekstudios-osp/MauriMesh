#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
DOCS="$ROOT/docs"
mkdir -p "$DOCS"

REPORT="$DOCS/maurimesh-intelligence-report-$STAMP.md"
LATEST="$DOCS/maurimesh-intelligence-report-latest.md"

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

line "# MauriMesh Intelligence Enhancement Report"
line ""
line "Generated: $STAMP"
line ""

line "## Intelligence Engine Files"

for file in \
  "src/maurimesh/intelligence/types.ts" \
  "src/maurimesh/intelligence/RouteIntelligence.ts" \
  "src/maurimesh/intelligence/ProofIntelligence.ts" \
  "src/maurimesh/intelligence/TikangaIntelligence.ts" \
  "src/maurimesh/intelligence/SelfHealingIntelligence.ts" \
  "src/maurimesh/intelligence/DeviceReadinessIntelligence.ts" \
  "src/maurimesh/intelligence/IntelligenceOrchestrator.ts" \
  "src/maurimesh/intelligence/index.ts"
do
  if has_file "$file"; then pass "$file exists"; else fail "$file missing"; fi
done

line ""
line "## UI Files"

if has_file "src/components/IntelligencePanel.tsx"; then pass "IntelligencePanel exists"; else fail "IntelligencePanel missing"; fi
if has_file "app/intelligence.tsx"; then pass "Intelligence screen exists"; else fail "app/intelligence.tsx missing"; fi

line ""
line "## Intelligence Capabilities"

for token in \
  "decideBestRoute" \
  "evaluateProof" \
  "evaluateTikangaGovernance" \
  "evaluateSelfHealing" \
  "evaluateDeviceReadiness" \
  "generateIntelligenceReport"
do
  if grep -R "$token" "$ROOT/src/maurimesh/intelligence" >/dev/null 2>&1; then
    pass "Capability found: $token"
  else
    fail "Capability missing: $token"
  fi
done

line ""
line "## Route Wiring"

if has_text "app/dashboard.tsx" "/intelligence"; then pass "Dashboard has /intelligence route"; else fail "Dashboard missing /intelligence"; fi
if has_text "src/lib/uiBackupRoutes.ts" "/intelligence"; then pass "Backup route registry has /intelligence"; else warn "Backup route registry missing /intelligence"; fi

line ""
line "## Truth Labels"

if has_text "src/maurimesh/intelligence/IntelligenceOrchestrator.ts" "does not prove real BLE"; then
  pass "Final truth label present"
else
  warn "Final truth label not confirmed"
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
echo "MAURIMESH INTELLIGENCE CHECK COMPLETE"
echo "Status: $STATUS"
echo "Score:  $SCORE%"
echo "Report: $LATEST"
echo "============================================================"
echo ""

if [ "$FAIL" -gt 0 ]; then exit 1; fi
