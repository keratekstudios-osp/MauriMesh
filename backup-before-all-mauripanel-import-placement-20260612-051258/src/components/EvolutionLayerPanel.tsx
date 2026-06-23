import React, { useMemo } from "react";
import { ScrollView, StyleSheet, Text, View } from "react-native";
import { MaoriProtocolPanel } from "./MaoriProtocolPanel";
import {
  evaluateEvolutionReport,
  evaluateBackupEvolutionReport,
  evaluateSafeFallbackEvolutionReport,
} from "../maurimesh/evolution";

const C = {
  bg: "#020403",
  panel: "rgba(2,12,8,0.92)",
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

export function EvolutionLayerPanel() {
  const report = useMemo(() => evaluateEvolutionReport(), []);
  const backup = useMemo(() => evaluateBackupEvolutionReport(), []);
  const fallback = useMemo(() => evaluateSafeFallbackEvolutionReport(), []);

  const statusColor =
    report.status === "STABLE"
      ? C.green
      : report.status === "NEEDS_PROOF"
        ? C.warn
        : C.blue;

  return (
    <ScrollView style={styles.root} contentContainerStyle={styles.content}>
      <View style={styles.header}>
        <Pill label="MAURIMESH EVOLUTION LAYER" color={C.blue} />
        <Text style={styles.title}>Evolution Layer</Text>
        <Text style={styles.subtitle}>
          Controlled self-improvement for MauriMesh: observe, score, recommend,
          require proof, protect Tikanga, and preserve rollback. This layer does
          not silently mutate production code.
        </Text>
      </View>

      <MaoriProtocolPanel screen="Evolution Layer" />

      <View style={styles.panel}>
        <View style={styles.row}>
          <Pill label={report.status} color={statusColor} />
          <Pill label={`${report.score}% READINESS`} color={C.emerald} />
        </View>

        <Text style={styles.sectionTitle}>Runtime Decision</Text>
        <Text style={styles.line}>Source: {report.source}</Text>
        <Text style={styles.line}>Generated: {report.generatedAt}</Text>
        <Text style={styles.truth}>{report.truthBoundary}</Text>
      </View>

      <View style={styles.panel}>
        <Text style={styles.sectionTitle}>Evolution Signals</Text>
        {report.signals.map((signal) => (
          <View key={signal.id} style={styles.signal}>
            <Text style={styles.signalTitle}>
              {signal.passed ? "PASS" : "NEEDS PROOF"} · {signal.label}
            </Text>
            <Text style={styles.line}>Kind: {signal.kind}</Text>
            <Text style={styles.line}>Confidence: {Math.round(signal.confidence * 100)}%</Text>
            <Text style={styles.line}>{signal.evidence}</Text>
          </View>
        ))}
      </View>

      <View style={styles.panel}>
        <Text style={styles.sectionTitle}>Recommended Next Evolutions</Text>
        {report.proposals.map((proposal) => (
          <View key={proposal.id} style={styles.proposal}>
            <Text style={styles.proposalTitle}>{proposal.title}</Text>
            <Text style={styles.line}>Decision: {proposal.decision}</Text>
            <Text style={styles.line}>Risk: {proposal.risk}</Text>
            <Text style={styles.line}>Target: {proposal.targetLayer}</Text>
            <Text style={styles.body}>{proposal.summary}</Text>

            <Text style={styles.smallHeader}>Required proof</Text>
            {proposal.requiredProof.map((item) => (
              <Text key={item} style={styles.bullet}>• {item}</Text>
            ))}

            <Text style={styles.smallHeader}>Rollback plan</Text>
            {proposal.rollbackPlan.map((item) => (
              <Text key={item} style={styles.bullet}>• {item}</Text>
            ))}

            <Text style={styles.smallHeader}>Tikanga notes</Text>
            {proposal.tikangaNotes.map((item) => (
              <Text key={item} style={styles.tikanga}>• {item}</Text>
            ))}

            <Text style={styles.noAuto}>
              canAutoApply: false — operator approval required.
            </Text>
          </View>
        ))}
      </View>

      <View style={styles.panel}>
        <Text style={styles.sectionTitle}>Backup / Fallback Evolution</Text>
        <Text style={styles.line}>Backup source: {backup.source}</Text>
        <Text style={styles.line}>Backup score: {backup.score}%</Text>
        <Text style={styles.line}>Fallback source: {fallback.source}</Text>
        <Text style={styles.line}>Fallback score: {fallback.score}%</Text>
        <Text style={styles.truth}>
          If the primary evolution engine fails, MauriMesh keeps a conservative
          backup report and safe fallback recommendations. No autonomous APK,
          BLE, routing, governance, or Rust changes are applied.
        </Text>
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
  signal: {
    borderTopWidth: 1,
    borderTopColor: "rgba(255,255,255,0.08)",
    paddingTop: 10,
    gap: 4,
  },
  signalTitle: { color: C.green, fontSize: 14, fontWeight: "900" },
  proposal: {
    borderTopWidth: 1,
    borderTopColor: "rgba(255,255,255,0.08)",
    paddingTop: 12,
    gap: 6,
  },
  proposalTitle: { color: C.blue, fontSize: 18, fontWeight: "900" },
  line: { color: C.muted, fontSize: 13, lineHeight: 20 },
  body: { color: C.muted, fontSize: 14, lineHeight: 21 },
  smallHeader: { color: C.white, fontSize: 13, fontWeight: "900", marginTop: 4 },
  bullet: { color: C.muted, fontSize: 12, lineHeight: 18 },
  tikanga: { color: C.emerald, fontSize: 12, lineHeight: 18 },
  noAuto: { color: C.warn, fontSize: 12, fontWeight: "800" },
  truth: { color: C.warn, fontSize: 12, lineHeight: 18 },
});
