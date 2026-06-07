#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH FULL WIRING INSPECTOR"
echo "Dependency + Android + Expo + BLE + Rust + UI + API wiring"
echo "============================================================"
echo ""

ROOT="$(pwd)"
REPORT="$ROOT/MAURIMESH_WIRING_REPORT.md"

: > "$REPORT"

write() {
  echo "$1"
  echo "$1" >> "$REPORT"
}

section() {
  echo ""
  echo "------------------------------------------------------------"
  echo "$1"
  echo "------------------------------------------------------------"

  {
    echo ""
    echo "## $1"
    echo ""
  } >> "$REPORT"
}

pass() {
  write "✅ PASS: $1"
}

warn() {
  write "⚠️ WARN: $1"
}

fail() {
  write "❌ FAIL: $1"
}

file_exists() {
  local file="$1"
  local label="$2"

  if [ -f "$file" ]; then
    pass "$label exists: $file"
  else
    fail "$label missing: $file"
  fi
}

dir_exists() {
  local dir="$1"
  local label="$2"

  if [ -d "$dir" ]; then
    pass "$label exists: $dir"
  else
    fail "$label missing: $dir"
  fi
}

grep_project() {
  local title="$1"
  local pattern="$2"

  section "$title"

  if grep -RIn --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=android/.gradle --exclude-dir=ios/Pods "$pattern" . >> "$REPORT" 2>/dev/null; then
    pass "Found pattern: $pattern"
  else
    warn "Pattern not found: $pattern"
  fi
}

section "PROJECT ROOT"

if [ ! -f package.json ]; then
  fail "package.json not found. You are not in the project root."
  exit 1
fi

pass "package.json found"
write "Project root: $ROOT"

section "CORE FILES"

file_exists "package.json" "package manifest"
file_exists "pnpm-lock.yaml" "pnpm lockfile"
file_exists "app.json" "Expo app.json"
file_exists "app.config.js" "Expo app.config.js"
file_exists "eas.json" "EAS config"
file_exists "metro.config.js" "Metro config"
file_exists "babel.config.js" "Babel config"
file_exists "tsconfig.json" "TypeScript config"

section "PACKAGE JSON SUMMARY"

node <<'NODE' >> "$REPORT" 2>&1 || true
const fs = require("fs");
const pkg = JSON.parse(fs.readFileSync("package.json", "utf8"));

console.log("name:", pkg.name);
console.log("version:", pkg.version);
console.log("main:", pkg.main);
console.log("packageManager:", pkg.packageManager);
console.log("scripts:", JSON.stringify(pkg.scripts || {}, null, 2));
console.log("dependencies:", Object.keys(pkg.dependencies || {}).length);
console.log("devDependencies:", Object.keys(pkg.devDependencies || {}).length);
console.log("overrides:", JSON.stringify(pkg.overrides || pkg.pnpm?.overrides || {}, null, 2));

const mustHave = [
  "expo",
  "react",
  "react-native",
  "expo-router",
  "expo-dev-client",
  "expo-modules-core",
  "react-native-ble-plx"
];

console.log("");
console.log("Required dependency check:");
for (const dep of mustHave) {
  const version = pkg.dependencies?.[dep] || pkg.devDependencies?.[dep];
  console.log(version ? `PASS ${dep}: ${version}` : `MISSING ${dep}`);
}
NODE

section "EXPO CONFIG INSPECTION"

if [ -f app.json ]; then
  cat app.json >> "$REPORT" 2>&1 || true
fi

if [ -f app.config.js ]; then
  cat app.config.js >> "$REPORT" 2>&1 || true
fi

grep_project "EXPO PACKAGE / APP ID SEARCH" "com.maurimesh\|com.anonymous\|android.package\|bundleIdentifier\|scheme"

section "ANDROID NATIVE PROJECT"

dir_exists "android" "Android native folder"
file_exists "android/settings.gradle" "Android settings.gradle"
file_exists "android/build.gradle" "Android root build.gradle"
file_exists "android/app/build.gradle" "Android app build.gradle"
file_exists "android/gradle/wrapper/gradle-wrapper.properties" "Gradle wrapper properties"
file_exists "android/app/src/main/AndroidManifest.xml" "Android manifest"
file_exists "android/app/src/main/java" "Android Java/Kotlin source root"

if [ -f android/gradle/wrapper/gradle-wrapper.properties ]; then
  section "GRADLE WRAPPER"
  cat android/gradle/wrapper/gradle-wrapper.properties >> "$REPORT"
fi

if [ -f android/app/build.gradle ]; then
  section "ANDROID APP BUILD.GRADLE IMPORTANT LINES"
  grep -nE "namespace|applicationId|minSdk|targetSdk|compileSdk|versionCode|versionName|ndkVersion|hermes|react|kotlin|jni|externalNativeBuild|cmake|rust" android/app/build.gradle >> "$REPORT" 2>&1 || true
fi

if [ -f android/build.gradle ]; then
  section "ANDROID ROOT BUILD.GRADLE IMPORTANT LINES"
  grep -nE "com.android|kotlin|gradle|maven|repositories|classpath|plugins" android/build.gradle >> "$REPORT" 2>&1 || true
fi

if [ -f android/settings.gradle ]; then
  section "ANDROID SETTINGS.GRADLE IMPORTANT LINES"
  grep -nE "pluginManagement|dependencyResolutionManagement|includeBuild|expo|react|autolinking|include" android/settings.gradle >> "$REPORT" 2>&1 || true
fi

section "ANDROID MANIFEST PERMISSIONS"

if [ -f android/app/src/main/AndroidManifest.xml ]; then
  grep -nE "BLUETOOTH|ACCESS_FINE_LOCATION|ACCESS_COARSE_LOCATION|NEARBY_WIFI|INTERNET|ACCESS_NETWORK_STATE|FOREGROUND_SERVICE|WAKE_LOCK|POST_NOTIFICATIONS|uses-permission|service|receiver|activity" android/app/src/main/AndroidManifest.xml >> "$REPORT" 2>&1 || true
fi

grep_project "BLE WIRING SEARCH" "react-native-ble-plx\|BleManager\|BluetoothManager\|BluetoothGatt\|BluetoothLeScanner\|BluetoothLeAdvertiser\|AdvertiseSettings\|GATT\|BLE"

grep_project "NATIVE MODULE WIRING SEARCH" "ReactPackage\|NativeModule\|TurboModule\|MauriMeshBle\|MauriMeshProof\|BlePlxCompat\|MainApplication\|MainActivity"

grep_project "PROOF LOGGING SEARCH" "MauriMeshProof\|TX_BLE\|RX_BLE\|WAITING_FOR_ACK\|DELIVER\|ACK\|packetId\|MM-PROOF"

grep_project "ROUTING ENGINE SEARCH" "route\|routing\|relay\|storeForward\|store-forward\|mesh\|hop\|gateway\|supernode\|anchor"

grep_project "SELF LEARNING / HEALING SEARCH" "selfHealing\|self-healing\|learning\|resilience\|governance\|tikanga\|MauriAI\|Cleo\|Chanelle"

grep_project "API URL WIRING SEARCH" "API_URL\|BASE_URL\|EXPO_PUBLIC\|replit.app\|spock.replit.dev\|/api/activity\|fetch("

grep_project "LOGIN / KEYBOARD SEARCH" "KeyboardAvoidingView\|TextInput\|autoFocus\|secureTextEntry\|login\|Login\|signIn\|auth"

section "EXPO ROUTER / UI ROUTES"

if [ -d app ]; then
  pass "Expo Router app/ directory exists"
  find app -maxdepth 5 -type f | sort >> "$REPORT"
else
  warn "No app/ directory found"
fi

if [ -d src ]; then
  pass "src/ directory exists"
  find src -maxdepth 5 -type f | sort >> "$REPORT"
else
  warn "No src/ directory found"
fi

section "RUST / NATIVE ENGINE INSPECTION"

if find . -maxdepth 6 -name Cargo.toml | grep -q .; then
  pass "Rust Cargo.toml found"
  find . -maxdepth 6 -name Cargo.toml -print >> "$REPORT"
else
  warn "No Cargo.toml found. Rust is not currently wired as a build dependency."
fi

grep_project "RUST AND JNI WIRING SEARCH" "cargo\|rust\|jniLibs\|System.loadLibrary\|externalNativeBuild\|cxxbridge\|uniffi\|JNA\|JNI"

section "DEPENDENCY VERSION SNAPSHOT"

if command -v node >/dev/null 2>&1; then
  node -v >> "$REPORT" 2>&1 || true
fi

if command -v pnpm >/dev/null 2>&1; then
  pnpm -v >> "$REPORT" 2>&1 || true
fi

if command -v java >/dev/null 2>&1; then
  java -version >> "$REPORT" 2>&1 || true
fi

if [ -d android ]; then
  cd android
  chmod +x ./gradlew || true
  ./gradlew --version >> "$REPORT" 2>&1 || true
  cd "$ROOT"
fi

section "TYPESCRIPT / IMPORT CHECK"

if [ -f tsconfig.json ]; then
  if command -v pnpm >/dev/null 2>&1; then
    pnpm exec tsc --noEmit >> "$REPORT" 2>&1 && pass "TypeScript check passed" || warn "TypeScript check failed. See report."
  else
    warn "pnpm missing, skipped TypeScript check"
  fi
else
  warn "No tsconfig.json, skipped TypeScript check"
fi

section "EXPO DOCTOR"

if command -v npx >/dev/null 2>&1; then
  npx expo-doctor >> "$REPORT" 2>&1 && pass "expo-doctor passed" || warn "expo-doctor reported issues. See report."
else
  warn "npx missing, skipped expo-doctor"
fi

section "ANDROID COMPILE DRY CHECK"

if [ -d android ]; then
  cd android
  chmod +x ./gradlew || true

  if ./gradlew :app:assembleDebug -x lint -x lintDebug -x test -x testDebugUnitTest >> "$REPORT" 2>&1; then
    pass "Android debug compile passed"
  else
    fail "Android debug compile failed. Do not spend EAS build."
  fi

  cd "$ROOT"
else
  warn "Android folder missing. Run npx expo prebuild --platform android first."
fi

section "FINAL APK SEARCH"

APK="$(find android/app/build/outputs/apk -name '*.apk' 2>/dev/null | sort | tail -1 || true)"

if [ -n "$APK" ]; then
  pass "Local APK produced: $APK"
else
  warn "No local APK found"
fi

section "FINAL DECISION"

FAIL_COUNT="$(grep -c '❌ FAIL' "$REPORT" || true)"
WARN_COUNT="$(grep -c '⚠️ WARN' "$REPORT" || true)"

write "Fails: $FAIL_COUNT"
write "Warnings: $WARN_COUNT"

if [ "$FAIL_COUNT" -eq 0 ]; then
  write ""
  write "✅ BUILD GATE RESULT: No hard fail found."
  write "Next step: review warnings, then build locally again before EAS."
else
  write ""
  write "❌ BUILD GATE RESULT: Hard wiring failures found."
  write "Do not run EAS yet."
fi

echo ""
echo "============================================================"
echo "INSPECTION COMPLETE"
echo "Report created:"
echo "$REPORT"
echo "============================================================"
echo ""
echo "Show summary:"
echo "grep -n \"FAIL\\|WARN\\|BUILD GATE\" \"$REPORT\""
echo ""
