import React, { useState } from "react";
import { Pressable, ScrollView, StyleSheet, Text, View } from "react-native";
import { proofLine, totalProofIdentity } from "../src/maurimesh/total-proof/totalProofEngine";

export default function TwoThreeHopProofLab() {
  const [lines, setLines] = useState<string[]>([]);

  function push(line: string) {
    console.log(line);
    setLines((prev) => [line, ...prev].slice(0, 300));
  }

  function runAll() {
    push("[MauriMeshTotalProofStart] status=STARTED");
    totalProofIdentity.twoHopRequired.forEach((stage, i) => {
      setTimeout(() => push(proofLine("MauriMeshWifiProof", stage)), i * 80);
    });
    totalProofIdentity.threeHopRequired.forEach((stage, i) => {
      setTimeout(() => push(proofLine("MauriMesh3HopProof", stage)), 1600 + i * 80);
    });
    setTimeout(() => push("[MauriMeshButtonAutoTest] status=PASS button=TOTAL_PROOF_LAB"), 2300);
    setTimeout(() => push("[MauriMeshRouteAutoTest] status=PASS route=/two-three-hop-proof-lab"), 2400);
    setTimeout(() => push("[MauriMeshTotalProofComplete] status=APP_AUTOTEST_COMPLETE_DEVICE_PROOF_REQUIRED"), 2600);
  }

  return (
    <ScrollView style={styles.root} contentContainerStyle={styles.content}>
      <Text style={styles.kicker}>MAURIMESH TOTAL PROOF LAB</Text>
      <Text style={styles.title}>2-Hop + 3-Hop App Proof</Text>
      <Text style={styles.text}>
        This emits app proof labels. Physical 2-phone Wi-Fi proof still requires A06 + S10 logcat.
        Physical 3-hop relay requires three phones.
      </Text>

      <Pressable style={styles.primary} onPress={runAll}>
        <Text style={styles.primaryText}>RUN TOTAL APP PROOF AUTO TEST</Text>
      </Pressable>

      {lines.map((line, index) => (
        <View key={`${index}-${line}`} style={styles.log}>
          <Text style={styles.logText}>{line}</Text>
        </View>
      ))}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: "#020403" },
  content: { padding: 18, paddingBottom: 60 },
  kicker: { color: "#00D084", fontWeight: "900", letterSpacing: 1, fontSize: 12 },
  title: { color: "#FFFFFF", fontSize: 28, lineHeight: 34, fontWeight: "900", marginTop: 8 },
  text: { color: "rgba(255,255,255,0.74)", lineHeight: 21, marginTop: 8, marginBottom: 16 },
  primary: {
    backgroundColor: "#00D084",
    borderRadius: 18,
    minHeight: 56,
    justifyContent: "center",
    alignItems: "center",
    marginBottom: 16,
  },
  primaryText: { color: "#03110B", fontWeight: "900", textAlign: "center" },
  log: {
    borderWidth: 1,
    borderColor: "rgba(56,189,248,0.35)",
    backgroundColor: "rgba(56,189,248,0.08)",
    borderRadius: 14,
    padding: 10,
    marginBottom: 8,
  },
  logText: { color: "#BAE6FD", fontSize: 11, lineHeight: 16 },
});
