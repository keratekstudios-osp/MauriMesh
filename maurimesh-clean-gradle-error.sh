#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH CLEAN GRADLE ERROR CAPTURE"
echo "Find exact Android compile blocker before EAS"
echo "============================================================"
echo ""

ROOT="/home/runner/workspace"
ANDROID="$ROOT/android"
FULL="$ROOT/gradle-clean-failure.log"
SUMMARY="$ROOT/gradle-clean-summary.log"

rm -f "$FULL" "$SUMMARY"

if [ ! -d "$ANDROID" ]; then
  echo "ERROR: android folder not found."
  echo "Run: npx expo prebuild --platform android --clean"
  exit 1
fi

cd "$ANDROID"

chmod +x ./gradlew || true

echo ""
echo "1. Gradle version"
./gradlew --version || true

echo ""
echo "2. Running clean Android debug compile"
echo "This does not use EAS quota."
echo ""

set +e
./gradlew :app:assembleDebug \
  -x lint \
  -x lintDebug \
  -x test \
  -x testDebugUnitTest \
  --stacktrace \
  2>&1 | tee "$FULL"
STATUS="${PIPESTATUS[0]}"
set -e

cd "$ROOT"

echo ""
echo "============================================================"
echo "EXTRACTING REAL ERROR"
echo "============================================================"
echo ""

{
  echo "MAURIMESH CLEAN GRADLE SUMMARY"
  echo "Generated: $(date)"
  echo ""
  echo "Exit status: $STATUS"
  echo ""
  echo "Important error lines:"
  echo ""

  grep -n -A45 -B20 -E \
  "FAILURE: Build failed|What went wrong|Execution failed|Could not resolve|Could not find|Could not determine|Plugin .* was not found|compileDebugKotlin|compileDebugJava|Manifest merger failed|A problem occurred|Caused by:|error:|Exception" \
  "$FULL" || true

  echo ""
  echo "Last 160 log lines:"
  echo ""
  tail -160 "$FULL" || true
} | tee "$SUMMARY"

echo ""
echo "============================================================"
echo "RESULT"
echo "============================================================"

if [ "$STATUS" -eq 0 ]; then
  echo "✅ Android debug compile passed."
  APK="$(find "$ROOT/android/app/build/outputs/apk" -name '*.apk' | sort | tail -1 || true)"
  echo "APK: ${APK:-not found}"
else
  echo "❌ Android debug compile failed."
  echo "Do not run EAS yet."
fi

echo ""
echo "Full log:"
echo "$FULL"
echo ""
echo "Summary:"
echo "$SUMMARY"
echo ""
echo "Now copy this output:"
echo "cat $SUMMARY"
