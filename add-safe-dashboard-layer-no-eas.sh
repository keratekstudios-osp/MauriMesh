#!/usr/bin/env bash
set -e

echo "=================================================="
echo "ADD SAFE DASHBOARD LAYER — NO EAS BUILD"
echo "=================================================="

BACKUP="$HOME/maurimesh-router-backups/backup-before-safe-dashboard-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP"
cp -R app "$BACKUP/app-current"

mkdir -p app

cat > app/_layout.tsx <<'TSX'
import React from "react";
import { Stack } from "expo-router";

export default function RootLayout() {
  return (
    <Stack
      screenOptions={{
        headerShown: false,
        contentStyle: { backgroundColor: "#020617" },
      }}
    />
  );
}
TSX

cat > app/index.tsx <<'TSX'
import React from "react";
import { Pressable, StyleSheet, Text, View } from "react-native";
import { useRouter } from "expo-router";

const MARKER = "SAFE_HOME_DASHBOARD_20260607_A";

export default function IndexScreen() {
  const router = useRouter();

  return (
    <View style={styles.screen}>
      <Text style={styles.brand}>MauriMesh</Text>
      <Text style={styles.title}>Messenger Boot Complete</Text>
      <Text style={styles.marker}>{MARKER}</Text>
      <Text style={styles.text}>
        Native APK shell, package identity, and safe Expo Router navigation are working.
      </Text>

      <Pressable style={styles.button} onPress={() => router.push("/dashboard")}>
        <Text style={styles.buttonText}>Open Dashboard</Text>
      </Pressable>
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
    marginBottom: 24,
  },
  button: {
    backgroundColor: "#00D084",
    borderRadius: 18,
    paddingVertical: 16,
    paddingHorizontal: 26,
  },
  buttonText: {
    color: "#020617",
    fontSize: 16,
    fontWeight: "900",
  },
});
TSX

cat > app/dashboard.tsx <<'TSX'
import React from "react";
import { Pressable, ScrollView, StyleSheet, Text, View } from "react-native";
import { useRouter } from "expo-router";

const MARKER = "SAFE_DASHBOARD_20260607_A";

export default function DashboardScreen() {
  const router = useRouter();

  return (
    <ScrollView style={styles.screen} contentContainerStyle={styles.content}>
      <Text style={styles.brand}>MauriMesh</Text>
      <Text style={styles.title}>Dashboard</Text>
      <Text style={styles.marker}>{MARKER}</Text>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>System Status</Text>
        <Text style={styles.cardText}>APK shell: PASS</Text>
        <Text style={styles.cardText}>Package: com.maurimesh.messenger</Text>
        <Text style={styles.cardText}>Router: safe Stack only</Text>
        <Text style={styles.cardText}>BLE/runtime UI: still isolated</Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Next Layers</Text>
        <Text style={styles.cardText}>1. Login</Text>
        <Text style={styles.cardText}>2. Settings</Text>
        <Text style={styles.cardText}>3. Chat</Text>
        <Text style={styles.cardText}>4. Living Mesh</Text>
        <Text style={styles.cardText}>5. BLE proof UI wiring</Text>
      </View>

      <Pressable style={styles.button} onPress={() => router.back()}>
        <Text style={styles.buttonText}>Back Home</Text>
      </Pressable>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  screen: {
    flex: 1,
    backgroundColor: "#020617",
  },
  content: {
    padding: 24,
    paddingTop: 72,
  },
  brand: {
    color: "#00D084",
    fontSize: 38,
    fontWeight: "900",
    marginBottom: 8,
  },
  title: {
    color: "#FFFFFF",
    fontSize: 28,
    fontWeight: "900",
    marginBottom: 8,
  },
  marker: {
    color: "#38BDF8",
    fontSize: 12,
    fontWeight: "800",
    marginBottom: 20,
  },
  card: {
    backgroundColor: "rgba(255,255,255,0.06)",
    borderColor: "rgba(0,208,132,0.28)",
    borderWidth: 1,
    borderRadius: 22,
    padding: 18,
    marginBottom: 16,
  },
  cardTitle: {
    color: "#FFFFFF",
    fontSize: 18,
    fontWeight: "900",
    marginBottom: 10,
  },
  cardText: {
    color: "rgba(255,255,255,0.72)",
    fontSize: 14,
    lineHeight: 22,
  },
  button: {
    backgroundColor: "#00D084",
    borderRadius: 18,
    paddingVertical: 16,
    alignItems: "center",
    marginTop: 8,
  },
  buttonText: {
    color: "#020617",
    fontSize: 16,
    fontWeight: "900",
  },
});
TSX

echo ""
echo "1. Active app files"
find app -maxdepth 2 -type f | sort

echo ""
echo "2. Crash-risk scan"
grep -R "unstable-native-tabs\|NativeTabs\|SplashScreen\|preventAutoHide\|hideAsync\|useFonts\|_layout.backup" app 2>/dev/null && exit 1 || echo "PASS: no risky startup patterns"

echo ""
echo "3. TypeScript"
npx tsc --noEmit

echo ""
echo "4. Clean export"
rm -rf dist .expo
npx expo export --platform android --clear

echo ""
echo "5. Marker check"
grep -R "SAFE_HOME_DASHBOARD_20260607_A\|SAFE_DASHBOARD_20260607_A" app dist .expo 2>/dev/null || true

echo ""
echo "=================================================="
echo "SAFE DASHBOARD LAYER READY — NO EAS BUILD USED"
echo "Backup: $BACKUP"
echo "=================================================="
