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
