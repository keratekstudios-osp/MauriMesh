import { describe, it, expect, beforeEach, vi } from "vitest";
import express from "express";
import type { AddressInfo } from "node:net";

// In-memory stand-in for the proofLedger table. The db client is mocked so these
// route tests exercise the real router/handler logic (status codes, the type
// filter, oversized-payload rejection) without a Postgres connection.
const store: Array<Record<string, unknown>> = [];

// drizzle helpers are stubbed: eq() captures the filter value so the fake db can
// honor ?type=, desc() is a no-op marker (ordering is asserted via insert order).
vi.mock("drizzle-orm", () => ({
  eq: (_col: unknown, val: unknown) => ({ kind: "eq", val }),
  desc: (col: unknown) => ({ kind: "desc", col }),
}));

vi.mock("../../lib/db/src/index", () => {
  const proofLedger = { eventType: "event_type", ts: "ts" };
  const db = {
    insert: () => ({
      values: (v: Record<string, unknown>) => ({
        returning: async () => {
          const row = {
            id: `id-${store.length + 1}`,
            ts: new Date().toISOString(),
            deviceId: null,
            peerId: null,
            packetId: null,
            routeId: null,
            ackId: null,
            ...v,
          };
          store.unshift(row);
          return [row];
        },
      }),
    }),
    select: () => ({
      from: () => ({
        where: (cond: { val?: unknown }) => ({
          orderBy: async () => store.filter((r) => r.eventType === cond.val),
        }),
        orderBy: async () => [...store],
      }),
    }),
  };
  return { db, proofLedger };
});

import { createProofRouter } from "../../server/proofRoutes";

function startServer() {
  const app = express();
  app.use(express.json({ limit: "1mb" }));
  app.use("/api/proof", createProofRouter());
  const server = app.listen(0);
  const { port } = server.address() as AddressInfo;
  return { server, base: `http://127.0.0.1:${port}` };
}

async function withServer<T>(fn: (base: string) => Promise<T>): Promise<T> {
  const { server, base } = startServer();
  try {
    return await fn(base);
  } finally {
    server.close();
  }
}

describe("proof routes — /api/proof/evidence", () => {
  beforeEach(() => {
    store.length = 0;
  });

  it("POST persists evidence and returns 201 with unverified/truth fields", async () => {
    await withServer(async (base) => {
      const res = await fetch(`${base}/api/proof/evidence`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ evidence: { runResult: "ack-ok", deviceId: "phone-A" } }),
      });
      expect(res.status).toBe(201);
      const body = await res.json();
      expect(body.ok).toBe(true);
      expect(body.entry.eventType).toBe("two_phone_hardware_evidence");
      expect(body.entry.verified).toBe(false);
      expect(body.entry.runtimeMode).toBe("client_submitted_evidence");
      expect(body.entry.deviceId).toBe("phone-A");
      expect(body.truth).toContain("NOT LIVE BLE");
      expect(store.length).toBe(1);
    });
  });

  it("POST rejects an empty payload with 400", async () => {
    await withServer(async (base) => {
      const res = await fetch(`${base}/api/proof/evidence`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: "{}",
      });
      expect(res.status).toBe(400);
      expect(store.length).toBe(0);
    });
  });

  it("POST rejects an oversized payload with 400 (ledger pollution guard)", async () => {
    await withServer(async (base) => {
      const res = await fetch(`${base}/api/proof/evidence`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ evidence: { blob: "x".repeat(70 * 1024) } }),
      });
      expect(res.status).toBe(400);
      expect(store.length).toBe(0);
    });
  });

  it("GET filters by ?type= and returns matching entries", async () => {
    await withServer(async (base) => {
      await fetch(`${base}/api/proof/evidence`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ evidence: { n: 1 } }),
      });

      const matched = await (
        await fetch(`${base}/api/proof/evidence?type=two_phone_hardware_evidence`)
      ).json();
      expect(matched.ok).toBe(true);
      expect(matched.entries.length).toBe(1);
      expect(matched.entries[0].eventType).toBe("two_phone_hardware_evidence");
      expect(matched.truth).toContain("NOT LIVE BLE");

      const none = await (
        await fetch(`${base}/api/proof/evidence?type=does_not_exist`)
      ).json();
      expect(none.entries.length).toBe(0);
    });
  });

  it("GET without a type filter returns all entries", async () => {
    await withServer(async (base) => {
      for (const n of [1, 2, 3]) {
        await fetch(`${base}/api/proof/evidence`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ evidence: { n } }),
        });
      }
      const all = await (await fetch(`${base}/api/proof/evidence`)).json();
      expect(all.ok).toBe(true);
      expect(all.entries.length).toBe(3);
    });
  });
});
