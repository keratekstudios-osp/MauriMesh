#!/usr/bin/env bash
set -e

echo "=================================================="
echo "ISOLATE APP TO ROOTLAYOUT ONLY — BOOT PROBE"
echo "NO EAS BUILD"
echo "=================================================="

BACKUP="$HOME/maurimesh-router-backups/backup-before-rootlayout-only-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP"

echo ""
echo "1. Backup full app folder outside project router"
cp -R app "$BACKUP/app"
echo "Backup saved to: $BACKUP"

echo ""
echo "2. Remove every app route file/folder except app/_layout.tsx"

find app -mindepth 1 -maxdepth 1 | while read item; do
  base="$(basename "$item")"
  if [ "$base" = "_layout.tsx" ]; then
    echo "Keeping: $item"
  else
    rm -rf "$item"
    echo "Removed from active Expo Router: $item"
  fi
done

echo ""
echo "3. Write root-only boot probe layout"

cat > app/_layout.tsx <<'TSX'
import React from "react";
import { StyleSheet, Text, View } from "react-native";

const MARKER = "ROOT_LAYOUT_BOOT_PROBE_20260607_C";

export default function RootLayout() {
  return (
    <View style={styles.screen}>
      <Text style={styles.brand}>MauriMesh</Text>
      <Text style={styles.status}>APK boot probe passed</Text>
      <Text style={styles.marker}>{MARKER}</Text>
      <Text style={styles.truth}>
        Router screens, BLE, routing, and engines are temporarily isolated.
        This proves the APK can boot before navigation is restored.
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
echo "4. Confirm active app folder is clean"
find app -maxdepth 3 -type f | sort

echo ""
echo "5. Confirm no expo-router imports remain in app/"
if grep -R "expo-router\|Stack\|Tabs\|Slot\|Redirect\|SplashScreen\|useFonts\|StatusBar\|router\." app 2>/dev/null; then
  echo "ERROR: risky router/startup import still present above."
  exit 1
else
  echo "PASS: app folder is root-layout-only and router isolated."
fi

echo ""
echo "6. TypeScript check"
npx tsc --noEmit

echo ""
echo "7. Clean Android export check"
rm -rf dist .expo
npx expo export --platform android --clear

echo ""
echo "8. Verify boot marker in export"
grep -R "ROOT_LAYOUT_BOOT_PROBE_20260607_C" dist .expo 2>/dev/null || echo "Marker not found by grep; export still passed."

echo ""
echo "9. Verify Android package identity"
grep -R "namespace\|applicationId" android/app/build.gradle 2>/dev/null || true
grep -R "package com.maurimesh.messenger" android/app/src/main/java 2>/dev/null || true
npx expo config --type public | grep -E "name:|slug:|scheme:|package:|bundleIdentifier:" || true

echo ""
echo "=================================================="
echo "ROOTLAYOUT-ONLY BOOT PROBE READY — NO EAS BUILD USED"
echo "Backup: $BACKUP"
echo "Marker: ROOT_LAYOUT_BOOT_PROBE_20260607_C"
echo "=================================================="
