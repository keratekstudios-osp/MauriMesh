export type HardwarePressure = "low" | "medium" | "high" | "critical";

export type DeviceHardwareSample = {
  batteryPercent: number;
  isCharging: boolean;
  thermalRisk: HardwarePressure;
  memoryPressure: HardwarePressure;
  storagePressure: HardwarePressure;
  networkPressure: HardwarePressure;
  blePressure: HardwarePressure;
  appCrashRisk: HardwarePressure;
  foreground: boolean;
  timestamp: number;
};

export type HardwareOptimisationDecision = {
  deviceHealthScore: number;
  pressure: HardwarePressure;
  safeMode: boolean;
  scanIntensity: "off" | "low" | "balanced" | "high";
  animationIntensity: "minimal" | "balanced" | "rich";
  proofTaskMode: "pause" | "defer" | "normal" | "priority";
  routePreference: "low_energy" | "balanced" | "fastest" | "store_forward";
  bleRetryPolicy: "pause" | "slow_retry" | "normal_retry";
  recommendations: string[];
  finalTruth: string;
};

export type HardwareLearningMemory = {
  samplesSeen: number;
  lastScores: number[];
  repeatedFaults: string[];
  learnedNotes: string[];
};
