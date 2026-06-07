#!/usr/bin/env bash
set -e

echo "=================================================="
echo "MAURIMESH ABSOLUTE MINIMAL ROOT LAYOUT FIX"
echo "NO EAS BUILD"
echo "=================================================="

BACKUP="backup-before-absolute-root-layout-fix-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP"

echo ""
echo "1. Find all layout files"
find app -name "_layout.*" -print || true

echo ""
echo "2. Backup all layout files"
find app -name "_layout.*" -print | while read f; do
  SAFE="$(echo "$f" | tr '/ ' '__')"
  cp "$f" "$BACKUP/$SAFE"
  echo "Backed up: $f"
done

echo ""
echo "3. Remove duplicate root layout files except app/_layout.tsx"

for f in app/_layout.js app/_layout.jsx app/_layout.ts app/_layout.android.tsx app/_layout.native.tsx; do
  if [ -f "$f" ]; then
    rm -f "$f"
    echo "Removed duplicate root layout: $f"
  fi
done

echo ""
echo "4. Replace root layout with absolute minimal Slot layout"

cat > app/_layout.tsx <<'TSX'
import React from "react";
import { Slot } from "expo-router";

/**
 * Absolute minimal MauriMesh root layout.
 *
 * No Stack.
 * No StatusBar.
 * No SplashScreen.
 * No fonts.
 * No effects.
 * No router calls.
 * No runtime engine startup.
 *
 * This isolates the APK crash so the app can boot first.
 */
export default function RootLayout() {
  return <Slot />;
}
TSX

echo ""
echo "5. Show final root layout"
cat app/_layout.tsx

echo ""
echo "6. Search for risky root boot calls"
grep -R "SplashScreen\|preventAutoHide\|hideAsync\|useFonts\|router\.\|setOptions\|StatusBar\|Stack" app/_layout.* app 2>/dev/null || true

echo ""
echo "7. TypeScript check"
npx tsc --noEmit

echo ""
echo "8. Android export check"
rm -rf dist .expo
npx expo export --platform android --clear

echo ""
echo "9. Verify package identity"
grep -R "namespace\|applicationId" android/app/build.gradle 2>/dev/null || true
grep -R "package com.maur
