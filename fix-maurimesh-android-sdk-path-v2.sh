#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "FIX MAURIMESH ANDROID SDK PATH V2"
echo "Safe unset-variable version"
echo "============================================================"
echo ""

ROOT="/home/runner/workspace"
ANDROID="$ROOT/android"

if [ ! -d "$ANDROID" ]; then
  echo "ERROR: android folder missing."
  exit 1
fi

echo "1. Current Android env"
echo "ANDROID_HOME=${ANDROID_HOME:-not set}"
echo "ANDROID_SDK_ROOT=${ANDROID_SDK_ROOT:-not set}"

echo ""
echo "2. Find Android SDK candidates"

SDK_FOUND=""

CANDIDATES=(
  "${ANDROID_HOME:-}"
  "${ANDROID_SDK_ROOT:-}"
  "$HOME/Android/Sdk"
  "$HOME/android-sdk"
  "/opt/android-sdk"
  "/usr/local/android-sdk"
)

for sdk in "${CANDIDATES[@]}"; do
  if [ -n "$sdk" ] && [ -d "$sdk" ]; then
    if [ -d "$sdk/platforms" ] || [ -d "$sdk/build-tools" ] || [ -d "$sdk/cmdline-tools" ] || [ -d "$sdk/platform-tools" ]; then
      SDK_FOUND="$sdk"
      break
    fi
  fi
done

if [ -z "$SDK_FOUND" ]; then
  echo "No standard SDK path found. Searching likely locations..."
  SDK_FOUND="$(find /home/runner /opt /usr/local /nix/store -maxdepth 8 -type d \( -name platforms -o -name build-tools -o -name platform-tools -o -name cmdline-tools \) 2>/dev/null \
    | sed -E 's#/(platforms|build-tools|platform-tools|cmdline-tools)$##' \
    | sort -u \
    | head -1 || true)"
fi

if [ -z "$SDK_FOUND" ]; then
  echo ""
  echo "❌ Android SDK not found in current Replit environment."
  echo ""
  echo "Your replit.nix has been written, but Replit has not loaded the Android SDK yet."
  echo ""
  echo "Do this now:"
  echo "1. Press Run once, or restart the Shell."
  echo "2. Then rerun:"
  echo "   cd /home/runner/workspace"
  echo "   ./fix-maurimesh-android-sdk-path-v2.sh"
  echo ""
  echo "Current replit.nix:"
  cat "$ROOT/replit.nix" 2>/dev/null || true
  exit 1
fi

echo "SDK_FOUND=$SDK_FOUND"

echo ""
echo "3. Export Android SDK env"
export ANDROID_HOME="$SDK_FOUND"
export ANDROID_SDK_ROOT="$SDK_FOUND"
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/tools/bin:$PATH"

echo "ANDROID_HOME=$ANDROID_HOME"
echo "ANDROID_SDK_ROOT=$ANDROID_SDK_ROOT"

echo ""
echo "4. Write android/local.properties"
cat > "$ANDROID/local.properties" <<PROP
sdk.dir=$ANDROID_HOME
PROP

cat "$ANDROID/local.properties"

echo ""
echo "5. SDK component snapshot"
find "$ANDROID_HOME" -maxdepth 3 -type d | grep -E "platforms/android|build-tools|platform-tools|ndk|cmake|cmdline-tools" | sort || true

echo ""
echo "6. Java repair from active binary"
unset JAVA_HOME
JAVA_BIN="$(readlink -f "$(command -v java)")"
export JAVA_HOME="$(dirname "$(dirname "$JAVA_BIN")")"
export PATH="$JAVA_HOME/bin:$PATH"

echo "JAVA_BIN=$JAVA_BIN"
echo "JAVA_HOME=$JAVA_HOME"
java -version

echo ""
echo "7. Retry Android debug compile"
cd "$ANDROID"
chmod +x ./gradlew
./gradlew --stop || true

set +e
./gradlew :app:assembleDebug \
  --console=plain \
  --no-daemon \
  --stacktrace \
  -x lint \
  -x lintDebug \
  -x test \
  -x testDebugUnitTest \
  2>&1 | tee "$ROOT/gradle-after-sdk-fix.log"
STATUS="${PIPESTATUS[0]}"
set -e

cd "$ROOT"

echo ""
echo "============================================================"
echo "RESULT"
echo "============================================================"

if [ "$STATUS" -eq 0 ]; then
  echo "✅ Android debug build passed."
  find "$ROOT/android/app/build/outputs/apk" -name "*.apk" -print
else
  echo "❌ Android debug build still failed."
  echo "Do not run EAS yet."
  echo ""
  echo "Error summary:"
  grep -ni -A80 -B30 -E "failed|failure|what went wrong|execution failed|exception|error|could not|cannot|unresolved|duplicate|manifest|kotlin|java|gradle|plugin|dependency|resolve|SDK|sdk.dir|ANDROID_HOME|NDK|CMake" "$ROOT/gradle-after-sdk-fix.log" | head -520 || true
fi
