#!/usr/bin/env bash
set -e

echo "=================================================="
echo "MAURIMESH ROOTLAYOUT BOOT PROBE — NO EAS BUILD"
echo "=================================================="

MARKER="ROOT_LAYOUT_BOOT_PROBE_20260607_A"
BACKUP="backup-before-rootlayout-boot-probe-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP"

echo ""
echo "1. Backup layout files"

find app -name "_layout.*" -print | while read f; do
  SAFE="$(echo "$f" | tr '/ ' '__')"
  cp "$f" "$BACKUP/$SAFE"
  echo "Backed up: $f"
done

echo ""
echo "2. Remove duplicate root layout variants"

rm -f app/_layout.js app/_layout.jsx app/_layout.ts app/_layout.android.tsx app/_layout.native.tsx

echo ""
echo "3. Replace app/_layout.tsx with native-only boot probe"

cat > app/_layout.tsx <<TSX
import React from "react";
import { StyleSheet, Text, View } from "react-native";

const MARKER = "$MARKER";

export default function RootLayout() {
  return (
    <View style={styles.screen}>
      <Text style={styles.brand}>MauriMesh</Text>
      <Text style={styles.status}>APK boot probe passed</Text>
      <Text style={styles.marker}>{MARKER}</Text>
      <Text style={styles.truth}>
        Navigation, BLE, routing, and engines are temporarily isolated until APK boot is stable.
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  screen: {
    flex: 1,
    backgroundColor: "#020617",
    alignItems: "center",
    justifyContent: "center",
    padding: 24,
  },
  brand: {
    color: "#00D084",
    fontSize: 42,
    fontWeight: "900",
    marginBottom: 12,
  },
  status: {
    color: "#FFFFFF",
    fontSize: 22,
    fontWeight: "800",
    marginBottom: 12,
    textAlign: "center",
  },
  marker: {
    color: "#38BDF8",
    fontSize: 12,
    fontWeight: "700",
    marginBottom: 18,
    textAlign: "center",
  },
  truth: {
    color: "rgba(255,255,255,0.72)",
    fontSize: 14,
    lineHeight: 21,
    textAlign: "center",
  },
});
TSX

echo ""
echo "4. Show active root layout"

cat app/_layout.tsx

echo ""
echo "5. Confirm there are no expo-router imports in root layout"

if grep -R "expo-router\|Stack\|Slot\|Redirect\|SplashScreen\|useFonts\|StatusBar\|router\." app/_layout.* 2>/dev/null; then
  echo "ERROR: risky root layout import still present."
  exit 1
else
  echo "PASS: root layout has no expo-router/startup side effects."
fi

echo ""
echo "6. TypeScript check"

npx tsc --noEmit

echo ""
echo "7. Clean export"

rm -rf dist .expo
npx expo export --platform android --clear

echo ""
echo "8. Verify exported bundle contains boot marker"

if grep -R "$MARKER" dist .expo 2>/dev/null; then
  echo "PASS: exported bundle contains $MARKER"
else
  echo "WARNING: marker not found by grep. Hermes/minification may hide it."
  echo "Still continue only if TypeScript and export passed."
fi

echo ""
echo "9. Verify Android identity"

grep -R "namespace\|applicationId" android/app/build.gradle 2>/dev/null || true
grep -R "package com.maurimesh.messenger" android/app/src/main/java 2>/dev/null || true
npx expo config --type public | grep -E "name:|slug:|scheme:|package:|bundleIdentifier:" || true

echo ""
echo "=================================================="
echo "BOOT PROBE READY — NO EAS BUILD USED"
echo "Backup: $BACKUP"
echo "Marker: $MARKER"
echo "=================================================="
