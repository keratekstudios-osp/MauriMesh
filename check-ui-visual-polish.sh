#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
DOCS="$ROOT/docs"
mkdir -p "$DOCS"

REPORT="$DOCS/ui-visual-polish-report-$STAMP.md"
LATEST="$DOCS/ui-visual-polish-report-latest.md"

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

line "# MauriMesh UI Visual Polish Report"
line ""
line "Generated: $STAMP"
line ""

line "## Visual System Files"

for file in \
  "src/theme/mauriTheme.ts" \
  "src/components/MauriPanel.tsx" \
  "src/components/MauriPageHeader.tsx" \
  "src/components/MauriMetricCard.tsx" \
  "src/components/MauriDivider.tsx" \
  "src/components/AppShell.tsx" \
  "src/components/MauriButton.tsx" \
  "src/components/StatusPill.tsx" \
  "src/components/MeshSignalCard.tsx"
do
  if has_file "$file"; then pass "$file exists"; else fail "$file missing"; fi
done

line ""
line "## Theme Polish Tokens"

for token in "panelStrong" "panelGlow" "panelBorderStrong" "typography" "shadow" "gradients" "obsidian" "mint"; do
  if has_text "src/theme/mauriTheme.ts" "$token"; then pass "Theme token found: $token"; else fail "Theme token missing: $token"; fi
done

line ""
line "## Dashboard Polish"

for token in "MauriPageHeader" "MauriPanel" "MauriMetricCard" "Backup Navigation Wiring" "Final Truth"; do
  if has_text "app/dashboard.tsx" "$token"; then pass "Dashboard uses $token"; else fail "Dashboard missing $token"; fi
done

line ""
line "## Login Polish"

for token in "MauriPanel" "MAURIMESH MESSENGER" "Open Dashboard"; do
  if has_text "app/login.tsx" "$token"; then pass "Login uses $token"; else fail "Login missing $token"; fi
done

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
echo "UI VISUAL POLISH CHECK COMPLETE"
echo "Status: $STATUS"
echo "Score:  $SCORE%"
echo "Report: $LATEST"
echo "============================================================"
echo ""

if [ "$FAIL" -gt 0 ]; then exit 1; fi
