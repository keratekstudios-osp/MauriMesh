import React, { useMemo } from "react";
import { StyleSheet, Text, View } from "react-native";
import { JumpCodeEngine } from "../routing/jumpCodeEngine";

const C = {
  panel: "rgba(2,12,8,0.92)",
  border: "rgba(56,189,248,0.45)",
  green: "#00D084",
  blue: "#38BDF8",
  white: "#FFFFFF",
  muted: "rgba(255,255,255,0.72)",
  warn: "#F59E0B",
};

export function JumpCodeProofPanel() {
  const proof = useMemo(() => {
    const engine = new JumpCodeEngine();

    const relays = [
      {
        id: "PHONE_B_RELAY",
        ackRate: 0.94,
        trustScore: 0.9,
        latencyMs: 38,
        batteryPct: 81,
      },
      {
        id: "PHONE_D_BACKUP",
        ackRate: 0.72,
        trustScore: 0.74,
        latencyMs: 64,
        batteryPct: 62,
      },
      {
        id: "FLAKY_X",
        ackRate: 0.38,
        trustScore: 0.44,
        latencyMs: 140,
        batteryPct: 33,
      },
    ];

    const path = engine.createJumpCodePath(
      "PHONE_A_SENDER",
      "PHONE_C_RECEIVER",
      relays,
    );

    return {
      path,
      shouldUseWeak: engine.shouldUseJumpCode(0.41),
      shouldUseStrong: engine.shouldUseJumpCode(0.86),
      relays,
    };
  }, []);

  return (
    <View style={styles.panel}>
      <Text style={styles.kicker}>JUMPCODE_ENGINE_CALLED</Text>
      <Text style={styles.title}>JumpCode Routing Proof</Text>

      <Text style={styles.body}>
        This panel proves the app UI can call the JumpCode engine after bundling.
        It creates a route path using ACK rate, trust score, relay choice, and fallback routing logic.
      </Text>

      <View style={styles.box}>
        <Text style={styles.label}>Generated JumpCode</Text>
        <Text style={styles.code}>{proof.path.jumpCode}</Text>
      </View>

      <Text style={styles.line}>From: {proof.path.fromNode}</Text>
      <Text style={styles.line}>To: {proof.path.toNode}</Text>
      <Text style={styles.line}>Selected relay: {proof.path.relayNode}</Text>
      <Text style={styles.line}>Hop count: {proof.path.hops.length}</Text>
      <Text style={styles.line}>
        Confidence: {Math.round(proof.path.confidence * 100)}%
      </Text>

      <View style={styles.box}>
        <Text style={styles.label}>Route Decision</Text>
        <Text style={styles.line}>
          Weak route score 0.41: {proof.shouldUseWeak ? "JUMPCODE_REQUIRED" : "DIRECT_ROUTE_ACCEPTABLE"}
        </Text>
        <Text style={styles.line}>
          Strong route score 0.86: {proof.shouldUseStrong ? "JUMPCODE_REQUIRED" : "DIRECT_ROUTE_ACCEPTABLE"}
        </Text>
      </View>

      <Text style={styles.truth}>
        APK_PROOF_REQUIRED: This proves UI/runtime callability only. Real BLE delivery still needs installed APK,
        physical phones, TX/RX/ACK logcat, matching packetId, routeId, JumpCode, and proof-ledger hash.
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  panel: {
    borderWidth: 1,
    borderColor: C.border,
    borderRadius: 24,
    backgroundColor: C.panel,
    padding: 16,
    gap: 10,
    marginVertical: 8,
  },
  kicker: {
    color: C.blue,
    fontSize: 11,
    fontWeight: "900",
    letterSpacing: 0.8,
  },
  title: {
    color: C.white,
    fontSize: 26,
    fontWeight: "900",
    letterSpacing: -0.5,
  },
  body: {
    color: C.muted,
    fontSize: 14,
    lineHeight: 21,
  },
  box: {
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.10)",
    borderRadius: 16,
    padding: 12,
    gap: 6,
    backgroundColor: "rgba(255,255,255,0.04)",
  },
  label: {
    color: C.white,
    fontSize: 14,
    fontWeight: "900",
  },
  code: {
    color: C.green,
    fontSize: 15,
    fontWeight: "900",
    fontFamily: "monospace",
  },
  line: {
    color: C.muted,
    fontSize: 13,
    lineHeight: 20,
  },
  truth: {
    color: C.warn,
    fontSize: 12,
    lineHeight: 18,
  },
});
