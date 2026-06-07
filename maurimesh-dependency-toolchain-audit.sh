#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH DEPENDENCY + JAVA + GRADLE + RUST AUDIT"
echo "Protect EAS quota before cloud build"
echo "============================================================"
echo ""

ROOT="$(pwd)"
REPORT="$ROOT/maurimesh-toolchain-audit-report.txt"

: > "$REPORT"

log() {
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
    echo "------------------------------------------------------------"
    echo "$1"
    echo "------------------------------------------------------------"
  } >> "$REPORT"
}

run_check() {
  local name="$1"
  shift

  section "$name"

  if "$@" >> "$REPORT" 2>&1; then
    echo "PASS: $name"
    echo "PASS: $name" >> "$REPORT"
  else
    echo "FAIL: $name"
    echo "FAIL: $name" >> "$REPORT"
  fi
}

section "PROJECT ROOT CHECK"

if [ ! -f package.json ]; then
  log "FAIL: package.json not found. Run this from your MauriMesh project root."
  exit 1
fi

log "PASS: package.json found"
log "ROOT: $ROOT"

section "NODE + PNPM"

node -v 2>&1 | tee -a "$REPORT" || true
npm -v 2>&1 | tee -a "$REPORT" || true

corepack enable >> "$REPORT" 2>&1 || true
corepack prepare pnpm@10.11.1 --activate >> "$REPORT" 2>&1 || true

pnpm -v 2>&1 | tee -a "$REPORT" || true

section "PACKAGE MANAGER LOCKFILE CHECK"

if [ -f pnpm-lock.yaml ]; then
  log "PASS: pnpm-lock.yaml exists"
else
  log "WARN: pnpm-lock.yaml missing"
fi

if grep -q '"packageManager"' package.json; then
  log "packageManager:"
  grep '"packageManager"' package.json | tee -a "$REPORT"
else
  log "WARN: packageManager not pinned in package.json"
fi

section "PACKAGE OVERRIDES CHECK"

node <<'NODE' | tee -a "$REPORT"
const fs = require("fs");
const pkg = JSON.parse(fs.readFileSync("package.json", "utf8"));

console.log("overrides:", JSON.stringify(pkg.overrides || {}, null, 2));
console.log("pnpm.overrides:", JSON.stringify(pkg.pnpm?.overrides || {}, null, 2));
console.log("resolutions:", JSON.stringify(pkg.resolutions || {}, null, 2));
NODE

section "REPAIR PNPM INSTALL"

pnpm install --no-frozen-lockfile 2>&1 | tee -a "$REPORT"

section "VERIFY FROZEN PNPM INSTALL"

if pnpm install --frozen-lockfile 2>&1 | tee -a "$REPORT"; then
  log "PASS: frozen lockfile install passes"
else
  log "FAIL: frozen lockfile install failed"
  log "Fix package.json / pnpm-lock.yaml before EAS."
  exit 1
fi

section "JAVA CHECK"

java -version 2>&1 | tee -a "$REPORT" || true
javac -version 2>&1 | tee -a "$REPORT" || true

JAVA_MAJOR="$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | awk -F. '{print $1}')"

if [ "$JAVA_MAJOR" = "17" ]; then
  log "PASS: Java 17 detected"
else
  log "WARN: Java 17 is recommended for React Native / Android Gradle builds"
fi

section "ANDROID SDK CHECK"

echo "ANDROID_HOME=${ANDROID_HOME:-missing}" | tee -a "$REPORT"
echo "ANDROID_SDK_ROOT=${ANDROID_SDK_ROOT:-missing}" | tee -a "$REPORT"

if command -v sdkmanager >/dev/null 2>&1; then
  sdkmanager --list_installed 2>/dev/null | grep -E "platforms;android|build-tools|ndk|cmake" | tee -a "$REPORT" || true
else
  log "WARN: sdkmanager not found in PATH"
fi

section "EXPO / REACT NATIVE CHECK"

npx expo --version 2>&1 | tee -a "$REPORT" || true
npx expo-doctor 2>&1 | tee -a "$REPORT" || true

section "ANDROID GRADLE FILE CHECK"

if [ -d android ]; then
  log "PASS: android folder exists"

  if [ -f android/gradle/wrapper/gradle-wrapper.properties ]; then
    log "Gradle wrapper:"
    cat android/gradle/wrapper/gradle-wrapper.properties | tee -a "$REPORT"
  fi

  if [ -f android/build.gradle ]; then
    log "android/build.gradle detected"
    grep -nE "com.android.application|com.android.tools.build|kotlin|gradle" android/build.gradle | tee -a "$REPORT" || true
  fi

  if [ -f android/settings.gradle ]; then
    log "android/settings.gradle detected"
    grep -nE "pluginManagement|com.facebook.react|expo|includeBuild" android/settings.gradle | tee -a "$REPORT" || true
  fi

  if [ -f android/app/build.gradle ]; then
    log "android/app/build.gradle detected"
    grep -nE "compileSdk|targetSdk|minSdk|namespace|applicationId|ndkVersion|kotlin" android/app/build.gradle | tee -a "$REPORT" || true
  fi
else
  log "WARN: android folder missing. Running Expo prebuild android."

  npx expo prebuild --platform android --clean 2>&1 | tee -a "$REPORT"
fi

section "GRADLE CHECK"

if [ -d android ]; then
  cd android
  chmod +x ./gradlew || true

  ./gradlew --version 2>&1 | tee -a "$REPORT"

  section "ANDROID DEPENDENCY TREE SNAPSHOT"
  ./gradlew :app:dependencies --configuration debugRuntimeClasspath 2>&1 | tee -a "$REPORT" || true

  section "ANDROID COMPILE TEST"
  if ./gradlew :app:assembleDebug -x lint -x lintDebug -x test -x testDebugUnitTest 2>&1 | tee -a "$REPORT"; then
    log "PASS: Android debug build passed"
  else
    log "FAIL: Android debug build failed"
    log "Do not spend EAS build yet."
    exit 1
  fi

  cd "$ROOT"
fi

section "RUST CHECK"

if command -v rustc >/dev/null 2>&1; then
  rustc --version 2>&1 | tee -a "$REPORT"
else
  log "WARN: rustc not installed"
fi

if command -v cargo >/dev/null 2>&1; then
  cargo --version 2>&1 | tee -a "$REPORT"
else
  log "WARN: cargo not installed"
fi

if [ -f Cargo.toml ]; then
  log "Cargo.toml found at project root"

  if command -v cargo
