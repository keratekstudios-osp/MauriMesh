#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
DOCS="$ROOT/docs"
mkdir -p "$DOCS"

REPORT="$DOCS/maurimesh-android-kotlin-telemetry-report-$STAMP.md"
LATEST="$DOCS/maurimesh-android-kotlin-telemetry-report-latest.md"

PASS=0
FAIL=0
WARN=0

line(){ echo "$1" | tee -a "$REPORT"; }
pass(){ PASS=$((PASS+1)); line "- [x] $1"; }
fail(){ FAIL=$((FAIL+1)); line "- [ ] MISSING: $1"; }
warn(){ WARN=$((WARN+1)); line "- [!] PARTIAL: $1"; }

has_text_file(){ grep -R "$1" "$2" >/dev/null 2>&1; }

: > "$REPORT"

line "# MauriMesh Android Kotlin Telemetry Report"
line ""
line "Generated: $STAMP"
line ""

line "## Native Files"

MODULE_FILE="$(find "$ROOT/android/app/src/main" -name "MauriMeshHardwareTelemetryModule.kt" | head -1 || true)"
PACKAGE_FILE="$(find "$ROOT/android/app/src/main" -name "MauriMeshHardwareTelemetryPackage.kt" | head -1 || true)"
MAIN_FILE="$(find "$ROOT/android/app/src/main" \( -name "MainApplication.kt" -o -name "MainApplication.java" \) | head -1 || true)"

if [ -n "$MODULE_FILE" ]; then pass "Telemetry module exists: ${MODULE_FILE#$ROOT/}"; else fail "Telemetry module missing"; fi
if [ -n "$PACKAGE_FILE" ]; then pass "Telemetry package exists: ${PACKAGE_FILE#$ROOT/}"; else fail "Telemetry package missing"; fi
if [ -n "$MAIN_FILE" ]; then pass "MainApplication found: ${MAIN_FILE#$ROOT/}"; else fail "MainApplication missing"; fi

line ""
line "## Native Capabilities"

for token in \
  "MauriMeshHardwareTelemetry" \
  "getHardwareTelemetry" \
  "BatteryManager" \
  "ActivityManager" \
  "StatFs" \
  "PowerManager" \
  "BluetoothManager" \
  "memoryUsedMb" \
  "storageFreeMb" \
  "bleEnabled" \
  "thermalRisk"
do
  if [ -n "$MODULE_FILE" ] && has_text_file "$token" "$MODULE_FILE"; then
    pass "Capability found: $token"
  else
    fail "Capability missing: $token"
  fi
done

line ""
line "## Registration"

if [ -n "$MAIN_FILE" ] && has_text_file "MauriMeshHardwareTelemetryPackage" "$MAIN_FILE"; then
  pass "MainApplication references MauriMeshHardwareTelemetryPackage"
else
  warn "MainApplication registration not confirmed. Manual package add may be required."
fi

line ""
line "## JS Bridge Compatibility"

if has_text_file "MauriMeshHardwareTelemetry" "$ROOT/src/maurimesh/device-hardware/NativeHardwareTelemetry.ts"; then
  pass "JS bridge expects MauriMeshHardwareTelemetry"
else
  fail "JS bridge missing MauriMeshHardwareTelemetry"
fi

if has_text_file "NATIVE_ANDROID" "$ROOT/src/maurimesh/device-hardware/NativeHardwareTelemetry.ts"; then
  pass "JS bridge supports NATIVE_ANDROID source"
else
  fail "JS bridge missing NATIVE_ANDROID source"
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
echo "ANDROID KOTLIN TELEMETRY CHECK COMPLETE"
echo "Status: $STATUS"
echo "Score:  $SCORE%"
echo "Report: $LATEST"
echo "============================================================"
echo ""

if [ "$FAIL" -gt 0 ]; then exit 1; fi
