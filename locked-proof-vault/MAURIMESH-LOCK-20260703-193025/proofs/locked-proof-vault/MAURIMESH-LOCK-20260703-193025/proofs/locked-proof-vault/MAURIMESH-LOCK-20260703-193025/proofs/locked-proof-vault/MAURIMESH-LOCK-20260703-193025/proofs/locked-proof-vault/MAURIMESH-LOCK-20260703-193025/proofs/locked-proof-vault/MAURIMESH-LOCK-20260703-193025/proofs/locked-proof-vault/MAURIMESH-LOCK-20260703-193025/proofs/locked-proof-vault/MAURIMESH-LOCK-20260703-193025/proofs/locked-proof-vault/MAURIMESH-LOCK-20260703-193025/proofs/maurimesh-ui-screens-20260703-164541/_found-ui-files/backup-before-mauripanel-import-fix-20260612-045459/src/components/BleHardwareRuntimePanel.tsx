import React, { useEffect, useState } from "react";
import { StyleSheet, Text, View } from "react-native";
import {
  BleHardwareRuntimeDecision,
  evaluateBleHardwareRuntime,
} from "../maurimesh/ble-runtime";
import { mauriTheme } from "../theme/mauriTheme";
import { MauriButton } from "./MauriButton";
import { StatusPill } from "./StatusPill";

function modeTone(
  mode: string
): "success" | "warning" | "danger" | "info" {
  if (mode === "NATIVE_CONTROLLED") return "success";
  if (mode === "JS_FALLBACK_CONTROLLED") return "warning";
  return "danger";
}

export function BleHardwareRuntimePanel() {
  const [decision, setDecision] = useState<BleHardwareRuntimeDecision | null>(null);

  async function refresh() {
    const next = await evaluateBleHardwareRuntime();
    setDecision(next);
  }

  useEffect(() => {
    refresh();
  }, []);

  if (!decision) {
    return (
      <MauriPanel>
        <StatusPill label="LOADING BLE HARDWARE POLICY" tone="info" />
        <Text style={styles.detail}>Evaluating BLE runtime tuning...</Text>
      </MauriPanel>
    );
  }

  return (
    <View style={styles.wrap}>
      <MauriPanel glow>
        <StatusPill label={decision.mode} tone={modeTone(decision.mode)} />
        <Text style={styles.title}>BLE Hardware Runtime</Text>
        <Text style={styles.detail}>{decision.operatorAlert}</Text>
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>BLE Tuning</Text>
        <Text style={styles.rowText}>Allow scan: {decision.allowScan ? "yes" : "no"}</Text>
        <Text style={styles.rowText}>Allow advertise: {decision.allowAdvertise ? "yes" : "no"}</Text>
        <Text style={styles.rowText}>Scan window: {decision.scanWindowMs} ms</Text>
        <Text style={styles.rowText}>Scan cooldown: {decision.scanCooldownMs} ms</Text>
        <Text style={styles.rowText}>Max retries: {decision.maxRetries}</Text>
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Runtime Protection</Text>
        <Text style={styles.rowText}>Safe mode: {decision.safeMode ? "yes" : "no"}</Text>
        <Text style={styles.rowText}>Proof hashing: {decision.allowProofHashing ? "allowed" : "deferred"}</Text>
        <Text style={styles.rowText}>Proof batch size: {decision.proofBatchSize}</Text>
        <Text style={styles.rowText}>Reduce animations: {decision.reduceAnimations ? "yes" : "no"}</Text>
        <Text style={styles.rowText}>Store-forward: {decision.useStoreForward ? "yes" : "no"}</Text>
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Backup Wiring</Text>
        <Text style={styles.detail}>
          If native telemetry or hardware controller fails, MauriMesh falls back to conservative BLE policy: low scan window, long cooldown, one retry, proof deferral, and minimal animation.
        </Text>
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Final Truth</Text>
        <Text style={styles.detail}>{decision.finalTruth}</Text>
      </MauriPanel>

      <MauriButton title="Refresh BLE Hardware Policy" onPress={refresh} />
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    gap: mauriTheme.spacing.md,
  },
  title: {
    color: mauriTheme.colors.white,
    fontSize: 24,
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
});
