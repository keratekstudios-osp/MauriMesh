import { HealthState, RepairPlan } from "../types/core.types";
import { SQRT2_INVERSE, clamp01, entropy } from "../math/mathIntelligence";

export type VitalSigns = {
  heartbeat: boolean;
  apiHealth: number;
  bleHealth: number;
  ackSuccessRate: number;
  routingStability: number;
  memoryIntegrity: number;
  batteryLevel: number;
  crashCount: number;
  proofIntegrity: number;
};

export function healthScore(signs: VitalSigns): number {
  const crashPenalty = signs.crashCount > 0 ? Math.min(0.4, signs.crashCount * 0.12) : 0;
  const disorder = entropy([
    signs.apiHealth,
    signs.bleHealth,
    signs.ackSuccessRate,
    signs.routingStability,
    signs.memoryIntegrity,
    signs.batteryLevel,
    signs.proofIntegrity,
  ]);

  const base =
    (Number(signs.heartbeat) +
      signs.apiHealth +
      signs.bleHealth +
      signs.ackSuccessRate +
      signs.routingStability +
      signs.memoryIntegrity +
      signs.batteryLevel +
      signs.proofIntegrity) /
    8;

  return clamp01(base - crashPenalty - disorder * 0.1);
}

export function classifyHealth(score: number): HealthState {
  if (score >= 0.85) return "healthy";
  if (score >= SQRT2_INVERSE) return "degraded";
  if (score >= 0.35) return "unstable";
  return "critical";
}

export function createRepairPlan(issue: string, signs: VitalSigns): RepairPlan {
  const score = healthScore(signs);
  const state = classifyHealth(score);

  let action: RepairPlan["action"] = "observe";
  let risk: RepairPlan["risk"] = "low";
  const steps: string[] = [];

  if (state === "healthy") {
    steps.push("Continue monitoring.");
  } else if (state === "degraded") {
    action = "auto_repair";
    risk = "low";
    steps.push("Repair smallest safe issue first.");
    steps.push("Prefer retry, fallback, or route downgrade before code changes.");
  } else if (state === "unstable") {
    action = "propose_repair";
    risk = "medium";
    steps.push("Pause layer advancement.");
    steps.push("Create repair proposal.");
    steps.push("Require verification after repair.");
  } else {
    action = "safe_mode";
    risk = "critical";
    steps.push("Enter safe mode.");
    steps.push("Freeze high-risk actions.");
    steps.push("Preserve proof ledger.");
    steps.push("Require human review.");
  }

  return {
    id: `repair_${Date.now()}_${Math.random().toString(36).slice(2)}`,
    timestamp: new Date().toISOString(),
    issue,
    healthState: state,
    risk,
    action,
    steps,
    rollbackRequired: action !== "observe",
  };
}
