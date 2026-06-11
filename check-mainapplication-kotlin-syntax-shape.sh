#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
DOCS="$ROOT/docs"
mkdir -p "$DOCS"

REPORT="$DOCS/mainapplication-kotlin-syntax-shape-$STAMP.md"
LATEST="$DOCS/mainapplication-kotlin-syntax-shape-latest.md"

MAIN_KT="$(find "$ROOT/android/app/src/main" -name "MainApplication.kt" | head -1 || true)"

PASS=0
FAIL=0

line(){ echo "$1" | tee -a "$REPORT"; }
pass(){ PASS=$((PASS+1)); line "- [x] $1"; }
fail(){ FAIL=$((FAIL+1)); line "- [ ] FAILED: $1"; }

: > "$REPORT"

line "# MainApplication Kotlin Syntax Shape Check"
line ""
line "Generated: $STAMP"
line ""

if [ -n "$MAIN_KT" ]; then pass "MainApplication.kt found"; else fail "MainApplication.kt missing"; fi

if grep -Fq "add(MauriMeshHardwareTelemetryPackage()) add(" "$MAIN_KT"; then
  fail "Bad joined add(...) add(...) line still exists"
else
  pass "No joined add(...) add(...) line"
fi

if grep -Fq "add(MauriMeshHardwareTelemetryPackage())" "$MAIN_KT"; then
  pass "Telemetry package add exists"
else
  fail "Telemetry package add missing"
fi

if grep -Fq "PackageList(this).packages.apply" "$MAIN_KT"; then
  pass "PackageList apply block exists"
else
  fail "PackageList apply block missing"
fi

if grep -Fq ".maurimesh.telemetry.MauriMeshHardwareTelemetryPackage" "$MAIN_KT"; then
  pass "Telemetry import exists"
else
  fail "Telemetry import missing"
fi

line ""
line "## Summary"
line ""
TOTAL=$((PASS + FAIL))
SCORE=$((PASS * 100 / TOTAL))
if [ "$FAIL" -eq 0 ]; then STATUS="COMPLETE"; else STATUS="INCOMPLETE"; fi
line "- Total: $TOTAL"
line "- Complete: $PASS"
line "- Failed: $FAIL"
line "- Score: $SCORE%"
line "- Status: **$STATUS**"

cp "$REPORT" "$LATEST"

echo ""
echo "============================================================"
echo "MAINAPPLICATION KOTLIN SHAPE CHECK COMPLETE"
echo "Status: $STATUS"
echo "Score:  $SCORE%"
echo "Report: $LATEST"
echo "============================================================"

if [ "$FAIL" -gt 0 ]; then exit 1; fi
