#!/usr/bin/env bash
# MauriMesh APK Build Script
# Builds a standalone Android APK via EAS Build (cloud) or local Expo.
# Usage: ./scripts/build-apk.sh [--local] [--profile preview|production]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MOBILE_DIR="$WORKSPACE_ROOT/artifacts/messenger-mobile"
PROFILE="${2:-preview}"

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║        MauriMesh APK Build Pipeline              ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""
echo "  Workspace : $WORKSPACE_ROOT"
echo "  Mobile dir: $MOBILE_DIR"
echo "  Profile   : $PROFILE"
echo ""

# ── Pre-flight checks ─────────────────────────────────────────────────────────

if ! command -v node &>/dev/null; then
  echo "ERROR: node not found. Install Node.js 18+ and retry."
  exit 1
fi

if ! command -v pnpm &>/dev/null; then
  echo "ERROR: pnpm not found. Install with: npm install -g pnpm"
  exit 1
fi

if ! command -v eas &>/dev/null; then
  echo "INFO: EAS CLI not found globally — checking local install..."
  EAS_BIN="$WORKSPACE_ROOT/node_modules/.bin/eas"
  if [[ ! -f "$EAS_BIN" ]]; then
    echo "ERROR: EAS CLI not found. Install with: npm install -g eas-cli"
    echo "       Or run: pnpm add -g eas-cli"
    exit 1
  fi
  EAS_CMD="$EAS_BIN"
else
  EAS_CMD="eas"
fi

echo "  EAS CLI   : $(${EAS_CMD} --version 2>/dev/null || echo 'unknown')"
echo ""

# ── Dependency install ────────────────────────────────────────────────────────

echo "[1/4] Installing workspace dependencies..."
cd "$WORKSPACE_ROOT"
pnpm install --frozen-lockfile 2>&1 | tail -5

# ── SDK / package compatibility check ────────────────────────────────────────

echo ""
echo "[2/4] Checking Expo SDK compatibility..."
cd "$MOBILE_DIR"
EXPO_SDK=$(node -e "const p=require('./package.json'); console.log(p.dependencies?.expo || p.devDependencies?.expo || 'unknown')")
echo "  Expo SDK version: $EXPO_SDK"

# Validate expo-secure-store is SDK-compatible
SECURE_STORE=$(node -e "const p=require('./package.json'); console.log(p.dependencies?.['expo-secure-store'] || p.devDependencies?.['expo-secure-store'] || 'not installed')")
echo "  expo-secure-store: $SECURE_STORE"

# ── Build ─────────────────────────────────────────────────────────────────────

if [[ "${1:-}" == "--local" ]]; then
  echo ""
  echo "[3/4] Running LOCAL build (requires Android SDK & NDK)..."
  echo "  ANDROID_HOME: ${ANDROID_HOME:-not set}"
  if [[ -z "${ANDROID_HOME:-}" ]]; then
    echo "WARNING: ANDROID_HOME is not set. Local build may fail."
    echo "         Set it to your Android SDK path and retry."
  fi
  cd "$MOBILE_DIR"
  "$EAS_CMD" build --platform android --profile "$PROFILE" --local \
    --output "$WORKSPACE_ROOT/build/maurimesh-$(date +%Y%m%d-%H%M).apk"
else
  echo ""
  echo "[3/4] Running CLOUD build (EAS Build)..."
  echo "  Profile: $PROFILE"
  echo "  This will upload the project to EAS and queue a build."
  echo ""
  if [[ -z "${EXPO_TOKEN:-}" ]]; then
    echo "WARNING: EXPO_TOKEN env var not set. You may be prompted to log in."
  fi
  cd "$MOBILE_DIR"
  "$EAS_CMD" build --platform android --profile "$PROFILE" --non-interactive
fi

# ── Post-build ────────────────────────────────────────────────────────────────

echo ""
echo "[4/4] Build complete."
echo ""
echo "  Next steps:"
echo "  1. Install the APK on a physical Android device"
echo "  2. Open MauriMesh and navigate to Android Readiness"
echo "  3. Run the two-phone BLE proof session"
echo "  4. Verify all gates pass in Production Readiness screen"
echo ""
echo "  APK profile: $PROFILE"
echo "  Docs:        See MauriMesh Developer Manual in-app"
echo ""
