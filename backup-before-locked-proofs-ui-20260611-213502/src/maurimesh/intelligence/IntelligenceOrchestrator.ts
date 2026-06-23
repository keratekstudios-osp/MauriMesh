import { evaluateDeviceReadiness } from "./DeviceReadinessIntelligence";
import { evaluateProof } from "./ProofIntelligence";
import { decideBestRoute } from "./RouteIntelligence";
import { evaluateSelfHealing } from "./SelfHealingIntelligence";
import { evaluateTikangaGovernance } from "./TikangaIntelligence";
import { IntelligenceReport, IntelligenceSignal } from "./types";

function statusFromScore(score: number): IntelligenceSignal["status"] {
  if (score >= 90) return "excellent";
  if (score >= 75) return "good";
  if (score >= 50) return "warning";
  return "critical";
}

export function generateIntelligenceReport(): IntelligenceReport {
  const route = decideBestRoute();
  const proof = evaluateProof();
  const governance = evaluateTikangaGovernance();
  const selfHealing = evaluateSelfHealing();
  const deviceReadiness = evaluateDeviceReadiness();

  const signals: IntelligenceSignal[] = [
    {
      id: "route",
      name: "Routing Intelligence",
      score: route.score,
      status: statusFromScore(route.score),
      detail: route.reason,
    },
    {
      id: "proof",
      name: "Proof Intelligence",
      score: proof.confidence,
      status: statusFromScore(proof.confidence),
      detail: proof.truth,
    },
    {
      id: "governance",
      name: "Tikanga Governance",
      score: governance.manaProtection,
      status: statusFromScore(governance.manaProtection),
      detail: governance.auditNote,
    },
    {
      id: "self_healing",
      name: "Self-Healing",
      score: selfHealing.healthScore,
      status: statusFromScore(selfHealing.healthScore),
      detail: `Homeostasis: ${selfHealing.homeostasis}`,
    },
    {
      id: "device_readiness",
      name: "Device Readiness",
      score: deviceReadiness.readinessScore,
      status: statusFromScore(deviceReadiness.readinessScore),
      detail: deviceReadiness.readyForRealBleProof
        ? "Ready for real BLE proof."
        : "APK/device proof still required.",
    },
  ];

  const overallScore = Math.round(
    signals.reduce((sum, signal) => sum + signal.score, 0) / signals.length
  );

  return {
    mode: "SIMULATION",
    overallScore,
    signals,
    route,
    proof,
    governance,
    selfHealing,
    deviceReadiness,
    finalTruth:
      "This intelligence layer scores UI/runtime readiness and decision logic. It does not prove real BLE until APK/device logcat proof is captured.",
  };
}
