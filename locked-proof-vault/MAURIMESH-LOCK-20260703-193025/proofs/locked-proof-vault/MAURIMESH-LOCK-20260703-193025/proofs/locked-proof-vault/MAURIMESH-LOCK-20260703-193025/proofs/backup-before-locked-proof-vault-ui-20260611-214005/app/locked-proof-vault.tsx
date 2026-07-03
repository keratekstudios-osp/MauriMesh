import React from "react";
import {
  Alert,
  Clipboard,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from "react-native";
import {
  createLockedProofReport,
  getProofVaultSummary,
  lockedProofs,
  MAURIMESH_LOCKED_PROOF_VAULT_BUILD,
} from "../src/maurimesh/proof/lockedProofVault";

const colors = {
  bg: "#020806",
  card: "#061B14",
  card2: "#03110D",
  border: "#0B6B4B",
  green: "#00D084",
  green2: "#22C55E",
  text: "#F8FAFC",
  muted: "#94A3B8",
  amber: "#FBBF24",
  red: "#F87171",
  blue: "#38BDF8",
};

function Pill({ label, tone }: { label: string; tone?: "green" | "amber" | "red" | "blue" }) {
  const backgroundColor =
    tone === "amber"
      ? "rgba(251,191,36,0.14)"
      : tone === "red"
        ? "rgba(248,113,113,0.14)"
        : tone === "blue"
          ? "rgba(56,189,248,0.14)"
          : "rgba(0,208,132,0.14)";

  const borderColor =
    tone === "amber"
      ? colors.amber
      : tone === "red"
        ? colors.red
        : tone === "blue"
          ? colors.blue
          : colors.green;

  return (
    <View style={[styles.pill, { backgroundColor, borderColor }]}>
      <Text style={[styles.pillText, { color: borderColor }]}>{label}</Text>
    </View>
  );
}

export default function LockedProofVaultScreen() {
  const summary = getProofVaultSummary();

  const copyReport = () => {
    const report = createLockedProofReport();
    Clipboard.setString(report);
    Alert.alert("Copied", "Locked Proof Vault report copied.");
  };

  return (
    <ScrollView style={styles.screen} contentContainerStyle={styles.content}>
      <Text style={styles.kicker}>MAURIMESH PROOF ARCHIVE</Text>
      <Text style={styles.title}>Locked Proof Vault</Text>
      <Text style={styles.subtitle}>
        Stored passed proof milestones. This is the archive/history layer, not the live proof-run log.
      </Text>

      <View style={styles.notice}>
        <Text style={styles.noticeTitle}>Why your live screen said “No proof log yet”</Text>
        <Text style={styles.noticeText}>
          The 3-device and store-forward proof screens only show the current live session.
          These locked results are now stored here as proof history.
        </Text>
      </View>

      <View style={styles.summary}>
        <Text style={styles.summaryTitle}>Vault Summary</Text>
        <Text style={styles.mono}>Build: {MAURIMESH_LOCKED_PROOF_VAULT_BUILD}</Text>
        <Text style={styles.mono}>Total proofs: {summary.total}</Text>
        <Text style={styles.mono}>Passed proofs: {summary.passed}</Text>
        <Text style={styles.mono}>Locked proofs: {summary.locked}</Text>
        <Text style={styles.mono}>Next: {summary.nextProofTarget}</Text>
      </View>

      {lockedProofs.map((proof) => (
        <View key={proof.proofId} style={styles.card}>
          <View style={styles.cardHeader}>
            <Text style={styles.proofId}>{proof.proofId}</Text>
            <Pill label={proof.status} tone={proof.status === "PASSED" ? "green" : "amber"} />
          </View>

          <Text style={styles.proofName}>{proof.name}</Text>

          <View style={styles.rowWrap}>
            <Pill label={proof.locked ? "LOCKED" : "UNLOCKED"} tone={proof.locked ? "green" : "red"} />
            <Pill label={proof.proofClass} tone="blue" />
          </View>

          <Text style={styles.label}>Packet ID</Text>
          <Text style={styles.packet}>{proof.packetId}</Text>

          <Text style={styles.label}>Route</Text>
          <Text style={styles.body}>{proof.route}</Text>

          <Text style={styles.label}>Devices</Text>
          {Object.entries(proof.devices).map(([role, device]) => (
            <Text key={role} style={styles.mono}>
              {role}: {device}
            </Text>
          ))}

          <Text style={styles.label}>Stages</Text>
          {proof.stages.map((stage, index) => (
            <Text key={`${proof.proofId}-${stage}`} style={styles.stage}>
              {index + 1}. {stage}
            </Text>
          ))}

          <Text style={styles.label}>Evidence</Text>
          {proof.evidence.map((item) => (
            <Text key={`${proof.proofId}-${item}`} style={styles.body}>
              • {item}
            </Text>
          ))}

          <Text style={styles.label}>Truth Rule</Text>
          <Text style={styles.truth}>{proof.truthRule}</Text>
        </View>
      ))}

      <TouchableOpacity style={styles.copyButton} onPress={copyReport}>
        <Text style={styles.copyText}>Copy Locked Proof Vault Report</Text>
      </TouchableOpacity>

      <View style={styles.footer}>
        <Text style={styles.footerText}>
          Locked proofs: 2-Hop, 3-Device Hop Relay, Store-Forward Delay.
        </Text>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  screen: {
    flex: 1,
    backgroundColor: colors.bg,
  },
  content: {
    padding: 18,
    paddingBottom: 48,
  },
  kicker: {
    color: colors.green,
    fontSize: 12,
    fontWeight: "900",
    letterSpacing: 2,
    marginTop: 8,
  },
  title: {
    color: colors.text,
    fontSize: 34,
    fontWeight: "900",
    marginTop: 8,
  },
  subtitle: {
    color: colors.muted,
    fontSize: 15,
    lineHeight: 22,
    marginTop: 8,
    marginBottom: 14,
  },
  notice: {
    backgroundColor: "rgba(251,191,36,0.10)",
    borderColor: "rgba(251,191,36,0.55)",
    borderWidth: 1,
    borderRadius: 18,
    padding: 14,
    marginBottom: 14,
  },
  noticeTitle: {
    color: colors.amber,
    fontSize: 16,
    fontWeight: "900",
    marginBottom: 6,
  },
  noticeText: {
    color: colors.text,
    fontSize: 14,
    lineHeight: 20,
  },
  summary: {
    backgroundColor: colors.card,
    borderColor: colors.border,
    borderWidth: 1,
    borderRadius: 20,
    padding: 16,
    marginBottom: 16,
  },
  summaryTitle: {
    color: colors.text,
    fontSize: 20,
    fontWeight: "900",
    marginBottom: 10,
  },
  card: {
    backgroundColor: colors.card2,
    borderColor: colors.border,
    borderWidth: 1,
    borderRadius: 22,
    padding: 16,
    marginBottom: 16,
  },
  cardHeader: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
  },
  proofId: {
    color: colors.blue,
    fontSize: 13,
    fontWeight: "900",
  },
  proofName: {
    color: colors.text,
    fontSize: 24,
    fontWeight: "900",
    marginTop: 10,
    marginBottom: 10,
  },
  rowWrap: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 8,
    marginBottom: 12,
  },
  pill: {
    borderWidth: 1,
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 999,
  },
  pillText: {
    fontSize: 11,
    fontWeight: "900",
  },
  label: {
    color: colors.green,
    fontSize: 13,
    fontWeight: "900",
    marginTop: 14,
    marginBottom: 6,
    textTransform: "uppercase",
    letterSpacing: 1,
  },
  packet: {
    color: colors.amber,
    fontSize: 16,
    fontWeight: "900",
  },
  body: {
    color: colors.text,
    fontSize: 14,
    lineHeight: 21,
  },
  mono: {
    color: colors.muted,
    fontSize: 13,
    lineHeight: 20,
    fontFamily: "monospace",
  },
  stage: {
    color: colors.text,
    fontSize: 13,
    lineHeight: 20,
    fontFamily: "monospace",
    marginBottom: 3,
  },
  truth: {
    color: colors.amber,
    fontSize: 14,
    lineHeight: 21,
    fontWeight: "700",
  },
  copyButton: {
    backgroundColor: colors.green,
    borderRadius: 18,
    paddingVertical: 18,
    alignItems: "center",
    marginTop: 4,
  },
  copyText: {
    color: "#00140D",
    fontSize: 16,
    fontWeight: "900",
  },
  footer: {
    marginTop: 16,
    padding: 14,
    borderRadius: 16,
    backgroundColor: "rgba(0,208,132,0.08)",
    borderColor: "rgba(0,208,132,0.35)",
    borderWidth: 1,
  },
  footerText: {
    color: colors.muted,
    fontSize: 13,
    lineHeight: 20,
  },
});
