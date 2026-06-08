import { Router } from "express";
import type { Response } from "express";
import { desc, eq } from "drizzle-orm";
import { db, proofLedger } from "../lib/db/src/index";
import { normalizeProofEvidence } from "./proofEvidence";
import type { ProofEvidenceRow } from "./proofEvidence";

export { normalizeProofEvidence, TWO_PHONE_EVIDENCE_TYPE } from "./proofEvidence";

// [SIMULATION - NOT LIVE BLE] Truth boundary: the server persists evidence that a
// CLIENT submits after a hardware run. The server itself cannot observe BLE
// radios, so it never marks these rows verified/real_native — they are recorded
// as client-submitted, unverified evidence.
const TRUTH =
  "[SIMULATION - NOT LIVE BLE] The server records client-submitted proof evidence. " +
  "Server-side storage does not itself prove live BLE; rows are unverified.";

const asOptString = (v: unknown): string | undefined =>
  typeof v === "string" && v.length > 0 ? v : undefined;

const fail = (res: Response, err: unknown, status = 500) => {
  const message = err instanceof Error ? err.message : String(err);
  res.status(status).json({ ok: false, error: message });
};

// Routes for persisting and querying hardware proof evidence in the ProofLedger.
export function createProofRouter(): Router {
  const router = Router();

  // Persist a two-phone hardware proof evidence report so it survives beyond the
  // OS share sheet and becomes queryable from the dashboard.
  router.post("/evidence", async (req, res) => {
    let row: ProofEvidenceRow;
    try {
      row = normalizeProofEvidence(req.body);
    } catch (err) {
      return fail(res, err, 400);
    }
    try {
      const [entry] = await db.insert(proofLedger).values(row).returning();
      res.status(201).json({ ok: true, entry, truth: TRUTH });
    } catch (err) {
      fail(res, err);
    }
  });

  // List proof-ledger entries, newest first. Optional ?type= filter (e.g.
  // ?type=two_phone_hardware_evidence to see only hardware-run results).
  router.get("/evidence", async (req, res) => {
    const type = asOptString(req.query.type);
    try {
      const rows = type
        ? await db
            .select()
            .from(proofLedger)
            .where(eq(proofLedger.eventType, type))
            .orderBy(desc(proofLedger.ts))
        : await db.select().from(proofLedger).orderBy(desc(proofLedger.ts));
      res.json({ ok: true, entries: rows, truth: TRUTH });
    } catch (err) {
      fail(res, err);
    }
  });

  return router;
}
