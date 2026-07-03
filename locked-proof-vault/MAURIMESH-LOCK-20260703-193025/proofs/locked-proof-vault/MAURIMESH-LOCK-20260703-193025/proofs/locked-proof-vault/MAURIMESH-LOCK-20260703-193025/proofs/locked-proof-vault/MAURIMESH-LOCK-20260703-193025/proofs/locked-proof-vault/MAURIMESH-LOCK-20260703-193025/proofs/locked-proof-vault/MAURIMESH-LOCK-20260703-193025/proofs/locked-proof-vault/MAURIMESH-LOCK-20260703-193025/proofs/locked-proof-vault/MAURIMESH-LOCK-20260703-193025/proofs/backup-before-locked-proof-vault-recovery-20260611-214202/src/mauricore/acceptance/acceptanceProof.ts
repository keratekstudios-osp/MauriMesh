import { AcceptanceProof } from "../types/core.types";
import { checkBuildReadiness } from "../build/buildPipeline";
import { verifyProofChain } from "../proof/proofLedger";

export function createAcceptanceProof(): AcceptanceProof {
  const build = checkBuildReadiness();
  const proofChainOk = verifyProofChain();

  const passed: string[] = [];
  const failed: string[] = [];
  const requiredNext: string[] = [];

  if (proofChainOk) passed.push("Proof chain integrity");
  else failed.push("Proof chain integrity");

  if (build.canBuildApk) passed.push("Build readiness gate");
  else {
    failed.push("Build readiness gate");
    requiredNext.push(...build.missing);
  }

  return {
    accepted: failed.length === 0,
    summary:
      failed.length === 0
        ? "MauriCore v1 passed acceptance gates."
        : "MauriCore v1 scaffold installed, but production acceptance requires remaining proof.",
    passed,
    failed,
    requiredNext,
  };
}
