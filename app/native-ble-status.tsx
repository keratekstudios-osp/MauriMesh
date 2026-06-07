import React, { useEffect, useState } from "react";
import { ScrollView, StyleSheet, Text, View } from "react-native";
import { getNativeBleBridgeStatus, NativeBleBridgeStatus } from "../src/lib/nativeBleBridge";

const MARKER = "NATIVE_BLE_STATUS_BRIDGE_20260607_A";

export default function NativeBleStatusScreen() {
  const [status, setStatus] = useState<NativeBleBridgeStatus | null>(null);

  useEffect(() => {
    let alive = true;
    getNativeBleBridgeStatus()
      .then((next) => {
        if (alive) setStatus(next);
      })
      .catch(() => {
        if (alive) {
          setStatus({
            platform: "unknown",
            modulePresent: false,
            moduleName: "MauriMeshBle",
            bluetoothScanPermission: "unavailable",
            bluetoothConnectPermission: "unavailable",
            fineLocationPermission: "unavailable",
            liveBleActive: false,
            truth:
              "Native BLE bridge status failed safely. No live BLE action was attempted.",
          });
        }
      });

    return () => {
      alive = false;
    };
  }, []);

  const moduleTone = status?.modulePresent ? "#00D084" : "#F59E0B";

  return (
    <ScrollView style={styles.screen} contentContainerStyle={styles.content}>
      <Text style={styles.brand}>MauriMesh</Text>
      <Text style={styles.title}>Native BLE Status</Text>
      <Text style={styles.marker}>{MARKER}</Text>

      <View style={styles.truthCard}>
        <Text style={styles.cardTitle}>Truth Boundary</Text>
        <Text style={styles.cardText}>
          {status?.truth || "Checking read-only native BLE bridge status..."}
        </Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Native Module</Text>
        <Text style={[styles.bigStatus, { color: moduleTone }]}>
          {status?.modulePresent ? "PRESENT" : "NOT CONFIRMED"}
        </Text>
        <Text style={styles.cardText}>Module name: {status?.moduleName || "MauriMeshBle"}</Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Platform</Text>
        <Text style={styles.cardText}>{status?.platform || "checking..."}</Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Android Permissions</Text>
        <Text style={styles.cardText}>BLUETOOTH_SCAN: {status?.bluetoothScanPermission || "checking..."}</Text>
        <Text style={styles.cardText}>BLUETOOTH_CONNECT: {status?.bluetoothConnectPermission || "checking..."}</Text>
        <Text style={styles.cardText}>ACCESS_FINE_LOCATION: {status?.fineLocationPermission || "checking..."}</Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Live BLE Active</Text>
        <Text style={styles.dangerText}>NO</Text>
        <Text style={styles.cardText}>
          This screen is status-only. Scan, advertise, connect, TX/RX, ACK, and relay are not activated here.
        </Text>
      </View>
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
    marginBottom: 14,
  },
  truthCard: {
    backgroundColor: "rgba(245,158,11,0.10)",
    borderColor: "rgba(245,158,11,0.45)",
    borderWidth: 1,
    borderRadius: 22,
    padding: 18,
    marginBottom: 14,
  },
  cardTitle: { color: "#FFFFFF", fontSize: 18, fontWeight: "900", marginBottom: 10 },
  cardText: { color: "rgba(255,255,255,0.76)", fontSize: 14, lineHeight: 22 },
  bigStatus: { fontSize: 28, fontWeight: "900", marginBottom: 8 },
  dangerText: { color: "#EF4444", fontSize: 22, fontWeight: "900", marginBottom: 8 },
});
