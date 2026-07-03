import { Router } from "express";
import type { Request, Response, NextFunction } from "express";
import { eq, desc, and, gt } from "drizzle-orm";
import {
  db,
  operators,
  acceptedDocs,
  adminCommands,
  meshSessions,
  insertOperatorSchema,
  insertAcceptedDocSchema,
  insertAdminCommandSchema,
} from "../lib/db/src/index";

// Roles in mesh_sessions that may perform privileged enterprise/admin actions.
const PRIVILEGED_ROLES = new Set(["operator", "admin"]);

type OperatorRequest = Request & {
  operator?: { username: string; nodeId: string; role: string };
};

const fail = (res: Response, err: unknown, status = 500) => {
  const message = err instanceof Error ? err.message : String(err);
  res.status(status).json({ ok: false, error: message });
};

// Authorize privileged enterprise routes against a valid, non-expired operator/
// admin session (mesh_sessions). Fail-closed: any missing/invalid/under-
// privileged token is rejected before reaching a handler.
async function requireOperator(req: OperatorRequest, res: Response, next: NextFunction) {
  try {
    const header = req.header("authorization") || "";
    const token = header.toLowerCase().startsWith("bearer ")
      ? header.slice(7).trim()
      : req.header("x-operator-token")?.trim() || "";
    if (!token) {
      return res.status(401).json({ ok: false, error: "missing operator token" });
    }
    const [session] = await db
      .select()
      .from(meshSessions)
      .where(and(eq(meshSessions.token, token), gt(meshSessions.expiresAt, new Date())))
      .limit(1);
    if (!session) {
      return res.status(401).json({ ok: false, error: "invalid or expired token" });
    }
    if (!PRIVILEGED_ROLES.has(session.role)) {
      return res.status(403).json({ ok: false, error: "operator role required" });
    }
    req.operator = { username: session.username, nodeId: session.nodeId, role: session.role };
    next();
  } catch (err) {
    fail(res, err);
  }
}

// Persistence routes for operator clearance, legal-doc acceptance, and admin
// command history. These replace what were previously in-file mock arrays so
// admin actions survive across sessions. All routes require an operator/admin
// session. Plain Express handlers to match the existing server style.
export function createEnterpriseRouter(): Router {
  const router = Router();

  router.use(requireOperator);

  // ── Operators ───────────────────────────────────────────────────────────
  router.get("/operators", async (_req, res) => {
    try {
      const rows = await db.select().from(operators).orderBy(desc(operators.createdAt));
      res.json({ ok: true, operators: rows });
    } catch (err) {
      fail(res, err);
    }
  });

  // Create or update an operator clearance record (keyed by nodeId).
  router.post("/operators", async (req, res) => {
    const parsed = insertOperatorSchema.safeParse(req.body);
    if (!parsed.success) return fail(res, parsed.error, 400);
    try {
      const [row] = await db
        .insert(operators)
        .values(parsed.data)
        .onConflictDoUpdate({
          target: operators.nodeId,
          set: {
            name: parsed.data.name,
            clearanceLevel: parsed.data.clearanceLevel,
            status: parsed.data.status,
            suspendedReason: parsed.data.suspendedReason ?? null,
            updatedAt: new Date(),
          },
        })
        .returning();
      res.json({ ok: true, operator: row });
    } catch (err) {
      fail(res, err);
    }
  });

  router.post("/operators/:id/suspend", async (req, res) => {
    const reason = typeof req.body?.reason === "string" ? req.body.reason : null;
    try {
      const [row] = await db
        .update(operators)
        .set({ status: "suspended", suspendedReason: reason, updatedAt: new Date() })
        .where(eq(operators.id, req.params.id))
        .returning();
      if (!row) return fail(res, "operator not found", 404);
      res.json({ ok: true, operator: row });
    } catch (err) {
      fail(res, err);
    }
  });

  router.post("/operators/:id/reinstate", async (req, res) => {
    try {
      const [row] = await db
        .update(operators)
        .set({ status: "active", suspendedReason: null, updatedAt: new Date() })
        .where(eq(operators.id, req.params.id))
        .returning();
      if (!row) return fail(res, "operator not found", 404);
      res.json({ ok: true, operator: row });
    } catch (err) {
      fail(res, err);
    }
  });

  // ── Legal docs ──────────────────────────────────────────────────────────
  router.get("/legal-docs", async (_req, res) => {
    try {
      const rows = await db.select().from(acceptedDocs).orderBy(desc(acceptedDocs.acceptedAt));
      res.json({ ok: true, acceptedDocs: rows });
    } catch (err) {
      fail(res, err);
    }
  });

  router.post("/legal-docs/accept", async (req, res) => {
    const parsed = insertAcceptedDocSchema.safeParse(req.body);
    if (!parsed.success) return fail(res, parsed.error, 400);
    try {
      const [row] = await db.insert(acceptedDocs).values(parsed.data).returning();
      res.json({ ok: true, acceptedDoc: row });
    } catch (err) {
      fail(res, err);
    }
  });

  // ── Admin command history ─────────────────────────────────────────────────
  router.get("/admin-commands", async (_req, res) => {
    try {
      const rows = await db.select().from(adminCommands).orderBy(desc(adminCommands.createdAt));
      res.json({ ok: true, adminCommands: rows });
    } catch (err) {
      fail(res, err);
    }
  });

  router.post("/admin-commands", async (req: OperatorRequest, res) => {
    // Default the actor to the authenticated operator when not supplied.
    const body = { actor: req.operator?.username, ...req.body };
    const parsed = insertAdminCommandSchema.safeParse(body);
    if (!parsed.success) return fail(res, parsed.error, 400);
    try {
      const [row] = await db.insert(adminCommands).values(parsed.data).returning();
      res.json({ ok: true, adminCommand: row });
    } catch (err) {
      fail(res, err);
    }
  });

  return router;
}
