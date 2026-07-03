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
