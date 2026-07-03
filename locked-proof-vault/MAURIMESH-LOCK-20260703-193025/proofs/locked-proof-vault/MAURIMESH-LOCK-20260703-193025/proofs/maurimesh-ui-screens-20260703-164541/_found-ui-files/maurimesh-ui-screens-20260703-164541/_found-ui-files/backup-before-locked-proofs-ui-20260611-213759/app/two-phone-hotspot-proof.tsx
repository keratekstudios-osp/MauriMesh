import React, { useMemo, useState } from "react";
import { Pressable, ScrollView, StyleSheet, Text, View } from "react-native";
import {
  formatProofLine,
  twoHopEvents,
  twoHopProof,
  validateRequiredStages,
} from "../src/maurimesh/total-proof/totalProofEngine";

type Role = "PHONE_A_GATEWAY" | "PHONE_B_CLIENT" | "ALL";

export default function TwoPhoneHotspotProofScreen() {
  const [role, setRole] = useState<Role>("ALL");
  const [lines, setLines] = useState<string[]>([]);

  const events = useMemo(() => {
    if (role === "ALL") return twoHopEvents;
    return twoHopEvents.filter((event) => event.phoneRole === role);
  }, [role]);

  const result = useMemo(
    () => validateRequiredStages(lines, twoHopProof.requiredStages),
    [lines]
  );

  function emitLine(event: typeof twoHopEvents[number]) {
    const line = formatProofLine(event);
    console.log(line);
    setLines((prev) => [line, ...prev].slice(0, 120));
  }

  function emitAll() {
    events.forEach((event, index) => {
      setTimeout(() => emitLine(event), index * 180);
    });
  }

  return (
    <ScrollView style={styles.root} contentContainerStyle={styles.content}>
      <View style={styles.hero}>
        <Text style={styles.kicker}>MAURIMESH 2-HOP HOTSPOT GATEWAY</Text>
        <Text style={styles.title}>PHONE B → PHONE A Gateway</Text>
        <Text style={styles.text}>
          Use PHONE A as hotspot/gateway and PHONE B as client/sender. These buttons emit
          MauriMeshHotspotProof lines into ReactNativeJS/logcat.
        </Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.label}>proofId</Text>
        <Text style={styles.value}>{twoHopProof.proofId}</Text>
        <Text style={styles.label}>packetId</Text>
        <Text style={styles.value}>{twoHopProof.packetId}</Text>
        <Text style={styles.label}>routeId</Text>
        <Text style={styles.value}>{twoHopProof.routeId}</Text>
        <Text style={styles.label}>path</Text>
        <Text style={styles.value}>{twoHopProof.path}</Text>
      </View>

      <Text style={styles.section}>Role</Text>
      {(["ALL", "PHONE_A_GATEWAY", "PHONE_B_CLIENT"] as Role[]).map((r) => (
        <Pressable key={r} style={[styles.button, role === r && styles.active]} onPress={() => setRole(r)}>
          <Text style={styles.buttonText}>{r}</Text>
        </Pressable>
      ))}

      <Pressable style={styles.primary} onPress={emitAll}>
        <Text style={styles.primaryText}>Emit 2-Hop Proof Logs</Text>
      </Pressable>

      <View style={styles.metric}>
        <Text style={styles.metricValue}>{result.score}%</Text>
        <Text style={styles.text}>2-hop app-stage proof score</Text>
      </View>

      <Text style={styles.section}>Required Stages</Text>
      {twoHopProof.requiredStages.map((stage) => (
        <View key={stage} style={styles.row}>
          <Text style={lines.some((line) => line.includes(stage)) ? styles.pass : styles.wait}>
            {lines.some((line) => line.includes(stage)) ? "PASS" : "WAIT"}
          </Text>
          <Text style={styles.stage}>{stage}</Text>
        </View>
      ))}

      <Text style={styles.section}>Log Lines</Text>
      {lines.map((line, index) => (
        <View key={`${index}-${line}`} style={styles.log}>
          <Text style={styles.logText}>{line}</Text>
        </View>
      ))}

      <View style={styles.truth}>
        <Text style={styles.truthTitle}>TRUTH</Text>
        <Text style={styles.text}>
          This confirms 2-hop proof labels. Physical proof requires PHONE_A and PHONE_B ADB/logcat
          with matching proofId, packetId, and routeId.
        </Text>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: "#020403" },
  content: { padding: 18, paddingBottom: 60 },
  hero: { borderWidth: 1, borderColor: "rgba(34,197,94,0.35)", backgroundColor: "rgba(2,12,8,0.92)", borderRadius: 24, padding: 18, marginBottom: 14 },
  kicker: { color: "#00D084", fontWeight: "900", letterSpacing: 1, fontSize: 12 },
  title: { color: "#FFFFFF", fontSize: 30, lineHeight: 36, fontWeight: "900", marginTop: 6 },
  text: { color: "rgba(255,255,255,0.74)", lineHeight: 21, marginTop: 6 },
  card: { borderWidth: 1, borderColor: "rgba(34,197,94,0.24)", backgroundColor: "rgba(255,255,255,0.05)", borderRadius: 20, padding: 14, marginBottom: 16 },
  label: { color: "#00D084", fontWeight: "900", marginTop: 8 },
  value: { color: "#FFFFFF", fontWeight: "800", marginTop: 3, fontSize: 12 },
  section: { color: "#FFFFFF", fontSize: 22, fontWeight: "900", marginTop: 18, marginBottom: 10 },
  button: { borderWidth: 1, borderColor: "rgba(255,255,255,0.16)", backgroundColor: "rgba(255,255,255,0.06)", borderRadius: 18, minHeight: 48, justifyContent: "center", alignItems: "center", marginBottom: 8 },
  active: { borderColor: "#00D084", backgroundColor: "rgba(0,208,132,0.22)" },
  buttonText: { color: "#FFFFFF", fontWeight: "900" },
  primary: { backgroundColor: "#00D084", borderRadius: 18, minHeight: 56, justifyContent: "center", alignItems: "center", marginTop: 8 },
  primaryText: { color: "#03110B", fontWeight: "900" },
  metric: { borderWidth: 1, borderColor: "rgba(34,197,94,0.24)", borderRadius: 18, padding: 14, backgroundColor: "rgba(255,255,255,0.05)", marginTop: 12 },
  metricValue: { color: "#FFFFFF", fontWeight: "900", fontSize: 30 },
  row: { flexDirection: "row", gap: 10, borderWidth: 1, borderColor: "rgba(255,255,255,0.12)", borderRadius: 16, padding: 12, marginBottom: 8 },
  pass: { color: "#22C55E", fontWeight: "900", width: 52 },
  wait: { color: "#F59E0B", fontWeight: "900", width: 52 },
  stage: { color: "#FFFFFF", fontWeight: "800", flex: 1 },
  log: { borderWidth: 1, borderColor: "rgba(56,189,248,0.35)", backgroundColor: "rgba(56,189,248,0.08)", borderRadius: 14, padding: 10, marginBottom: 8 },
  logText: { color: "#BAE6FD", fontSize: 11, lineHeight: 16 },
  truth: { borderWidth: 1, borderColor: "rgba(245,158,11,0.55)", backgroundColor: "rgba(245,158,11,0.1)", borderRadius: 22, padding: 15, marginTop: 18 },
  truthTitle: { color: "#F59E0B", fontWeight: "900" },
});
