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
