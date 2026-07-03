#!/usr/bin/env bash
set -e

echo "=================================================="
echo "ADD SAFE BLE PROOF UI LAYER — NO EAS BUILD"
echo "=================================================="

BACKUP="$HOME/maurimesh-router-backups/backup-before-safe-ble-proof-ui-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP"
cp -R app "$BACKUP/app-current" 2>/dev/null || true
cp -R src "$BACKUP/src-current" 2>/dev/null || true

mkdir -p app src/lib

echo ""
echo "1. Create safe proof simulation data"

cat > src/lib/proofSimulation.ts <<'TS'
export type ProofEvent = {
  id: string;
  stage: string;
  status: "PASS" | "WAITING" | "ISOLATED";
  detail: string;
};

export const proofEvents: ProofEvent[] = [
  {
    id: "apk-shell",
    stage: "APK Launch",
    status: "PASS",
    detail: "com.maurimesh.messenger opens without RootLayout crash.",
  },
  {
    id: "router-stack",
    stage: "Router",
    status: "PASS",
    detail: "Safe Expo Router Stack opens dashboard and UI screens.",
  },
  {
    id: "ble-runtime",
    stage: "BLE Runtime",
    status: "ISOLATED",
    detail: "Native BLE send/receive proof is protected and not active in this UI shell.",
  },
  {
    id: "two-phone-proof",
    stage: "Two-Phone Proof",
    status: "WAITING",
    detail: "Requires physical device test after native proof UI is restored.",
  },
];
TS

echo ""
echo "2. Create BLE Proof screen"

cat > app/ble-proof.tsx <<'TSX'
import React from "react";
import { ScrollView, StyleSheet, Text, View } from "react-native";
import { proofEvents } from "../src/lib/proofSimulation";

const MARKER = "SAFE_BLE_PROOF_UI_20260607_A";

export default function BleProofScreen() {
  return (
    <ScrollView style={styles.screen} contentContainerStyle={styles.content}>
      <Text style={styles.brand}>MauriMesh</Text>
      <Text style={styles.title}>BLE Proof UI</Text>
      <Text style={styles.marker}>{MARKER}</Text>

      <View style={styles.truthCard}>
        <Text style={styles.cardTitle}>Truth Boundary</Text>
        <Text style={styles.cardText}>
          This is a safe APK UI layer. It does not claim live BLE. Real BLE proof requires
          physical phones, permissions, native logs, TX/RX/ACK events, and two-phone validation.
        </Text>
      </View>

      {proofEvents.map((event) => (
        <View key={event.id} style={styles.card}>
          <Text style={styles.rowTitle}>{event.stage}</Text>
          <Text style={styles.status}>{event.status}</Text>
          <Text style={styles.cardText}>{event.detail}</Text>
        </View>
      ))}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: "#020617" },
  content: { padding: 24, paddingTop: 72 },
  brand: { color: "#00D084", fontSize: 38, fontWeight: "900", marginBottom: 8 },
  title: { color: "#FFFFFF", fontSize: 28, fontWeight: "900", marginBottom: 8 },
  marker: { color: "#38BDF8", fontSize: 12, fontWeight: "800", marginBottom: 20 },
  truthCard: {
    backgroundColor: "rgba(245,158,11,0.10)",
    borderColor: "rgba(245,158,11,0.45)",
    borderWidth: 1,
    borderRadius: 22,
    padding: 18,
    marginBottom: 16,
  },
  card: {
    backgroundColor: "rgba(255,255,255,0.06)",
    borderColor: "rgba(0,208,132,0.28)",
    borderWidth: 1,
    borderRadius: 22,
    padding: 18,
    marginBottom: 14,
  },
  cardTitle: { color: "#FFFFFF", fontSize: 18, fontWeight: "900", marginBottom: 10 },
  rowTitle: { color: "#FFFFFF", fontSize: 18, fontWeight: "900", marginBottom: 6 },
  status: { color: "#00D084", fontSize: 13, fontWeight: "900", marginBottom: 8 },
  cardText: { color: "rgba(255,255,255,0.76)", fontSize: 14, lineHeight: 22 },
});
TSX

echo ""
echo "3. Create Proof Ledger screen"

cat > app/proof-ledger.tsx <<'TSX'
import React from "react";
import { ScrollView, StyleSheet, Text, View } from "react-native";
import { proofEvents } from "../src/lib/proofSimulation";

const MARKER = "SAFE_PROOF_LEDGER_20260607_A";

export default function ProofLedgerScreen() {
  return (
    <ScrollView style={styles.screen} contentContainerStyle={styles.content}>
      <Text style={styles.brand}>MauriMesh</Text>
      <Text style={styles.title}>Proof Ledger</Text>
      <Text style={styles.marker}>{MARKER}</Text>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Current Verified State</Text>
        <Text style={styles.cardText}>APK shell: PASS</Text>
        <Text style={styles.cardText}>Package identity: com.maurimesh.messenger</Text>
        <Text style={styles.cardText}>RootLayout crash: isolated and bypassed</Text>
        <Text style={styles.cardText}>Safe UI shell: PASS</Text>
      </View>

      {proofEvents.map((event, index) => (
        <View key={event.id} style={styles.ledgerRow}>
          <Text style={styles.index}>{String(index + 1).padStart(2, "0")}</Text>
          <View style={styles.rowBody}>
            <Text style={styles.rowTitle}>{event.stage}</Text>
            <Text style={styles.rowText}>{event.detail}</Text>
            <Text style={styles.rowStatus}>{event.status}</Text>
          </View>
        </View>
      ))}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: "#020617" },
  content: { padding: 24, paddingTop: 72 },
  brand: { color: "#00D084", fontSize: 38, fontWeight: "900", marginBottom: 8 },
  title: { color: "#FFFFFF", fontSize: 28, fontWeight: "900", marginBottom: 8 },
  marker: { color: "#38BDF8", fontSize: 12, fontWeight: "800", marginBottom: 20 },
  card: {
    backgroundColor: "rgba(255,255,255,0.06)",
    borderColor: "rgba(0,208,132,0.28)",
    borderWidth: 1,
    borderRadius: 22,
    padding: 18,
    marginBottom: 18,
  },
  cardTitle: { color: "#FFFFFF", fontSize: 18, fontWeight: "900", marginBottom: 10 },
  cardText: { color: "rgba(255,255,255,0.76)", fontSize: 14, lineHeight: 22 },
  ledgerRow: {
    flexDirection: "row",
    gap: 14,
    backgroundColor: "rgba(255,255,255,0.05)",
    borderColor: "rgba(0,208,132,0.22)",
    borderWidth: 1,
    borderRadius: 18,
    padding: 16,
    marginBottom: 12,
  },
  index: { color: "#38BDF8", fontSize: 14, fontWeight: "900", width: 30 },
  rowBody: { flex: 1 },
  rowTitle: { color: "#FFFFFF", fontSize: 16, fontWeight: "900", marginBottom: 6 },
  rowText: { color: "rgba(255,255,255,0.72)", fontSize: 14, lineHeight: 21 },
  rowStatus: { color: "#00D084", fontSize: 12, fontWeight: "900", marginTop: 8 },
});
TSX

echo ""
echo "4. Upgrade dashboard buttons"

cat > app/dashboard.tsx <<'TSX'
import React from "react";
import { Pressable, ScrollView, StyleSheet, Text, View } from "react-native";
import { useRouter } from "expo-router";

const MARKER = "SAFE_DASHBOARD_PROOF_BUTTONS_20260607_A";

const buttons = [
  { title: "Settings", route: "/settings" },
  { title: "Chat", route: "/chat" },
  { title: "Living Mesh", route: "/living-mesh" },
  { title: "Mesh Status", route: "/mesh-status" },
  { title: "Add Friend", route: "/add-friend" },
  { title: "Pixel Calling", route: "/pixel-calling" },
  { title: "BLE Proof UI", route: "/ble-proof" },
  { title: "Proof Ledger", route: "/proof-ledger" },
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
        <Text style={styles.cardText}>BLE/runtime UI: safe proof shell only</Text>
      </View>

      {buttons.map((button) => (
        <Pressable
          key={button.route}
          style={styles.navButton}
          onPress={() => router.push(button.route)}
        >
          <Text style={styles.navButtonText}>{button.title}</Text>
        </Pressable>
      ))}

      <Pressable style={styles.homeButton} onPress={() => router.back()}>
        <Text style={styles.homeButtonText}>Back Home</Text>
      </Pressable>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: "#020617" },
  content: { padding: 24, paddingTop: 72, paddingBottom: 42 },
  brand: { color: "#00D084", fontSize: 38, fontWeight: "900", marginBottom: 8 },
  title: { color: "#FFFFFF", fontSize: 28, fontWeight: "900", marginBottom: 8 },
  marker: { color: "#38BDF8", fontSize: 12, fontWeight: "800", marginBottom: 20 },
  card: {
    backgroundColor: "rgba(255,255,255,0.06)",
    borderColor: "rgba(0,208,132,0.28)",
    borderWidth: 1,
    borderRadius: 22,
    padding: 18,
    marginBottom: 18,
  },
  cardTitle: { color: "#FFFFFF", fontSize: 18, fontWeight: "900", marginBottom: 10 },
  cardText: { color: "rgba(255,255,255,0.72)", fontSize: 14, lineHeight: 22 },
  navButton: {
    backgroundColor: "rgba(0,208,132,0.14)",
    borderColor: "rgba(0,208,132,0.34)",
    borderWidth: 1,
    borderRadius: 18,
    paddingVertical: 18,
    paddingHorizontal: 20,
    marginBottom: 12,
  },
  navButtonText: { color: "#FFFFFF", fontSize: 16, fontWeight: "900" },
  homeButton: {
    backgroundColor: "#00D084",
    borderRadius: 18,
    paddingVertical: 18,
    alignItems: "center",
    marginTop: 10,
  },
  homeButtonText: { color: "#020617", fontSize: 16, fontWeight: "900" },
});
TSX

echo ""
echo "5. Active app files"
find app -maxdepth 2 -type f | sort

echo ""
echo "6. Crash-risk scan"
grep -R "unstable-native-tabs\|NativeTabs\|SplashScreen\|preventAutoHide\|hideAsync\|useFonts\|_layout.backup" app 2>/dev/null && {
  echo "FAIL: risky startup pattern found."
  exit 1
} || echo "PASS: no known risky startup patterns"

echo ""
echo "7. TypeScript"
npx tsc --noEmit

echo ""
echo "8. Clean export"
rm -rf dist .expo
npx expo export --platform android --clear

echo ""
echo "9. Marker check"
grep -R "SAFE_BLE_PROOF_UI_20260607_A\|SAFE_PROOF_LEDGER_20260607_A\|SAFE_DASHBOARD_PROOF_BUTTONS_20260607_A" app dist .expo 2>/dev/null || true

echo ""
echo "=================================================="
echo "SAFE BLE PROOF UI LAYER READY — NO EAS BUILD USED"
echo "Backup: $BACKUP"
echo "=================================================="
