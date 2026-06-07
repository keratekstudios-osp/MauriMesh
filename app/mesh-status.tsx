import React, { useEffect, useState } from "react";
import { ScrollView, StyleSheet, Text, View } from "react-native";
import { getMeshStatus, MeshStatus } from "../src/lib/meshClient";
import {
  MeshGovernanceCounters,
  tickMeshGovernanceSim,
} from "../src/lib/meshGovernanceSim";

const MARKER = "API_FALLBACK_MESH_STATUS_20260607_A";

const GOVERNANCE_TICK_MS = 1500;

export default function MeshStatusScreen() {
  const [mesh, setMesh] = useState<MeshStatus | null>(null);
  const [governance, setGovernance] = useState<MeshGovernanceCounters | null>(
    null
  );
  const [governanceSource, setGovernanceSource] = useState<"live" | "local">(
    "local"
  );

  useEffect(() => {
    let alive = true;

    const poll = async () => {
      let status: MeshStatus;
      try {
        status = await getMeshStatus();
      } catch {
        status = {
          mode: "UNAVAILABLE",
          message: "Mesh status failed safely.",
          nodes: [],
          routes: [],
        };
      }
      if (!alive) return;

      setMesh(status);

      // Prefer the shared server-side counters when the live API supplies them
      // so every client shows the same activity; otherwise fall back to a local
      // simulation so the screen still moves in offline preview.
      if (status.governance) {
        setGovernance(status.governance);
        setGovernanceSource("live");
      } else {
        setGovernance(tickMeshGovernanceSim());
        setGovernanceSource("local");
      }
    };

    poll();
    const timer = setInterval(poll, GOVERNANCE_TICK_MS);
    return () => {
      alive = false;
      clearInterval(timer);
    };
  }, []);

  const mode = mesh?.mode || "UNAVAILABLE";
  const tone =
    mode === "LIVE"
      ? "#00D084"
      : mode === "SIMULATION"
        ? "#F59E0B"
        : "#EF4444";

  return (
    <ScrollView style={styles.screen} contentContainerStyle={styles.content}>
      <Text style={styles.brand}>MauriMesh</Text>
      <Text style={styles.title}>Mesh Status</Text>
      <Text style={styles.marker}>{MARKER}</Text>

      <View style={[styles.statusPill, { borderColor: tone }]}>
        <Text style={[styles.statusText, { color: tone }]}>{mode}</Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>API Fallback</Text>
        <Text style={styles.cardText}>
          {mesh?.message || "Checking mesh fallback status..."}
        </Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Nodes Visible</Text>
        <Text style={styles.cardText}>{mesh?.nodes.length || 0} node(s)</Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Routes Visible</Text>
        <Text style={styles.cardText}>{mesh?.routes.length || 0} route(s)</Text>
      </View>

      <View style={[styles.card, styles.govCard]}>
        <Text style={styles.cardTitle}>Self-Healing & Traffic Control</Text>
        <Text style={styles.govBadge}>[SIMULATION - NOT LIVE BLE]</Text>

        <View style={styles.govRow}>
          <Text style={styles.govLabel}>Peers rehabilitated</Text>
          <Text style={styles.govValue}>
            {governance?.rehabilitations ?? 0}
          </Text>
        </View>
        <View style={styles.govRow}>
          <Text style={styles.govLabel}>Traffic-shaped routes</Text>
          <Text style={styles.govValue}>
            {governance?.trafficShapedRoutes ?? 0}
          </Text>
        </View>
        <View style={[styles.govRow, styles.govRowLast]}>
          <Text style={styles.govLabel}>Peers quarantined now</Text>
          <Text style={styles.govValue}>
            {governance?.quarantinedPeers ?? 0}
          </Text>
        </View>

        <Text style={styles.govSource}>
          {governanceSource === "live"
            ? "Source: shared live API — the same numbers on web and every phone."
            : "Source: local device fallback — live governance unavailable."}
        </Text>

        <Text style={styles.cardText}>
          Live counters from the routing engine&apos;s self-healing and
          traffic-control layers, updating every {GOVERNANCE_TICK_MS / 1000}s as
          the simulated mesh runs. On a physical device these reflect real BLE
          packet flow; here they are development simulation only.
        </Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Truth Boundary</Text>
        <Text style={styles.cardText}>
          This screen can show live API data only if EXPO_PUBLIC_MESH_API_URL is configured.
          Otherwise it shows labelled simulation. It does not claim live BLE.
        </Text>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: "#020617" },
  content: { padding: 24, paddingTop: 72 },
  brand: { color: "#00D084", fontSize: 38, fontWeight: "900", marginBottom: 8 },
  title: { color: "#FFFFFF", fontSize: 28, fontWeight: "900", marginBottom: 8 },
  marker: { color: "#38BDF8", fontSize: 12, fontWeight: "800", marginBottom: 18 },
  statusPill: {
    alignSelf: "flex-start",
    borderWidth: 1,
    borderRadius: 999,
    paddingVertical: 7,
    paddingHorizontal: 14,
    marginBottom: 18,
    backgroundColor: "rgba(255,255,255,0.04)",
  },
  statusText: { fontSize: 12, fontWeight: "900", letterSpacing: 1 },
  card: {
    backgroundColor: "rgba(255,255,255,0.06)",
    borderColor: "rgba(0,208,132,0.28)",
    borderWidth: 1,
    borderRadius: 18,
    padding: 16,
    marginBottom: 12,
  },
  cardTitle: { color: "#FFFFFF", fontSize: 17, fontWeight: "900", marginBottom: 8 },
  cardText: { color: "rgba(255,255,255,0.78)", fontSize: 14, lineHeight: 22 },
  govCard: {
    borderColor: "rgba(245,158,11,0.45)",
  },
  govBadge: {
    color: "#F59E0B",
    fontSize: 11,
    fontWeight: "900",
    letterSpacing: 0.8,
    marginBottom: 12,
  },
  govRow: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    paddingVertical: 8,
    borderBottomWidth: 1,
    borderBottomColor: "rgba(255,255,255,0.08)",
  },
  govRowLast: {
    borderBottomWidth: 0,
    marginBottom: 8,
  },
  govLabel: { color: "rgba(255,255,255,0.82)", fontSize: 14, fontWeight: "700" },
  govValue: { color: "#00D084", fontSize: 20, fontWeight: "900" },
  govSource: {
    color: "#38BDF8",
    fontSize: 12,
    fontWeight: "700",
    marginBottom: 10,
  },
});
