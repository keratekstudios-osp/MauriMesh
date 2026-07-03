#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH JAVA + NATIVE BLE/GATT WIRING COVERAGE CHECK"
echo "============================================================"
echo "Goal:"
echo "- Separate Java/JAVA_HOME environment blocker from Kotlin code blocker"
echo "- Check actual logger coverage, excluding helper-only references"
echo "- Re-run Gradle Kotlin compile if Java can be found"
echo "- Do not claim native BLE/GATT pass"
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +"%Y%m%d-%H%M%S")"
OUT_DIR="$ROOT/docs/native-proof"
mkdir -p "$OUT_DIR"

REPORT="$OUT_DIR/JAVA_AND_NATIVE_BLE_GATT_WIRING_COVERAGE_$STAMP.md"
JAVA_REPORT="$OUT_DIR/java-home-check-$STAMP.txt"
COVERAGE_REPORT="$OUT_DIR/native-ble-gatt-actual-logger-coverage-$STAMP.txt"
GRADLE_OUT="$OUT_DIR/gradle-kotlin-compile-after-java-check-$STAMP.txt"

LOGGER_FILE="$ROOT/android/app/src/main/java/com/maurimesh/messenger/MauriMeshNativeBlePacketLogger.kt"

echo "[1/5] Checking Java/JAVA_HOME..."

{
  echo "Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  echo ""
  echo "Current JAVA_HOME: ${JAVA_HOME:-not-set}"
  echo "Current PATH: $PATH"
  echo ""

  echo "command -v java:"
  command -v java || true
  echo ""

  echo "Known Java candidates:"
  find /nix/store /usr/lib/jvm /usr/local /opt -maxdepth 5 -type f -path "*/bin/java" 2>/dev/null | head -30 || true
} > "$JAVA_REPORT"

JAVA_BIN=""

if command -v java >/dev/null 2>&1; then
  JAVA_BIN="$(command -v java)"
else
  JAVA_BIN="$(find /nix/store /usr/lib/jvm /usr/local /opt -maxdepth 5 -type f -path "*/bin/java" 2>/dev/null | head -1 || true)"
fi

if [ -n "$JAVA_BIN" ] && [ -x "$JAVA_BIN" ]; then
  JAVA_HOME_CANDIDATE="$(cd "$(dirname "$JAVA_BIN")/.." && pwd)"
  export JAVA_HOME="$JAVA_HOME_CANDIDATE"
  export PATH="$JAVA_HOME/bin:$PATH"

  echo "Java found:"
  echo "$JAVA_BIN"
  echo "JAVA_HOME set to:"
  echo "$JAVA_HOME"
  java -version 2>&1 | tee -a "$JAVA_REPORT" || true
else
  echo "Java not found in current Replit environment."
  echo "Gradle compile will remain blocked until Java/JDK is available."
fi

echo ""
echo "[2/5] Checking actual native logger coverage..."

: > "$COVERAGE_REPORT"

echo "Actual logger usages excluding helper file:" >> "$COVERAGE_REPORT"
echo "Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")" >> "$COVERAGE_REPORT"
echo "" >> "$COVERAGE_REPORT"

if [ -d "$ROOT/android/app/src/main/java" ]; then
  grep -RIn "MauriMeshNativeBlePacketLogger\." "$ROOT/android/app/src/main/java" 2>/dev/null \
    | grep -v "MauriMeshNativeBlePacketLogger.kt" >> "$COVERAGE_REPORT" || true
else
  echo "No android native source tree found." >> "$COVERAGE_REPORT"
fi

echo "" >> "$COVERAGE_REPORT"
echo "Stage coverage:" >> "$COVERAGE_REPORT"

check_usage() {
  local label="$1"
  local pattern="$2"

  if grep -RIn "$pattern" "$ROOT/android/app/src/main/java" 2>/dev/null | grep -v "MauriMeshNativeBlePacketLogger.kt" >/dev/null 2>&1; then
    echo "$label: WIRED" >> "$COVERAGE_REPORT"
  else
    echo "$label: MISSING_ACTUAL_USAGE" >> "$COVERAGE_REPORT"
  fi
}

check_usage "advertise_start_packetId" "MauriMeshNativeBlePacketLogger\.advertiseStart"
check_usage "scan_result_packetId" "MauriMeshNativeBlePacketLogger\.scanResult"
check_usage "gatt_write_packetId" "MauriMeshNativeBlePacketLogger\.gattWrite"
check_usage "gatt_read_packetId" "MauriMeshNativeBlePacketLogger\.gattRead"
check_usage "characteristic_changed_packetId" "MauriMeshNativeBlePacketLogger\.characteristicChanged"
check_usage "relay_packetId" "MauriMeshNativeBlePacketLogger\.relay"
check_usage "ack_packetId" "MauriMeshNativeBlePacketLogger\.ack"

cat "$COVERAGE_REPORT"

echo ""
echo "[3/5] Showing latest wiring report changes/warnings..."

LATEST_WIRING_REPORT="$(ls -t "$OUT_DIR"/MAURIMESH_NATIVE_BLE_GATT_PACKETID_WIRING_REPORT_*.md 2>/dev/null | head -1 || true)"

if [ -n "$LATEST_WIRING_REPORT" ]; then
  echo "Latest wiring report:"
  echo "$LATEST_WIRING_REPORT"
  echo ""
  sed -n '/## Changes/,$p' "$LATEST_WIRING_REPORT" | head -80 || true
else
  echo "No stamped wiring report found."
fi

echo ""
echo "[4/5] Running Gradle Kotlin compile if Java is available..."

GRADLE_STATUS="SKIPPED_NO_JAVA"

if command -v java >/dev/null 2>&1 && [ -x "$ROOT/android/gradlew" ]; then
  set +e
  (
    cd "$ROOT/android"
    ./gradlew :app:compileDebugKotlin --no-daemon
  ) > "$GRADLE_OUT" 2>&1
  CODE="$?"
  set -e

  if [ "$CODE" -eq 0 ]; then
    GRADLE_STATUS="PASS"
    echo "Gradle Kotlin compile: PASS"
  else
    GRADLE_STATUS="FAILED"
    echo "Gradle Kotlin compile: FAILED"
    echo "Showing last 120 lines:"
    tail -120 "$GRADLE_OUT" || true
  fi
else
  echo "Gradle Kotlin compile skipped because Java or android/gradlew is unavailable."
  echo "Java report:"
  echo "$JAVA_REPORT"
fi

echo ""
echo "[5/5] Writing final report..."

cat > "$REPORT" <<MD
# MauriMesh Java + Native BLE/GATT Wiring Coverage Check

Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")

## Java / Gradle Status

Gradle Kotlin compile status:

\`\`\`txt
$GRADLE_STATUS
\`\`\`

Java report:

\`\`\`txt
$JAVA_REPORT
\`\`\`

Gradle output:

\`\`\`txt
$GRADLE_OUT
\`\`\`

## Actual Native Logger Coverage

Coverage report:

\`\`\`txt
$COVERAGE_REPORT
\`\`\`

## Truth

Native BLE/GATT packet-bound PASS is still **NOT CLAIMED**.

The native logger helper exists.

Some guarded wiring exists.

A native packet-bound pass requires the same packetId to appear in real native Android BLE/GATT logs across:

\`\`\`txt
advertise_start_packetId
scan_result_packetId
gatt_write_packetId
gatt_read_packetId
characteristic_changed_packetId
relay_packetId
ack_packetId
\`\`\`

## Next Step

If Gradle fails with a Kotlin error, patch that error first.

If Gradle passes, wire the missing actual stages.

If Java is missing, fix Replit Java/JDK environment or rely on EAS cloud build for native compile.
MD

ARCHIVE="$ROOT/archives/maurimesh-java-native-ble-gatt-coverage-$STAMP.tar.gz"
tar -czf "$ARCHIVE" \
  -C "$ROOT" \
  "docs/native-proof" \
  >/dev/null 2>&1 || true

echo ""
echo "============================================================"
echo "MAURIMESH JAVA + NATIVE BLE/GATT COVERAGE CHECK COMPLETE"
echo "============================================================"
echo "Java report:"
echo "$JAVA_REPORT"
echo ""
echo "Coverage report:"
echo "$COVERAGE_REPORT"
echo ""
echo "Gradle status:"
echo "$GRADLE_STATUS"
echo ""
echo "Gradle output:"
echo "$GRADLE_OUT"
echo ""
echo "Final report:"
echo "$REPORT"
echo ""
echo "Archive:"
echo "$ARCHIVE"
echo ""
echo "FINAL TRUTH:"
echo "This was a coverage/environment check only."
echo "Native BLE/GATT packet-bound PASS is NOT claimed."
echo "============================================================"
