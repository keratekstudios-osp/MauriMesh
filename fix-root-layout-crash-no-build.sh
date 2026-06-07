#!/usr/bin/env bash
set -e

echo "=================================================="
echo "MAURIMESH ROOT LAYOUT CRASH FIX — NO EAS BUILD"
echo "=================================================="

BACKUP="backup-before-root-layout-fix-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP"

echo ""
echo "1. Backup current root layout files"

for f in app/_layout.tsx app/_layout.jsx app/_layout.ts app/_layout.js; do
  if [ -f "$f" ]; then
    cp "$f" "$BACKUP/$(basename "$f")"
    echo "Backed up: $f"
  fi
done

echo ""
echo "2. Show current RootLayout references"

grep -R "RootLayout\|SplashScreen\|useFonts\|hideAsync\|preventAutoHide\|setOptions\|router\." app/_layout.* 2>/dev/null || true

echo ""
echo "3. Replace app/_layout.tsx with safe production layout"

cat > app/_layout.tsx <<'TSX'
import React from "react";
import { Stack } from "expo-router";
import { StatusBar } from "expo-status-bar";

/**
 * MauriMesh safe root layout.
 *
 * Purpose:
 * - Keep APK boot stable.
 * - Avoid startup side effects that can crash release builds.
 * - Do not call SplashScreen, useFonts, router methods, or undefined runtime helpers here.
 *
 * BLE, routing, proof ledger, and MauriMesh engine screens remain preserved in their own routes.
 */
export default function RootLayout() {
  return (
    <>
      <Stack
        screenOptions={{
          headerShown: false,
          animation: "fade",
          contentStyle: {
            backgroundColor: "#020617",
          },
        }}
      />
      <StatusBar style="light" />
    </>
  );
}
TSX

echo ""
echo "4. Verify new root layout"

cat app/_layout.tsx

echo ""
echo "5. TypeScript check"

npx tsc --noEmit

echo ""
echo "6. Expo export check"

npx expo export --platform android --clear

echo ""
echo "7. Verify Android package identity stayed correct"

grep -R "namespace\|applicationId" android/app/build.gradle 2>/dev/null || true
grep -R "package com.maurimesh.messenger" android/app/src/main/java 2>/dev/null || true
npx expo config --type public | grep -E "name:|slug:|scheme:|package:|bundleIdentifier:" || true

echo ""
echo "=================================================="
echo "ROOT LAYOUT FIX COMPLETE — NO EAS BUILD USED"
echo "Backup: $BACKUP"
echo "=================================================="
