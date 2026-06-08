// TASK_189B_REAL_PROOF_ROUTES_20260608_A

import express from "express";
import { desc, eq } from "drizzle-orm";
import { db, proofLedger } from "../lib/db/src/index";
import {
  shapeTwoPhoneHardwareEvidenceRow,
  TWO_PHONE_HARDWARE_EVIDENCE_TYPE,
} from "./proofEvidence";

export function createProofRouter() {
  const router = express.Router();

  router.post("/evidence", async (req, res) => {
    try {
      const evidenceJson = req.body?.evidenceJson ?? req.body;
      const row = shapeTwoPhoneHardwareEvidenceRow(evidenceJson);

      const [entry] = await db.insert(proofLedger).values(row).returning();

      res.json({
        ok: true,
        marker: "TASK_189B_REAL_PROOF_ROUTES_20260608_A",
        type: TWO_PHONE_HARDWARE_EVIDENCE_TYPE,
        entry,
      });
    } catch (error) {
      res.status(400).json({
        ok: false,
        marker: "TASK_189B_REAL_PROOF_ROUTES_20260608_A",
        error: error instanceof Error ? error.message : String(error),
      });
    }
  });

  router.get("/evidence", async (req, res) => {
    try {
      const type =
        typeof req.query.type === "string"
          ? req.query.type
          : TWO_PHONE_HARDWARE_EVIDENCE_TYPE;

      const entries =
        type === TWO_PHONE_HARDWARE_EVIDENCE_TYPE
          ? await db
              .select()
              .from(proofLedger)
              .where(eq(proofLedger.eventType, type))
              .orderBy(desc(proofLedger.ts))
          : await db.select().from(proofLedger).orderBy(desc(proofLedger.ts));

      res.json({
        ok: true,
        marker: "TASK_189B_REAL_PROOF_ROUTES_20260608_A",
        type,
        entries,
      });
    } catch (error) {
      res.status(500).json({
        ok: false,
        marker: "TASK_189B_REAL_PROOF_ROUTES_20260608_A",
        error: error instanceof Error ? error.message : String(error),
      });
    }
  });

  router.get("/health", (_req, res) => {
    res.json({
      ok: true,
      marker: "TASK_189B_REAL_PROOF_ROUTES_20260608_A",
      routes: [
        "POST /api/proof/evidence",
        "GET /api/proof/evidence?type=two_phone_hardware_evidence",
      ],
    });
  });

  return router;
}
