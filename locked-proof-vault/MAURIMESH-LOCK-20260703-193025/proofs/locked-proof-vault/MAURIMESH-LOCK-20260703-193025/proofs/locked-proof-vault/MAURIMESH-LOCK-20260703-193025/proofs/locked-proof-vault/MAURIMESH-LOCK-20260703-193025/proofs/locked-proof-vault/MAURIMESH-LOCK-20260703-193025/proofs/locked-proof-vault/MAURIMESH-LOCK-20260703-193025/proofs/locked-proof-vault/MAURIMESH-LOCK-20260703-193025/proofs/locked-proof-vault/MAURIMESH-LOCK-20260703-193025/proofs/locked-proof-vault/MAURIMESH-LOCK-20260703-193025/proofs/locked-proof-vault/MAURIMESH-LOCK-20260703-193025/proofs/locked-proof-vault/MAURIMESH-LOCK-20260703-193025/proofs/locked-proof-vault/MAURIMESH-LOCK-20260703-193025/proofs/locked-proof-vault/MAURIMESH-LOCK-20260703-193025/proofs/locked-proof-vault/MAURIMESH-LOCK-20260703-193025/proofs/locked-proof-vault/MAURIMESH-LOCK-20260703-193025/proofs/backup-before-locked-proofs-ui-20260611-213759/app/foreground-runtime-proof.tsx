import React, { useEffect, useState } from "react";
import {
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from "react-native";
import {
  getMauriMeshForegroundRuntimeStatus,
  startMauriMeshForegroundRuntime,
  stopMauriMeshForegroundRuntime,
} from "../src/maurimesh/background/foregroundRuntimeClient";

const MARKER = "TASK_182_FOREGROUND_RUNTIME_PROOF_UI_20260608_A";

export default function ForegroundRuntimeProofScreen() {
  const [status, setStatus] = useState<any>({});
  const [working, setWorking] = useState(false);

  async function refresh() {
    const next = await getMauriMeshForegroundRuntimeStatus();
    setStatus(next);
  }

  async function start() {
    setWorking(true);
    try {
      await startMauriMeshForegroundRuntime();
      await refresh();
    } finally {
      setWorking(false);
    }
  }

  async function stop() {
    setWorking(true);
    try {
      await stopMauriMeshForegroundRuntime();
      await refresh();
    } finally {
      setWorking(false);
    }
  }

  useEffect(() => {
    refresh();
    const timer = setInterval(refresh, 5000);
    return () => clearInterval(timer);
  }, []);

  return (
    <ScrollView style={styles.page} contentContainerStyle={styles.content}>
      <Text style={styles.brand}>MauriMesh</Text>
      <Text style={styles.title}>Foreground Runtime Proof</Text>
      <Text style={styles.marker}>{MARKER}</Text>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Native Runtime</Text>
        <Line label="Capability" value={status.capability || "unknown"} />
        <Line label="Heartbeat present" value={Boolean(status.heartbeatPresent)} />
        <Line label="Native marker" value={status.marker || "none"} />
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Heartbeat</Text>
        <Text style={styles.body}>{status.heartbeat || "No heartbeat yet."}</Text>
      </View>

      <View style={styles.warningCard}>
        <Text style={styles.cardTitle}>Truth Boundary</Text>
        <Text style={styles.body}>
          This proves native foreground service execution when heartbeat appears.
          Real screen-lock survival still requires physical phone proof: start service,
          lock screen for 10+ minutes, unlock, verify heartbeat advanced and BLE scan still works.
        </Text>
      </View>

      <TouchableOpacity style={styles.button} disabled={working} onPress={start}>
        <Text style={styles.buttonText}>{working ? "Working..." : "Start Mesh Foreground Service"}</Text>
      </TouchableOpacity>

      <TouchableOpacity style={styles.secondaryButton} disabled={working} onPress={stop}>
        <Text style={styles.secondaryButtonText}>Stop Service</Text>
      </TouchableOpacity>

      <TouchableOpacity style={styles.secondaryButton} disabled={working} onPress={refresh}>
        <Text style={styles.secondaryButtonText}>Refresh Status</Text>
      </TouchableOpacity>
    </ScrollView>
  );
}

function Line({ label, value }: { label: string; value: string | number | boolean }) {
  return (
    <Text style={styles.body}>
      <Text style={styles.label}>{label}: </Text>
      {String(value)}
    </Text>
  );
}

const styles = StyleSheet.create({
  page: { flex: 1, backgroundColor: "#050816" },
  content: { padding: 24, paddingTop: 56, paddingBottom: 80 },
  brand: { color: "#00D084", fontSize: 42, fontWeight: "900", marginBottom: 20 },
  title: { color: "#FFFFFF", fontSize: 28, fontWeight: "900", marginBottom: 10 },
  marker: { color: "#4FC3F7", fontSize: 12, fontWeight: "900", letterSpacing: 1, marginBottom: 24 },
  card: {
    borderWidth: 1,
    borderColor: "rgba(0, 208, 132, 0.32)",
    borderRadius: 20,
    padding: 20,
    marginBottom: 16,
    backgroundColor: "rgba(255,255,255,0.035)",
  },
  warningCard: {
    borderWidth: 1,
    borderColor: "rgba(245, 158, 11, 0.55)",
    borderRadius: 20,
    padding: 20,
    marginBottom: 16,
    backgroundColor: "rgba(245, 158, 11, 0.055)",
  },
  cardTitle: { color: "#FFFFFF", fontSize: 21, fontWeight: "900", marginBottom: 12 },
  body: { color: "rgba(255,255,255,0.76)", fontSize: 15, lineHeight: 24, marginBottom: 6 },
  label: { color: "#FFFFFF", fontWeight: "900" },
  button: {
    backgroundColor: "#00D084",
    borderRadius: 18,
    padding: 18,
    alignItems: "center",
    marginTop: 6,
    marginBottom: 12,
  },
  buttonText: { color: "#03120C", fontSize: 16, fontWeight: "900" },
  secondaryButton: {
    borderWidth: 1,
    borderColor: "rgba(0, 208, 132, 0.5)",
    borderRadius: 18,
    padding: 16,
    alignItems: "center",
    marginBottom: 12,
  },
  secondaryButtonText: { color: "#00D084", fontSize: 15, fontWeight: "900" },
});
