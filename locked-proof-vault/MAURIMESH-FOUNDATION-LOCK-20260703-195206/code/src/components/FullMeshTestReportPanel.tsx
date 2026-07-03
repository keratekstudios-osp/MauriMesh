import React, { useMemo, useState } from "react";
import {
  Alert,
  Platform,
  Pressable,
  ScrollView,
  Share,
  StyleSheet,
  Text,
  TextInput,
  View,
} from "react-native";
import { runFullMeshTestReport } from "../maurimesh/full-mesh-test";
import { MaoriProtocolPanel } from "./MaoriProtocolPanel";

const C = {
  bg: "#020403",
  panel: "rgba(2,12,8,0.92)",
  panel2: "rgba(1,8,5,0.94)",
  border: "rgba(0,208,132,0.32)",
  green: "#00D084",
  emerald: "#10B981",
  blue: "#38BDF8",
  white: "#FFFFFF",
  muted: "rgba(255,255,255,0.72)",
  warn: "#F59E0B",
  danger: "#FB7185",
};

function Pill({ label, color = C.green }: { label: string; color?: string }) {
  return (
    <View style={[styles.pill, { borderColor: color }]}>
      <Text style={[styles.pillText, { color }]}>{label}</Text>
    </View>
  );
}

function Button({
  title,
  onPress,
}: {
  title: string;
  onPress: () => void;
}) {
  return (
    <Pressable onPress={onPress} style={styles.button}>
      <Text style={styles.buttonText}>{title}</Text>
    </Pressable>
  );
}

export function FullMeshTestReportPanel() {
  const initialReport = useMemo(() => runFullMeshTestReport(), []);
  const [report, setReport] = useState(initialReport);

  const rerun = () => {
    setReport(runFullMeshTestReport());
  };

  const shareReport = async () => {
    try {
      await Share.share({
        title: "MauriMesh Full Mesh Test Report",
        message: report.copyBlock,
      });
    } catch (error) {
      Alert.alert(
        "Share unavailable",
        "Use the report box below. Long press inside it, select all, then copy.",
      );
    }
  };

  const copyFallback = () => {
    Alert.alert(
      "Copy report",
      Platform.OS === "android"
        ? "Long press inside the report box below, choose Select all, then Copy. Or press Share Report."
        : "Long press inside the report box below, choose Select all, then Copy. Or press Share Report.",
    );
  };

  const scoreColor =
    report.score >= 90 ? C.green : report.score >= 70 ? C.warn : C.danger;

  return (
    <ScrollView style={styles.root} contentContainerStyle={styles.content}>
      <View style={styles.header}>
        <Pill label="FULL MESH TEST" color={C.blue} />
        <Text style={styles.title}>Full Mesh Test Report</Text>
        <Text style={styles.subtitle}>
          One in-APK report for full app activity, mesh proof gates, route inventory,
          Māori protocol, JumpCode, Evolution, ACK, relay, native telemetry, and final truth.
        </Text>
      </View>

      <View style={styles.panel}>
        <View style={styles.row}>
          <Pill label={`${report.score}%`} color={scoreColor} />
          <Pill label={`PASS ${report.passCount}`} />
          <Pill label={`WARN ${report.warnCount}`} color={C.warn} />
          <Pill label={`FAIL ${report.failCount}`} color={report.failCount > 0 ? C.danger : C.green} />
        </View>

        <Text style={styles.sectionTitle}>Report Summary</Text>
        <Text style={styles.line}>Generated: {report.generatedAt}</Text>
        <Text style={styles.line}>Mode: {report.appMode}</Text>
        <Text style={styles.line}>Routes: {report.routeInventory.present}/{report.routeInventory.total} present</Text>
        <Text style={styles.line}>Required routes missing: {report.routeInventory.requiredMissing}</Text>
        <Text style={styles.truth}>{report.finalTruth}</Text>

        <View style={styles.buttonRow}>
          <Button title="Run Full Mesh Test" onPress={rerun} />
          <Button title="Share Report" onPress={shareReport} />
          <Button title="Copy Help" onPress={copyFallback} />
        </View>
      </View>

      <MaoriProtocolPanel screen="Full Mesh Test Report" compact />

      <View style={styles.panel}>
        <Text style={styles.sectionTitle}>Checks</Text>
        {report.checks.map((item, index) => {
          const color =
            item.status === "PASS"
              ? C.green
              : item.status === "WARN" || item.status === "APK_REQUIRED" || item.status === "NATIVE_REQUIRED"
                ? C.warn
                : C.danger;

          return (
            <View key={item.id} style={styles.check}>
              <Text style={[styles.checkTitle, { color }]}>
                {index + 1}. [{item.status}] {item.title}
              </Text>
              <Text style={styles.line}>{item.detail}</Text>
              {item.proofRequired.map((proof) => (
                <Text key={proof} style={styles.bullet}>• {proof}</Text>
              ))}
            </View>
          );
        })}
      </View>

      <View style={styles.panel}>
        <Text style={styles.sectionTitle}>Copyable Full Report Block</Text>
        <Text style={styles.line}>
          Long press in the box, select all, copy. You can paste this whole block back into ChatGPT.
        </Text>
        <TextInput
          value={report.copyBlock}
          multiline
          editable={false}
          selectTextOnFocus
          style={styles.reportBox}
          textAlignVertical="top"
        />
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: C.bg },
  content: { padding: 18, gap: 14, paddingBottom: 42 },
  header: { gap: 10 },
  title: { color: C.white, fontSize: 34, fontWeight: "900", letterSpacing: -1 },
  subtitle: { color: C.muted, fontSize: 15, lineHeight: 22 },
  panel: {
    borderWidth: 1,
    borderColor: C.border,
    borderRadius: 24,
    backgroundColor: C.panel,
    padding: 16,
    gap: 10,
  },
  row: { flexDirection: "row", flexWrap: "wrap", gap: 8 },
  buttonRow: { flexDirection: "row", flexWrap: "wrap", gap: 10, marginTop: 6 },
  button: {
    backgroundColor: C.green,
    borderRadius: 16,
    paddingVertical: 11,
    paddingHorizontal: 14,
  },
  buttonText: { color: "#00150D", fontWeight: "900", fontSize: 13 },
  pill: {
    alignSelf: "flex-start",
    borderWidth: 1,
    borderRadius: 999,
    paddingVertical: 5,
    paddingHorizontal: 10,
    backgroundColor: "rgba(255,255,255,0.05)",
  },
  pillText: { fontSize: 11, fontWeight: "900", letterSpacing: 0.7 },
  sectionTitle: { color: C.white, fontSize: 21, fontWeight: "900" },
  line: { color: C.muted, fontSize: 13, lineHeight: 20 },
  bullet: { color: C.muted, fontSize: 12, lineHeight: 18 },
  truth: { color: C.warn, fontSize: 12, lineHeight: 18 },
  check: {
    borderTopWidth: 1,
    borderTopColor: "rgba(255,255,255,0.08)",
    paddingTop: 10,
    gap: 4,
  },
  checkTitle: { fontSize: 14, fontWeight: "900", lineHeight: 20 },
  reportBox: {
    minHeight: 420,
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.12)",
    borderRadius: 16,
    backgroundColor: C.panel2,
    color: C.white,
    padding: 12,
    fontSize: 11,
    lineHeight: 16,
    fontFamily: Platform.OS === "ios" ? "Menlo" : "monospace",
  },
});
