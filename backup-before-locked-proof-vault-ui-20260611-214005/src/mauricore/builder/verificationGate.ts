import { VerificationReport } from "../types/core.types";
import { getLayer } from "./layerRegistry";
import { hasPassingProof, verifyProofChain } from "../proof/proofLedger";

export function verifyLayer(layerId: string): VerificationReport {
  const layer = getLayer(layerId);

  if (!layer) {
    return {
      ok: false,
      layerId,
      checks: [{ name: "layer_exists", ok: false, detail: "Layer not found." }],
      decision: "hold",
    };
  }

  const checks = [
    {
      name: "layer_exists",
      ok: true,
      detail: "Layer exists in registry.",
    },
    {
      name: "rollback_ready",
      ok: layer.rollbackReady,
      detail: layer.rollbackReady ? "Rollback is ready." : "Rollback missing.",
    },
    {
      name: "proof_chain",
      ok: verifyProofChain(),
      detail: "Proof chain integrity check.",
    },
    {
      name: "passing_proof",
      ok: !layer.proofRequired || hasPassingProof(layerId),
      detail: layer.proofRequired ? "Layer requires passing proof." : "Layer does not require proof.",
    },
    {
      name: "confidence",
      ok: layer.confidence >= 0.72,
      detail: `Layer confidence: ${layer.confidence}`,
    },
  ];

  const ok = checks.every((check) => check.ok);

  return {
    ok,
    layerId,
    checks,
    decision: ok ? "advance" : layer.riskLevel === "critical" ? "review" : "hold",
  };
}
