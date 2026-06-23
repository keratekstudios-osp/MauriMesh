import { CoreDecision, RiskLevel } from "../types/core.types";
import { mauriCoreConfig } from "../config/mauricore.config";

export const CORE_LAWS = [
  "Understand first.",
  "Protect the foundation.",
  "Verify before change.",
  "Use logic before action.",
  "Never fake proof.",
  "Never label simulation as live.",
  "Never delete working systems without backup.",
  "Preserve original engineering intent.",
  "Prefer repair over rebuild.",
  "Advance layers only after verification.",
  "Protect privacy, identity, and user data.",
  "High-risk actions require human approval.",
  "Core moral rules cannot be auto-mutated.",
];

export function riskFromAction(action: string): RiskLevel {
  const lower = action.toLowerCase();

  if (
    lower.includes("identity") ||
    lower.includes("crypto") ||
    lower.includes("delete") ||
    lower.includes("native") ||
    lower.includes("ble permission") ||
    lower.includes("core constitution")
  ) {
    return "critical";
  }

  if (
    lower.includes("ble") ||
    lower.includes("routing") ||
    lower.includes("packet") ||
    lower.includes("build.gradle") ||
    lower.includes("androidmanifest")
  ) {
    return "high";
  }

  if (
    lower.includes("api") ||
    lower.includes("storage") ||
    lower.includes("memory") ||
    lower.includes("proof")
  ) {
    return "medium";
  }

  return "low";
}

export function createCoreDecision(action: string, reason: string, confidence = 0.75): CoreDecision {
  const risk = riskFromAction(action);
  const requiresHumanApproval =
    risk === "critical" ||
    (risk === "high" && mauriCoreConfig.governance.humanApprovalForHighRisk);

  return {
    id: `decision_${Date.now()}_${Math.random().toString(36).slice(2)}`,
    timestamp: new Date().toISOString(),
    action,
    status: requiresHumanApproval ? "requires_review" : "allowed",
    reason,
    risk,
    confidence,
    requiresProof: true,
    requiresHumanApproval,
    evidence: ["core_constitution_evaluated"],
  };
}

export function blockDecision(action: string, reason: string): CoreDecision {
  return {
    id: `blocked_${Date.now()}_${Math.random().toString(36).slice(2)}`,
    timestamp: new Date().toISOString(),
    action,
    status: "blocked",
    reason,
    risk: "critical",
    confidence: 1,
    requiresProof: true,
    requiresHumanApproval: true,
    evidence: ["core_law_block"],
  };
}

export function evaluateAgainstCoreLaws(action: string): CoreDecision {
  const lower = action.toLowerCase();

  if (lower.includes("fake proof") || lower.includes("label simulation as live")) {
    return blockDecision(action, "Blocked by Core Law: never fake proof or label simulation as live.");
  }

  if (lower.includes("delete working") || lower.includes("overwrite core")) {
    return blockDecision(action, "Blocked by Core Law: protect foundation and preserve working systems.");
  }

  return createCoreDecision(action, "Action passed initial Core Constitution evaluation.");
}
