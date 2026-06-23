import React from "react";
import { ScrollView, StyleSheet, Text, View } from "react-native";
import { getApiConfigStatus } from "../src/maurimesh/config/apiConfig";

export default function ApiConfigScreen() {
  const status = getApiConfigStatus();

  return (
    <ScrollView style={styles.root} contentContainerStyle={styles.content}>
      <Text style={styles.brand}>MauriMesh</Text>
      <Text style={styles.title}>API Configuration</Text>
      <Text style={styles.marker}>{status.marker}</Text>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Mesh API URL</Text>
        <Text style={styles.line}>Configured: {status.configured ? "yes" : "no"}</Text>
        <Text style={styles.line}>URL: {status.url || "not set"}</Text>
        <Text style={styles.muted}>{status.message}</Text>
      </View>

      <View style={styles.truth}>
        <Text style={styles.truthTitle}>Required for Proof Ledger</Text>
        <Text style={styles.truthText}>
          Set EXPO_PUBLIC_MESH_API_URL to your running Replit/server URL before
          building the APK. Without this, Proof Ledger cannot save or load
          server-recorded evidence from the phone.
        </Text>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: "#020403" },
  content: { padding: 22, gap: 16 },
  brand: { color: "#00D084", fontSize: 36, fontWeight: "900" },
  title: { color: "#FFFFFF", fontSize: 30, fontWeight: "900" },
  marker: { color: "#38BDF8", fontSize: 12, fontWeight: "800" },
  card: {
    borderWidth: 1,
    borderColor: "rgba(0,208,132,0.26)",
    backgroundColor: "rgba(255,255,255,0.045)",
    borderRadius: 18,
    padding: 16,
    gap: 10,
  },
  cardTitle: { color: "#FFFFFF", fontSize: 20, fontWeight: "900" },
  line: { color: "rgba(255,255,255,0.78)", fontSize: 16, lineHeight: 24 },
  muted: { color: "rgba(255,255,255,0.62)", lineHeight: 22 },
  truth: {
    borderWidth: 1,
    borderColor: "rgba(245,158,11,0.45)",
    borderRadius: 18,
    padding: 16,
  },
  truthTitle: { color: "#FFFFFF", fontSize: 18, fontWeight: "900" },
  truthText: { color: "rgba(255,255,255,0.7)", lineHeight: 22, marginTop: 8 },
});
