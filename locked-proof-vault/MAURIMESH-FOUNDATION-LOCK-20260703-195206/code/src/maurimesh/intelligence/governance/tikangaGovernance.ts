import { MauriMeshGovernanceResult } from "../types";

export function mauriMeshTikangaGovernance(input: {
  packetId?: string;
  proofType?: string;
  claimsNativeBleGattPass?: boolean;
  hasNativeBleGattEvidence?: boolean;
  storesProof?: boolean;
  userApprovedExam?: boolean;
  protectedTerms?: string[];
}): MauriMeshGovernanceResult {
  const tikanga = ["pono", "tika", "manaakitanga", "kaitiakitanga", "rangatiratanga"];
  const warnings: string[] = [];

  if (input.claimsNativeBleGattPass && !input.hasNativeBleGattEvidence) {
    return {
      decision: "REFUSED",
      risk: "PROTECTED",
      tikanga,
      warnings: ["Native BLE/GATT PASS claim blocked because native packet-bound evidence is missing."],
      reason: "Pono/tika requires proof claims to match evidence.",
    };
  }

  if (!input.userApprovedExam) {
    warnings.push("Exam approval not confirmed.");
  }

  if (!input.storesProof) {
    warnings.push("Proof vault storage not confirmed.");
  }

  if (input.protectedTerms?.length) {
    warnings.push(`Protected cultural terms present: ${input.protectedTerms.join(", ")}`);
  }

  const risk = warnings.length >= 2 ? "HIGH" : warnings.length === 1 ? "MEDIUM" : "LOW";
  const decision = warnings.length >= 2 ? "REVIEW_REQUIRED" : warnings.length === 1 ? "APPROVED_WITH_WARNING" : "APPROVED";

  return {
    decision,
    risk,
    tikanga,
    warnings,
    reason: warnings.length ? "Approved conditionally with governance warnings." : "Governance approved.",
  };
}
