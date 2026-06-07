#!/usr/bin/env bash
set -e

echo "=================================================="
echo "ADD SAFE UI SHELL LAYER — NO EAS BUILD"
echo "=================================================="

BACKUP="$HOME/maurimesh-router-backups/backup-before-safe-ui-shell-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP"
cp -R app "$BACKUP/app-current"

mkdir -p app

cat > app/settings.tsx <<'TSX'
import React from "react";
import { ScrollView, StyleSheet, Text, View } from "react-native";

const MARKER = "SAFE_SETTINGS_20260607_A";

export default function SettingsScreen() {
  return (
    <ScrollView style={styles.screen} contentContainerStyle={styles.content}>
      <Text style={styles.brand}>MauriMesh</Text>
      <Text style={styles.title}>Settings</Text>
      <Text style={styles.marker}>{MARKER}</Text>
      <View style={styles.card}>
        <Text style={styles.cardTitle}>Runtime Mode</Text>
        <Text style={styles.cardText}>Safe UI shell only. BLE/runtime engines still isolated until stable route proof.</Text>
      </View>
      <View style={styles.card}>
        <Text style={styles.cardTitle}>Package</Text>
        <Text style={styles.cardText}>com.maurimesh.messenger</Text>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: "#020617" },
  content: { padding: 24, paddingTop: 72 },
  brand: { color: "#00D084", fontSize: 38, fontWeight: "900", marginBottom: 8 },
  title: { color: "#FFFFFF", fontSize: 28, fontWeight: "900", marginBottom: 8 },
  marker: { color: "#38BDF8", fontSize: 12, fontWeight: "800", marginBottom: 20 },
  card: { backgroundColor: "rgba(255,255,255,0.06)", borderColor: "rgba(0,208,132,0.28)", borderWidth: 1, borderRadius: 22, padding: 18, marginBottom: 16 },
  cardTitle: { color: "#FFFFFF", fontSize: 18, fontWeight: "900", marginBottom: 10 },
  cardText: { color: "rgba(255,255,255,0.72)", fontSize: 14, lineHeight: 22 },
});
TSX

cat > app/chat.tsx <<'TSX'
import React from "react";
import { ScrollView, StyleSheet, Text, View } from "react-native";

const MARKER = "SAFE_CHAT_20260607_A";

export default function ChatScreen() {
  return (
    <ScrollView style={styles.screen} contentContainerStyle={styles.content}>
      <Text style={styles.brand}>MauriMesh</Text>
      <Text style={styles.title}>Chat</Text>
      <Text style={styles.marker}>{MARKER}</Text>
      <View style={styles.bubbleLeft}><Text style={styles.text}>Safe chat UI loaded.</Text></View>
      <View style={styles.bubbleRight}><Text style={styles.text}>BLE send/receive remains isolated until native proof is restored.</Text></View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: "#020617" },
  content: { padding: 24, paddingTop: 72 },
  brand: { color: "#00D084", fontSize: 38, fontWeight: "900", marginBottom: 8 },
  title: { color: "#FFFFFF", fontSize: 28, fontWeight: "900", marginBottom: 8 },
  marker: { color: "#38BDF8", fontSize: 12, fontWeight: "800", marginBottom: 20 },
  bubbleLeft: { alignSelf: "flex-start", maxWidth: "86%", backgroundColor: "rgba(255,255,255,0.06)", borderColor: "rgba(0,208,132,0.28)", borderWidth: 1, borderRadius: 18, padding: 16, marginBottom: 12 },
  bubbleRight: { alignSelf: "flex-end", maxWidth: "86%", backgroundColor: "rgba(0,208,132,0.18)", borderColor: "#00D084", borderWidth: 1, borderRadius: 18, padding: 16, marginBottom: 12 },
  text: { color: "#FFFFFF", fontSize: 14, lineHeight: 21 },
});
TSX

cat > app/living-mesh.tsx <<'TSX'
import React from "react";
import { ScrollView, StyleSheet, Text, View } from "react-native";

const MARKER = "SAFE_LIVING_MESH_20260607_A";

export default function LivingMeshScreen() {
  return (
    <ScrollView style={styles.screen} contentContainerStyle={styles.content}>
      <Text style={styles.brand}>MauriMesh</Text>
      <Text style={styles.title}>Living Mesh</Text>
      <Text style={styles.marker}>{MARKER}</Text>
      <View style={styles.canvas}>
        <View style={[styles.node, { left: "18%", top: "30%" }]}><Text style={styles.nodeText}>A</Text></View>
        <View style={[styles.node, { left: "50%", top: "55%" }]}><Text style={styles.nodeText}>B</Text></View>
        <View style={[styles.node, { left: "78%", top: "32%" }]}><Text style={styles.nodeText}>C</Text></View>
      </View>
      <Text style={styles.note}>Safe visual shell only. Live BLE topology remains isolated.</Text>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: "#020617" },
  content: { padding: 24, paddingTop: 72 },
  brand: { color: "#00D084", fontSize: 38, fontWeight: "900", marginBottom: 8 },
  title: { color: "#FFFFFF", fontSize: 28, fontWeight: "900", marginBottom: 8 },
  marker: { color: "#38BDF8", fontSize: 12, fontWeight: "800", marginBottom: 20 },
  canvas: { height: 330, backgroundColor: "rgba(255,255,255,0.04)", borderColor: "rgba(0,208,132,0.28)", borderWidth: 1, borderRadius: 24, position: "relative" },
  node: { position: "absolute", width: 58, height: 58, marginLeft: -29, marginTop: -29, borderRadius: 29, backgroundColor: "rgba(0,208,132,0.18)", borderColor: "#00D084", borderWidth: 1, alignItems: "center", justifyContent: "center" },
  nodeText: { color: "#FFFFFF", fontWeight: "900", fontSize: 18 },
  note: { color: "rgba(255,255,255,0.72)", fontSize: 14, lineHeight: 22, marginTop: 18 },
});
TSX

cat > app/mesh-status.tsx <<'TSX'
import React from "react";
import { ScrollView, StyleSheet, Text, View } from "react-native";

const MARKER = "SAFE_MESH_STATUS_20260607_A";

export default function MeshStatusScreen() {
  return (
    <ScrollView style={styles.screen} contentContainerStyle={styles.content}>
      <Text style={styles.brand}>MauriMesh</Text>
      <Text style={styles.title}>Mesh Status</Text>
      <Text style={styles.marker}>{MARKER}</Text>
      {["APK shell PASS", "Router safe Stack PASS", "BLE proof UI isolated", "Runtime engines protected"].map((item) => (
        <View key={item} style={styles.card}><Text style={styles.cardText}>{item}</Text></View>
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
  card: { backgroundColor: "rgba(255,255,255,0.06)", borderColor: "rgba(0,208,132,0.28)", borderWidth: 1, borderRadius: 18, padding: 16, marginBottom: 12 },
  cardText: { color: "rgba(255,255,255,0.82)", fontSize: 15, fontWeight: "700" },
});
TSX

cat > app/add-friend.tsx <<'TSX'
import React from "react";
import { ScrollView, StyleSheet, Text, View } from "react-native";

const MARKER = "SAFE_ADD_FRIEND_20260607_A";

export default function AddFriendScreen() {
  return (
    <ScrollView style={styles.screen} contentContainerStyle={styles.content}>
      <Text style={styles.brand}>MauriMesh</Text>
      <Text style={styles.title}>Add Friend</Text>
      <Text style={styles.marker}>{MARKER}</Text>
      <View style={styles.qr}><Text style={styles.qrText}>QR SHELL</Text></View>
      <Text style={styles.note}>Camera and BLE nearby discovery are isolated until native proof restore.</Text>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: "#020617" },
  content: { padding: 24, paddingTop: 72 },
  brand: { color: "#00D084", fontSize: 38, fontWeight: "900", marginBottom: 8 },
  title: { color: "#FFFFFF", fontSize: 28, fontWeight: "900", marginBottom: 8 },
  marker: { color: "#38BDF8", fontSize: 12, fontWeight: "800", marginBottom: 20 },
  qr: { height: 260, borderRadius: 24, borderWidth: 1, borderColor: "rgba(0,208,132,0.28)", backgroundColor: "rgba(255,255,255,0.06)", alignItems: "center", justifyContent: "center" },
  qrText: { color: "#00D084", fontSize: 22, fontWeight: "900", letterSpacing: 2 },
  note: { color: "rgba(255,255,255,0.72)", fontSize: 14, lineHeight: 22, marginTop: 18 },
});
TSX

cat > app/pixel-calling.tsx <<'TSX'
import React from "react";
import { ScrollView, StyleSheet, Text, View } from "react-native";

const MARKER = "SAFE_PIXEL_CALLING_20260607_A";

export default function PixelCallingScreen() {
  return (
    <ScrollView style={styles.screen} contentContainerStyle={styles.content}>
      <Text style={styles.brand}>MauriMesh</Text>
      <Text style={styles.title}>Pixel Calling</Text>
      <Text style={styles.marker}>{MARKER}</Text>
      <View style={styles.video}><Text style={styles.videoText}>CALL UI SHELL</Text></View>
      <Text style={styles.note}>Real media transport is not active in this safe shell.</Text>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: "#020617" },
  content: { padding: 24, paddingTop: 72 },
  brand: { color: "#00D084", fontSize: 38, fontWeight: "900", marginBottom: 8 },
  title: { color: "#FFFFFF", fontSize: 28, fontWeight: "900", marginBottom: 8 },
  marker: { color: "#38BDF8", fontSize: 12, fontWeight: "800", marginBottom: 20 },
  video: { height: 360, borderRadius: 24, borderWidth: 1, borderColor: "rgba(0,208,132,0.28)", backgroundColor: "rgba(255,255,255,0.04)", alignItems: "center", justifyContent: "center" },
  videoText: { color: "#FFFFFF", fontSize: 22, fontWeight: "900" },
  note: { color: "rgba(255,255,255,0.72)", fontSize: 14, lineHeight: 22, marginTop: 18 },
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
grep -R "SAFE_SETTINGS_20260607_A\|SAFE_CHAT_20260607_A\|SAFE_LIVING_MESH_20260607_A\|SAFE_MESH_STATUS_20260607_A\|SAFE_ADD_FRIEND_20260607_A\|SAFE_PIXEL_CALLING_20260607_A" app dist .expo 2>/dev/null || true

echo ""
echo "=================================================="
echo "SAFE UI SHELL LAYER READY — NO EAS BUILD USED"
echo "Backup: $BACKUP"
echo "=================================================="
