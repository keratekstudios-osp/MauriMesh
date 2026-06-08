import React from "react";
import { ActivityIndicator, ScrollView, StyleSheet, Text, View } from "react-native";
import { proofEvents } from "../src/lib/proofSimulation";
import { apiGet } from "../src/lib/api";

const MARKER = "SAFE_PROOF_LEDGER_20260607_A";
const HARDWARE_EVIDENCE_TYPE = "two_phone_hardware_evidence";

type LedgerEntry = {
  id: string;
  eventType: string;
  runtimeMode: string;
  source: string;
  verified: boolean;
  deviceId: string | null;
  peerId: string | null;
  rawLogExcerpt: string | null;
  ts: string;
};

type EvidenceResponse = { ok: boolean; entries: LedgerEntry[] };

function prettyEvidence(raw: string | null): string {
  if (!raw) return "(no evidence body)";
  try {
    return JSON.stringify(JSON.parse(raw), null, 2);
  } catch {
    return raw;
  }
}

const TASK_189B_PROOF_LEDGER_HARDWARE_VIEW = "TASK_189B_PROOF_LEDGER_HARDWARE_VIEW_20260608_A";

export default function ProofLedgerScreen() {
  const [entries, setEntries] = React.useState<LedgerEntry[]>([]);
  const [status, setStatus] = React.useState<"loading" | "ready" | "unavailable">(
    "loading",
  );
  const [error, setError] = React.useState<string | null>(null);

  React.useEffect(() => {
    let active = true;
    (async () => {
      const res = await apiGet<EvidenceResponse>(
        `/api/proof/evidence?type=${HARDWARE_EVIDENCE_TYPE}`,
      );
      if (!active) return;
      if (res.ok) {
        setEntries(res.data.entries ?? []);
        setStatus("ready");
      } else {
        setError(res.error);
        setStatus("unavailable");
      }
    })();
    return () => {
      active = false;
    };
  }, []);

  return (
    <ScrollView style={styles.screen} contentContainerStyle={styles.content}>
      <Text style={styles.brand}>MauriMesh</Text>
      <Text style={styles.title}>Proof Ledger</Text>
      <Text style={styles.marker}>{MARKER}</Text>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Current Verified State</Text>
        <Text style={styles.cardText}>APK shell: PASS</Text>
        <Text style={styles.cardText}>Package identity: com.maurimesh.messenger</Text>
        <Text style={styles.cardText}>RootLayout crash: isolated and bypassed</Text>
        <Text style={styles.cardText}>Safe UI shell: PASS</Text>
      </View>

      <Text style={styles.sectionTitle}>Build / Runtime Simulation</Text>
      {proofEvents.map((event, index) => (
        <View key={event.id} style={styles.ledgerRow}>
          <Text style={styles.index}>{String(index + 1).padStart(2, "0")}</Text>
          <View style={styles.rowBody}>
            <Text style={styles.rowTitle}>{event.stage}</Text>
            <Text style={styles.rowText}>{event.detail}</Text>
            <Text style={styles.rowStatus}>{event.status}</Text>
          </View>
        </View>
      ))}

      <Text style={styles.sectionTitle}>Hardware Evidence (server-recorded)</Text>
      <View style={styles.truthCard}>
        <Text style={styles.truthText}>
          These entries are two-phone proof reports submitted from a device and
          permanently recorded on the server. Server storage does not itself prove
          live BLE — entries are client-submitted and unverified.
        </Text>
      </View>

      {status === "loading" && (
        <View style={styles.stateRow}>
          <ActivityIndicator color="#00D084" />
          <Text style={styles.stateText}>Loading recorded evidence…</Text>
        </View>
      )}

      {status === "unavailable" && (
        <Text style={styles.stateText}>
          Recorded evidence unavailable: {error ?? "mesh API not configured"}.
        </Text>
      )}

      {status === "ready" && entries.length === 0 && (
        <Text style={styles.stateText}>
          No hardware evidence recorded yet. Run a two-phone proof and save it to
          the ledger.
        </Text>
      )}

      {status === "ready" &&
        entries.map((entry) => (
          <View key={entry.id} style={styles.evidenceCard}>
            <Text style={styles.evidenceTs}>{entry.ts}</Text>
            <Text style={styles.evidenceMeta}>
              {entry.source} · {entry.runtimeMode} ·{" "}
              {entry.verified ? "verified" : "unverified"}
            </Text>
            {(entry.deviceId || entry.peerId) && (
              <Text style={styles.evidenceMeta}>
                {entry.deviceId ?? "?"} ↔ {entry.peerId ?? "?"}
              </Text>
            )}
            <Text style={styles.evidenceJson}>{prettyEvidence(entry.rawLogExcerpt)}</Text>
          </View>
        ))}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: "#020617" },
  content: { padding: 24, paddingTop: 72 },
  brand: { color: "#00D084", fontSize: 38, fontWeight: "900", marginBottom: 8 },
  title: { color: "#FFFFFF", fontSize: 28, fontWeight: "900", marginBottom: 8 },
  marker: { color: "#38BDF8", fontSize: 12, fontWeight: "800", marginBottom: 20 },
  sectionTitle: {
    color: "#FFFFFF",
    fontSize: 18,
    fontWeight: "900",
    marginTop: 8,
    marginBottom: 12,
  },
  card: {
    backgroundColor: "rgba(255,255,255,0.06)",
    borderColor: "rgba(0,208,132,0.28)",
    borderWidth: 1,
    borderRadius: 22,
    padding: 18,
    marginBottom: 18,
  },
  cardTitle: { color: "#FFFFFF", fontSize: 18, fontWeight: "900", marginBottom: 10 },
  cardText: { color: "rgba(255,255,255,0.76)", fontSize: 14, lineHeight: 22 },
  ledgerRow: {
    flexDirection: "row",
    gap: 14,
    backgroundColor: "rgba(255,255,255,0.05)",
    borderColor: "rgba(0,208,132,0.22)",
    borderWidth: 1,
    borderRadius: 18,
    padding: 16,
    marginBottom: 12,
  },
  index: { color: "#38BDF8", fontSize: 14, fontWeight: "900", width: 30 },
  rowBody: { flex: 1 },
  rowTitle: { color: "#FFFFFF", fontSize: 16, fontWeight: "900", marginBottom: 6 },
  rowText: { color: "rgba(255,255,255,0.72)", fontSize: 14, lineHeight: 21 },
  rowStatus: { color: "#00D084", fontSize: 12, fontWeight: "900", marginTop: 8 },
  truthCard: {
    backgroundColor: "rgba(245,158,11,0.10)",
    borderColor: "rgba(245,158,11,0.45)",
    borderWidth: 1,
    borderRadius: 18,
    padding: 16,
    marginBottom: 14,
  },
  truthText: { color: "rgba(255,255,255,0.82)", fontSize: 13, lineHeight: 20 },
  stateRow: { flexDirection: "row", alignItems: "center", gap: 10, marginBottom: 12 },
  stateText: {
    color: "rgba(255,255,255,0.62)",
    fontSize: 13,
    lineHeight: 20,
    marginBottom: 12,
  },
  evidenceCard: {
    backgroundColor: "rgba(255,255,255,0.05)",
    borderColor: "rgba(56,189,248,0.30)",
    borderWidth: 1,
    borderRadius: 18,
    padding: 16,
    marginBottom: 12,
  },
  evidenceTs: { color: "#38BDF8", fontSize: 13, fontWeight: "900", marginBottom: 4 },
  evidenceMeta: { color: "rgba(255,255,255,0.66)", fontSize: 12, marginBottom: 4 },
  evidenceJson: {
    color: "rgba(255,255,255,0.82)",
    fontSize: 12,
    fontFamily: "monospace",
    marginTop: 6,
  },
});
