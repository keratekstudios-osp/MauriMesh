#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH FINAL AUTH BYPASS USING NODE"
echo "Fix /api/mesh-public/* 401 block"
echo "============================================================"
echo ""

BASE="https://mauri-mesh-messenger.replit.app"
BACKUP="backup-before-node-auth-bypass-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP"

echo "1. Patch auth middleware with Node"

node <<'NODE'
const fs = require("fs");
const path = require("path");

const files = [
  "artifacts/api-server/src/middleware/requireAuth.ts",
  "artifacts/api-server/src/routes/auth.ts",
  "artifacts/api-server/src/lib/logger.ts",
  "server/middleware/requireAuth.ts",
  "server/routes/auth.ts",
  "src/middleware/requireAuth.ts",
  "src/routes/auth.ts"
];

const bypass = `
// MAURIMESH_PUBLIC_MESH_AUTH_BYPASS
if (
  req &&
  (
    (req.path && req.path.startsWith("/api/mesh-public/")) ||
    (req.url && req.url.startsWith("/api/mesh-public/"))
  )
) {
  return next();
}

`;

let patched = 0;

for (const file of files) {
  if (!fs.existsSync(file)) continue;

  let text = fs.readFileSync(file, "utf8");

  if (
    !text.includes("Authentication required") &&
    !text.includes("req.headers.authorization") &&
    !text.includes("Bearer <token>") &&
    !text.includes("authorization")
  ) {
    continue;
  }

  fs.copyFileSync(file, `${file}.bak-node-auth-bypass-${Date.now()}`);

  if (text.includes("MAURIMESH_PUBLIC_MESH_AUTH_BYPASS")) {
    console.log(`Already patched: ${file}`);
    continue;
  }

  const patterns = [
    /const\s+authHeader\s*=\s*req\.headers\.authorization\s*;/,
    /const\s+authorization\s*=\s*req\.headers\.authorization\s*;/,
    /const\s+token\s*=\s*req\.headers\.authorization\s*;/,
    /if\s*\(\s*!req\.headers\.authorization\s*\)\s*\{/,
    /if\s*\(\s*!authHeader\s*\)\s*\{/,
    /if\s*\(\s*!authorization\s*\)\s*\{/,
    /if\s*\(\s*!token\s*\)\s*\{/
  ];

  let changed = false;

  for (const pattern of patterns) {
    if (pattern.test(text)) {
      text = text.replace(pattern, `${bypass}$&`);
      changed = true;
      break;
    }
  }

  if (!changed && text.includes("Authentication required. Provide Authorization")) {
    text = text.replace("res.status(401).json({", `${bypass}res.status(401).json({`);
    changed = true;
  }

  if (!changed && text.includes("Authentication required")) {
    text = bypass + text;
    changed = true;
  }

  if (changed) {
    fs.writeFileSync(file, text);
    console.log(`PATCHED: ${file}`);
    patched++;
  } else {
    console.log(`NO SAFE PATCH POINT: ${file}`);
  }
}

console.log(`Patched files: ${patched}`);
NODE

echo ""
echo "2. Create public mesh route"

mkdir -p artifacts/api-server/src/routes

cat > artifacts/api-server/src/routes/meshPublic.ts <<'TS'
import express from "express";
import fs from "fs";
import path from "path";

export const meshPublicRouter = express.Router();

const runtimeDir = path.join(process.cwd(), ".maurimesh", "runtime");
const ledgerFile = path.join(runtimeDir, "activity-ledger.jsonl");
const decisionFile = path.join(runtimeDir, "packet-decisions.jsonl");

function ensureRuntime() {
  fs.mkdirSync(runtimeDir, { recursive: true });
  if (!fs.existsSync(ledgerFile)) fs.writeFileSync(ledgerFile, "");
  if (!fs.existsSync(decisionFile)) fs.writeFileSync(decisionFile, "");
}

function now() {
  return new Date().toISOString();
}

function readLines(file: string, limit = 300) {
  ensureRuntime();
  const raw = fs.readFileSync(file, "utf8").trim();
  if (!raw) return [];
  return raw.split("\n").slice(-limit).map((line) => {
    try { return JSON.parse(line); } catch { return null; }
  }).filter(Boolean);
}

function append(file: string, value: unknown) {
  ensureRuntime();
  fs.appendFileSync(file, JSON.stringify(value) + "\n");
}

function makeEvent(input: any = {}) {
  return {
    id: input.id || `evt_${Date.now()}_${Math.random().toString(16).slice(2)}`,
    packetId: input.packetId || "unknown_packet",
    stage: input.stage || "UNKNOWN",
    status: input.status || "UNKNOWN",
    transport: input.transport || "UNKNOWN",
    fromPeerId: input.fromPeerId || null,
    toPeerId: input.toPeerId || input.peerId || null,
    peerId: input.peerId || null,
    latencyMs: Number.isFinite(Number(input.latencyMs)) ? Number(input.latencyMs) : null,
    payloadBytes: Number.isFinite(Number(input.payloadBytes)) ? Number(input.payloadBytes) : null,
    retryCount: Number.isFinite(Number(input.retryCount)) ? Number(input.retryCount) : 0,
    error: input.error || null,
    detail: input.detail || null,
    createdAt: input.createdAt || now()
  };
}

function isAck(e: any) {
  return ["ACK", "RX_ACK", "DELIVERED", "TX_BLE_OK"].includes(e.stage) ||
    ["ACK", "OK", "DELIVERED"].includes(e.status);
}

function isFail(e: any) {
  return ["FAIL", "ERROR", "TIMEOUT", "TX_BLE_ERROR", "ACK_TIMEOUT"].includes(e.stage) ||
    ["FAIL", "ERROR", "TIMEOUT"].includes(e.status);
}

function isWaiting(e: any) {
  return ["WAITING_FOR_ACK", "PENDING_ACK", "ACK_PENDING"].includes(e.stage) ||
    ["WAITING_FOR_ACK", "PENDING_ACK", "ACK_PENDING"].includes(e.status);
}

function score(events: any[], transport: string) {
  const r = events.filter((e) => e.transport === transport);
  const acks = r.filter(isAck).length;
  const failures = r.filter(isFail).length;
  const waitingAck = r.filter(isWaiting).length;
  let score = 50 + acks * 14 - failures * 20 - waitingAck * 6;
  if (transport === "BLE") score += 4;
  score = Math.max(0, Math.min(100, score));
  return { transport, score, acks, failures, waitingAck };
}

function snapshot() {
  const events = readLines(ledgerFile, 500);
  const recent = events.slice(-100);
  const latestEvent = events[events.length - 1] || null;
  const failures = recent.filter(isFail);
  const acks = recent.filter(isAck);
  const waiting = recent.filter(isWaiting);

  const scores = [
    score(recent, "BLE"),
    score(recent, "WIFI"),
    score(recent, "WIFI_DIRECT"),
    score(recent, "LOCAL_WIFI"),
    score(recent, "INTERNET")
  ].sort((a, b) => b.score - a.score);

  let meshState = latestEvent ? "active" : "no_activity_yet";
  let nextAction = latestEvent ? "continue_monitoring" : "start_packet_probe";

  if (waiting.length) {
    meshState = "waiting_for_ack";
    nextAction = "verify_reverse_ack_path";
  }

  if (failures.length >= 3) {
    meshState = "degraded";
    nextAction = "repair_route_then_retry";
  }

  if (acks.length && failures.length === 0) {
    meshState = "healthy";
    nextAction = "continue_current_route";
  }

  return {
    ok: true,
    public: true,
    service: "MauriMesh Public Mesh Intelligence",
    meshState,
    nextAction,
    latestEvent,
    transportDecision: {
      bestTransport: scores[0].transport,
      bestScore: scores[0].score,
      scores
    },
    ackHealth: {
      waitingForAck: waiting.length > 0,
      waitingAckCount: waiting.length,
      recentAckCount: acks.length,
      recentFailureCount: failures.length
    },
    activityFeed: recent.slice(-30),
    timestamp: now()
  };
}

meshPublicRouter.get("/api/mesh-public/health", (_req, res) => {
  res.json({
    ok: true,
    public: true,
    service: "MauriMesh Public Mesh Intelligence",
    status: "online",
    timestamp: now()
  });
});

meshPublicRouter.get("/api/mesh-public/activity", (_req, res) => {
  res.json(snapshot());
});

meshPublicRouter.post("/api/mesh-public/activity/ingest", express.json({ limit: "1mb" }), (req, res) => {
  const saved = makeEvent(req.body || {});
  append(ledgerFile, saved);
  res.json({
    ok: true,
    public: true,
    saved,
    intelligence: snapshot(),
    timestamp: now()
  });
});

meshPublicRouter.post("/api/mesh-public/packet/decision", express.json({ limit: "1mb" }), (req, res) => {
  const body: any = req.body || {};
  const snap = snapshot();

  const decision = {
    id: `decision_${Date.now()}_${Math.random().toString(16).slice(2)}`,
    packetId: body.packetId || "unknown_packet",
    transport: body.preferredTransport || snap.transportDecision.bestTransport || "BLE",
    nextAction: snap.nextAction,
    requireAck: true,
    retryPolicy: {
      maxRetries: snap.ackHealth.recentFailureCount >= 3 ? 5 : 3,
      retryBackoffMs: snap.ackHealth.recentFailureCount >= 3 ? 2500 : 750,
      strictReversePathAck: true
    },
    routePolicy: {
      ttl: Number.isFinite(Number(body.ttl)) ? Number(body.ttl) : 8,
      targetPeerId: body.targetPeerId || null,
      allowStoreAndForward: true,
      allowFallbackToInternet: true
    },
    createdAt: now()
  };

  append(decisionFile, decision);

  res.json({
    ok: true,
    public: true,
    decision,
    intelligence: snap,
    timestamp: now()
  });
});
TS

echo ""
echo "3. Mount public route into API server"

node <<'NODE'
const fs = require("fs");

const candidates = [
  "artifacts/api-server/src/index.ts",
  "artifacts/api-server/src/server.ts",
  "artifacts/api-server/index.ts",
  "server/index.ts",
  "server/index.js"
];

let serverFile = candidates.find((f) => fs.existsSync(f));

if (!serverFile) {
  console.error("No server entry found.");
  process.exit(1);
}

let text = fs.readFileSync(serverFile, "utf8");
fs.copyFileSync(serverFile, `${serverFile}.bak-mesh-public-${Date.now()}`);

if (!text.includes("meshPublicRouter")) {
  text = `import { meshPublicRouter } from "./routes/meshPublic";\n` + text;

  const patterns = [
    /const\s+app\s*=\s*express\(\)\s*;/,
    /let\s+app\s*=\s*express\(\)\s*;/,
    /var\s+app\s*=\s*express\(\)\s*;/
  ];

  let mounted = false;

  for (const pattern of patterns) {
    if (pattern.test(text)) {
      text = text.replace(
        pattern,
        `$&\n\n// MauriMesh public mesh intelligence routes - before auth\napp.use(meshPublicRouter);`
      );
      mounted = true;
      break;
    }
  }

  if (!mounted) {
    text += `\n\n// MauriMesh public mesh intelligence routes\napp.use(meshPublicRouter);\n`;
  }

  fs.writeFileSync(serverFile, text);
  console.log(`Mounted meshPublicRouter in ${serverFile}`);
} else {
  console.log(`meshPublicRouter already present in ${serverFile}`);
}
NODE

echo ""
echo "4. Verify patch lines"

grep -RIn "meshPublicRouter\|MAURIMESH_PUBLIC_MESH_AUTH_BYPASS\|Authentication required" \
  artifacts/api-server/src server backend src api \
  --exclude-dir=node_modules \
  --exclude-dir=.pnpm \
  2>/dev/null || true

echo ""
echo "5. Test deployed current state"

curl -sS -i --max-time 15 "$BASE/api/mesh-public/health" || true

echo ""
curl -sS -i --max-time 15 "$BASE/api/mesh-public/activity" || true

echo ""
echo "============================================================"
echo "DONE"
echo "Now press Replit Restart/Run or Deploy."
echo "Then test:"
echo "curl -i $BASE/api/mesh-public/health"
echo "============================================================"
