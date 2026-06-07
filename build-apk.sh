#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MOBILE_DIR="$SCRIPT_DIR/artifacts/messenger-mobile"

echo ""
echo "=== MauriMesh APK Build ==="
echo "Building from: $MOBILE_DIR"
echo ""

if [ -z "$EXPO_TOKEN" ]; then
  echo "ERROR: EXPO_TOKEN is not set. Add it to Replit Secrets first."
  exit 1
fi

which eas > /dev/null 2>&1 || npm install -g eas-cli

cd "$MOBILE_DIR"
echo "Logged in as: $(EXPO_TOKEN=$EXPO_TOKEN eas whoami 2>&1 | head -1)"
echo ""
echo "Submitting preview APK build..."
echo ""
EXPO_TOKEN=$EXPO_TOKEN eas build -p android --profile preview --non-interactive
