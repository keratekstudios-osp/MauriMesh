import React from "react";
import {
  Alert,
  ScrollView,
  Share,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from "react-native";
import { router } from "expo-router";
import {
  LOCKED_PROOF_VAULT,
  getLockedProofVaultReport,
} from "../src/maurimesh/proof/lockedProofVault";

const BUILD_MARKER = "LOCKED_PROOF_VAULT_UI_20260612";

export default function LockedProofsScreen() {
  const passed = LOCKED_PROOF_VAULT.filter((proof) => proof.status === "PASSED").length;

  async function copyReport() {
    const report = [
      "MAURIMESH LOCKED PROOF VAULT REPORT",
      `Build marker: ${BUILD_MARKER}`,
      `Passed proofs: ${passed}/${LOCKED_PROOF_VAULT.length}`,
      "",
      getLockedProofVaultReport(),
    ].join("\n");

    try {
      await Share.share({ message: report });
    } catch {
      Alert.alert("Locked Proof Vault Report", report);
    }
  }

  return (
    <ScrollView style={styles.root} contentContainerStyle={styles.content}>
      <Text style={styles.kicker}>MAURIMESH PROOF VAULT</Text>
      <Text style={styles.title}>Locked Proofs</Text>
      <Text style={styles.marker}>{BUILD_MARKER}</Text>

      <View style={styles.summary}>
        <Text style={styles.summaryLabel}>PASSED PROOF MILESTONES</Text>
        <Text style={styles.summaryNumber}>
          {passed}/{LOCKED_PROOF_VAULT.length}
        </Text>
        <Text style={styles.summaryText}>
          These are locked proof records from completed APK/logcat proof runs.
        </Text>
      </View>

      {LOCKED_PROOF_VAULT.map((proof) => (
        <View key={proof.proofId} style={styles.card}>
          <View style={styles.row}>
            <Text style={styles.proofId}>{proof.proofId}</Text>
            <Text style={styles.pass}>{proof.status}</Text>
          </View>

          <Text style={styles.proofTitle}>{proof.title}</Text>

          <Text style={styles.label}>Packet ID</Text>
          <Text style={styles.packet}>{proof.packetId}</Text>

          <Text style={styles.label}>Route</Text>
          <Text style={styles.value}>{proof.route}</Text>

          <Text style={styles.label}>Truth Rule</Text>
          <Text style={styles.value}>{proof.truthRule}</Text>

          <Text style={styles.label}>Stages</Text>
          {proof.stages.map((stage) => (
            <View key={`${proof.proofId}-${stage.order}`} style={styles.stage}>
              <Text style={styles.stageTitle}>
                {stage.order}. {stage.role} / {stage.device}
              </Text>
              <Text style={styles.stageCode}>{stage.stage}</Text>
              <Text style={styles.stageText}>{stage.summary}</Text>
            </View>
          ))}
        </View>
      ))}

      <TouchableOpacity style={styles.primary} onPress={copyReport}>
        <Text style={styles.primaryText}>Copy Locked Proof Vault Report</Text>
      </TouchableOpacity>

      <TouchableOpacity style={styles.secondary} onPress={() => router.back()}>
        <Text style={styles.secondaryText}>Back</Text>
      </TouchableOpacity>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: "#020806" },
  content: { padding: 18, paddingBottom: 48 },
  kicker: {
    color: "#F4C542",
    fontSize: 11,
    fontWeight: "900",
    letterSpacing: 2,
  },
  title: {
    color: "#F8FFFC",
    fontSize: 34,
    fontWeight: "900",
    marginTop: 6,
  },
  marker: {
    color: "#00D084",
    fontSize: 11,
    fontWeight: "800",
    marginTop: 4,
  },
  summary: {
    marginTop: 18,
    padding: 16,
    borderRadius: 18,
    backgroundColor: "#062018",
    borderWidth: 1,
    borderColor: "#00D084",
  },
  summaryLabel: { color: "#9EF5CF", fontWeight: "900", fontSize: 12 },
  summaryNumber: {
    color: "#FFFFFF",
    fontSize: 44,
    fontWeight: "900",
    marginTop: 4,
  },
  summaryText: { color: "#AFC9BF", marginTop: 6, fontWeight: "700" },
  card: {
    marginTop: 16,
    padding: 16,
    borderRadius: 18,
    backgroundColor: "#04140F",
    borderWidth: 1,
    borderColor: "#107A55",
  },
  row: { flexDirection: "row", justifyContent: "space-between", gap: 12 },
  proofId: { color: "#83AFA0", fontSize: 11, fontWeight: "900" },
  pass: { color: "#27D46A", fontSize: 12, fontWeight: "900" },
  proofTitle: {
    color: "#FFFFFF",
    fontSize: 22,
    fontWeight: "900",
    marginTop: 10,
  },
  label: {
    color: "#6CE7B7",
    fontSize: 11,
    fontWeight: "900",
    marginTop: 14,
    letterSpacing: 1,
  },
  packet: {
    color: "#F4C542",
    fontSize: 16,
    fontWeight: "900",
    marginTop: 4,
  },
  value: { color: "#D8FFF0", fontSize: 14, fontWeight: "700", marginTop: 4 },
  stage: {
    marginTop: 10,
    padding: 12,
    borderRadius: 14,
    backgroundColor: "#03100C",
    borderWidth: 1,
    borderColor: "#173E31",
  },
  stageTitle: { color: "#FFFFFF", fontWeight: "900", fontSize: 14 },
  stageCode: {
    color: "#00D084",
    fontWeight: "900",
    fontSize: 12,
    marginTop: 4,
  },
  stageText: { color: "#B9D2C8", fontWeight: "700", marginTop: 4 },
  primary: {
    marginTop: 18,
    backgroundColor: "#00D084",
    padding: 18,
    borderRadius: 18,
    alignItems: "center",
  },
  primaryText: { color: "#00130C", fontSize: 16, fontWeight: "900" },
  secondary: {
    marginTop: 12,
    borderColor: "#29483E",
    borderWidth: 1,
    padding: 16,
    borderRadius: 18,
    alignItems: "center",
  },
  secondaryText: { color: "#C6FFF0", fontSize: 15, fontWeight: "900" },
});
