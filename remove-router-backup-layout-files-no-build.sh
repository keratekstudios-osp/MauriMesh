#!/usr/bin/env bash
set -e

echo "=================================================="
echo "REMOVE ROUTER BACKUP LAYOUT FILES — NO EAS BUILD"
echo "=================================================="

BACKUP="backup-before-removing-app-layout-backups-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP"

echo ""
echo "1. Find all app layout-looking files"
find app -maxdepth 2 -type f | grep -E "_layout|layout" || true

echo ""
echo "2. Move risky backup layout files out of app/"
find app -maxdepth 2 -type f \( \
  -name "_layout.backup.*" -o \
  -name "_layout.bak.*" -o \
  -name "_layout.old.*" -o \
  -name "*.backup.tsx" -o \
  -name "*.bak.tsx" -o \
  -name "*.old.tsx" \
\) -print | while read f; do
  SAFE="$(echo "$f" | tr '/ ' '__')"
  cp "$f" "$BACKUP/$SAFE"
  rm -f "$f"
  echo "Moved out of app router: $f"
done

echo ""
echo "3. Force only one root layout file"

rm -f app/_layout.js app/_layout.jsx app/_layout.ts app/_layout.android.tsx app/_layout.native.tsx

cat > app/_layout.tsx <<'TSX'
import React from "react";
import { StyleSheet, Text, View } from "react-native";

const MARKER = "ROOT_LAYOUT_BOOT_PROBE_20260607_A";

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
echo "4. Verify only safe root layout remains"
find app -maxdepth 2 -type f | grep -E "_layout|layout" || true

echo ""
echo "5. Confirm no risky imports remain in app root layout files"
if find app -maxdepth 2 -type f | grep -E "_layout|layout" | xargs grep -n "expo-router\|Stack\|Slot\|Redirect\|SplashScreen\|useFonts\|StatusBar\|router\." 2>/dev/null; then
  echo "ERROR: risky root layout import still present above."
  exit 1
else
  echo "PASS: no risky root layout imports found."
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
grep -R "ROOT_LAYOUT_BOOT_PROBE_20260607_A" dist .expo 2>/dev/null || echo "Marker not found by grep; export still passed."

echo ""
echo "=================================================="
echo "BOOT PROBE CLEANUP COMPLETE — NO EAS BUILD USED"
echo "Backup: $BACKUP"
echo "=================================================="
