import { CoreMode } from "../types/core.types";

export const mauriCoreConfig = {
  coreName: "MauriCore Living Kernel",
  version: "1.0.0",
  mode: (process.env.MAURICORE_MODE as CoreMode) || "development",

  proof: {
    requireProofForLayerAdvance: true,
    allowSimulationAsProof: false,
    requireRollbackBeforePatch: true,
    chainProofRecords: true,
  },

  governance: {
    humanApprovalForHighRisk: true,
    protectTikangaRules: true,
    protectIdentityRules: true,
    protectPrivacyRules: true,
    protectCoreConstitution: true,
  },

  learning: {
    allowLearning: process.env.MAURICORE_ENABLE_LEARNING !== "false",
    allowSelfMutation: false,
    requireVerifiedMemory: true,
    protectAgainstMemoryPoisoning: true,
  },

  routing: {
    safestVerifiedRouteWins: true,
    useAckHistory: true,
    useBatteryAwareness: true,
    usePrivacyRisk: true,
    useTrustScore: true,
    maxHops: 8,
  },

  healing: {
    allowLowRiskAutoRepair: true,
    allowMediumRiskAutoRepair: false,
    allowHighRiskAutoRepair: false,
    enterSafeModeOnCritical: true,
  },

  build: {
    allowApkBuildOnlyAfterVerification: true,
    requireTypecheck: true,
    requireTestReport: true,
    requireDeviceProofForBle: true,
  },

  boundaries: {
    simulationMustBeLabelled: true,
    replitBleProofAllowed: false,
    nativeProofRequiresPhysicalDevices: true,
  },
};
