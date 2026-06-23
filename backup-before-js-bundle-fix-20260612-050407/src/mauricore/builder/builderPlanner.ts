import { CoreDecision } from "../types/core.types";
import { evaluateAgainstCoreLaws } from "../constitution/coreConstitution";
import { tikangaDecision } from "../culture/tikangaEngine";
import { createProofRecord } from "../proof/proofLedger";
import { recordMemory } from "../memory/livingMemory";

export function planBuildAction(action: string): CoreDecision {
  const core = evaluateAgainstCoreLaws(action);
  const tikanga = tikangaDecision(action);

  if (!tikanga.allowed) {
    const blocked: CoreDecision = {
      ...core,
      status: "requires_review",
      reason: `Tikanga review required: ${tikanga.reason}`,
      tikanga,
      requiresHumanApproval: true,
    };

    createProofRecord({
      layerId: "builder_planner",
      action,
      result: "requires_review",
      evidence: [tikanga.reason],
      confidence: 0.75,
    });

    return blocked;
  }

  createProofRecord({
    layerId: "builder_planner",
    action,
    result: core.status === "blocked" ? "blocked" : "pass",
    evidence: core.evidence || [],
    confidence: core.confidence,
  });

  recordMemory({
    event: "BUILD_ACTION_PLANNED",
    result: core.status === "blocked" ? "blocked" : "success",
    lesson: "Builder must plan through Core Constitution and Tikanga before action.",
    futureBehaviour: "Always plan before patching.",
    confidence: 0.75,
    quality: "observed",
    evidence: [action],
  });

  return {
    ...core,
    tikanga,
  };
}
