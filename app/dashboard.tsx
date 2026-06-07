import React from "react";
import { useRouter } from "expo-router";
import {
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from "react-native";

const MARKER = "SAFE_DASHBOARD_LIVE_MESH_OPS_20260608_A";

const routes = [
  ["Settings", "/settings"],
  ["Chat", "/chat"],
  ["Living Mesh", "/living-mesh"],
  ["Mesh Status", "/mesh-status"],
  ["Add Friend", "/add-friend"],
  ["Pixel Calling", "/pixel-calling"],
  ["BLE Proof UI", "/ble-proof"],
  ["Proof Ledger", "/proof-ledger"],
  ["Native BLE Audit", "/native-ble-audit"],
  ["Native BLE Status", "/native-ble-status"],
  ["Native BLE Scan Proof", "/native-ble-scan-proof"],
  ["Live Mesh Ops", "/live-mesh-ops"],
] as const;

export default function Dashboard() {
  const router = useRouter();

  return (
    <ScrollView style={styles.page} contentContainerStyle={styles.content}>
      <Text style={styles.brand}>MauriMesh</Text>
      <Text style={styles.title}>Dashboard</Text>
      <Text style={styles.marker}>{MARKER}</Text>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>System Status</Text>
        <Text style={styles.body}>APK shell: PASS</Text>
        <Text style={styles.body}>Package: com.maurimesh.messenger</Text>
        <Text style={styles.body}>Router: safe Stack only</Text>
        <Text style={styles.body}>Native bridge: PRESENT</Text>
        <Text style={styles.body}>BLE scan proof: isolated test only</Text>
      </View>

      {routes.map(([label, route]) => (
        <TouchableOpacity
          key={route}
          style={styles.button}
          onPress={() => router.push(route as any)}
        >
          <Text style={styles.buttonText}>{label}</Text>
        </TouchableOpacity>
      ))}

      <TouchableOpacity style={styles.homeButton} onPress={() => router.push("/")}>
        <Text style={styles.homeButtonText}>Back Home</Text>
      </TouchableOpacity>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  page: {
    flex: 1,
    backgroundColor: "#050816",
  },
  content: {
    padding: 24,
    paddingTop: 56,
    paddingBottom: 80,
  },
  brand: {
    color: "#00D084",
    fontSize: 42,
    fontWeight: "900",
    marginBottom: 24,
  },
  title: {
    color: "#FFFFFF",
    fontSize: 30,
    fontWeight: "900",
    marginBottom: 10,
  },
  marker: {
    color: "#4FC3F7",
    fontSize: 14,
    fontWeight: "900",
    letterSpacing: 1.2,
    marginBottom: 26,
  },
  card: {
    borderWidth: 1,
    borderColor: "rgba(0, 208, 132, 0.28)",
    borderRadius: 20,
    padding: 22,
    marginBottom: 20,
    backgroundColor: "rgba(255,255,255,0.035)",
  },
  cardTitle: {
    color: "#FFFFFF",
    fontSize: 21,
    fontWeight: "900",
    marginBottom: 14,
  },
  body: {
    color: "rgba(255,255,255,0.76)",
    fontSize: 17,
    lineHeight: 26,
  },
  button: {
    backgroundColor: "rgba(0, 208, 132, 0.12)",
    borderWidth: 1,
    borderColor: "rgba(0, 208, 132, 0.32)",
    borderRadius: 18,
    padding: 20,
    marginBottom: 14,
  },
  buttonText: {
    color: "#FFFFFF",
    fontSize: 18,
    fontWeight: "900",
  },
  homeButton: {
    backgroundColor: "#00D084",
    borderRadius: 18,
    padding: 20,
    marginTop: 18,
    alignItems: "center",
  },
  homeButtonText: {
    color: "#03120C",
    fontSize: 18,
    fontWeight: "900",
  },
});
