import React from "react";
import { ScrollView, StyleSheet, Text, View } from "react-native";
import { nativeBleAuditStatus } from "../src/lib/nativeBleAudit";

const MARKER = "NATIVE_BLE_AUDIT_UI_20260607_A";

export default function NativeBleAuditScreen() {
  const riskTone =
    nativeBleAuditStatus.riskyStartupPatternSeen === "YES" ? "#EF4444" : "#00D084";

  return (
    <ScrollView style={styles.screen} contentContainerStyle={styles.content}>
      <Text style={styles.brand}>MauriMesh</Text>
      <Text style={styles.title}>Native BLE Audit</Text>
      <Text style={styles.marker}>{MARKER}</Text>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Audit Report</Text>
        <Text style={styles.cardText}>{nativeBleAuditStatus.reportPath}</Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Native BLE Evidence Count</Text>
        <Text style={styles.bigNumber}>{nativeBleAuditStatus.nativeSignalCount}</Text>
        <Text style={styles.cardText}>
          Count of audit lines matching BLE, Bluetooth, GATT, scan, advertise,
          packet, ACK, relay, proof, or MauriMesh native signals.
        </Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Android Permissions Seen</Text>
        <Text style={styles.status}>{nativeBleAuditStatus.androidPermissionsSeen}</Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Startup Crash Risk Seen</Text>
        <Text style={[styles.status, { color: riskTone }]}>
          {nativeBleAuditStatus.riskyStartupPatternSeen}
        </Text>
      </View>

      <View style={styles.truthCard}>
        <Text style={styles.cardTitle}>Truth Boundary</Text>
        <Text style={styles.cardText}>{nativeBleAuditStatus.truth}</Text>
        <Text style={styles.cardText}>
          Real BLE activation still requires native module wiring, Android
          permission validation, physical phone logs, and TX/RX/ACK proof.
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
  bigNumber: { color: "#00D084", fontSize: 42, fontWeight: "900", marginBottom: 8 },
  status: { color: "#00D084", fontSize: 22, fontWeight: "900" },
});
