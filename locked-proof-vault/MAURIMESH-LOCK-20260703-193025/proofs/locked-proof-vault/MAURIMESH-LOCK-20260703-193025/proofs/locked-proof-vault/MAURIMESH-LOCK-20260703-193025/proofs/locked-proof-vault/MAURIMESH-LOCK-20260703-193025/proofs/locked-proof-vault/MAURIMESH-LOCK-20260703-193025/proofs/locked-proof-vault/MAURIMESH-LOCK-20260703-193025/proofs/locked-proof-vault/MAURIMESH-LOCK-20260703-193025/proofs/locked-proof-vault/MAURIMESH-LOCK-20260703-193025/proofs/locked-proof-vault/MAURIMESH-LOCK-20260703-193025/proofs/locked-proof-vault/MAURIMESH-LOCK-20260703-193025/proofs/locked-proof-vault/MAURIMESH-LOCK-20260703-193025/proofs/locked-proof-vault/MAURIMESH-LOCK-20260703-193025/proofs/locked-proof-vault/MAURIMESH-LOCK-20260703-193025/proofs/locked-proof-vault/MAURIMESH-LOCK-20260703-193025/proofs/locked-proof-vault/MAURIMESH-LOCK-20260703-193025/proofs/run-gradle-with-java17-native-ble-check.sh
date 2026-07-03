#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH JAVA 17 GRADLE NATIVE BLE CHECK"
echo "============================================================"
echo "Goal:"
echo "- Find Java 17"
echo "- Set JAVA_HOME only for this shell run"
echo "- Run Gradle Kotlin compile"
echo "- Check native BLE/GATT packet logger coverage"
echo "- Do NOT claim native BLE/GATT pass"
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +"%Y%m%d-%H%M%S")"
OUT_DIR="$ROOT/docs/native-proof"
mkdir -p "$OUT_DIR"

JAVA_REPORT="$OUT_DIR/java17-check-$STAMP.txt"
GRADLE_OUT="$OUT_DIR/gradle-java17-compile-$STAMP.txt"
COVERAGE_OUT="$OUT_DIR/native-ble-gatt-java17-coverage-$STAMP.txt"
REPORT="$OUT_DIR/JAVA17_NATIVE_BLE_GATT_CHECK_$STAMP.md"

echo "[1/5] Searching for Java 17..."

: > "$JAVA_REPORT"

{
  echo "Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  echo ""
  echo "Current JAVA_HOME=${JAVA_HOME:-not-set}"
  echo ""
  echo "Current java:"
  command -v java || true
  java -version 2>&1 || true
  echo ""
  echo "Searching common Java 17 locations..."
} >> "$JAVA_REPORT"

JAVA17_HOME=""

for candidate in \
  /usr/lib/jvm/java-17-openjdk \
  /usr/lib/jvm/java-17-openjdk-amd64 \
  /usr/lib/jvm/temurin-17-jdk \
  /usr/lib/jvm/jdk-17 \
  /opt/jdk-17 \
  /nix/store/*jdk-17* \
  /nix/store/*openjdk-17* \
  /nix/store/*temurin-bin-17*
do
  if [ -x "$candidate/bin/java" ]; then
    JAVA17_HOME="$candidate"
    break
  fi
done

if [ -z "$JAVA17_HOME" ]; then
  echo ""
  echo "No direct Java 17 folder found."
  echo "Trying nix-shell with jdk17 if available..."
  echo ""
  if command -v nix-shell >/dev/null 2>&1; then
    USE_NIX_SHELL="yes"
  else
    USE_NIX_SHELL="no"
  fi
else
  USE_NIX_SHELL="no"
fi

echo "JAVA17_HOME=$JAVA17_HOME" >> "$JAVA_REPORT"
echo "USE_NIX_SHELL=$USE_NIX_SHELL" >> "$JAVA_REPORT"

echo ""
echo "[2/5] Java 17 result..."

if [ -n "$JAVA17_HOME" ]; then
  export JAVA_HOME="$JAVA17_HOME"
  export PATH="$JAVA_HOME/bin:$PATH"
  echo "Using Java 17:"
  echo "$JAVA_HOME"
  java -version 2>&1 | tee -a "$JAVA_REPORT"
elif [ "$USE_NIX_SHELL" = "yes" ]; then
  echo "Will run Gradle inside nix-shell -p jdk17."
else
  echo "ERROR: Java 17 not found and nix-shell unavailable."
  echo ""
  echo "Fix required:"
  echo "Add Java 17/JDK 17 to this Replit environment, then rerun."
  echo ""
  echo "Native BLE/GATT packet-bound PASS is NOT claimed."
  exit 1
fi

echo ""
echo "[3/5] Running Gradle Kotlin compile with Java 17..."

GRADLE_STATUS="FAILED"

if [ "$USE_NIX_SHELL" = "yes" ]; then
  set +e
  nix-shell -p jdk17 --run "cd '$ROOT/android' && export JAVA_HOME=\$(dirname \$(dirname \$(readlink -f \$(command -v java)))) && ./gradlew :app:compileDebugKotlin --no-daemon" > "$GRADLE_OUT" 2>&1
  CODE="$?"
  set -e
else
  set +e
  (
    cd "$ROOT/android"
    ./gradlew :app:compileDebugKotlin --no-daemon
  ) > "$GRADLE_OUT" 2>&1
  CODE="$?"
  set -e
fi

if [ "$CODE" -eq 0 ]; then
  GRADLE_STATUS="PASS"
  echo "Gradle Kotlin compile: PASS"
else
  GRADLE_STATUS="FAILED"
  echo "Gradle Kotlin compile: FAILED"
  echo ""
  echo "Last 160 lines:"
  tail -160 "$GRADLE_OUT" || true
fi

echo ""
echo "[4/5] Checking actual packet logger coverage..."

: > "$COVERAGE_OUT"

{
  echo "Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  echo ""
  echo "Actual logger calls excluding helper:"
  grep -RIn "MauriMeshNativeBlePacketLogger\." "$ROOT/android/app/src/main/java" 2>/dev/null \
    | grep -v "MauriMeshNativeBlePacketLogger.kt" || true
  echo ""
  echo "Stage coverage:"
} >> "$COVERAGE_OUT"

check_stage() {
  local label="$1"
  local pattern="$2"

  if grep -RIn "$pattern" "$ROOT/android/app/src/main/java" 2>/dev/null | grep -v "MauriMeshNativeBlePacketLogger.kt" >/dev/null 2>&1; then
    echo "$label: WIRED" >> "$COVERAGE_OUT"
  else
    echo "$label: MISSING_ACTUAL_USAGE" >> "$COVERAGE_OUT"
  fi
}

check_stage "advertise_start_packetId" "MauriMeshNativeBlePacketLogger\.advertiseStart"
check_stage "scan_result_packetId" "MauriMeshNativeBlePacketLogger\.scanResult"
check_stage "gatt_write_packetId" "MauriMeshNativeBlePacketLogger\.gattWrite"
check_stage "gatt_read_packetId" "MauriMeshNativeBlePacketLogger\.gattRead"
check_stage "characteristic_changed_packetId" "MauriMeshNativeBlePacketLogger\.characteristicChanged"
check_stage "relay_packetId" "MauriMeshNativeBlePacketLogger\.relay"
check_stage "ack_packetId" "MauriMeshNativeBlePacketLogger\.ack"

cat "$COVERAGE_OUT"

echo ""
echo "[5/5] Writing report..."

cat > "$REPORT" <<MD
# MauriMesh Java 17 Native BLE/GATT Check

Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")

## Java 17

Java report:

\`\`\`txt
$JAVA_REPORT
\`\`\`

## Gradle Kotlin Compile

Status:

\`\`\`txt
$GRADLE_STATUS
\`\`\`

Gradle output:

\`\`\`txt
$GRADLE_OUT
\`\`\`

## Native BLE/GATT Logger Coverage

Coverage output:

\`\`\`txt
$COVERAGE_OUT
\`\`\`

## Truth

Native BLE/GATT packet-bound PASS is **NOT CLAIMED**.

This check only verifies whether the native Kotlin code can compile and which native packet logger stages are actually wired.

## Current Known Coverage Before Further Wiring

Expected from last check:

\`\`\`txt
gatt_write_packetId: WIRED
ack_packetId: WIRED
advertise_start_packetId: missing
scan_result_packetId: missing
gatt_read_packetId: missing
characteristic_changed_packetId: missing
relay_packetId: missing
\`\`\`

## Next Rule

If Gradle passes, wire the missing actual native stages.

If Gradle fails with Kotlin errors, patch those errors first.

If Java 17 is unavailable, fix Replit environment before native compile proof.
MD

ARCHIVE="$ROOT/archives/maurimesh-java17-native-ble-gatt-check-$STAMP.tar.gz"
tar -czf "$ARCHIVE" \
  -C "$ROOT" \
  "docs/native-proof" \
  >/dev/null 2>&1 || true

echo ""
echo "============================================================"
echo "MAURIMESH JAVA 17 NATIVE BLE CHECK COMPLETE"
echo "============================================================"
echo "Gradle status:"
echo "$GRADLE_STATUS"
echo ""
echo "Java report:"
echo "$JAVA_REPORT"
echo ""
echo "Gradle output:"
echo "$GRADLE_OUT"
echo ""
echo "Coverage output:"
echo "$COVERAGE_OUT"
echo ""
echo "Final report:"
echo "$REPORT"
echo ""
echo "Archive:"
echo "$ARCHIVE"
echo ""
echo "FINAL TRUTH:"
echo "Native BLE/GATT packet-bound PASS is NOT claimed."
echo "============================================================"
