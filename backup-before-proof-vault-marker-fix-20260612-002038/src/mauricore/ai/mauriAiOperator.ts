import { planBuildAction } from "../builder/builderPlanner";
import { getLayers } from "../builder/layerRegistry";
import { detectMemoryPoisoning, getLivingMemory } from "../memory/livingMemory";
import { getProofLedger } from "../proof/proofLedger";

export function mauriAiSystemReview() {
  const layers = getLayers();
  const memory = getLivingMemory();
  const proof = getProofLedger();
  const poisoningAlerts = detectMemoryPoisoning();

  const missingOrWeak = layers.filter((layer) => {
    return layer.status === "missing" || layer.status === "partial" || layer.confidence < 0.72;
  });

  const nextActions = missingOrWeak.map((layer) => {
    return planBuildAction(`Improve layer: ${layer.id}`);
  });

  return {
    timestamp: new Date().toISOString(),
    layersTotal: layers.length,
    weakLayers: missingOrWeak.map((layer) => layer.id),
    memoryRecords: memory.length,
    proofRecords: proof.length,
    poisoningAlerts,
    nextActions,
    summary:
      "Mauri AI reviewed layers, memory, proof, and poisoning risk. It proposes governed improvements only.",
  };
}

export function detectContradiction(inputs: string[]): string[] {
  const contradictions: string[] = [];

  const joined = inputs.join(" ").toLowerCase();

  if (joined.includes("simulation") && joined.includes("live proof")) {
    contradictions.push("Contradiction: simulation cannot be live proof.");
  }

  if (joined.includes("delete") && joined.includes("protect foundation")) {
    contradictions.push("Contradiction: delete action conflicts with foundation protection.");
  }

  return contradictions;
}

export function driftDetector(originalPurpose: string, currentBehaviour: string): {
  driftDetected: boolean;
  reason: string;
} {
  const purpose = originalPurpose.toLowerCase();
  const behaviour = currentBehaviour.toLowerCase();

  if (behaviour.includes("fake proof") || behaviour.includes("unsafe autonomy")) {
    return {
      driftDetected: true,
      reason: "Behaviour violates Core truth or safety principles.",
    };
  }

  if (purpose.includes("privacy") && behaviour.includes("share private")) {
    return {
      driftDetected: true,
      reason: "Behaviour drifted away from privacy foundation.",
    };
  }

  return {
    driftDetected: false,
    reason: "No major drift detected.",
  };
}
