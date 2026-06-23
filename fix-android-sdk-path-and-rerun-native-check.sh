#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH ANDROID SDK PATH CHECK + GRADLE RETEST"
echo "============================================================"
echo "Goal:"
echo "- Find Android SDK if it exists"
echo "- Set ANDROID_HOME for this shell run"
echo "- Write android/local.properties only if SDK exists"
echo "- Rerun Gradle Kotlin compile"
echo "- Do NOT claim native BLE/GATT pass"
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +"%Y%m%d-%H%M%S")"
OUT_DIR="$ROOT/docs/native-proof"
mkdir -p "$OUT_DIR"

REPORT="$OUT_DIR/ANDROID_SDK_PATH_AND_NATIVE_GRADLE_RETEST_$STAMP.md"
SDK_REPORT="$OUT_DIR/android-sdk-path-check-$STAMP.txt"
GRADLE_OUT="$OUT_DIR/gradle-after-android-sdk-path-$STAMP.txt"
COVERAGE_OUT="$OUT_DIR/native-ble-gatt-coverage-after-sdk-check-$STAMP.txt"

BACKUP_LOCAL="$ROOT/backups/local-properties-before-sdk-check-$STAMP"
mkdir -p "$ROOT/backups"

if [ -f "$ROOT/android/local.properties" ]; then
  cp "$ROOT/android/local.properties" "$BACKUP_LOCAL" || true
fi

echo "[1/5] Finding Java 17 again..."

JAVA17_HOME=""

for candidate in \
  /nix/store/*jdk-17* \
  /nix/store/*openjdk-17* \
  /nix/store/*temurin-bin-17* \
  /nix/store/*zulu*17*
do
  if [ -x "$candidate/bin/java" ]; then
    JAVA17_HOME="$candidate"
    break
  fi
done

if [ -z "$JAVA17_HOME" ]; then
  echo "ERROR: Java 17 not found."
  echo "Previous run found Java 17, but this shell cannot see it now."
  exit 1
fi

export JAVA_HOME="$JAVA17_HOME"
export PATH="$JAVA_HOME/bin:$PATH"

echo "Using JAVA_HOME:"
echo "$JAVA_HOME"
java -version || true

echo ""
echo "[2/5] Searching for Android SDK..."

: > "$SDK_REPORT"

{
  echo "Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  echo ""
  echo "Existing ANDROID_HOME=${ANDROID_HOME:-not-set}"
  echo "Existing ANDROID_SDK_ROOT=${ANDROID_SDK_ROOT:-not-set}"
  echo ""
  echo "Common SDK folder checks:"
} >> "$SDK_REPORT"

SDK_CANDIDATES=()

for d in \
  "$ANDROID_HOME" \
  "$ANDROID_SDK_ROOT" \
  "$HOME/Android/Sdk" \
  "$HOME/android-sdk" \
  "$HOME/.android/sdk" \
  "/opt/android-sdk" \
  "/usr/local/android-sdk" \
  "/android-sdk" \
  "/nix/store"
do
  if [ -n "${d:-}" ] && [ -d "${d:-}" ]; then
    SDK_CANDIDATES+=("$d")
  fi
done

FOUND_SDK=""

for d in "${SDK_CANDIDATES[@]}"; do
  echo "Checking: $d" >> "$SDK_REPORT"

  if [ -d "$d/platforms" ] && [ -d "$d/build-tools" ]; then
    FOUND_SDK="$d"
    break
  fi

  if [ "$d" = "/nix/store" ]; then
    NIX_SDK="$(find /nix/store -maxdepth 2 -type d 2>/dev/null | grep -E 'android-sdk|androidsdk|cmdline-tools' | head -1 || true)"
    if [ -n "$NIX_SDK" ]; then
      PARENT="$NIX_SDK"
      while [ "$PARENT" != "/" ]; do
        if [ -d "$PARENT/platforms" ] && [ -d "$PARENT/build-tools" ]; then
          FOUND_SDK="$PARENT"
          break
        fi
        PARENT="$(dirname "$PARENT")"
      done
    fi
  fi

  [ -n "$FOUND_SDK" ] && break
done

if [ -z "$FOUND_SDK" ]; then
  echo "No Android SDK found." | tee -a "$SDK_REPORT"

  cat > "$REPORT" <<MD
# MauriMesh Android SDK Path Check

Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")

## Result

Android SDK was not found in this Replit environment.

## Meaning

Local Gradle compile cannot proceed here until Android SDK is available.

This does not prove the native Kotlin patch is bad.

It means local Replit native compile is blocked by environment.

## Current Truth

- Java 17: available
- Android SDK: missing
- Gradle Kotlin compile: blocked
- Native BLE/GATT packet-bound PASS: NOT CLAIMED

## Next Options

1. Use EAS cloud build to compile native Android.
2. Add Android SDK to Replit environment.
3. Run native compile on a machine with Android SDK installed.

## No App Source Changed

This check did not edit MauriMesh source code.
MD

  echo ""
  echo "============================================================"
  echo "ANDROID SDK NOT FOUND"
  echo "============================================================"
  echo "Report:"
  echo "$REPORT"
  echo ""
  echo "FINAL TRUTH:"
  echo "Java 17 is fixed, but Android SDK is missing."
  echo "Native BLE/GATT packet-bound PASS is NOT claimed."
  echo "============================================================"
  exit 0
fi

export ANDROID_HOME="$FOUND_SDK"
export ANDROID_SDK_ROOT="$FOUND_SDK"
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/tools/bin:$PATH"

echo "Android SDK found:"
echo "$ANDROID_HOME" | tee -a "$SDK_REPORT"

echo ""
echo "[3/5] Writing android/local.properties..."

cat > "$ROOT/android/local.properties" <<PROP
sdk.dir=$ANDROID_HOME
PROP

echo "android/local.properties:"
cat "$ROOT/android/local.properties"

echo ""
echo "[4/5] Running Gradle Kotlin compile..."

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
  echo "Last 160 lines:"
  tail -160 "$GRADLE_OUT" || true
fi

echo ""
echo "[5/5] Checking coverage again..."

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

cat > "$REPORT" <<MD
# MauriMesh Android SDK Path + Native Gradle Retest

Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")

## Environment

JAVA_HOME:

\`\`\`txt
$JAVA_HOME
\`\`\`

ANDROID_HOME:

\`\`\`txt
$ANDROID_HOME
\`\`\`

## Gradle Kotlin Compile

Status:

\`\`\`txt
$GRADLE_STATUS
\`\`\`

Output:

\`\`\`txt
$GRADLE_OUT
\`\`\`

## Coverage

Coverage:

\`\`\`txt
$COVERAGE_OUT
\`\`\`

## Truth

Native BLE/GATT packet-bound PASS is **NOT CLAIMED**.

If Gradle passed, the next step is to wire missing actual stages.
If Gradle failed with Kotlin errors, patch those exact errors.
MD

ARCHIVE="$ROOT/archives/maurimesh-android-sdk-native-gradle-retest-$STAMP.tar.gz"
tar -czf "$ARCHIVE" -C "$ROOT" "docs/native-proof" >/dev/null 2>&1 || true

echo ""
echo "============================================================"
echo "ANDROID SDK PATH + NATIVE GRADLE RETEST COMPLETE"
echo "============================================================"
echo "Gradle status:"
echo "$GRADLE_STATUS"
echo ""
echo "SDK report:"
echo "$SDK_REPORT"
echo ""
echo "Gradle output:"
echo "$GRADLE_OUT"
echo ""
echo "Coverage output:"
echo "$COVERAGE_OUT"
echo ""
echo "Report:"
echo "$REPORT"
echo ""
echo "Archive:"
echo "$ARCHIVE"
echo ""
echo "FINAL TRUTH:"
echo "Native BLE/GATT packet-bound PASS is NOT claimed."
echo "============================================================"
