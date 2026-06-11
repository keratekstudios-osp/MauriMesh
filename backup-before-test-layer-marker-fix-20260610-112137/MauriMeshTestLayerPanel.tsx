import React, { useMemo, useState } from "react";
import {
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from "react-native";
import {
  createThreeHopBleManualProofInstructions,
  createOneRealDeviceApkProofInstructions,
  REQUIRED_ROUTES,
  runMauriMeshFullAppTest,
  type MauriMeshFullTestReport,
} from "../maurimesh/test-layer";

const C = {
  bg: "#020403",
  panel: "rgba(2,12,8,0.92)",
  border: "rgba(34,197,94,0.32)",
  green: "#00D084",
  emerald: "#10B981",
  white: "#FFFFFF",
  muted: "rgba(255,255,255,0.72)",
  warn: "#F59E0B",
  danger: "#EF4444",
  blue: "#38BDF8",
};

function Pill({ label, tone }: { label: string; tone: "pass" | "warn" | "fail" | "info" }) {
  const color =
    tone === "pass" ? C.green : tone === "warn" ? C.warn : tone === "fail" ? C.danger : C.blue;

  return (
    <View style={[styles.pill, { borderColor: color }]}>
      <Text style={[styles.pillText, { color }]}>{label}</Text>
    </View>
  );
}

export function MauriMeshTestLayerPanel() {
  const [report, setReport] = useState<MauriMeshFullTestReport | null>(null);

  const proofInstructions = useMemo(
    () => createThreeHopBleManualProofInstructions(),
    [],
  );

  const oneDeviceInstructions = useMemo(
    () => createOneRealDeviceApkProofInstructions(),
    [],
  );

  const runTest = () => {
    setReport(runMauriMeshFullAppTest());
  };

  const statusTone =
    report?.status === "PASSED"
      ? "pass"
      : report?.status === "FAILED"
        ? "fail"
        : "warn";

  return (
    <ScrollView style={styles.root} contentContainerStyle={styles.content}>
      <View style={styles.header}>
        <Pill label="MAURIMESH TEST LAYER" tone="info" />
        <Text style={styles.title}>Full App Test</Text>
        <Text style={styles.subtitle}>
          One button checks app process, UI routes, messaging lifecycle, ACK proof rules,
          3-hop BLE proof requirements, Pixel Calling fallback, AI pixel reconstruction,
          and truth boundaries.
        </Text>
      </View>

      <Pressable onPress={runTest} style={({ pressed }) => [styles.button, pressed && styles.pressed]}>
        <Text style={styles.buttonText}>RUN FULL MAURIMESH TEST</Text>
      </Pressable>

      <Pressable onPress={runTest} style={({ pressed }) => [styles.buttonSecondary, pressed && styles.pressed]}>
        <Text style={styles.buttonSecondaryText}>RUN ONE REAL DEVICE APK TEST</Text>
      </Pressable>

      {report ? (
        <View style={styles.panel}>
          <Pill label={report.status} tone={statusTone} />
          <Text style={styles.resultTitle}>{report.finalReply}</Text>

          <View style={styles.metrics}>
            <View style={styles.metric}>
              <Text style={styles.metricValue}>{report.score}%</Text>
              <Text style={styles.metricLabel}>Score</Text>
            </View>
            <View style={styles.metric}>
              <Text style={styles.metricValue}>{report.passed}</Text>
              <Text style={styles.metricLabel}>Passed</Text>
            </View>
            <View style={styles.metric}>
              <Text style={[styles.metricValue, { color: C.warn }]}>{report.warnings}</Text>
              <Text style={styles.metricLabel}>Warnings</Text>
            </View>
            <View style={styles.metric}>
              <Text style={[styles.metricValue, { color: report.failed ? C.danger : C.green }]}>
                {report.failed}
              </Text>
              <Text style={styles.metricLabel}>Failed</Text>
            </View>
          </View>

          <Text style={styles.truth}>{report.realDeviceTruth}</Text>
        </View>
      ) : (
        <View style={styles.panel}>
          <Pill label="READY" tone="info" />
          <Text style={styles.resultTitle}>Press the button to run the full MauriMesh test.</Text>
          <Text style={styles.truth}>
            This returns PASS/WARN/FAIL inside the app. Real BLE proof still requires APK/logcat.
          </Text>
        </View>
      )}

      {report ? (
        <View style={styles.panel}>
          <Text style={styles.sectionTitle}>Test Steps</Text>
          {report.steps.map((s) => (
            <View key={s.id} style={styles.step}>
              <Pill
                label={s.severity}
                tone={s.severity === "PASS" ? "pass" : s.severity === "WARN" ? "warn" : "fail"}
              />
              <Text style={styles.stepTitle}>{s.label}</Text>
              <Text style={styles.stepDetail}>{s.detail}</Text>
              <Text style={styles.proofTag}>
                {s.proofTag}
                {s.proofRequired ? " · PROOF REQUIRED" : " · PROCESS CHECK"}
              </Text>
            </View>
          ))}
        </View>
      ) : null}

      <View style={styles.panel}>
        <Text style={styles.sectionTitle}>One Real Device APK Test</Text>
        <Text style={styles.truth}>
          After APK build and install, this confirms the app works correctly on one real Android device:
          launch, no crash, route loading, permissions, native telemetry state, Bluetooth readiness,
          messaging process, Pixel Calling fallback, and AI reconstruction proof labels.
        </Text>
        {oneDeviceInstructions.map((item, index) => (
          <Text key={item} style={styles.listItem}>
            {index + 1}. {item}
          </Text>
        ))}
      </View>

      <View style={styles.panel}>
        <Text style={styles.sectionTitle}>3-Hop BLE Proof Path</Text>
        {proofInstructions.map((item, index) => (
          <Text key={item} style={styles.listItem}>
            {index + 1}. {item}
          </Text>
        ))}
      </View>

      <View style={styles.panel}>
        <Text style={styles.sectionTitle}>Routes Expected</Text>
        {REQUIRED_ROUTES.map((route) => (
          <Text key={route} style={styles.routeItem}>
            {route}
          </Text>
        ))}
      </View>

      <View style={styles.panel}>
        <Text style={styles.sectionTitle}>Final Truth</Text>
        <Text style={styles.truth}>
          This layer tests every known app pathway and the correct beginning-to-end
          message proof process. It does not fake real BLE. Real pass requires physical
          phones, APK install, permissions, Bluetooth ON, and logcat proof.
        </Text>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: C.bg },
  content: { padding: 18, gap: 14, paddingBottom: 42 },
  header: { gap: 10 },
  title: { color: C.white, fontSize: 36, fontWeight: "900", letterSpacing: -1 },
  subtitle: { color: C.muted, fontSize: 15, lineHeight: 22 },
  button: {
    minHeight: 58,
    borderRadius: 22,
    backgroundColor: C.green,
    alignItems: "center",
    justifyContent: "center",
    paddingHorizontal: 18,
  },
  pressed: { opacity: 0.72, transform: [{ scale: 0.98 }] },
  buttonText: { color: "#00150D", fontSize: 16, fontWeight: "900", letterSpacing: 0.6 },
  panel: {
    borderWidth: 1,
    borderColor: C.border,
    borderRadius: 24,
    backgroundColor: C.panel,
    padding: 16,
    gap: 12,
  },
  pill: {
    alignSelf: "flex-start",
    borderWidth: 1,
    borderRadius: 999,
    paddingVertical: 5,
    paddingHorizontal: 10,
    backgroundColor: "rgba(255,255,255,0.05)",
  },
  pillText: { fontSize: 11, fontWeight: "900", letterSpacing: 0.7 },
  resultTitle: { color: C.white, fontSize: 19, fontWeight: "900", lineHeight: 25 },
  metrics: { flexDirection: "row", flexWrap: "wrap", gap: 10 },
  metric: {
    minWidth: "45%",
    flex: 1,
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.10)",
    borderRadius: 18,
    padding: 12,
    backgroundColor: "rgba(255,255,255,0.04)",
  },
  metricValue: { color: C.green, fontSize: 24, fontWeight: "900" },
  metricLabel: { color: C.muted, fontSize: 12, fontWeight: "700" },
  truth: { color: C.muted, fontSize: 14, lineHeight: 21 },
  sectionTitle: { color: C.white, fontSize: 21, fontWeight: "900" },
  step: {
    borderTopWidth: 1,
    borderTopColor: "rgba(255,255,255,0.08)",
    paddingTop: 12,
    gap: 7,
  },
  stepTitle: { color: C.white, fontSize: 16, fontWeight: "900" },
  stepDetail: { color: C.muted, fontSize: 13, lineHeight: 19 },
  proofTag: { color: C.emerald, fontSize: 11, fontWeight: "900", letterSpacing: 0.4 },
  listItem: { color: C.muted, fontSize: 13, lineHeight: 20 },
  routeItem: { color: C.blue, fontSize: 13, fontWeight: "800", paddingVertical: 2 },
});
