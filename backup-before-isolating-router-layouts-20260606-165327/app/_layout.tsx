import React from "react";
import { StyleSheet, Text, View } from "react-native";

const MARKER = "ROOT_LAYOUT_BOOT_PROBE_20260607_A";

export default function RootLayout() {
  return (
    <View style={styles.screen}>
      <Text style={styles.brand}>MauriMesh</Text>
      <Text style={styles.status}>APK boot probe passed</Text>
      <Text style={styles.marker}>{MARKER}</Text>
      <Text style={styles.truth}>
        Navigation, BLE, routing, and engines are temporarily isolated until APK boot is stable.
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  screen: {
    flex: 1,
    backgroundColor: "#020617",
    alignItems: "center",
    justifyContent: "center",
    padding: 24,
  },
  brand: {
    color: "#00D084",
    fontSize: 42,
    fontWeight: "900",
    marginBottom: 12,
  },
  status: {
    color: "#FFFFFF",
    fontSize: 22,
    fontWeight: "800",
    marginBottom: 12,
    textAlign: "center",
  },
  marker: {
    color: "#38BDF8",
    fontSize: 12,
    fontWeight: "700",
    marginBottom: 18,
    textAlign: "center",
  },
  truth: {
    color: "rgba(255,255,255,0.72)",
    fontSize: 14,
    lineHeight: 21,
    textAlign: "center",
  },
});
