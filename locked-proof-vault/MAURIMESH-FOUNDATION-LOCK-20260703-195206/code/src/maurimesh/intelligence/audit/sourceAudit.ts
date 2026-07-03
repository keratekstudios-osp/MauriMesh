export const MAURIMESH_UNIFIED_SPINE_REQUIRED_FILES = [
  "src/maurimesh/intelligence/types.ts",
  "src/maurimesh/intelligence/routing/routeScoring.ts",
  "src/maurimesh/intelligence/resilience/selfHealing.ts",
  "src/maurimesh/intelligence/governance/tikangaGovernance.ts",
  "src/maurimesh/intelligence/proof/proofVerdict.ts",
  "src/maurimesh/intelligence/exam/examEngine.ts",
  "src/maurimesh/intelligence/spine/unifiedSpine.ts",
  "app/maurimesh-spine-exam.tsx",
];

export function mauriMeshSourceAuditSummary() {
  return {
    system: "MAURIMESH_UNIFIED_INTELLIGENCE_SPINE_V1",
    requiredFiles: MAURIMESH_UNIFIED_SPINE_REQUIRED_FILES,
    requiredRuntimeScreens: [
      "/dashboard",
      "/3-device-proof",
      "/store-forward-proof",
      "/proof-vault-health",
      "/locked-proof-vault",
      "/learner-core",
      "/maurimesh-spine-exam",
    ],
    truth:
      "Source audit confirms structure only. Runtime phone proof and native BLE/GATT packet-bound evidence are separate gates.",
  };
}
