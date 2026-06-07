#!/usr/bin/env bash
set -e

echo "=================================================="
echo "WIRE SAFE DASHBOARD BUTTONS — NO EAS BUILD"
echo "=================================================="

BACKUP="$HOME/maurimesh-router-backups/backup-before-dashboard-buttons-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP"
cp -R app "$BACKUP/app-current"

cat > app/dashboard.tsx <<'TSX'
import React from "react";
import { Pressable, ScrollView, StyleSheet, Text, View } from "react-native";
import { useRouter } from "expo-router";

const MARKER = "SAFE_DASHBOARD_BUTTONS_20260607_A";

const routes = [
  { title: "Settings", path: "/settings" },
  { title: "Chat", path: "/chat" },
  { title: "Living Mesh", path: "/living-mesh" },
  { title: "Mesh Status", path: "/mesh-status" },
  { title: "Add Friend", path: "/add-friend" },
  { title: "Pixel Calling", path: "/pixel-calling" },
];

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

      <View style={styles.grid}>
        {routes.map((item) => (
          <Pressable
            key={item.path}
            style={styles.button}
            onPress={() => router.push(item.path as never)}
          >
            <Text style={styles.buttonText}>{item.title}</Text>
          </Pressable>
        ))}
      </View>

      <Pressable style={styles.backButton} onPress={() => router.back()}>
        <Text style={styles.backButtonText}>Back Home</Text>
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
  grid: {
    gap: 12,
    marginTop: 4,
  },
  button: {
    backgroundColor: "rgba(0,208,132,0.16)",
    borderColor: "rgba(0,208,132,0.42)",
    borderWidth: 1,
    borderRadius: 18,
    paddingVertical: 16,
    paddingHorizontal: 18,
  },
  buttonText: {
    color: "#FFFFFF",
    fontSize: 16,
    fontWeight: "900",
  },
  backButton: {
    backgroundColor: "#00D084",
    borderRadius: 18,
    paddingVertical: 16,
    alignItems: "center",
    marginTop: 18,
  },
  backButtonText: {
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
echo "2. Marker check"
grep -R "SAFE_DASHBOARD_BUTTONS_20260607_A" app 2>/dev/null

echo ""
echo "3. Crash-risk scan"
grep -R "unstable-native-tabs\|NativeTabs\|SplashScreen\|preventAutoHide\|hideAsync\|useFonts\|_layout.backup" app 2>/dev/null && exit 1 || echo "PASS: no risky startup patterns"

echo ""
echo "4. TypeScript"
npx tsc --noEmit

echo ""
echo "5. Clean export"
rm -rf dist .expo
npx expo export --platform android --clear

echo ""
echo "=================================================="
echo "SAFE DASHBOARD BUTTONS READY — NO EAS BUILD USED"
echo "Backup: $BACKUP"
echo "=================================================="
