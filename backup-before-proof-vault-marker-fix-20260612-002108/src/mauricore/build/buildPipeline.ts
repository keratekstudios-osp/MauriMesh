import { BuildReadiness } from "../types/core.types";
import { getLayers } from "../builder/layerRegistry";
import { verifyLayer } from "../builder/verificationGate";
import { verifyProofChain } from "../proof/proofLedger";

export function checkBuildReadiness(): BuildReadiness {
  const layers = getLayers();
  const missing: string[] = [];
  const warnings: string[] = [];
  const requiredProof: string[] = [];

  for (const layer of layers) {
    const report = verifyLayer(layer.id);

    if (!report.ok) {
      if (layer.riskLevel === "critical" || layer.riskLevel === "high") {
        missing.push(layer.id);
      } else {
        warnings.push(`Layer not fully verified: ${layer.id}`);
      }
    }

    if (layer.proofRequired) {
      requiredProof.push(layer.id);
    }
  }

  if (!verifyProofChain()) {
    missing.push("proof_chain_integrity");
  }

  return {
    ok: missing.length === 0,
    canBuildApk: missing.length === 0,
    missing,
    warnings,
    requiredProof,
  };
}

export function buildPipelinePlan(): string[] {
  return [
    "1. Scan layers",
    "2. Verify Core Constitution",
    "3. Verify Proof Ledger integrity",
    "4. Run TypeScript check",
    "5. Run unit/smoke tests",
    "6. Verify rollback readiness",
    "7. Verify simulation/reality boundary",
    "8. Build APK only after gates pass",
    "9. Install APK on physical device",
    "10. Capture runtime logs",
    "11. Complete two-phone proof for BLE layers",
    "12. Record acceptance proof",
  ];
}
