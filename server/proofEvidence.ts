// TASK_189B_REAL_PROOF_EVIDENCE_HELPER_20260608_A

import crypto from "crypto";

export const TWO_PHONE_HARDWARE_EVIDENCE_TYPE =
  "two_phone_hardware_evidence" as const;

export type TwoPhoneHardwareEvidencePayload = Record<string, unknown>;

export type ProofLedgerEvidenceRow = {
  eventType: typeof TWO_PHONE_HARDWARE_EVIDENCE_TYPE;
  packetId: string;
  fromNode: string;
  toNode: string;
  status: string;
  transport: string;
  proofHash: string;
  evidenceJson: unknown;
  ts: Date;
};

export function hashEvidence(evidence: unknown): string {
  return crypto
    .createHash("sha256")
    .update(JSON.stringify(evidence))
    .digest("hex");
}

export function shapeTwoPhoneHardwareEvidenceRow(
  evidence: unknown
): ProofLedgerEvidenceRow {
  if (!evidence || typeof evidence !== "object") {
    throw new Error("Evidence payload must be a JSON object.");
  }

  const body = evidence as TwoPhoneHardwareEvidencePayload;
  const proofHash = hashEvidence(body);

  return {
    eventType: TWO_PHONE_HARDWARE_EVIDENCE_TYPE,
    packetId: String(
      body.packetId ||
        body.id ||
        `two_phone_hw_${Date.now()}_${proofHash.slice(0, 8)}`
    ),
    fromNode: String(body.fromNode || body.from || body.phoneA || "unknown_sender"),
    toNode: String(body.toNode || body.to || body.phoneB || "unknown_receiver"),
    status: String(body.status || body.result || "hardware_evidence_submitted"),
    transport: String(body.transport || "BLE"),
    proofHash,
    evidenceJson: body,
    ts: new Date(),
  };
}
