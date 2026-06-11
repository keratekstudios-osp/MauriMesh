#!/usr/bin/env bash
set -u
set -o pipefail

ROOT="/home/runner/workspace"
STAMP="$(date +%Y%m%d-%H%M%S)"
DOCS="$ROOT/docs"
REPORT="$DOCS/maurimesh-total-apk-usb-debug-test-build-$STAMP.md"
LATEST="$DOCS/maurimesh-total-apk-usb-debug-test-build-latest.md"
LOG="$DOCS/maurimesh-total-apk-usb-debug-test-build-$STAMP.log"
LATEST_LOG="$DOCS/maurimesh-total-apk-usb-debug-test-build-latest.log"

mkdir -p "$DOCS"
cd "$ROOT" || {
  echo "ERROR: /home/runner/workspace not found."
  exit 1
}

exec > >(tee -a "$LOG") 2>&1

PASS=0
WARN=0
FAIL=0

pass() {
  PASS=$((PASS + 1))
  echo "PASS: $1"
  echo "- [PASS] $1" >> "$REPORT"
}

warn() {
  WARN=$((WARN + 1))
  echo "WARN: $1"
  echo "- [WARN] $1" >> "$REPORT"
}

fail() {
  FAIL=$((FAIL + 1))
  echo "FAIL: $1"
  echo "- [FAIL] $1" >> "$REPORT"
}

section() {
  echo ""
  echo "============================================================"
  echo "$1"
  echo "============================================================"
  echo ""
  {
    echo ""
    echo "## $1"
    echo ""
  } >> "$REPORT"
}

run_capture() {
  local title="$1"
  shift
  section "$title"
  echo "+ $*"
  {
    echo '```txt'
    echo "+ $*"
  } >> "$REPORT"

  if "$@" >> "$REPORT" 2>&1; then
    echo "OK: $title"
    echo '```' >> "$REPORT"
    return 0
  else
    echo "FAILED/NON-FATAL: $title"
    echo '```' >> "$REPORT"
    return 1
  fi
}

cat > "$REPORT" <<MD
# MauriMesh Total APK USB Debug + Build Test Report

Generated: $STAMP  
Root: $ROOT  

This report checks:
- USB debugging / ADB visibility when a device is connected
- MauriMesh required route inventory
- Full Mesh Test Report route
- Dashboard route button/reference
- Package/dependency sanity
- TypeScript check
- Expo export bundle sanity
- Android native permissions/wiring
- Kotlin/native module presence
- Local Gradle readiness when Java/Android folder are available
- Device logcat when ADB device is available
- EAS APK build trigger without Replit emulator install

MD

echo ""
echo "============================================================"
echo "MAURIMESH TOTAL APK USB DEBUG + TEST + BUILD"
echo "============================================================"
echo "Report: $REPORT"
echo "Log:    $LOG"
echo ""

section "0. Root Validation"

if [ -f "$ROOT/package.json" ]; then
  pass "package.json exists in /home/runner/workspace"
else
  fail "package.json missing in /home/runner/workspace"
  cp "$REPORT" "$LATEST"
  cp "$LOG" "$LATEST_LOG"
  exit 1
fi

if [ -d "$ROOT/app" ]; then
  pass "app directory exists"
else
  fail "app directory missing"
  cp "$REPORT" "$LATEST"
  cp "$LOG" "$LATEST_LOG"
  exit 1
fi

if [ -d "$ROOT/android" ]; then
  pass "android native directory exists"
else
  warn "android native directory missing; EAS/prebuild may be required"
fi

section "1. USB Debugging / ADB Test"

ADB_BIN="$(command -v adb || true)"

if [ -z "$ADB_BIN" ]; then
  warn "adb not installed in this environment. In Replit this is normal. Run the Mac ADB block below on your Mac for USB debugging."
else
  pass "adb exists: $ADB_BIN"

  adb kill-server >/dev/null 2>&1 || true
  adb start-server >/dev/null 2>&1 || true

  echo "ADB devices:"
  adb devices -l | tee "$DOCS/adb-devices-$STAMP.txt"

  DEVICE_LINES="$(adb devices | awk 'NR>1 && NF>=2 {print $0}' || true)"
  DEVICE_COUNT="$(echo "$DEVICE_LINES" | grep -cE '[[:space:]]device$' || true)"
  UNAUTH_COUNT="$(echo "$DEVICE_LINES" | grep -cE '[[:space:]]unauthorized$' || true)"
  OFFLINE_COUNT="$(echo "$DEVICE_LINES" | grep -cE '[[:space:]]offline$' || true)"

  if [ "$DEVICE_COUNT" -ge 1 ]; then
    SERIAL="$(adb devices | awk 'NR>1 && $2=="device" {print $1; exit}')"
    pass "ADB authorized device connected: $SERIAL"

    {
      echo "### ADB Device Properties"
      echo '```txt'
      adb -s "$SERIAL" shell getprop ro.product.model 2>/dev/null || true
      adb -s "$SERIAL" shell getprop ro.product.device 2>/dev/null || true
      adb -s "$SERIAL" shell getprop ro.product.brand 2>/dev/null || true
      adb -s "$SERIAL" shell getprop ro.build.version.release 2>/dev/null || true
      adb -s "$SERIAL" shell getprop ro.build.version.sdk 2>/dev/null || true
      adb -s "$SERIAL" shell getprop ro.build.display.id 2>/dev/null || true
      echo '```'
    } >> "$REPORT"

    MODEL="$(adb -s "$SERIAL" shell getprop ro.product.model 2>/dev/null | tr -d '\r' || true)"
    DEVICE="$(adb -s "$SERIAL" shell getprop ro.product.device 2>/dev/null | tr -d '\r' || true)"
    SDK="$(adb -s "$SERIAL" shell getprop ro.build.version.sdk 2>/dev/null | tr -d '\r' || true)"

    echo "Connected model: ${MODEL:-unknown}"
    echo "Connected device: ${DEVICE:-unknown}"
    echo "SDK: ${SDK:-unknown}"

    if echo "$MODEL" | grep -q "SM-A065F"; then
      pass "Connected USB phone is SM-A065F"
    else
      warn "Connected USB phone is not SM-A065F. Model detected: ${MODEL:-unknown}. Do not flash A06 firmware to the wrong device."
    fi

    echo ""
    echo "Clearing logcat..."
    adb -s "$SERIAL" logcat -c >/dev/null 2>&1 || true

    PKG=""
    if [ -f android/app/build.gradle ]; then
      PKG="$(grep -E 'applicationId ' android/app/build.gradle | head -n 1 | sed -E 's/.*applicationId[[:space:]]+["'"'"']([^"'"'"']+)["'"'"'].*/\1/' || true)"
    fi
    if [ -z "$PKG" ] && [ -f android/app/build.gradle.kts ]; then
      PKG="$(grep -E 'applicationId[[:space:]]*=' android/app/build.gradle.kts | head -n 1 | sed -E 's/.*applicationId[[:space:]]*=[[:space:]]*["'"'"']([^"'"'"']+)["'"'"'].*/\1/' || true)"
    fi
    if [ -z "$PKG" ]; then
      PKG="com.maurimesh.messenger"
      warn "Could not read package id from Gradle. Using fallback $PKG"
    else
      pass "Detected Android package id: $PKG"
    fi

    echo "Trying to launch installed app package: $PKG"
    adb -s "$SERIAL" shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1 || warn "Could not launch $PKG. APK may not be installed yet."

    echo "Waiting 15 seconds for app logs..."
    sleep 15

    adb -s "$SERIAL" logcat -d > "$DOCS/adb-logcat-full-$STAMP.txt" 2>/dev/null || true
    grep -Ei "AndroidRuntime|FATAL EXCEPTION|ReactNativeJS|MauriMesh|BLE|Bluetooth|TX_BLE|RX_BLE|ACK|NativeTelemetry|MauriCore" \
      "$DOCS/adb-logcat-full-$STAMP.txt" > "$DOCS/adb-logcat-maurimesh-$STAMP.txt" 2>/dev/null || true

    if grep -Ei "AndroidRuntime|FATAL EXCEPTION|ReactNativeJS.*(Error|Exception|TypeError|ReferenceError)" "$DOCS/adb-logcat-full-$STAMP.txt" >/dev/null 2>&1; then
      fail "Device logcat contains fatal/runtime React Native or Android errors"
    else
      pass "No obvious AndroidRuntime/FATAL/ReactNativeJS fatal found in captured logcat"
    fi

    {
      echo "### Filtered ADB Logcat"
      echo '```txt'
      tail -250 "$DOCS/adb-logcat-maurimesh-$STAMP.txt" 2>/dev/null || true
      echo '```'
    } >> "$REPORT"

  elif [ "$UNAUTH_COUNT" -ge 1 ]; then
    warn "ADB sees phone but unauthorized. Unlock phone, accept RSA prompt, then run: adb devices -l"
  elif [ "$OFFLINE_COUNT" -ge 1 ]; then
    warn "ADB sees phone offline. Replug USB, toggle USB debugging, restart adb server."
  else
    warn "No ADB device connected. In Replit this is expected. USB debugging must be tested on your Mac with phone connected."
  fi
fi

section "2. Required Route Inventory"

REQUIRED_ROUTES=(
  "app/dashboard.tsx"
  "app/test-layer.tsx"
  "app/full-mesh-test-report.tsx"
  "app/maori-protocols.tsx"
  "app/jumpcode-proof.tsx"
  "app/evolution-layer.tsx"
  "app/native-telemetry.tsx"
  "app/mauricore-ble-runtime.tsx"
  "app/device-proof.tsx"
  "app/proof-ledger.tsx"
  "app/message-fallback.tsx"
  "app/route-lab.tsx"
  "app/hybrid-wifi-ble-mesh.tsx"
  "app/living-mesh.tsx"
  "app/self-healing.tsx"
  "app/pixel-calling.tsx"
  "app/ai-pixel-reconstruction.tsx"
)

for route_file in "${REQUIRED_ROUTES[@]}"; do
  if [ -f "$route_file" ]; then
    pass "Required route exists: $route_file"
  else
    fail "Required route missing: $route_file"
  fi
done

{
  echo "### Route Inventory"
  echo '```txt'
  find app -type f -name "*.tsx" | sort
  echo '```'
} >> "$REPORT"

if grep -RIn "full-mesh-test-report" app/dashboard.tsx app/test-layer.tsx app/full-mesh-test-report.tsx >/dev/null 2>&1; then
  pass "Full Mesh Test Report route is referenced in app files"
else
  warn "Full Mesh Test Report route file exists but route reference not found outside route file"
fi

section "3. Dependency / Package Test"

NODE_VERSION="$(node -v 2>/dev/null || true)"
NPM_VERSION="$(npm -v 2>/dev/null || true)"

if [ -n "$NODE_VERSION" ]; then
  pass "Node available: $NODE_VERSION"
else
  fail "Node missing"
fi

if [ -n "$NPM_VERSION" ]; then
  pass "npm available: $NPM_VERSION"
else
  warn "npm missing"
fi

if command -v pnpm >/dev/null 2>&1 && [ -f pnpm-lock.yaml ]; then
  pass "pnpm lockfile detected"
  run_capture "pnpm install check" pnpm install --frozen-lockfile || run_capture "pnpm install fallback" pnpm install || warn "pnpm install failed"
elif [ -f package-lock.json ]; then
  pass "npm package-lock detected"
  run_capture "npm ci check" npm ci || run_capture "npm install fallback" npm install || warn "npm install failed"
else
  warn "No pnpm-lock.yaml or package-lock.json found; running npm install"
  run_capture "npm install" npm install || warn "npm install failed"
fi

section "4. TypeScript Test"

if [ -f tsconfig.json ]; then
  if command -v pnpm >/dev/null 2>&1 && [ -f pnpm-lock.yaml ]; then
    if pnpm exec tsc --noEmit >> "$REPORT" 2>&1; then
      pass "TypeScript check passed"
    else
      warn "TypeScript check has errors. Build may still pass if EAS transpiles, but fix these before final release."
    fi
  else
    if npx tsc --noEmit >> "$REPORT" 2>&1; then
      pass "TypeScript check passed"
    else
      warn "TypeScript check has errors. Build may still pass if EAS transpiles, but fix these before final release."
    fi
  fi
else
  warn "No tsconfig.json found"
fi

section "5. Expo Export / Bundle Test"

if [ -f app.json ] || [ -f app.config.js ] || [ -f app.config.ts ]; then
  rm -rf ".maurimesh-total-export-$STAMP"
  if npx expo export --platform android --output-dir ".maurimesh-total-export-$STAMP" >> "$REPORT" 2>&1; then
    pass "Expo Android export passed"
  else
    fail "Expo Android export failed"
  fi
else
  warn "No Expo config found. Skipping expo export."
fi

section "6. Android Native Permission + BLE Wiring Test"

MANIFEST="android/app/src/main/AndroidManifest.xml"

if [ -f "$MANIFEST" ]; then
  pass "AndroidManifest.xml exists"

  for perm in \
    "android.permission.BLUETOOTH" \
    "android.permission.BLUETOOTH_ADMIN" \
    "android.permission.BLUETOOTH_SCAN" \
    "android.permission.BLUETOOTH_CONNECT" \
    "android.permission.BLUETOOTH_ADVERTISE" \
    "android.permission.ACCESS_FINE_LOCATION" \
    "android.permission.ACCESS_COARSE_LOCATION" \
    "android.permission.FOREGROUND_SERVICE"; do
    if grep -q "$perm" "$MANIFEST"; then
      pass "Manifest permission present: $perm"
    else
      warn "Manifest permission not found: $perm"
    fi
  done

  {
    echo "### AndroidManifest BLE lines"
    echo '```xml'
    grep -nEi "BLUETOOTH|LOCATION|FOREGROUND|service|receiver|Mauri|Ble" "$MANIFEST" || true
    echo '```'
  } >> "$REPORT"
else
  warn "AndroidManifest.xml missing"
fi

if find android -type f \( -name "*.kt" -o -name "*.java" \) 2>/dev/null | grep -Ei "MauriMeshBle|BleModule|NativeTelemetry|MauriCore" >/dev/null 2>&1; then
  pass "Native MauriMesh BLE/telemetry source files detected"
else
  warn "Native MauriMesh BLE/telemetry source files not detected by filename"
fi

{
  echo "### Native files"
  echo '```txt'
  find android/app/src/main -type f \( -name "*.kt" -o -name "*.java" -o -name "AndroidManifest.xml" \) 2>/dev/null | sort | grep -Ei "Mauri|Ble|Telemetry|MainApplication|MainActivity|AndroidManifest" || true
  echo '```'
} >> "$REPORT"

if grep -RIn "MauriMeshBleModule\|NativeTelemetry\|BluetoothAdapter\|BluetoothLeScanner\|BluetoothGatt\|BluetoothGattServer" android/app/src/main 2>/dev/null >> "$REPORT"; then
  pass "Native BLE/telemetry implementation strings found"
else
  warn "Native BLE/telemetry strings not found"
fi

section "7. Kotlin / MainApplication Wiring Test"

MAIN_APP="$(find android/app/src/main -type f \( -name "MainApplication.kt" -o -name "MainApplication.java" \) 2>/dev/null | head -n 1 || true)"

if [ -n "$MAIN_APP" ]; then
  pass "MainApplication found: $MAIN_APP"

  if grep -q "MauriMeshBle" "$MAIN_APP"; then
    pass "MainApplication references MauriMesh BLE module/package"
  else
    warn "MainApplication does not visibly reference MauriMesh BLE module/package"
  fi

  {
    echo "### MainApplication relevant lines"
    echo '```txt'
    grep -nEi "Mauri|Ble|Package|ReactPackage|getPackages|NativeTelemetry" "$MAIN_APP" || true
    echo '```'
  } >> "$REPORT"
else
  warn "MainApplication file not found"
fi

section "8. Local Gradle Readiness Test"

if [ -d android ] && [ -f android/gradlew ]; then
  chmod +x android/gradlew || true

  if command -v java >/dev/null 2>&1; then
    pass "Java available for local Gradle"
    java -version 2>> "$REPORT" || true

    echo "Running lightweight Gradle tasks check..."
    if (cd android && ./gradlew tasks --all) >> "$REPORT" 2>&1; then
      pass "Gradle tasks check passed"
    else
      warn "Gradle tasks check failed locally. EAS may still build remotely."
    fi

    if [ "${RUN_LOCAL_ANDROID_BUILD:-0}" = "1" ]; then
      echo "RUN_LOCAL_ANDROID_BUILD=1 detected. Running local debug build..."
      if (cd android && ./gradlew :app:assembleDebug -x lint -x test) >> "$REPORT" 2>&1; then
        pass "Local Android assembleDebug passed"
      else
        warn "Local Android assembleDebug failed"
      fi
    else
      warn "Skipped local assembleDebug. Set RUN_LOCAL_ANDROID_BUILD=1 to run it."
    fi
  else
    warn "Java not available locally. Skipping local Gradle."
  fi
else
  warn "android/gradlew missing. Skipping local Gradle."
fi

section "9. In-App Proof Screens Required After Install"

cat >> "$REPORT" <<'TXT'
After installing the APK, manually open and screenshot:

1. /dashboard
2. /full-mesh-test-report
3. /test-layer
4. /native-telemetry
5. /mauricore-ble-runtime
6. /device-proof
7. /proof-ledger
8. /message-fallback
9. /route-lab
10. /hybrid-wifi-ble-mesh

Real two-phone proof still requires:
- PHONE_A_TX_BLE_START
- PHONE_B_RX_BLE_FROM_A
- PHONE_B_ACK_SENT
- PHONE_A_ACK_RECEIVED
- matching packetId
- matching routeId
TXT

section "10. EAS Build Trigger"

if command -v npx >/dev/null 2>&1; then
  pass "npx available"

  if grep -q '"preview-apk"' eas.json 2>/dev/null || grep -q 'preview-apk' eas.json 2>/dev/null; then
    pass "preview-apk profile found in eas.json"
  else
    warn "preview-apk profile not clearly found in eas.json"
  fi

  echo ""
  echo "Starting EAS Android APK build in non-interactive mode."
  echo "This avoids the Replit emulator install prompt."
  echo ""

  if npx eas-cli build --platform android --profile preview-apk --clear-cache --non-interactive >> "$REPORT" 2>&1; then
    pass "EAS APK build command completed"
  else
    fail "EAS APK build command failed. Read report/log for exact build blocker."
  fi
else
  fail "npx missing; cannot trigger EAS build"
fi

section "11. Final Score"

TOTAL=$((PASS + WARN + FAIL))
if [ "$TOTAL" -eq 0 ]; then
  SCORE=0
else
  SCORE=$((PASS * 100 / TOTAL))
fi

{
  echo ""
  echo "PASS: $PASS"
  echo "WARN: $WARN"
  echo "FAIL: $FAIL"
  echo "SCORE: $SCORE%"
  echo ""
  echo "Report: $REPORT"
  echo "Log: $LOG"
} | tee -a "$REPORT"

cp "$REPORT" "$LATEST"
cp "$LOG" "$LATEST_LOG"

echo ""
echo "============================================================"
echo "MAURIMESH TOTAL TEST COMPLETE"
echo "============================================================"
echo "PASS: $PASS"
echo "WARN: $WARN"
echo "FAIL: $FAIL"
echo "SCORE: $SCORE%"
echo ""
echo "Latest report:"
echo "$LATEST"
echo ""
echo "Latest log:"
echo "$LATEST_LOG"
echo ""
echo "Show report:"
echo "cat $LATEST"
echo "============================================================"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
