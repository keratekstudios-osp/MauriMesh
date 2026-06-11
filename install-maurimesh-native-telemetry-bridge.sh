#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "INSTALL MAURIMESH NATIVE HARDWARE TELEMETRY BRIDGE"
echo "Adds native telemetry interface + safe JS fallback + UI screen."
echo "This prepares MauriMesh for APK/device hardware readings."
echo "Does not delete existing UI/intelligence/hardware layers."
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$ROOT/backup-before-native-telemetry-$STAMP"

APP="$ROOT/app"
SRC="$ROOT/src"
HW="$SRC/maurimesh/device-hardware"
COMP="$SRC/components"
DOCS="$ROOT/docs"

mkdir -p "$BACKUP" "$APP" "$HW" "$COMP" "$DOCS"

if [ ! -f "$ROOT/package.json" ]; then
  echo "ERROR: package.json not found. Run from Replit project root."
  exit 1
fi

backup_file() {
  local file="$1"
  if [ -f "$ROOT/$file" ]; then
    mkdir -p "$BACKUP/$(dirname "$file")"
    cp "$ROOT/$file" "$BACKUP/$file"
  fi
}

backup_file "app/dashboard.tsx"
backup_file "app/native-telemetry.tsx"
backup_file "src/lib/uiBackupRoutes.ts"
backup_file "src/components/NativeTelemetryPanel.tsx"
backup_file "src/maurimesh/device-hardware/NativeHardwareTelemetry.ts"
backup_file "src/maurimesh/device-hardware/index.ts"

echo "Backup saved:"
echo "$BACKUP"

# ============================================================
# 1. NATIVE HARDWARE TELEMETRY TYPES + SAFE BRIDGE
# ============================================================

cat > "$HW/NativeHardwareTelemetry.ts" <<'TS'
import { NativeModules, Platform } from "react-native";
import {
  DeviceHardwareSample,
  HardwarePressure,
} from "./types";

export type NativeHardwareTelemetryReading = {
  source: "NATIVE_ANDROID" | "JS_FALLBACK";
  platform: string;
  batteryPercent: number;
  isCharging: boolean;
  memoryUsedMb: number;
  memoryTotalMb: number;
  memoryPressure: HardwarePressure;
  storageFreeMb: number;
  storageTotalMb: number;
  storagePressure: HardwarePressure;
  thermalRisk: HardwarePressure;
  bleAvailable: boolean;
  bleEnabled: boolean;
  blePressure: HardwarePressure;
  appCrashRisk: HardwarePressure;
  foreground: boolean;
  timestamp: number;
  truth: string;
};

type NativeTelemetryModule = {
  getHardwareTelemetry?: () => Promise<Partial<NativeHardwareTelemetryReading>>;
};

function toPressureFromRatio(used: number, total: number): HardwarePressure {
  if (!total || total <= 0) return "medium";
  const ratio = used / total;

  if (ratio >= 0.94) return "critical";
  if (ratio >= 0.84) return "high";
  if (ratio >= 0.68) return "medium";
  return "low";
}

function toStoragePressure(free: number, total: number): HardwarePressure {
  if (!total || total <= 0) return "medium";
  const freeRatio = free / total;

  if (freeRatio <= 0.04) return "critical";
  if (freeRatio <= 0.10) return "high";
  if (freeRatio <= 0.22) return "medium";
  return "low";
}

function fallbackReading(): NativeHardwareTelemetryReading {
  return {
    source: "JS_FALLBACK",
    platform: Platform.OS,
    batteryPercent: 68,
    isCharging: false,
    memoryUsedMb: 1200,
    memoryTotalMb: 4096,
    memoryPressure: "medium",
    storageFreeMb: 8192,
    storageTotalMb: 64000,
    storagePressure: "low",
    thermalRisk: "low",
    bleAvailable: Platform.OS === "android",
    bleEnabled: false,
    blePressure: "medium",
    appCrashRisk: "low",
    foreground: true,
    timestamp: Date.now(),
    truth:
      "JS fallback telemetry is a safe placeholder. Real battery, memory, storage, thermal, and BLE state require APK native module integration. MauriMesh cannot physically repair hardware or bypass Android protections.",
  };
}

export async function getNativeHardwareTelemetry(): Promise<NativeHardwareTelemetryReading> {
  const nativeModule = NativeModules.MauriMeshHardwareTelemetry as
    | NativeTelemetryModule
    | undefined;

  if (
    Platform.OS === "android" &&
    nativeModule &&
    typeof nativeModule.getHardwareTelemetry === "function"
  ) {
    try {
      const native = await nativeModule.getHardwareTelemetry();

      const memoryUsedMb = Number(native.memoryUsedMb ?? 0);
      const memoryTotalMb = Number(native.memoryTotalMb ?? 0);
      const storageFreeMb = Number(native.storageFreeMb ?? 0);
      const storageTotalMb = Number(native.storageTotalMb ?? 0);

      return {
        source: "NATIVE_ANDROID",
        platform: "android",
        batteryPercent: Number(native.batteryPercent ?? 50),
        isCharging: Boolean(native.isCharging ?? false),
        memoryUsedMb,
        memoryTotalMb,
        memoryPressure:
          native.memoryPressure ||
          toPressureFromRatio(memoryUsedMb, memoryTotalMb),
        storageFreeMb,
        storageTotalMb,
        storagePressure:
          native.storagePressure ||
          toStoragePressure(storageFreeMb, storageTotalMb),
        thermalRisk: native.thermalRisk || "medium",
        bleAvailable: Boolean(native.bleAvailable ?? false),
        bleEnabled: Boolean(native.bleEnabled ?? false),
        blePressure: native.blePressure || "medium",
        appCrashRisk: native.appCrashRisk || "low",
        foreground: Boolean(native.foreground ?? true),
        timestamp: Number(native.timestamp ?? Date.now()),
        truth:
          "Native Android telemetry received from APK bridge. This reads device state, but still cannot physically repair hardware or bypass Android protections.",
      };
    } catch {
      return fallbackReading();
    }
  }

  return fallbackReading();
}

export function telemetryToHardwareSample(
  reading: NativeHardwareTelemetryReading
): DeviceHardwareSample {
  return {
    batteryPercent: reading.batteryPercent,
    isCharging: reading.isCharging,
    thermalRisk: reading.thermalRisk,
    memoryPressure: reading.memoryPressure,
    storagePressure: reading.storagePressure,
    networkPressure: "medium",
    blePressure: reading.blePressure,
    appCrashRisk: reading.appCrashRisk,
    foreground: reading.foreground,
    timestamp: reading.timestamp,
  };
}
TS

# ============================================================
# 2. EXPORT FROM DEVICE-HARDWARE INDEX
# ============================================================

if [ -f "$HW/index.ts" ]; then
  if ! grep -Fq './NativeHardwareTelemetry' "$HW/index.ts"; then
    cat >> "$HW/index.ts" <<'TS'
export * from "./NativeHardwareTelemetry";
TS
  fi
else
  cat > "$HW/index.ts" <<'TS'
export * from "./NativeHardwareTelemetry";
TS
fi

# ============================================================
# 3. UI PANEL
# ============================================================

cat > "$COMP/NativeTelemetryPanel.tsx" <<'TSX'
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
import { MauriPanel } from "./MauriPanel";
import { StatusPill } from "./StatusPill";

function toneFromSource(
  source: string
): "success" | "warning" | "danger" | "info" {
  return source === "NATIVE_ANDROID" ? "success" : "warning";
}

function toneFromPressure(
  pressure: string
): "success" | "warning" | "danger" | "info" {
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
        <Text style={styles.detail}>Reading device telemetry state...</Text>
      </MauriPanel>
    );
  }

  const sample = telemetryToHardwareSample(reading);
  const decision = analyseHardwareSample(sample);
  const policy = createRuntimePolicy(decision);

  return (
    <View style={styles.wrap}>
      <MauriPanel glow>
        <StatusPill label={reading.source} tone={toneFromSource(reading.source)} />
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
        <StatusPill label={reading.memoryPressure} tone={toneFromPressure(reading.memoryPressure)} />
        <Text style={styles.rowText}>Used: {reading.memoryUsedMb} MB</Text>
        <Text style={styles.rowText}>Total: {reading.memoryTotalMb} MB</Text>
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Storage</Text>
        <StatusPill label={reading.storagePressure} tone={toneFromPressure(reading.storagePressure)} />
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
        <Text style={styles.sectionTitle}>Runtime Policy From Telemetry</Text>
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
          This bridge can read and adapt to device conditions inside an APK. It cannot repair physical hardware, override Android restrictions, or prove BLE delivery without TX/RX/ACK device logs.
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
TSX

# ============================================================
# 4. SCREEN
# ============================================================

cat > "$APP/native-telemetry.tsx" <<'TSX'
import React from "react";
import { AppShell } from "../src/components/AppShell";
import { MauriPageHeader } from "../src/components/MauriPageHeader";
import { NativeTelemetryPanel } from "../src/components/NativeTelemetryPanel";

export default function NativeTelemetryScreen() {
  return (
    <AppShell>
      <MauriPageHeader
        eyebrow="NATIVE TELEMETRY"
        title="Native Telemetry"
        subtitle="APK-ready hardware bridge for battery, memory, storage, thermal, BLE adapter state, and runtime optimisation."
        tone="info"
      />
      <NativeTelemetryPanel />
    </AppShell>
  );
}
TSX

# ============================================================
# 5. KOTLIN TEMPLATE DOC
# ============================================================

cat > "$DOCS/maurimesh-native-telemetry-kotlin-template-$STAMP.md" <<'MD'
# MauriMesh Native Android Telemetry Kotlin Template

This is the native module target name expected by JS:

```txt
MauriMeshHardwareTelemetry
