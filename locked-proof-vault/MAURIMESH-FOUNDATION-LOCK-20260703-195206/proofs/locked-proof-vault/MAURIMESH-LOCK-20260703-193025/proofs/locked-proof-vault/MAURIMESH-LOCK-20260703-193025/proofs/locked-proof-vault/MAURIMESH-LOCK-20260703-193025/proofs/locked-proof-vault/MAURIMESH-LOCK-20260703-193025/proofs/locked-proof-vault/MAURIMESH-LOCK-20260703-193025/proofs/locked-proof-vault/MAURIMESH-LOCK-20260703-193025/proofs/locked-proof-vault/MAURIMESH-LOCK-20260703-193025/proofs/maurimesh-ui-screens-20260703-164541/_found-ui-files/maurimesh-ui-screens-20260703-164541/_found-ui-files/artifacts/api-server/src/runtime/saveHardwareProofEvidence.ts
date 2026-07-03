import fs from "fs";
import path from "path";
import crypto from "crypto";

export const TASK_189_HARDWARE_EVIDENCE_LEDGER_MARKER =
  "TASK_189_HARDWARE_EVIDENCE_LEDGER_20260608_A";

export type HardwareProofEvidenceRecord = {
  id: string;
  type: "two_phone_hardware_evidence";
  createdAt: string;
  source: "two_phone_proof_screen";
  sha256: string;
  evidenceJson: unknown;
  truthLevel: "hardware_evidence_submitted";
};

const LEDGER_DIR = path.join(process.cwd(), ".maurimesh-runtime");
const LEDGER_PATH = path.join(LEDGER_DIR, "proof-ledger-hardware-evidence.jsonl");

function stableStringify(value: unknown): string {
  return JSON.stringify(value, Object.keys(value as any || {}).sort());
}

function sha256(value: unknown): string {
  return crypto.createHash("sha256").update(JSON.stringify(value)).digest("hex");
}

export function getHardwareProofEvidenceLedgerPath(): string {
  return LEDGER_PATH;
}

export async function saveHardwareProofEvidenceToServerLedger(
  evidenceJson: unknown
): Promise<HardwareProofEvidenceRecord> {
  if (!evidenceJson || typeof evidenceJson !== "object") {
    throw new Error("Evidence JSON must be an object.");
  }

  fs.mkdirSync(LEDGER_DIR, { recursive: true });

  const now = new Date().toISOString();
  const digest = sha256(evidenceJson);

  const record: HardwareProofEvidenceRecord = {
    id: `proof_hw_${Date.now()}_${digest.slice(0, 12)}`,
    type: "two_phone_hardware_evidence",
    createdAt: now,
    source: "two_phone_proof_screen",
    sha256: digest,
    evidenceJson,
    truthLevel: "hardware_evidence_submitted",
  };

  fs.appendFileSync(LEDGER_PATH, JSON.stringify(record) + "\n", "utf8");

  return record;
}

export async function listHardwareProofEvidenceFromServerLedger(
  type?: string
): Promise<HardwareProofEvidenceRecord[]> {
  if (!fs.existsSync(LEDGER_PATH)) return [];

  const rows = fs
    .readFileSync(LEDGER_PATH, "utf8")
    .split("\n")
    .map((line) => line.trim())
    .filter(Boolean)
    .map((line) => JSON.parse(line) as HardwareProofEvidenceRecord)
    .filter((record) => !type || record.type === type);

  return rows.reverse();
}
