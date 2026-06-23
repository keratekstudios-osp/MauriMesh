import {
  MauriAiDecision,
  MauriAiGovernanceResult,
  MauriAiSignal,
} from "../ai/mauriAiTypes";

function clamp01(value: number): number {
  if (!Number.isFinite(value)) return 0;
  return Math.max(0, Math.min(1, value));
}

export class AiGovernanceIntelligence {
  evaluate(signal: MauriAiSignal, proposedDecision: MauriAiDecision): MauriAiGovernanceResult {
    const warnings: string[] = [];

    let score = 1;

    if (!signal.physicalBleProven) {
      score -= 0.35;
      warnings.push("Physical BLE is not proven in this runtime.");
    }

    if (signal.tikangaSafe === false) {
      score -= 0.5;
      warnings.push("Tikanga safety check failed.");
    }

    if (signal.peerTrusted === false) {
      score -= 0.2;
      warnings.push("Peer is not trusted.");
    }

    if (signal.batterySafe === false) {
      score -= 0.15;
      warnings.push("Battery state is unsafe for aggressive routing.");
    }

    score = clamp01(score);

    if (score < 0.35) {
      return {
        allowed: false,
        decision: "block_unsafe",
        score,
        warnings,
        truth: "Governance blocked unsafe or unproven action.",
      };
    }

    if (!signal.physicalBleProven && proposedDecision !== "store_forward") {
      return {
        allowed: false,
        decision: "require_physical_proof",
        score,
        warnings,
        truth: "Physical proof required before live BLE routing claims.",
      };
    }

    return {
      allowed: true,
      decision: proposedDecision,
      score,
      warnings,
      truth: "Governance allowed action with current safety score.",
    };
  }
}
