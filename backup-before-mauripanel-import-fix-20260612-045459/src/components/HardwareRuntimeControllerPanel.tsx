import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { useHardwareRuntimeController } from "../hooks/useHardwareRuntimeController";
import { mauriTheme } from "../theme/mauriTheme";
import { MauriButton } from "./MauriButton";
import { StatusPill } from "./StatusPill";

function modeTone(
  mode: string
): "success" | "warning" | "danger" | "info" {
  if (mode === "full") return "success";
  if (mode === "balanced") return "info";
  if (mode === "reduced") return "warning";
  return "danger";
}

export function HardwareRuntimeControllerPanel() {
  const runtime = useHardwareRuntimeController();

  if (runtime.loading || !runtime.state || !runtime.ble || !runtime.proof) {
    return (
      <MauriPanel>
        <StatusPill label="LOADING CONTROLLER" tone="info" />
        <Text style={styles.detail}>Evaluating hardware runtime policy...</Text>
      </MauriPanel>
    );
  }

  const state = runtime.state;

  return (
    <View style={styles.wrap}>
      <MauriPanel glow>
        <StatusPill label={state.source} tone={state.source === "NATIVE_ANDROID" ? "success" : "warning"} />
        <Text style={styles.score}>{state.decision.deviceHealthScore}%</Text>
        <Text style={styles.title}>Hardware Runtime Controller</Text>
        <StatusPill label={state.runtimeMode.toUpperCase()} tone={modeTone(state.runtimeMode)} />
        <Text style={styles.detail}>{state.operatorAlert}</Text>
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Runtime Flags</Text>
        <Text style={styles.rowText}>Throttle BLE: {state.shouldThrottleBle ? "yes" : "no"}</Text>
        <Text style={styles.rowText}>Throttle proof: {state.shouldThrottleProof ? "yes" : "no"}</Text>
        <Text style={styles.rowText}>Reduce animations: {state.shouldReduceAnimations ? "yes" : "no"}</Text>
        <Text style={styles.rowText}>Use store-forward: {state.shouldUseStoreForward ? "yes" : "no"}</Text>
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>BLE Runtime Tuning</Text>
        <Text style={styles.rowText}>Allow scan: {runtime.ble.allowScan ? "yes" : "no"}</Text>
        <Text style={styles.rowText}>Allow advertise: {runtime.ble.allowAdvertise ? "yes" : "no"}</Text>
        <Text style={styles.rowText}>Scan window: {runtime.ble.scanWindowMs} ms</Text>
        <Text style={styles.rowText}>Scan cooldown: {runtime.ble.scanCooldownMs} ms</Text>
        <Text style={styles.rowText}>Max retries: {runtime.ble.maxRetries}</Text>
        <Text style={styles.detail}>{runtime.ble.reason}</Text>
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Proof Runtime Tuning</Text>
        <Text style={styles.rowText}>Proof hashing: {runtime.proof.allowProofHashing ? "allowed" : "paused"}</Text>
        <Text style={styles.rowText}>Ledger write: {runtime.proof.allowLedgerWrite ? "allowed" : "paused"}</Text>
        <Text style={styles.rowText}>Batch size: {runtime.proof.proofBatchSize}</Text>
        <Text style={styles.detail}>{runtime.proof.reason}</Text>
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Learning Memory</Text>
        <Text style={styles.rowText}>Samples seen: {state.memory.samplesSeen}</Text>
        <Text style={styles.rowText}>Repeated faults: {state.memory.repeatedFaults.join(", ") || "none"}</Text>
        {state.memory.learnedNotes.map((note) => (
          <Text key={note} style={styles.bullet}>• {note}</Text>
        ))}
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Truth Boundary</Text>
        <Text style={styles.detail}>{state.finalTruth}</Text>
      </MauriPanel>

      <MauriButton title="Refresh Runtime Policy" onPress={runtime.refresh} />
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    gap: mauriTheme.spacing.md,
  },
  score: {
    color: mauriTheme.colors.greenstone,
    fontSize: 54,
    fontWeight: "900",
    letterSpacing: -1.4,
  },
  title: {
    color: mauriTheme.colors.white,
    fontSize: 22,
    fontWeight: "900",
  },
  sectionTitle: {
    color: mauriTheme.colors.greenstone,
    fontSize: 18,
    fontWeight: "900",
  },
  detail: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 21,
  },
  rowText: {
    color: mauriTheme.colors.white,
    lineHeight: 22,
  },
  bullet: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 22,
  },
});
