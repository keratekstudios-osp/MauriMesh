import React, { useMemo, useState } from "react";
import { Pressable, ScrollView, StyleSheet, Text, View } from "react-native";
import { useRouter } from "expo-router";
import { getBleRuntimeBridgeDashboardData } from "./bleRuntimeBridgeDashboard";
import { requestNativeBleStatus } from "../bridges/androidBleRuntimeBridge";

function Pill({ label, ok }: { label: string; ok: boolean }) {
  return (
    <View style={[styles.pill, { borderColor: ok ? "#00D084" : "#F59E0B" }]}>
      <Text style={[styles.pillText, { color: ok ? "#00D084" : "#F59E0B" }]}>
        {label}
      </Text>
    </View>
  );
}

export default function MauriCoreBleRuntimeScreen() {
  const router = useRouter();
  const [refresh, setRefresh] = useState(0);
  const [nativeStatus, setNativeStatus] = useState<Record<string, unknown> | null>(null);

  const data = useMemo(() => getBleRuntimeBridgeDashboardData(), [refresh]);

  async function checkNativeStatus() {
    const result = await requestNativeBleStatus();
    setNativeStatus(result);
    setRefresh((value) => value + 1);
  }

  return (
    <ScrollView style={styles.safe} contentContainerStyle={styles.content}>
      <Text style={styles.brand}>MauriMesh</Text>
      <Text style={styles.title}>MauriCore Android BLE Runtime</Text>
      <Text style={styles.code}>NATIVE_BLE_RUNTIME_BRIDGE</Text>

      <View style={styles.row}>
        <Pill
          label={data.acceptance.nativeModulePresent ? "NATIVE_MODULE_PRESENT" : "NATIVE_MODULE_MISSING"}
          ok={data.acceptance.nativeModulePresent}
        />
        <Pill
          label={data.acceptance.eventListenerActive ? "EVENT_LISTENER_ACTIVE" : "EVENT_LISTENER_INACTIVE"}
          ok={data.acceptance.eventListenerActive}
        />
        <Pill
          label={data.acceptance.hasProofEvents ? "PROOF_EVENTS_SEEN" : "WAITING_FOR_PROOF_EVENTS"}
          ok={data.acceptance.hasProofEvents}
        />
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Bridge State</Text>
        <Text style={styles.line}>Platform: {data.bridge.platform}</Text>
        <Text style={styles.line}>Event: {data.bridge.eventName}</Text>
        <Text style={styles.line}>Native module: {String(data.bridge.nativeModulePresent)}</Text>
        <Text style={styles.line}>Listening: {String(data.bridge.listening)}</Text>
        {data.bridge.lastError ? (
          <Text style={styles.warn}>Warning: {data.bridge.lastError}</Text>
        ) : null}
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Proof Event Summary</Text>
        <Text style={styles.line}>Total: {data.summary.total}</Text>
        <Text style={styles.line}>RX packets: {data.summary.rxPackets}</Text>
        <Text style={styles.line}>TX packets: {data.summary.txPackets}</Text>
        <Text style={styles.line}>ACK sent: {data.summary.ackSent}</Text>
        <Text style={styles.line}>ACK received: {data.summary.ackReceived}</Text>
        <Text style={styles.line}>Scan events: {data.summary.scanEvents}</Text>
        <Text style={styles.line}>Proof-ready events: {data.summary.proofReady}</Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Native Status</Text>
        <Pressable style={styles.button} onPress={checkNativeStatus}>
          <Text style={styles.buttonText}>Check Native BLE Status</Text>
        </Pressable>
        {nativeStatus ? (
          <Text style={styles.mono}>{JSON.stringify(nativeStatus, null, 2)}</Text>
        ) : (
          <Text style={styles.line}>No native status requested yet.</Text>
        )}
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Recent Native Proof Events</Text>
        {data.events.length === 0 ? (
          <Text style={styles.warn}>
            No native BLE proof events received yet. This is expected until the APK runs on a physical Android phone and BLE activity occurs.
          </Text>
        ) : (
          data.events.map((event) => (
            <View key={event.id} style={styles.event}>
              <Text style={styles.eventTitle}>{event.kind}</Text>
              <Text style={styles.line}>Packet: {event.packetId ?? "none"}</Text>
              <Text style={styles.line}>Peer: {event.peerId ?? "none"}</Text>
              <Text style={styles.line}>Time: {event.timestamp}</Text>
            </View>
          ))
        )}
      </View>

      <Pressable style={styles.backButton} onPress={() => router.back()}>
        <Text style={styles.backText}>Back</Text>
      </Pressable>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: "#020617" },
  content: { padding: 20, paddingBottom: 44 },
  brand: {
    color: "#00D084",
    fontSize: 32,
    fontWeight: "900",
    marginTop: 18,
  },
  title: {
    color: "#FFFFFF",
    fontSize: 25,
    fontWeight: "900",
    marginTop: 18,
  },
  code: {
    color: "#38BDF8",
    fontSize: 12,
    fontWeight: "900",
    letterSpacing: 1,
    marginTop: 8,
    marginBottom: 18,
  },
  row: { flexDirection: "row", flexWrap: "wrap", gap: 8, marginBottom: 12 },
  pill: {
    borderWidth: 1,
    borderRadius: 999,
    paddingHorizontal: 10,
    paddingVertical: 6,
    backgroundColor: "rgba(255,255,255,0.04)",
  },
  pillText: { fontSize: 11, fontWeight: "900" },
  card: {
    borderWidth: 1,
    borderColor: "rgba(0,208,132,0.25)",
    backgroundColor: "rgba(0,40,34,0.72)",
    borderRadius: 18,
    padding: 16,
    marginTop: 12,
  },
  cardTitle: { color: "#FFFFFF", fontSize: 18, fontWeight: "900", marginBottom: 10 },
  line: {
    color: "rgba(255,255,255,0.78)",
    fontSize: 14,
    lineHeight: 21,
    fontWeight: "600",
  },
  warn: {
    color: "#F59E0B",
    fontSize: 14,
    lineHeight: 21,
    fontWeight: "800",
  },
  mono: {
    color: "#CFFAFE",
    fontSize: 12,
    lineHeight: 18,
    fontWeight: "700",
    marginTop: 10,
  },
  event: {
    borderTopWidth: 1,
    borderTopColor: "rgba(255,255,255,0.08)",
    marginTop: 10,
    paddingTop: 10,
  },
  eventTitle: { color: "#00D084", fontSize: 14, fontWeight: "900" },
  button: {
    minHeight: 48,
    borderRadius: 14,
    backgroundColor: "#00D084",
    alignItems: "center",
    justifyContent: "center",
    marginBottom: 10,
  },
  buttonText: { color: "#020617", fontSize: 15, fontWeight: "900" },
  backButton: {
    marginTop: 18,
    minHeight: 52,
    borderRadius: 16,
    alignItems: "center",
    justifyContent: "center",
    backgroundColor: "#00D084",
  },
  backText: { color: "#020617", fontWeight: "900", fontSize: 16 },
});
