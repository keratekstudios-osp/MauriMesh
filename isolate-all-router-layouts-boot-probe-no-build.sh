#!/usr/bin/env bash
set -e

echo "=================================================="
echo "ISOLATE ALL ROUTER LAYOUTS — BOOT PROBE"
echo "NO EAS BUILD"
echo "=================================================="

BACKUP="backup-before-isolating-router-layouts-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP"

echo ""
echo "1. Backup app router files"
cp -R app "$BACKUP/app"

echo ""
echo "2. Move route groups and nested layouts out of app/"

mkdir -p "$BACKUP/moved-router-groups"

if [ -d "app/(tabs)" ]; then
  mv "app/(tabs)" "$BACKUP/moved-router-groups/tabs"
  echo "Moved app/(tabs) out of Expo Router."
fi

find app -mindepth 2 -name "_layout.*" -print | while read f; do
  SAFE="$(echo "$f" | tr '/() ' '____')"
  mv "$f" "$BACKUP/moved-router-groups/$SAFE"
  echo "Moved nested layout out of app router: $f"
done

echo ""
echo "3. Remove backup/old layout files from app root"

find app -maxdepth 1 -type f \( \
  -name "_layout.backup.*" -o \
  -name "_layout.bak.*" -o \
  -name "_layout.old.*" -o \
  -name "*.backup.tsx" -o \
  -name "*.bak.tsx" -o \
  -name "*.old.tsx" \
\) -print | while read f; do
  SAFE="$(echo "$f" | tr '/ ' '__')"
  mv "$f" "$BACKUP/$SAFE"
  echo "Moved root backup layout: $f"
done

echo ""
echo "4. Force only one safe root layout"

rm -f app/_layout.js app/_layout.jsx app/_layout.ts app/_layout.android.tsx app/_layout.native.tsx

cat > app/_layout.tsx <<'TSX'
import React from "react";
import { StyleSheet, Text, View } from "react-native";

const MARKER = "ROOT_LAYOUT_BOOT_PROBE_20260607_B";

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
echo "5. Show remaining app files"
find app -maxdepth 3 -type f | sort

echo ""
echo "6. Confirm no Expo Router imports remain anywhere in app/"
if grep -R "expo-router\|Stack\|Tabs\|Slot\|Redirect\|SplashScreen\|useFonts\|StatusBar\|router\." app 2>/dev/null; then
  echo "ERROR: risky router/startup import still present above."
  exit 1
else
  echo "PASS: app folder is isolated from router startup imports."
fi

echo ""
echo "7. TypeScript check"
npx tsc --noEmit

echo ""
echo "8. Clean Android export check"
rm -rf dist .expo
npx expo export --platform android --clear

echo ""
echo "9. Verify boot marker in export"
grep -R "ROOT_LAYOUT_BOOT_PROBE_20260607_B" dist .expo 2>/dev/null || echo "Marker not found by grep; export still passed."

echo ""
echo "=================================================="
echo "ALL ROUTER LAYOUTS ISOLATED — NO EAS BUILD USED"
echo "Backup: $BACKUP"
echo "Marker: ROOT_LAYOUT_BOOT_PROBE_20260607_B"
echo "=================================================="
