#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH ANDROID SDK PATH CHECK + GRADLE RETEST V2"
echo "============================================================"
echo "Fix:"
echo "- Handles empty ANDROID_HOME safely"
echo "- Keeps Java 17"
echo "- Searches for Android SDK"
echo "- Only writes local.properties if SDK exists"
echo "- Does NOT claim native BLE/GATT pass"
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +"%Y%m%d-%H%M%S")"
OUT_DIR="$ROOT/docs/native-proof"
mkdir -p "$OUT_DIR" "$ROOT/backups" "$ROOT/archives"

REPORT="$OUT_DIR/ANDROID_SDK_PATH_AND_NATIVE_GRADLE_RETEST_V2_$STAMP.md"
SDK_REPORT="$OUT_DIR/android-sdk-path-check-v2-$STAMP.txt"
GRADLE_OUT="$OUT_DIR/gradle-after-android-sdk-path-v2-$STAMP.txt"
COVERAGE_OUT="$OUT_DIR/native-ble-gatt-coverage-after-sdk-check-v2-$STAMP.txt"

echo "[1/5] Finding Java 17..."

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
  exit 1
fi

export JAVA_HOME="$JAVA17_HOME"
export PATH="$JAVA_HOME/bin:$PATH"

echo "Using JAVA_HOME:"
echo "$JAVA_HOME"
java -version || true

echo ""
echo "[2/5] Searching for Android SDK safely..."

CURRENT_ANDROID_HOME="${ANDROID_HOME:-}"
CURRENT_ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-}"

{
  echo "Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  echo ""
  echo "Existing ANDROID_HOME=${CURRENT_ANDROID_HOME:-not-set}"
  echo "Existing ANDROID_SDK_ROOT=${CURRENT_ANDROID_SDK_ROOT:-not-set}"
  echo ""
} > "$SDK_REPORT"

FOUND_SDK=""

check_sdk_dir() {
  local d="$1"
  if [ -n "$d" ] && [ -d "$d/platforms" ] && [ -d "$d/build-tools" ]; then
    FOUND_SDK="$d"
  fi
}

check_sdk_dir "$CURRENT_ANDROID_HOME"
check_sdk_dir "$CURRENT_ANDROID_SDK_ROOT"
check_sdk_dir "$HOME/Android/Sdk"
check_sdk_dir "$HOME/android-sdk"
check_sdk_dir "$HOME/.android/sdk"
check_sdk_dir "/opt/android-sdk"
check_sdk_dir "/usr/local/android-sdk"
check_sdk_dir "/android-sdk"

if [ -z "$FOUND_SDK" ]; then
  echo "Searching /nix/store for Android SDK candidates..." | tee -a "$SDK_REPORT"

  while IFS= read -r d; do
    if [ -d "$d/platforms" ] && [ -d "$d/build-tools" ]; then
      FOUND_SDK="$d"
      break
    fi
  done < <(find /nix/store -maxdepth 4 -type d 2>/dev/null | grep -Ei 'android-sdk|androidsdk|sdk' | head -200 || true)
fi

if [ -z "$FOUND_SDK" ]; then
  echo ""
  echo "============================================================"
  echo "ANDROID SDK NOT FOUND IN REPLIT"
  echo "============================================================"
  echo "Java 17 is fixed."
  echo "Android SDK is missing."
  echo "Local Gradle native compile cannot run here."
  echo ""
  echo "This is an environment blocker, not proof that the Kotlin patch is bad."
  echo "Use EAS cloud build or a machine with Android SDK."
  echo "============================================================"

  cat > "$REPORT" <<MD
# MauriMesh Android SDK Path Check V2

Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")

## Result

Android SDK was not found in this Replit environment.

## Current Truth

- Java 17: FOUND
- Android SDK: MISSING
- Local Gradle Kotlin compile: BLOCKED
- Native BLE/GATT packet-bound PASS: NOT CLAIMED

## Meaning

This is an environment blocker, not a confirmed Kotlin/code failure.

## Next Correct Path

Use one of:

1. EAS cloud build.
2. Replit environment with Android SDK installed.
3. Local Mac/PC with Android Studio SDK installed.

## Protection

No app source was changed by this check.
MD

  echo "Report:"
  echo "$REPORT"
  exit 0
fi

echo "Android SDK found:"
echo "$FOUND_SDK" | tee -a "$SDK_REPORT"

export ANDROID_HOME="$FOUND_SDK"
export ANDROID_SDK_ROOT="$FOUND_SDK"
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/tools/bin:$PATH"

echo ""
echo "[3/5] Writing android/local.properties..."

if [ -f "$ROOT/android/local.properties" ]; then
  cp "$ROOT/android/local.properties" "$ROOT/backups/local.properties.before-sdk-v2-$STAMP" || true
fi

cat > "$ROOT/android/local.properties" <<PROP
sdk.dir=$ANDROID_HOME
PROP

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
echo "[5/5] Checking packet logger coverage..."

{
  echo "Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  echo ""
  echo "Actual logger calls excluding helper:"
  grep -RIn "MauriMeshNativeBlePacketLogger\." "$ROOT/android/app/src/main/java" 2>/dev/null \
    | grep -v "MauriMeshNativeBlePacketLogger.kt" || true
  echo ""
  echo "Stage coverage:"
} > "$COVERAGE_OUT"

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
# MauriMesh Android SDK Path + Native Gradle Retest V2

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

Native BLE/GATT packet-bound PASS is NOT CLAIMED.
MD

ARCHIVE="$ROOT/archives/maurimesh-android-sdk-native-gradle-retest-v2-$STAMP.tar.gz"
tar -czf "$ARCHIVE" -C "$ROOT" "docs/native-proof" >/dev/null 2>&1 || true

echo ""
echo "============================================================"
echo "ANDROID SDK PATH + NATIVE GRADLE RETEST V2 COMPLETE"
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
