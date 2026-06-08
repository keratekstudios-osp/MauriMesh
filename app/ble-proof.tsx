import React from "react";
import {
  ActivityIndicator,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from "react-native";
import { proofEvents } from "../src/lib/proofSimulation";
import { apiPost } from "../src/lib/api";

const MARKER = "SAFE_BLE_PROOF_UI_20260607_A";

type SaveState =
  | { kind: "idle" }
  | { kind: "saving" }
  | { kind: "saved"; id: string }
  | { kind: "error"; message: string };

type SaveResponse = { ok: boolean; entry?: { id: string } };

// Build the evidence report submitted to the Proof Ledger. On a physical device
// this would carry the real two-phone run output; in this UI shell it carries
// the available proof report. Either way the server records it as unverified,
// client-submitted evidence — it does not prove live BLE.
function buildEvidence() {
  return {
    marker: MARKER,
    generatedAt: new Date().toISOString(),
    truthBoundary:
      "Client-submitted proof report. Not verified live BLE. Server storage does not prove BLE.",
    events: proofEvents,
  };
}

export default function BleProofScreen() {
  const [save, setSave] = React.useState<SaveState>({ kind: "idle" });

  const onSave = React.useCallback(async () => {
    setSave({ kind: "saving" });
    const res = await apiPost<SaveResponse>("/api/proof/evidence", {
      evidence: buildEvidence(),
    });
    if (res.ok && res.data.entry?.id) {
      setSave({ kind: "saved", id: res.data.entry.id });
    } else {
      setSave({
        kind: "error",
        message: res.ok ? "Unexpected server response." : res.error,
      });
    }
  }, []);

  return (
    <ScrollView style={styles.screen} contentContainerStyle={styles.content}>
      <Text style={styles.brand}>MauriMesh</Text>
      <Text style={styles.title}>BLE Proof UI</Text>
      <Text style={styles.marker}>{MARKER}</Text>

      <View style={styles.truthCard}>
        <Text style={styles.cardTitle}>Truth Boundary</Text>
        <Text style={styles.cardText}>
          This is a safe APK UI layer. It does not claim live BLE. Real BLE proof requires
          physical phones, permissions, native logs, TX/RX/ACK events, and two-phone validation.
        </Text>
      </View>

      {proofEvents.map((event) => (
        <View key={event.id} style={styles.card}>
          <Text style={styles.rowTitle}>{event.stage}</Text>
          <Text style={styles.status}>{event.status}</Text>
          <Text style={styles.cardText}>{event.detail}</Text>
        </View>
      ))}

      <TouchableOpacity
        style={[styles.saveButton, save.kind === "saving" && styles.saveButtonBusy]}
        onPress={onSave}
        disabled={save.kind === "saving"}
        accessibilityRole="button"
      >
        {save.kind === "saving" ? (
          <View style={styles.saveRow}>
            <ActivityIndicator color="#020617" />
            <Text style={styles.saveText}>Saving…</Text>
          </View>
        ) : (
          <Text style={styles.saveText}>Save to Proof Ledger</Text>
        )}
      </TouchableOpacity>

      <Text style={styles.saveHint}>
        Records this report on the server as client-submitted, unverified evidence.
        Server storage does not prove live BLE.
      </Text>

      {save.kind === "saved" && (
        <Text style={styles.savedText}>Saved to Proof Ledger (id {save.id}).</Text>
      )}
      {save.kind === "error" && (
        <Text style={styles.errorText}>Could not save: {save.message}</Text>
      )}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: "#020617" },
  content: { padding: 24, paddingTop: 72 },
  brand: { color: "#00D084", fontSize: 38, fontWeight: "900", marginBottom: 8 },
  title: { color: "#FFFFFF", fontSize: 28, fontWeight: "900", marginBottom: 8 },
  marker: { color: "#38BDF8", fontSize: 12, fontWeight: "800", marginBottom: 20 },
  truthCard: {
    backgroundColor: "rgba(245,158,11,0.10)",
    borderColor: "rgba(245,158,11,0.45)",
    borderWidth: 1,
    borderRadius: 22,
    padding: 18,
    marginBottom: 16,
  },
  card: {
    backgroundColor: "rgba(255,255,255,0.06)",
    borderColor: "rgba(0,208,132,0.28)",
    borderWidth: 1,
    borderRadius: 22,
    padding: 18,
    marginBottom: 14,
  },
  cardTitle: { color: "#FFFFFF", fontSize: 18, fontWeight: "900", marginBottom: 10 },
  rowTitle: { color: "#FFFFFF", fontSize: 18, fontWeight: "900", marginBottom: 6 },
  status: { color: "#00D084", fontSize: 13, fontWeight: "900", marginBottom: 8 },
  cardText: { color: "rgba(255,255,255,0.76)", fontSize: 14, lineHeight: 22 },
  saveButton: {
    backgroundColor: "#00D084",
    borderRadius: 18,
    paddingVertical: 16,
    alignItems: "center",
    marginTop: 8,
  },
  saveButtonBusy: { opacity: 0.7 },
  saveRow: { flexDirection: "row", alignItems: "center", gap: 10 },
  saveText: { color: "#020617", fontSize: 16, fontWeight: "900" },
  saveHint: {
    color: "rgba(255,255,255,0.6)",
    fontSize: 12,
    lineHeight: 18,
    marginTop: 10,
  },
  savedText: { color: "#00D084", fontSize: 14, fontWeight: "900", marginTop: 12 },
  errorText: { color: "#F87171", fontSize: 14, fontWeight: "900", marginTop: 12 },
});
