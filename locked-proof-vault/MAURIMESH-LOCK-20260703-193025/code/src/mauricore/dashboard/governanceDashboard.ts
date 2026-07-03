import { getLayers } from "../builder/layerRegistry";
import { checkBuildReadiness } from "../build/buildPipeline";
import { getLivingMemory } from "../memory/livingMemory";
import { getProofLedger, verifyProofChain } from "../proof/proofLedger";
import { mauriAiSystemReview } from "../ai/mauriAiOperator";

export function getGovernanceDashboardData() {
  const layers = getLayers();
  const proof = getProofLedger();
  const memory = getLivingMemory();
  const build = checkBuildReadiness();

  return {
    timestamp: new Date().toISOString(),
    core: {
      name: "MauriCore Living Kernel",
      version: "1.0.0",
      proofChainOk: verifyProofChain(),
    },
    layers,
    proofCount: proof.length,
    memoryCount: memory.length,
    build,
    mauriAi: mauriAiSystemReview(),
  };
}
