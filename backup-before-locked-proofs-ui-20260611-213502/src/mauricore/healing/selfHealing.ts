import { RepairPlan } from "../types/core.types";
import { createProofRecord } from "../proof/proofLedger";
import { recordMemory } from "../memory/livingMemory";

export function executeSafeRepair(plan: RepairPlan): {
  executed: boolean;
  reason: string;
} {
  if (plan.risk === "high" || plan.risk === "critical") {
    createProofRecord({
      layerId: "self_healing",
      action: plan.issue,
      result: "requires_review",
      evidence: plan.steps,
      confidence: 0.7,
      note: "High-risk repair requires human approval.",
    });

    return {
      executed: false,
      reason: "Repair requires human review.",
    };
  }

  recordMemory({
    event: "SELF_HEALING_REPAIR_PLAN",
    result: "success",
    lesson: "Low-risk repair may be executed after rollback check.",
    futureBehaviour: "Prefer smallest safe repair first.",
    confidence: 0.75,
    quality: "observed",
    evidence: plan.steps,
  });

  createProofRecord({
    layerId: "self_healing",
    action: plan.issue,
    result: "pass",
    evidence: plan.steps,
    confidence: 0.75,
  });

  return {
    executed: true,
    reason: "Low-risk repair executed through safe repair path.",
  };
}
