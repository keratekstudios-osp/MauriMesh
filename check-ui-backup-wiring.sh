#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
DOCS="$ROOT/docs"
mkdir -p "$DOCS"

REPORT="$DOCS/ui-backup-wiring-report-$STAMP.md"
LATEST="$DOCS/ui-backup-wiring-report-latest.md"

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

line "# MauriMesh UI Backup Wiring Report"
line ""
line "Generated: $STAMP"
line ""

line "## Backup Wiring Files"

if has_file "src/lib/uiBackupRoutes.ts"; then pass "Route registry exists"; else fail "src/lib/uiBackupRoutes.ts missing"; fi
if has_file "src/components/SafeNavButton.tsx"; then pass "SafeNavButton exists"; else fail "src/components/SafeNavButton.tsx missing"; fi

line ""
line "## Route Registry Coverage"

ROUTES=(
  "/login"
  "/dashboard"
  "/chat"
  "/settings"
  "/add-friend"
  "/living-mesh"
  "/mesh-status"
  "/pixel-calling"
  "/ui-roadmap"
  "/proof-ledger"
  "/route-lab"
  "/tikanga-engine"
  "/self-healing"
  "/device-proof"
  "/operator-console"
  "/mauricore-governance"
  "/mauricore-ble-runtime"
)

for route in "${ROUTES[@]}"; do
  if has_text "src/lib/uiBackupRoutes.ts" "$route"; then
    pass "Backup registry contains $route"
  else
    fail "Backup registry missing $route"
  fi
done

line ""
line "## Fallback Route Coverage"

for route in "${ROUTES[@]}"; do
  if grep -Fq "fallbackRoute" "$ROOT/src/lib/uiBackupRoutes.ts" && grep -Fq "$route" "$ROOT/src/lib/uiBackupRoutes.ts"; then
    pass "$route has registry entry with fallback system available"
  else
    fail "$route fallback not confirmed"
  fi
done

line ""
line "## SafeNavButton Checks"

if has_text "src/components/SafeNavButton.tsx" "router.push"; then pass "SafeNavButton uses router.push"; else fail "SafeNavButton missing router.push"; fi
if has_text "src/components/SafeNavButton.tsx" "router.replace"; then pass "SafeNavButton uses fallback router.replace"; else fail "SafeNavButton missing fallback router.replace"; fi
if has_text "src/components/SafeNavButton.tsx" "getUiRoute"; then pass "SafeNavButton uses route registry"; else fail "SafeNavButton missing route registry"; fi

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
echo "UI BACKUP WIRING CHECK COMPLETE"
echo "Status: $STATUS"
echo "Score:  $SCORE%"
echo "Report: $LATEST"
echo "============================================================"
echo ""

if [ "$FAIL" -gt 0 ]; then exit 1; fi
