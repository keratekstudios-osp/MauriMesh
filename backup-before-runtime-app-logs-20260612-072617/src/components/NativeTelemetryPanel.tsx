import React, { useEffect, useState } from "react";
import { StyleSheet, Text, View } from "react-native";
import {
  analyseHardwareSample,
  createRuntimePolicy,
  getNativeHardwareTelemetry,
  NativeHardwareTelemetryReading,
  telemetryToHardwareSample,
} from "../maurimesh/device-hardware";
import { mauriTheme } from "../theme/mauriTheme";
import { StatusPill } from "./StatusPill";

import { MauriPanel } from "./MauriPanel";
function sourceTone(source: string): "success" | "warning" | "danger" | "info" {
  return source === "NATIVE_ANDROID" ? "success" : "warning";
}

function pressureTone(pressure: string): "success" | "warning" | "danger" | "info" {
  if (pressure === "low") return "success";
  if (pressure === "medium") return "warning";
  return "danger";
}

export function NativeTelemetryPanel() {
  const [reading, setReading] = useState<NativeHardwareTelemetryReading | null>(null);

  useEffect(() => {
    getNativeHardwareTelemetry().then(setReading);
  }, []);

  if (!reading) {
    return (
      <MauriPanel>
        <StatusPill label="LOADING TELEMETRY" tone="info" />
        <Text style={styles.detail}>Reading telemetry...</Text>
      </MauriPanel>
    );
  }

  const sample = telemetryToHardwareSample(reading);
  const decision = analyseHardwareSample(sample);
  const policy = createRuntimePolicy(decision);

  return (
    <View style={styles.wrap}>
      <MauriPanel glow>
        <StatusPill label={reading.source} tone={sourceTone(reading.source)} />
        <Text style={styles.score}>{decision.deviceHealthScore}%</Text>
        <Text style={styles.title}>Native Telemetry Health</Text>
        <Text style={styles.detail}>{reading.truth}</Text>
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Battery</Text>
        <Text style={styles.rowText}>Battery: {reading.batteryPercent}%</Text>
        <Text style={styles.rowText}>Charging: {reading.isCharging ? "yes" : "no"}</Text>
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Memory</Text>
        <StatusPill label={reading.memoryPressure} tone={pressureTone(reading.memoryPressure)} />
        <Text style={styles.rowText}>Used: {reading.memoryUsedMb} MB</Text>
        <Text style={styles.rowText}>Total: {reading.memoryTotalMb} MB</Text>
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Storage</Text>
        <StatusPill label={reading.storagePressure} tone={pressureTone(reading.storagePressure)} />
        <Text style={styles.rowText}>Free: {reading.storageFreeMb} MB</Text>
        <Text style={styles.rowText}>Total: {reading.storageTotalMb} MB</Text>
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Thermal + BLE</Text>
        <Text style={styles.rowText}>Thermal risk: {reading.thermalRisk}</Text>
        <Text style={styles.rowText}>BLE available: {reading.bleAvailable ? "yes" : "no"}</Text>
        <Text style={styles.rowText}>BLE enabled: {reading.bleEnabled ? "yes" : "no"}</Text>
        <Text style={styles.rowText}>BLE pressure: {reading.blePressure}</Text>
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Runtime Policy</Text>
        <Text style={styles.rowText}>BLE scan: {policy.allowBleScan ? "allowed" : "paused"}</Text>
        <Text style={styles.rowText}>BLE advertise: {policy.allowBleAdvertise ? "allowed" : "paused"}</Text>
        <Text style={styles.rowText}>Proof hashing: {policy.allowProofHashing ? "allowed" : "deferred"}</Text>
        <Text style={styles.rowText}>Heavy animation: {policy.allowHeavyAnimation ? "allowed" : "reduced"}</Text>
        <Text style={styles.rowText}>Route mode: {policy.routeMode}</Text>
        <Text style={styles.detail}>{policy.operatorMessage}</Text>
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Truth Boundary</Text>
        <Text style={styles.detail}>
          This reads and adapts to device conditions when native APK telemetry exists. It cannot repair physical hardware, override Android restrictions, or prove BLE delivery without TX/RX/ACK logs.
        </Text>
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
});
