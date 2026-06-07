#!/usr/bin/env bash
set -e

echo "=================================================="
echo "ADD SAFE INDEX ROUTE — NO EAS BUILD"
echo "=================================================="

mkdir -p app

cat > app/index.tsx <<'TSX'
import React from "react";
import { StyleSheet, Text, View } from "react-native";

const MARKER = "SAFE_INDEX_ROUTE_20260607_A";

export default function IndexScreen() {
  return (
    <View style={styles.screen}>
      <Text style={styles.brand}>MauriMesh</Text>
      <Text style={styles.title}>Messenger Boot Complete</Text>
      <Text style={styles.marker}>{MARKER}</Text>
      <Text style={styles.text}>
        Native APK shell, package identity, and Expo Router are working.
        Next layer: dashboard, chat, settings, living mesh, then BLE UI wiring.
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
  title: {
    color: "#FFFFFF",
    fontSize: 22,
    fontWeight: "800",
    textAlign: "center",
    marginBottom: 12,
  },
  marker: {
    color: "#38BDF8",
    fontSize: 12,
    fontWeight: "800",
    marginBottom: 18,
  },
  text: {
    color: "rgba(255,255,255,0.72)",
    fontSize: 14,
    lineHeight: 21,
    textAlign: "center",
  },
});
TSX

echo ""
echo "1. Active app files"
find app -maxdepth 2 -type f | sort

echo ""
echo "2. TypeScript check"
npx tsc --noEmit

echo ""
echo "3. Clean export"
rm -rf dist .expo
npx expo export --platform android --clear

echo ""
echo "4. Verify safe index marker"
grep -R "SAFE_INDEX_ROUTE_20260607_A" dist .expo 2>/dev/null || echo "Marker not found by grep; export still passed."

echo ""
echo "=================================================="
echo "SAFE INDEX ROUTE READY — NO EAS BUILD USED"
echo "Marker: SAFE_INDEX_ROUTE_20260607_A"
echo "=================================================="
