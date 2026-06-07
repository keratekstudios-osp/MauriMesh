#!/usr/bin/env bash
set -euo pipefail

ROOT="/home/runner/workspace"
LOG="$ROOT/gradle-real-error.log"
SUMMARY="$ROOT/gradle-real-error-summary.txt"

echo ""
echo "============================================================"
echo "MAURIMESH REAL GRADLE ERROR EXTRACTOR"
echo "============================================================"

cd "$ROOT"

# Fix JAVA_HOME from active Java binary
unset JAVA_HOME
JAVA_BIN="$(readlink -f "$(command -v java)")"
export JAVA_HOME="$(dirname "$(dirname "$JAVA_BIN")")"
export PATH="$JAVA_HOME/bin:$PATH"

echo "JAVA_BIN=$JAVA_BIN"
echo "JAVA_HOME=$JAVA_HOME"
java -version

echo ""
echo "Stop Gradle daemons"
cd "$ROOT/android"
chmod +x ./gradlew
./gradlew --stop || true

echo ""
echo "Run clean plain Gradle build"
rm -f "$LOG" "$SUMMARY"

set +e
./gradlew :app:assembleDebug \
  --console=plain \
  --no-daemon \
  --stacktrace \
  -x lint \
  -x lintDebug \
  -x test \
  -x testDebugUnitTest \
  2>&1 | tee "$LOG"
STATUS="${PIPESTATUS[0]}"
set -e

cd "$ROOT"

echo ""
echo "============================================================"
echo "EXTRACTING FIRST REAL ERROR"
echo "============================================================"

{
  echo "Exit status: $STATUS"
  echo ""
  echo "JAVA_HOME=$JAVA_HOME"
  echo ""
  echo "FIRST FAILURE BLOCK:"
  grep -ni -A120 -B30 "FAILURE: Build failed" "$LOG" | head -180 || true
  echo ""
  echo "WHAT WENT WRONG:"
  grep -ni -A120 -B30 "What went wrong" "$LOG" | head -180 || true
  echo ""
  echo "TASK FAILURE / COMPILE ERRORS:"
  grep -ni -A80 -B30 -E "Execution failed|Task .* failed|compile.* failed|Could not|Cannot|error:|Unresolved reference|Duplicate class|Manifest merger failed|Plugin .* not found|No matching variant|A problem occurred" "$LOG" | head -260 || true
  echo ""
  echo "LAST 220 LINES:"
  tail -220 "$LOG" || true
} | tee "$SUMMARY"

echo ""
echo "============================================================"
echo "RESULT"
echo "============================================================"

if [ "$STATUS" -eq 0 ]; then
  echo "✅ BUILD PASSED"
  find "$ROOT/android/app/build/outputs/apk" -name "*.apk" -print
else
  echo "❌ BUILD FAILED"
  echo "Do not run EAS yet."
  echo ""
  echo "Send this output:"
  echo "cat $SUMMARY"
fi
