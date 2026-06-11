#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
DOCS="$ROOT/docs"
mkdir -p "$DOCS"

REPORT="$DOCS/maurimesh-mainapplication-telemetry-fix-report-$STAMP.md"
LATEST="$DOCS/maurimesh-mainapplication-telemetry-fix-report-latest.md"

PASS=0
FAIL=0
WARN=0

line(){ echo "$1" | tee -a "$REPORT"; }
pass(){ PASS=$((PASS+1)); line "- [x] $1"; }
fail(){ FAIL=$((FAIL+1)); line "- [ ] MISSING: $1"; }
warn(){ WARN=$((WARN+1)); line "- [!] PARTIAL: $1"; }

MAIN_KT="$(find "$ROOT/android/app/src/main" -name "MainApplication.kt" | head -1 || true)"

: > "$REPORT"
line "# MauriMesh MainApplication Telemetry Fix Report"
line ""
line "Generated: $STAMP"
line ""

if [ -n "$MAIN_KT" ]; then
  pass "MainApplication.kt found: ${MAIN_KT#$ROOT/}"
else
  fail "MainApplication.kt missing"
fi

if [ -n "$MAIN_KT" ] && grep -Fq "MauriMeshHardwareTelemetryPackage" "$MAIN_KT"; then
  pass "Telemetry package reference exists"
else
  fail "Telemetry package reference missing"
fi

if [ -n "$MAIN_KT" ] && grep -Fq "import " "$MAIN_KT" && grep -Fq ".maurimesh.telemetry.MauriMeshHardwareTelemetryPackage" "$MAIN_KT"; then
  pass "Telemetry import exists"
else
  fail "Telemetry import missing"
fi

if [ -n "$MAIN_KT" ] && grep -Eq "apply \\{|toMutableList\\(\\)" "$MAIN_KT"; then
  pass "Mutable/apply package registration pattern exists"
else
  warn "Mutable/apply registration pattern not confirmed"
fi

if [ -n "$MAIN_KT" ] && grep -Fq "PackageList(this).packages.add" "$MAIN_KT"; then
  fail "Bad immutable PackageList(this).packages.add pattern still exists"
else
  pass "Bad immutable add pattern removed"
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
echo "MAINAPPLICATION TELEMETRY FIX CHECK COMPLETE"
echo "Status: $STATUS"
echo "Score:  $SCORE%"
echo "Report: $LATEST"
echo "============================================================"
echo ""

if [ "$FAIL" -gt 0 ]; then exit 1; fi
