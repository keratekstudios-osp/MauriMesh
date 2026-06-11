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
