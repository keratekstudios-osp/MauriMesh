import React from "react";
import {
  Alert,
  Platform,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from "react-native";
import { BLE_2_HOP_PROOF } from "../src/maurimesh/proof/ble2HopProof";

function copyProofReport() {
  const report = [
    "MAURIMESH FULL PROOF REPORT",
    "",
    `Title: ${BLE_2_HOP_PROOF.title}`,
    `Status: ${BLE_2_HOP_PROOF.status}`,
    `Packet ID: ${BLE_2_HOP_PROOF.packetId}`,
    `Path: ${BLE_2_HOP_PROOF.path}`,
    `Phone A: ${BLE_2_HOP_PROOF.devices.phoneA}`,
    `Phone B: ${BLE_2_HOP_PROOF.devices.phoneB}`,
    "",
    "Sequence:",
    ...BLE_2_HOP_PROOF.sequence.map((item, index) => `${index + 1}. ${item}`),
    "",
    "Proof Log:",
    ...BLE_2_HOP_PROOF.proofLog,
    "",
    `Truth: ${BLE_2_HOP_PROOF.truth}`,
    "",
    "Replit: UI/API/SIMULATION ONLY",
    "APK/device proof: PHYSICAL DEVICE VALIDATION",
  ].join("\n");

  if (Platform.OS === "web" && typeof navigator !== "undefined" && navigator.clipboard) {
    navigator.clipboard.writeText(report);
    Alert.alert("Proof report copied");
    return;
  }

  console.log(report);
  Alert.alert("Proof report printed", "Proof report has been printed to console/log output.");
}

export default function Ble2HopProofScreen() {
  return (
    <ScrollView style={styles.screen} contentContainerStyle={styles.content}>
      <Text style={styles.kicker}>MAURIMESH PROOF MODE</Text>
      <Text style={styles.title}>2-Hop BLE Proof</Text>

      <View style={styles.passCard}>
        <Text style={styles.passLabel}>STATUS</Text>
        <Text style={styles.passText}>{BLE_2_HOP_PROOF.status}</Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Packet proof identity</Text>
        <Text style={styles.label}>Packet ID</Text>
        <Text style={styles.packet}>{BLE_2_HOP_PROOF.packetId}</Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Proof path</Text>
        <Text style={styles.body}>{BLE_2_HOP_PROOF.path}</Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Devices</Text>
        <Text style={styles.body}>A06: {BLE_2_HOP_PROOF.devices.phoneA}</Text>
        <Text style={styles.body}>S10: {BLE_2_HOP_PROOF.devices.phoneB}</Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Sequence complete</Text>
        {BLE_2_HOP_PROOF.sequence.map((item, index) => (
          <View key={item} style={styles.step}>
            <Text style={styles.dot}>●</Text>
            <Text style={styles.stepText}>{index + 1}. {item}</Text>
            <Text style={styles.done}>DONE</Text>
          </View>
        ))}
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Proof log block</Text>
        <View style={styles.logBox}>
          {BLE_2_HOP_PROOF.proofLog.map((line) => (
            <Text key={line} style={styles.logText}>{line}</Text>
          ))}
        </View>
      </View>

      <View style={styles.truthCard}>
        <Text style={styles.truthTitle}>Truth rule</Text>
        <Text style={styles.truthText}>{BLE_2_HOP_PROOF.truth}</Text>
      </View>

      <TouchableOpacity style={styles.button} onPress={copyProofReport}>
        <Text style={styles.buttonText}>Copy Full Proof Report</Text>
      </TouchableOpacity>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  screen: {
    flex: 1,
    backgroundColor: "#020403",
  },
  content: {
    padding: 18,
    paddingBottom: 40,
    gap: 14,
  },
  kicker: {
    color: "#00D084",
    fontWeight: "900",
    letterSpacing: 2,
    fontSize: 12,
  },
  title: {
    color: "white",
    fontSize: 32,
    fontWeight: "900",
  },
  passCard: {
    borderWidth: 1,
    borderColor: "#00D084",
    backgroundColor: "rgba(0,208,132,0.14)",
    borderRadius: 20,
    padding: 18,
  },
  passLabel: {
    color: "#00D084",
    fontSize: 12,
    fontWeight: "900",
    letterSpacing: 1.5,
  },
  passText: {
    color: "white",
    fontSize: 28,
    fontWeight: "900",
    marginTop: 4,
  },
  card: {
    borderWidth: 1,
    borderColor: "rgba(0,208,132,0.35)",
    backgroundColor: "rgba(0,20,12,0.88)",
    borderRadius: 20,
    padding: 16,
    gap: 10,
  },
  cardTitle: {
    color: "white",
    fontSize: 18,
    fontWeight: "900",
  },
  label: {
    color: "rgba(255,255,255,0.65)",
    fontSize: 12,
    fontWeight: "800",
  },
  packet: {
    color: "#00D084",
    fontSize: 18,
    fontWeight: "900",
  },
  body: {
    color: "rgba(255,255,255,0.78)",
    fontSize: 14,
    lineHeight: 21,
  },
  step: {
    flexDirection: "row",
    alignItems: "center",
    backgroundColor: "rgba(0,208,132,0.12)",
    borderWidth: 1,
    borderColor: "rgba(0,208,132,0.5)",
    borderRadius: 14,
    padding: 12,
    gap: 8,
  },
  dot: {
    color: "#22C55E",
    fontSize: 18,
  },
  stepText: {
    flex: 1,
    color: "white",
    fontWeight: "800",
  },
  done: {
    color: "#22C55E",
    fontSize: 10,
    fontWeight: "900",
  },
  logBox: {
    borderRadius: 14,
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.16)",
    backgroundColor: "rgba(0,0,0,0.35)",
    padding: 12,
    gap: 4,
  },
  logText: {
    color: "rgba(255,255,255,0.82)",
    fontSize: 12,
    lineHeight: 18,
  },
  truthCard: {
    borderWidth: 1,
    borderColor: "rgba(245,158,11,0.6)",
    backgroundColor: "rgba(245,158,11,0.12)",
    borderRadius: 20,
    padding: 16,
    gap: 8,
  },
  truthTitle: {
    color: "#F59E0B",
    fontSize: 16,
    fontWeight: "900",
  },
  truthText: {
    color: "rgba(255,255,255,0.84)",
    lineHeight: 21,
  },
  button: {
    minHeight: 56,
    borderRadius: 18,
    backgroundColor: "#00D084",
    alignItems: "center",
    justifyContent: "center",
    paddingHorizontal: 18,
  },
  buttonText: {
    color: "white",
    fontSize: 16,
    fontWeight: "900",
  },
});
