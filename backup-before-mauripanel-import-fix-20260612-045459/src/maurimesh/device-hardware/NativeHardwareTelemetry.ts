import { NativeModules, Platform } from "react-native";
import { DeviceHardwareSample, HardwarePressure } from "./types";

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

function pressureFromMemory(used: number, total: number): HardwarePressure {
  if (!total || total <= 0) return "medium";
  const ratio = used / total;
  if (ratio >= 0.94) return "critical";
  if (ratio >= 0.84) return "high";
  if (ratio >= 0.68) return "medium";
  return "low";
}

function pressureFromStorage(free: number, total: number): HardwarePressure {
  if (!total || total <= 0) return "medium";
  const ratio = free / total;
  if (ratio <= 0.04) return "critical";
  if (ratio <= 0.1) return "high";
  if (ratio <= 0.22) return "medium";
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
      "JS fallback telemetry. Real hardware readings require APK native module. MauriMesh cannot physically repair hardware or bypass Android protections.",
  };
}

export async function getNativeHardwareTelemetry(): Promise<NativeHardwareTelemetryReading> {
  const nativeModule = NativeModules.MauriMeshHardwareTelemetry as NativeTelemetryModule | undefined;

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
          native.memoryPressure || pressureFromMemory(memoryUsedMb, memoryTotalMb),
        storageFreeMb,
        storageTotalMb,
        storagePressure:
          native.storagePressure || pressureFromStorage(storageFreeMb, storageTotalMb),
        thermalRisk: native.thermalRisk || "medium",
        bleAvailable: Boolean(native.bleAvailable ?? false),
        bleEnabled: Boolean(native.bleEnabled ?? false),
        blePressure: native.blePressure || "medium",
        appCrashRisk: native.appCrashRisk || "low",
        foreground: Boolean(native.foreground ?? true),
        timestamp: Number(native.timestamp ?? Date.now()),
        truth:
          "Native Android telemetry received. MauriMesh can optimise app behaviour but cannot physically repair hardware or bypass Android protections.",
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
