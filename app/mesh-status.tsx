import React, { useEffect, useState } from "react";
import { ScrollView, StyleSheet, Text, View } from "react-native";
import { getMeshStatus, MeshStatus } from "../src/lib/meshClient";

const MARKER = "API_FALLBACK_MESH_STATUS_20260607_A";

export default function MeshStatusScreen() {
  const [mesh, setMesh] = useState<MeshStatus | null>(null);

  useEffect(() => {
    let alive = true;
    getMeshStatus()
      .then((status) => {
        if (alive) setMesh(status);
      })
      .catch(() => {
        if (alive) {
          setMesh({
            mode: "UNAVAILABLE",
            message: "Mesh status failed safely.",
            nodes: [],
            routes: [],
          });
        }
      });
    return () => {
      alive = false;
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
});
