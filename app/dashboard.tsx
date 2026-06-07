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
  { title: "Native BLE Audit", route: "/native-ble-audit" },
  { title: "Native BLE Status", route: "/native-ble-status" },
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
