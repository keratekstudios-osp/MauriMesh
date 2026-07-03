import type { Express, Request, Response } from "express";
import {
  listHardwareProofEvidenceFromServerLedger,
  saveHardwareProofEvidenceToServerLedger,
  TASK_189_HARDWARE_EVIDENCE_LEDGER_MARKER,
} from "../runtime/saveHardwareProofEvidence";

export function registerProofEvidenceRoute(app: Express): void {
  app.post("/api/proof/evidence", async (req: Request, res: Response) => {
    try {
      const evidenceJson = req.body?.evidenceJson ?? req.body;

      const saved = await saveHardwareProofEvidenceToServerLedger(evidenceJson);

      res.json({
        ok: true,
        marker: TASK_189_HARDWARE_EVIDENCE_LEDGER_MARKER,
        type: saved.type,
        record: saved,
      });
    } catch (error) {
      res.status(400).json({
        ok: false,
        marker: TASK_189_HARDWARE_EVIDENCE_LEDGER_MARKER,
        error: error instanceof Error ? error.message : String(error),
      });
    }
  });

  app.get("/api/proof/evidence", async (req: Request, res: Response) => {
    try {
      const type =
        typeof req.query.type === "string" ? req.query.type : undefined;

      const entries = await listHardwareProofEvidenceFromServerLedger(type);

      res.json({
        ok: true,
        marker: TASK_189_HARDWARE_EVIDENCE_LEDGER_MARKER,
        entries,
      });
    } catch (error) {
      res.status(500).json({
        ok: false,
        marker: TASK_189_HARDWARE_EVIDENCE_LEDGER_MARKER,
        error: error instanceof Error ? error.message : String(error),
      });
    }
  });

  // Compatibility path if existing API mounts routes without /api prefix.
  app.post("/proof/evidence", async (req: Request, res: Response) => {
    try {
      const evidenceJson = req.body?.evidenceJson ?? req.body;
      const saved = await saveHardwareProofEvidenceToServerLedger(evidenceJson);
      res.json({ ok: true, marker: TASK_189_HARDWARE_EVIDENCE_LEDGER_MARKER, record: saved });
    } catch (error) {
      res.status(400).json({
        ok: false,
        marker: TASK_189_HARDWARE_EVIDENCE_LEDGER_MARKER,
        error: error instanceof Error ? error.message : String(error),
      });
    }
  });
}
