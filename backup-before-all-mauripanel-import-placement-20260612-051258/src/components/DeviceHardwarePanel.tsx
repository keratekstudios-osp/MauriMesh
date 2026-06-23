import React from "react";
import { StyleSheet, Text, View } from "react-native";
import {
import { MauriPanel } from "./MauriPanel";
  createRuntimePolicy,
  runHardwareStabilizerDemo,
} from "../maurimesh/device-hardware";
import { mauriTheme } from "../theme/mauriTheme";
import { StatusPill } from "./StatusPill";

function toneFromPressure(
  pressure: string
): "success" | "warning" | "danger" | "info" {
  if (pressure === "low") return "success";
  if (pressure === "medium") return "warning";
  return "danger";
}

export function DeviceHardwarePanel() {
  const { sample, decision, memory } = runHardwareStabilizerDemo();
  const policy = createRuntimePolicy(decision);

  return (
    <View style={styles.wrap}>
      <MauriPanel glow>
        <StatusPill label="DEVICE HARDWARE STABILIZER" tone={toneFromPressure(decision.pressure)} />
        <Text style={styles.score}>{decision.deviceHealthScore}%</Text>
        <Text style={styles.title}>Device Health Score</Text>
        <Text style={styles.detail}>{decision.finalTruth}</Text>
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Current Hardware Sample</Text>
        <Text style={styles.rowText}>Battery: {sample.batteryPercent}%</Text>
        <Text style={styles.rowText}>Charging: {sample.isCharging ? "yes" : "no"}</Text>
        <Text style={styles.rowText}>Thermal risk: {sample.thermalRisk}</Text>
        <Text style={styles.rowText}>Memory pressure: {sample.memoryPressure}</Text>
        <Text style={styles.rowText}>Storage pressure: {sample.storagePressure}</Text>
        <Text style={styles.rowText}>BLE pressure: {sample.blePressure}</Text>
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Optimisation Decision</Text>
        <StatusPill label={decision.safeMode ? "SAFE MODE" : "BALANCED MODE"} tone={decision.safeMode ? "warning" : "success"} />
        <Text style={styles.rowText}>Scan intensity: {decision.scanIntensity}</Text>
        <Text style={styles.rowText}>Animation intensity: {decision.animationIntensity}</Text>
        <Text style={styles.rowText}>Proof tasks: {decision.proofTaskMode}</Text>
        <Text style={styles.rowText}>Route preference: {decision.routePreference}</Text>
        <Text style={styles.rowText}>BLE retry policy: {decision.bleRetryPolicy}</Text>
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Runtime Policy</Text>
        <Text style={styles.rowText}>BLE scan: {policy.allowBleScan ? "allowed" : "paused"}</Text>
        <Text style={styles.rowText}>BLE advertise: {policy.allowBleAdvertise ? "allowed" : "paused"}</Text>
        <Text style={styles.rowText}>Proof hashing: {policy.allowProofHashing ? "allowed" : "deferred"}</Text>
        <Text style={styles.rowText}>Heavy animation: {policy.allowHeavyAnimation ? "allowed" : "reduced"}</Text>
        <Text style={styles.rowText}>Max BLE retries: {policy.maxBleRetries}</Text>
        <Text style={styles.detail}>{policy.operatorMessage}</Text>
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Recommendations</Text>
        {decision.recommendations.map((item) => (
          <Text key={item} style={styles.bullet}>✓ {item}</Text>
        ))}
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Learning Memory</Text>
        <Text style={styles.rowText}>Samples seen: {memory.samplesSeen}</Text>
        {memory.learnedNotes.map((note) => (
          <Text key={note} style={styles.bullet}>• {note}</Text>
        ))}
      </MauriPanel>
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
