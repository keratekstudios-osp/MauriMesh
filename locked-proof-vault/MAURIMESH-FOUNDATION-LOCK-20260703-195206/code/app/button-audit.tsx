import { useRouter } from "expo-router";
import React, { useState } from "react";
import {
  Alert,
  Platform,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from "react-native";
import { MAURIMESH_AUDIT_ROUTES } from "../src/maurimesh/audit/buttonAuditRegistry";
import { SafeButton } from "../src/components/SafeButton";

type AuditResult = {
  auditId: string;
  title: string;
  route: string;
  status: "NOT_TESTED" | "OPEN_ATTEMPTED" | "PASS_MARKED" | "FAIL_MARKED";
  note: string;
  timestamp?: string;
};

const BUILD_MARKER = "BUTTON_AUDIT_FALLBACK_20260612";

function riskColor(risk: string) {
  if (risk === "HIGH") return "#EF4444";
  if (risk === "MEDIUM") return "#F59E0B";
  return "#22C55E";
}

export default function ButtonAuditScreen() {
  const router = useRouter();
  const [results, setResults] = useState<Record<string, AuditResult>>({});

  function updateResult(routeAuditId: string, partial: Partial<AuditResult>) {
    const route = MAURIMESH_AUDIT_ROUTES.find((item) => item.auditId === routeAuditId);

    if (!route) return;

    setResults((prev) => ({
      ...prev,
      [routeAuditId]: {
        auditId: route.auditId,
        title: route.title,
        route: route.route,
        status: "NOT_TESTED",
        note: "",
        ...prev[routeAuditId],
        ...partial,
        timestamp: new Date().toISOString(),
      },
    }));
  }

  function openRoute(route: string, auditId: string, title: string) {
    console.log(`MAURIMESH_BUTTON_AUDIT | ROUTE_OPEN_ATTEMPT | ${auditId} | ${route}`);

    updateResult(auditId, {
      status: "OPEN_ATTEMPTED",
      note: `Opened route attempt: ${route}`,
    });

    try {
      router.push(route as never);
      console.log(`MAURIMESH_BUTTON_AUDIT | ROUTE_PUSH_OK | ${auditId} | ${route}`);
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      console.log(`MAURIMESH_BUTTON_AUDIT | ROUTE_PUSH_ERROR | ${auditId} | ${message}`);

      updateResult(auditId, {
        status: "FAIL_MARKED",
        note: message,
      });

      Alert.alert("Route fallback", `${title} could not open safely.\n\n${message}`);
    }
  }

  function mark(auditId: string, status: "PASS_MARKED" | "FAIL_MARKED") {
    updateResult(auditId, {
      status,
      note: status === "PASS_MARKED" ? "Operator marked PASS." : "Operator marked FAIL.",
    });

    console.log(`MAURIMESH_BUTTON_AUDIT | ${status} | ${auditId}`);
  }

  function buildReport() {
    const lines = [
      "MAURIMESH FULL BUTTON AUDIT REPORT",
      "",
      `Build marker: ${BUILD_MARKER}`,
      `Generated: ${new Date().toISOString()}`,
      "",
      "Routes:",
      ...MAURIMESH_AUDIT_ROUTES.map((route) => {
        const result = results[route.auditId];
        return [
          `- ${route.title}`,
          `  route: ${route.route}`,
          `  auditId: ${route.auditId}`,
          `  risk: ${route.risk}`,
          `  expected: ${route.expected}`,
          `  status: ${result?.status || "NOT_TESTED"}`,
          `  note: ${result?.note || ""}`,
          `  timestamp: ${result?.timestamp || ""}`,
        ].join("\n");
      }),
      "",
      "Crash fallback rule:",
      "Any route/button that fails must be patched before final proof APK.",
    ];

    return lines.join("\n");
  }

  function copyReport() {
    const report = buildReport();

    if (Platform.OS === "web" && typeof navigator !== "undefined" && navigator.clipboard) {
      navigator.clipboard.writeText(report);
      Alert.alert("Audit report copied");
      return;
    }

    console.log(report);
    Alert.alert("Audit report printed", "Report printed to logcat/console.");
  }

  function resetAudit() {
    setResults({});
    console.log("MAURIMESH_BUTTON_AUDIT | RESET");
  }

  return (
    <ScrollView style={styles.screen} contentContainerStyle={styles.content}>
      <Text style={styles.kicker}>MAURIMESH SAFETY</Text>
      <Text style={styles.title}>Full Button Audit</Text>
      <Text style={styles.marker}>{BUILD_MARKER}</Text>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Purpose</Text>
        <Text style={styles.body}>
          Test every important route before proof work. If a screen crashes, mark FAIL and patch it before final APK proof.
        </Text>
      </View>

      {MAURIMESH_AUDIT_ROUTES.map((item) => {
        const result = results[item.auditId];
        const color = riskColor(item.risk);

        return (
          <View key={item.auditId} style={[styles.auditCard, { borderColor: color }]}>
            <View style={styles.row}>
              <Text style={styles.auditTitle}>{item.title}</Text>
              <Text style={[styles.risk, { color }]}>{item.risk}</Text>
            </View>

            <Text style={styles.route}>{item.route}</Text>
            <Text style={styles.body}>{item.expected}</Text>
            <Text style={styles.status}>
              Status: {result?.status || "NOT_TESTED"}
            </Text>

            <SafeButton
              title={`Open ${item.title}`}
              auditId={`open_${item.auditId}`}
              variant={item.risk === "HIGH" ? "warning" : "primary"}
              onPress={() => openRoute(item.route, item.auditId, item.title)}
            />

            <View style={styles.row}>
              <TouchableOpacity
                style={styles.passButton}
                onPress={() => mark(item.auditId, "PASS_MARKED")}
              >
                <Text style={styles.buttonText}>Mark PASS</Text>
              </TouchableOpacity>

              <TouchableOpacity
                style={styles.failButton}
                onPress={() => mark(item.auditId, "FAIL_MARKED")}
              >
                <Text style={styles.buttonText}>Mark FAIL</Text>
              </TouchableOpacity>
            </View>
          </View>
        );
      })}

      <SafeButton
        title="Copy Full Button Audit Report"
        auditId="copy_full_button_audit_report"
        onPress={copyReport}
      />

      <SafeButton
        title="Reset Audit"
        auditId="reset_button_audit"
        variant="danger"
        onPress={resetAudit}
      />
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: "#020403" },
  content: { padding: 18, paddingBottom: 48, gap: 14 },
  kicker: { color: "#F59E0B", fontWeight: "900", letterSpacing: 2, fontSize: 12 },
  title: { color: "white", fontSize: 32, fontWeight: "900" },
  marker: { color: "#F59E0B", fontSize: 11, fontWeight: "900" },
  card: {
    borderWidth: 1,
    borderColor: "rgba(245,158,11,0.45)",
    backgroundColor: "rgba(245,158,11,0.12)",
    borderRadius: 22,
    padding: 16,
    gap: 8,
  },
  cardTitle: { color: "white", fontSize: 18, fontWeight: "900" },
  body: { color: "rgba(255,255,255,0.78)", lineHeight: 21 },
  auditCard: {
    borderWidth: 1,
    backgroundColor: "rgba(0,20,12,0.88)",
    borderRadius: 22,
    padding: 16,
    gap: 10,
  },
  row: { flexDirection: "row", gap: 10, alignItems: "center" },
  auditTitle: { flex: 1, color: "white", fontSize: 18, fontWeight: "900" },
  risk: { fontSize: 11, fontWeight: "900", letterSpacing: 1 },
  route: { color: "#38BDF8", fontWeight: "900" },
  status: { color: "#00D084", fontWeight: "900" },
  passButton: {
    flex: 1,
    minHeight: 44,
    borderRadius: 14,
    backgroundColor: "#22C55E",
    alignItems: "center",
    justifyContent: "center",
  },
  failButton: {
    flex: 1,
    minHeight: 44,
    borderRadius: 14,
    backgroundColor: "#EF4444",
    alignItems: "center",
    justifyContent: "center",
  },
  buttonText: { color: "white", fontWeight: "900" },
});
