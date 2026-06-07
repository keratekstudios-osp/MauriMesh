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
