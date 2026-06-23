#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "FAST JAVA + NATIVE BLE/GATT COVERAGE CHECK"
echo "============================================================"

ROOT="$(pwd)"
STAMP="$(date +"%Y%m%d-%H%M%S")"
OUT_DIR="$ROOT/docs/native-proof"
mkdir -p "$OUT_DIR"

JAVA_REPORT="$OUT_DIR/fast-java-check-$STAMP.txt"
COVERAGE_REPORT="$OUT_DIR/fast-native-ble-gatt-coverage-$STAMP.txt"
GRADLE_OUT="$OUT_DIR/fast-gradle-check-$STAMP.txt"
REPORT="$OUT_DIR/FAST_JAVA_NATIVE_BLE_GATT_COVERAGE_$STAMP.md"

echo "[1/4] Fast Java check..."

{
  echo "JAVA_HOME=${JAVA_HOME:-not-set}"
  echo ""
  echo "command -v java:"
  command -v java || true
  echo ""
  echo "java -version:"
  java -version 2>&1 || true
  echo ""
  echo "Replit/Nix Java candidates:"
  ls -d /nix/store/*jdk* 2>/dev/null | head -10 || true
  ls -d /nix/store/*openjdk* 2>/dev/null | head -10 || true
} > "$JAVA_REPORT"

JAVA_OK="no"

if command -v java >/dev/null 2>&1; then
  JAVA_OK="yes"
else
  JDK_DIR="$(ls -d /nix/store/*jdk* /nix/store/*openjdk* 2>/dev/null | head -1 || true)"
  if [ -n "$JDK_DIR" ] && [ -x "$JDK_DIR/bin/java" ]; then
    export JAVA_HOME="$JDK_DIR"
    export PATH="$JAVA_HOME/bin:$PATH"
    JAVA_OK="yes"
  fi
fi

echo "Java OK: $JAVA_OK"

echo ""
echo "[2/4] Actual logger coverage excluding helper..."

: > "$COVERAGE_REPORT"

grep -RIn "MauriMeshNativeBlePacketLogger\." "$ROOT/android/app/src/main/java" 2>/dev/null \
  | grep -v "MauriMeshNativeBlePacketLogger.kt" >> "$COVERAGE_REPORT" || true

echo "" >> "$COVERAGE_REPORT"
echo "Stage coverage:" >> "$COVERAGE_REPORT"

check_stage() {
  local label="$1"
  local pattern="$2"

  if grep -RIn "$pattern" "$ROOT/android/app/src/main/java" 2>/dev/null | grep -v "MauriMeshNativeBlePacketLogger.kt" >/dev/null 2>&1; then
    echo "$label: WIRED" >> "$COVERAGE_REPORT"
  else
    echo "$label: MISSING_ACTUAL_USAGE" >> "$COVERAGE_REPORT"
  fi
}

check_stage "advertise_start_packetId" "MauriMeshNativeBlePacketLogger\.advertiseStart"
check_stage "scan_result_packetId" "MauriMeshNativeBlePacketLogger\.scanResult"
check_stage "gatt_write_packetId" "MauriMeshNativeBlePacketLogger\.gattWrite"
check_stage "gatt_read_packetId" "MauriMeshNativeBlePacketLogger\.gattRead"
check_stage "characteristic_changed_packetId" "MauriMeshNativeBlePacketLogger\.characteristicChanged"
check_stage "relay_packetId" "MauriMeshNativeBlePacketLogger\.relay"
check_stage "ack_packetId" "MauriMeshNativeBlePacketLogger\.ack"

cat "$COVERAGE_REPORT"

echo ""
echo "[3/4] Gradle Kotlin compile check..."

GRADLE_STATUS="SKIPPED_NO_JAVA"

if [ "$JAVA_OK" = "yes" ] && [ -x "$ROOT/android/gradlew" ]; then
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
    tail -120 "$GRADLE_OUT" || true
  fi
else
  echo "Gradle skipped: Java missing or android/gradlew unavailable."
fi

echo ""
echo "[4/4] Final report..."

cat > "$REPORT" <<MD
# Fast Java + Native BLE/GATT Coverage Check

Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")

## Java

Java OK: $JAVA_OK

Java report:

\`\`\`txt
$JAVA_REPORT
\`\`\`

## Gradle

Gradle status:

\`\`\`txt
$GRADLE_STATUS
\`\`\`

Gradle output:

\`\`\`txt
$GRADLE_OUT
\`\`\`

## Coverage

Coverage report:

\`\`\`txt
$COVERAGE_REPORT
\`\`\`

## Truth

Native BLE/GATT packet-bound PASS is NOT claimed.

This check only verifies environment and source wiring coverage.
MD

echo ""
echo "============================================================"
echo "FAST JAVA + NATIVE BLE/GATT COVERAGE CHECK COMPLETE"
echo "============================================================"
echo "Java OK:"
echo "$JAVA_OK"
echo ""
echo "Gradle status:"
echo "$GRADLE_STATUS"
echo ""
echo "Java report:"
echo "$JAVA_REPORT"
echo ""
echo "Coverage report:"
echo "$COVERAGE_REPORT"
echo ""
echo "Gradle output:"
echo "$GRADLE_OUT"
echo ""
echo "Final report:"
echo "$REPORT"
echo ""
echo "FINAL TRUTH:"
echo "Coverage/environment check only."
echo "Native BLE/GATT packet-bound PASS is NOT claimed."
echo "============================================================"
