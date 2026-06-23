import React, { useMemo } from "react";
import { StyleSheet, Text, View } from "react-native";
import {
  evaluateMaoriProtocolForScreen,
  getMaoriProtocolBackupSummary,
} from "../maurimesh/protocols";

const C = {
  panel: "rgba(2,12,8,0.92)",
  border: "rgba(0,208,132,0.32)",
  green: "#00D084",
  emerald: "#10B981",
  white: "#FFFFFF",
  muted: "rgba(255,255,255,0.72)",
  warn: "#F59E0B",
  danger: "#FB7185",
  blue: "#38BDF8",
};

export function MaoriProtocolPanel({
  screen,
  compact = false,
}: {
  screen: string;
  compact?: boolean;
}) {
  const decision = useMemo(() => evaluateMaoriProtocolForScreen(screen), [screen]);
  const backup = useMemo(() => getMaoriProtocolBackupSummary(), []);

  const actionColor =
    decision.action === "APPROVED"
      ? C.green
      : decision.action === "REVIEW_REQUIRED" || decision.action === "REFUSED"
        ? C.danger
        : C.warn;

  return (
    <View style={styles.panel}>
      <View style={styles.row}>
        <View style={styles.pill}>
          <Text style={styles.pillText}>TE REO / TIKANGA</Text>
        </View>
        <View style={[styles.pill, { borderColor: actionColor }]}>
          <Text style={[styles.pillText, { color: actionColor }]}>{decision.action}</Text>
        </View>
      </View>

      <Text style={styles.title}>Kawa Māori / Māori Protocol</Text>
      <Text style={styles.reo}>{decision.reoSummary}</Text>
      <Text style={styles.english}>{decision.englishSummary}</Text>

      {!compact && (
        <>
          <View style={styles.divider} />

          {decision.terms.map((term) => (
            <View key={term.id} style={styles.term}>
              <Text style={styles.termReo}>{term.reo}</Text>
              <Text style={styles.termEnglish}>{term.english}</Text>
              <Text style={styles.termMeaning}>{term.engineeringMeaning}</Text>
              <Text style={styles.proofLabel}>{term.proofLabel}</Text>
            </View>
          ))}

          <View style={styles.divider} />

          <Text style={styles.meta}>Source: {decision.source}</Text>
          <Text style={styles.meta}>Risk: {decision.risk}</Text>
          <Text style={styles.meta}>Backup status: {backup.status}</Text>
          <Text style={styles.meta}>
            Terms: {backup.totalTerms} total · {backup.primaryTerms} primary · {backup.backupTerms} backup ·{" "}
            {backup.fallbackTerms} fallback
          </Text>

          {decision.warnings.map((warning) => (
            <Text key={warning} style={styles.warning}>
              {warning}
            </Text>
          ))}

          <Text style={styles.truth}>{decision.truthBoundary}</Text>
        </>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  panel: {
    borderWidth: 1,
    borderColor: C.border,
    borderRadius: 22,
    backgroundColor: C.panel,
    padding: 15,
    gap: 9,
    marginVertical: 8,
  },
  row: { flexDirection: "row", flexWrap: "wrap", gap: 8 },
  pill: {
    alignSelf: "flex-start",
    borderWidth: 1,
    borderColor: C.green,
    borderRadius: 999,
    paddingVertical: 4,
    paddingHorizontal: 9,
    backgroundColor: "rgba(255,255,255,0.05)",
  },
  pillText: { color: C.green, fontSize: 10, fontWeight: "900", letterSpacing: 0.7 },
  title: { color: C.white, fontSize: 20, fontWeight: "900" },
  reo: { color: C.emerald, fontSize: 14, lineHeight: 21, fontWeight: "800" },
  english: { color: C.muted, fontSize: 13, lineHeight: 20 },
  divider: { height: 1, backgroundColor: "rgba(255,255,255,0.08)", marginVertical: 4 },
  term: {
    borderTopWidth: 1,
    borderTopColor: "rgba(255,255,255,0.06)",
    paddingTop: 8,
    gap: 2,
  },
  termReo: { color: C.green, fontSize: 15, fontWeight: "900" },
  termEnglish: { color: C.white, fontSize: 13, fontWeight: "700" },
  termMeaning: { color: C.muted, fontSize: 12, lineHeight: 18 },
  proofLabel: {
    color: C.blue,
    fontSize: 11,
    fontFamily: "monospace",
    marginTop: 2,
  },
  meta: { color: C.muted, fontSize: 12 },
  warning: { color: C.warn, fontSize: 12, lineHeight: 18 },
  truth: { color: C.muted, fontSize: 12, lineHeight: 18 },
});
