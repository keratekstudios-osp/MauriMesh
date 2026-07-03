import { ProofRecord, ProofResult } from "../types/core.types";
import { deterministicHash } from "./hashEngine";

const proofLedger: ProofRecord[] = [];

export function createProofRecord(input: {
  layerId: string;
  action: string;
  result: ProofResult;
  evidence?: string[];
  confidence?: number;
  note?: string;
}): ProofRecord {
  const previous = proofLedger[proofLedger.length - 1];

  const draft = {
    id: `proof_${Date.now()}_${Math.random().toString(36).slice(2)}`,
    timestamp: new Date().toISOString(),
    layerId: input.layerId,
    action: input.action,
    result: input.result,
    evidence: input.evidence || [],
    previousHash: previous?.hash,
    confidence: input.confidence ?? 0.5,
    note: input.note,
  };

  const record: ProofRecord = {
    ...draft,
    hash: deterministicHash(draft),
  };

  proofLedger.push(record);
  return record;
}

export function getProofLedger(): ProofRecord[] {
  return [...proofLedger];
}

export function verifyProofChain(records = proofLedger): boolean {
  for (let i = 0; i < records.length; i++) {
    const current = records[i];
    if (i > 0 && current.previousHash !== records[i - 1].hash) return false;
  }

  return true;
}

export function hasPassingProof(layerId: string): boolean {
  return proofLedger.some((record) => record.layerId === layerId && record.result === "pass");
}
