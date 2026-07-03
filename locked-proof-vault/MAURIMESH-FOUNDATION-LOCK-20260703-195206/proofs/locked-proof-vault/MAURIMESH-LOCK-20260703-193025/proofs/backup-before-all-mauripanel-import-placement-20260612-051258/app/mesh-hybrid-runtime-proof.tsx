import React, { useMemo, useState } from "react";
import { Pressable, ScrollView, StyleSheet, Text, View } from "react-native";
import { createInitialMemory } from "../src/maurimesh/intelligent-hybrid-proof/meshMemory";
import {
  logProofEvent,
  runIntelligentProofCycle,
  runUntilTrustTarget,
} from "../src/maurimesh/intelligent-hybrid-proof/meshAiRuntime";
import { MeshMemory, ProofEvent } from "../src/maurimesh/intelligent-hybrid-proof/types";

export default function MeshHybridRuntimeProof() {
  const [memory, setMemory] = useState<MeshMemory>(() => createInitialMemory());
  const [events, setEvents] = useState<ProofEvent[]>([]);
  const [logLines, setLogLines] = useState<string[]>([]);

  const logicScore = useMemo(() => {
    const signedTargets = memory.routePipelines.filter(
      (p) => p.id === "A_B_WIFI_HOTSPOT_2HOP" || p.id === "A_B_C_APP_3HOP"
    );
    if (signedTargets.length === 0) return 0;
    return Math.round(
      signedTargets.reduce((sum, p) => sum + p.trust, 0) / signedTargets.length
    );
  }, [memory]);

  function pushEvents(nextEvents: ProofEvent[]) {
    const lines = nextEvents.map(logProofEvent);
    setEvents((prev) => [...nextEvents, ...prev].slice(0, 400));
    setLogLines((prev) => [...lines.reverse(), ...prev].slice(0, 400));
  }

  function runOneCycle() {
    const result = runIntelligentProofCycle(memory);
    setMemory(result.memory);
    pushEvents(result.events);
  }

  function runTo100() {
    const result = runUntilTrustTarget(8);
    setMemory(result.memory);
    pushEvents(result.events);
  }

  const twoHop = memory.routePipelines.find((p) => p.id === "A_B_WIFI_HOTSPOT_2HOP");
  const threeHop = memory.routePipelines.find((p) => p.id === "A_B_C_APP_3HOP");
  const mac = memory.routePipelines.find((p) => p.id === "MAC_C_BRIDGE_CANDIDATE");
  const airpods = memory.routePipelines.find((p) => p.id === "AIRPODS_OBSERVED_ONLY");

  return (
    <ScrollView style={styles.root} contentContainerStyle={styles.content}>
      <View style={styles.hero}>
        <Text style={styles.kicker}>MAURIMESH INTELLIGENT HYBRID RUNTIME</Text>
        <Text style={styles.title}>BLE Hybrid + 2-Hop + A-B-C Proof Logic</Text>
        <Text style={styles.text}>
          Mauri AI traffic control learns route trust, remembers mistakes, applies governance,
          self-heals weak routes, blocks false relays, and signs off logic only when trust reaches 100%.
        </Text>
      </View>

      <View style={styles.metric}>
        <Text style={styles.metricValue}>{logicScore}%</Text>
        <Text style={styles.text}>Logic trust score</Text>
      </View>

      <Pressable style={styles.primary} onPress={runOneCycle}>
        <Text style={styles.primaryText}>RUN ONE SELF-LEARNING PROOF CYCLE</Text>
      </Pressable>

      <Pressable style={styles.secondary} onPress={runTo100}>
        <Text style={styles.secondaryText}>RUN UNTIL 100% LOGIC TRUST</Text>
      </Pressable>

      <Text style={styles.section}>Route Memory</Text>
      {[twoHop, threeHop, mac, airpods].filter(Boolean).map((p) => (
        <View key={p!.id} style={styles.card}>
          <Text style={styles.cardTitle}>{p!.label}</Text>
          <Text style={styles.line}>id: {p!.id}</Text>
          <Text style={styles.line}>trust: {p!.trust}%</Text>
          <Text style={styles.line}>latency: {p!.latencyMs}ms</Text>
          <Text style={styles.line}>successes: {p!.successes}</Text>
          <Text style={styles.line}>mistakes: {p!.mistakes}</Text>
          <Text style={p!.signedOff ? styles.pass : styles.wait}>
            {p!.signedOff ? "SIGNED OFF" : "WAITING"}
          </Text>
          <Text style={styles.truth}>{p!.truth}</Text>
        </View>
      ))}

      <Text style={styles.section}>Governance Warnings</Text>
      {memory.governanceWarnings.length === 0 ? (
        <Text style={styles.text}>No warnings yet.</Text>
      ) : (
        memory.governanceWarnings.map((w) => (
          <View key={w} style={styles.warnCard}>
            <Text style={styles.warnText}>{w}</Text>
          </View>
        ))
      )}

      <Text style={styles.section}>Mistake Memory</Text>
      {memory.mistakes.length === 0 ? (
        <Text style={styles.text}>No mistakes remembered yet.</Text>
      ) : (
        memory.mistakes.map((m, i) => (
          <View key={`${i}-${m}`} style={styles.warnCard}>
            <Text style={styles.warnText}>{m}</Text>
          </View>
        ))
      )}

      <Text style={styles.section}>Signed Proofs</Text>
      {memory.signedProofs.length === 0 ? (
        <Text style={styles.text}>No signed proofs yet. Run until 100% logic trust.</Text>
      ) : (
        memory.signedProofs.map((p) => (
          <View key={p} style={styles.signedCard}>
            <Text style={styles.signedText}>{p}</Text>
          </View>
        ))
      )}

      <Text style={styles.section}>Live Proof Log Lines</Text>
      {logLines.map((line, i) => (
        <View key={`${i}-${line}`} style={styles.logCard}>
          <Text style={styles.logText}>{line}</Text>
        </View>
      ))}

      <View style={styles.truthBox}>
        <Text style={styles.truthTitle}>TRUTH BOUNDARY</Text>
        <Text style={styles.text}>
          2-hop physical proof requires A06 + S10 both present in ADB/logcat. 3-hop physical proof
          requires a third MauriMesh relay device or a Mac companion bridge. AirPods can be observed
          as BLE devices but cannot relay MauriMesh packets.
        </Text>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: "#020403" },
  content: { padding: 18, paddingBottom: 60 },
  hero: {
    borderWidth: 1,
    borderColor: "rgba(34,197,94,0.35)",
    backgroundColor: "rgba(2,12,8,0.92)",
    borderRadius: 24,
    padding: 18,
    marginBottom: 14,
  },
  kicker: { color: "#00D084", fontWeight: "900", letterSpacing: 1, fontSize: 12 },
  title: { color: "#FFFFFF", fontSize: 28, lineHeight: 34, fontWeight: "900", marginTop: 6 },
  text: { color: "rgba(255,255,255,0.74)", lineHeight: 21, marginTop: 6 },
  metric: {
    borderWidth: 1,
    borderColor: "rgba(34,197,94,0.24)",
    borderRadius: 20,
    padding: 16,
    backgroundColor: "rgba(255,255,255,0.05)",
    marginBottom: 12,
  },
  metricValue: { color: "#FFFFFF", fontWeight: "900", fontSize: 42 },
  primary: {
    backgroundColor: "#00D084",
    borderRadius: 18,
    minHeight: 56,
    justifyContent: "center",
    alignItems: "center",
    marginTop: 8,
  },
  primaryText: { color: "#03110B", fontWeight: "900", textAlign: "center" },
  secondary: {
    borderWidth: 1,
    borderColor: "rgba(34,197,94,0.35)",
    borderRadius: 18,
    minHeight: 52,
    justifyContent: "center",
    alignItems: "center",
    backgroundColor: "rgba(255,255,255,0.06)",
    marginTop: 8,
  },
  secondaryText: { color: "#FFFFFF", fontWeight: "900", textAlign: "center" },
  section: { color: "#FFFFFF", fontSize: 22, fontWeight: "900", marginTop: 22, marginBottom: 10 },
  card: {
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.13)",
    backgroundColor: "rgba(255,255,255,0.05)",
    borderRadius: 18,
    padding: 14,
    marginBottom: 10,
  },
  cardTitle: { color: "#FFFFFF", fontWeight: "900", fontSize: 15, marginBottom: 6 },
  line: { color: "rgba(255,255,255,0.76)", marginTop: 3 },
  pass: { color: "#22C55E", fontWeight: "900", marginTop: 8 },
  wait: { color: "#F59E0B", fontWeight: "900", marginTop: 8 },
  truth: { color: "#BAE6FD", lineHeight: 19, marginTop: 8 },
  warnCard: {
    borderWidth: 1,
    borderColor: "rgba(245,158,11,0.45)",
    backgroundColor: "rgba(245,158,11,0.1)",
    borderRadius: 14,
    padding: 10,
    marginBottom: 8,
  },
  warnText: { color: "#FDE68A", lineHeight: 18 },
  signedCard: {
    borderWidth: 1,
    borderColor: "rgba(34,197,94,0.45)",
    backgroundColor: "rgba(34,197,94,0.1)",
    borderRadius: 14,
    padding: 10,
    marginBottom: 8,
  },
  signedText: { color: "#BBF7D0", lineHeight: 18, fontWeight: "800" },
  logCard: {
    borderWidth: 1,
    borderColor: "rgba(56,189,248,0.35)",
    backgroundColor: "rgba(56,189,248,0.08)",
    borderRadius: 14,
    padding: 10,
    marginBottom: 8,
  },
  logText: { color: "#BAE6FD", fontSize: 11, lineHeight: 16 },
  truthBox: {
    borderWidth: 1,
    borderColor: "rgba(245,158,11,0.55)",
    backgroundColor: "rgba(245,158,11,0.1)",
    borderRadius: 22,
    padding: 15,
    marginTop: 18,
  },
  truthTitle: { color: "#F59E0B", fontWeight: "900" },
});
