#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "REPAIR BAD next() AUTH PATCH + REMOUNT MESH PUBLIC ROUTES"
echo "============================================================"
echo ""

ROUTES_INDEX="artifacts/api-server/src/routes/index.ts"
AUTH_FILE="artifacts/api-server/src/routes/auth.ts"
MESH_ROUTE="artifacts/api-server/src/routes/meshPublic.ts"
BACKUP="backup-before-auth-next-repair-$(date +%Y%m%d-%H%M%S)"

mkdir -p "$BACKUP"

echo "1. Backup files"
[ -f "$AUTH_FILE" ] && cp "$AUTH_FILE" "$BACKUP/auth.ts.bak"
[ -f "$ROUTES_INDEX" ] && cp "$ROUTES_INDEX" "$BACKUP/routes-index.ts.bak"

echo ""
echo "2. Remove bad MAURIMESH_PUBLIC_MESH_AUTH_BYPASS blocks from auth.ts"

if [ -f "$AUTH_FILE" ]; then
  node <<'NODE'
const fs = require("fs");
const file = "artifacts/api-server/src/routes/auth.ts";
let text = fs.readFileSync(file, "utf8");

// Remove the bad bypass block that calls next() inside auth.ts.
text = text.replace(
/\s*\/\/ MAURIMESH_PUBLIC_MESH_AUTH_BYPASS[\s\S]*?return next\(\);\s*\}\s*/g,
"\n"
);

fs.writeFileSync(file, text);
console.log("Cleaned bad next() bypass from auth.ts");
NODE
else
  echo "No auth.ts found at $AUTH_FILE"
fi

echo ""
echo "3. Confirm no bad next() remains near auth.ts line 208"
grep -n "MAURIMESH_PUBLIC_MESH_AUTH_BYPASS\|return next()" "$AUTH_FILE" 2>/dev/null || echo "OK: no bad next() bypass in auth.ts"

echo ""
echo "4. Ensure mesh public route file exists"

mkdir -p artifacts/api-server/src/routes

cat > "$MESH_ROUTE" <<'TS'
import express from "express";

export const meshPublicRouter = express.Router();

const events: any[] = [];

function now() {
  return new Date().toISOString();
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

function snapshot() {
  const recent = events.slice(-100);
  const latestEvent = recent[recent.length - 1] || null;

  const failures = recent.filter(isFail);
  const acks = recent.filter(isAck);
  const waiting = recent.filter(isWaiting);

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
      bestTransport: "BLE",
      bestScore: 55,
      scores: [
        { transport: "BLE", score: 55 },
        { transport: "WIFI", score: 50 },
        { transport: "WIFI_DIRECT", score: 50 },
        { transport: "LOCAL_WIFI", score: 50 },
        { transport: "INTERNET", score: 50 }
      ]
    },
    ackHealth: {
      waitingForAck: waiting.length > 0,
      waitingAckCount: waiting.length,
      recentAckCount: acks.length,
      recentFailureCount: failures.length
    },
    activityFeed: recent,
    timestamp: now()
  };
}

meshPublicRouter.get("/mesh-public/health", (_req, res) => {
  res.json({
    ok: true,
    public: true,
    status: "online",
    service: "MauriMesh Public Mesh Intelligence",
    timestamp: now()
  });
});

meshPublicRouter.get("/mesh-public/activity", (_req, res) => {
  res.json(snapshot());
});

meshPublicRouter.post("/mesh-public/activity/ingest", express.json({ limit: "1mb" }), (req, res) => {
  const saved = {
    id: `evt_${Date.now()}_${Math.random().toString(16).slice(2)}`,
    packetId: req.body?.packetId || "unknown_packet",
    stage: req.body?.stage || "UNKNOWN",
    status: req.body?.status || "UNKNOWN",
    transport: req.body?.transport || "UNKNOWN",
    fromPeerId: req.body?.fromPeerId || null,
    toPeerId: req.body?.toPeerId || req.body?.peerId || null,
    peerId: req.body?.peerId || null,
    latencyMs: Number.isFinite(Number(req.body?.latencyMs)) ? Number(req.body.latencyMs) : null,
    payloadBytes: Number.isFinite(Number(req.body?.payloadBytes)) ? Number(req.body.payloadBytes) : null,
    retryCount: Number.isFinite(Number(req.body?.retryCount)) ? Number(req.body.retryCount) : 0,
    error: req.body?.error || null,
    detail: req.body?.detail || null,
    createdAt: now()
  };

  events.push(saved);

  res.json({
    ok: true,
    public: true,
    saved,
    intelligence: snapshot(),
    timestamp: now()
  });
});

meshPublicRouter.post("/mesh-public/packet/decision", express.json({ limit: "1mb" }), (req, res) => {
  const body: any = req.body || {};
  const intelligence = snapshot();

  const decision = {
    id: `decision_${Date.now()}_${Math.random().toString(16).slice(2)}`,
    packetId: body.packetId || "unknown_packet",
    transport: body.preferredTransport || intelligence.transportDecision.bestTransport || "BLE",
    nextAction: intelligence.nextAction,
    requireAck: true,
    retryPolicy: {
      maxRetries: intelligence.ackHealth.recentFailureCount >= 3 ? 5 : 3,
      retryBackoffMs: intelligence.ackHealth.recentFailureCount >= 3 ? 2500 : 750,
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

  res.json({
    ok: true,
    public: true,
    decision,
    intelligence,
    timestamp: now()
  });
});
TS

echo ""
echo "5. Remount meshPublicRouter above router.use(requireAuth)"

node <<'NODE'
const fs = require("fs");
const file = "artifacts/api-server/src/routes/index.ts";

if (!fs.existsSync(file)) {
  throw new Error("routes/index.ts not found");
}

let text = fs.readFileSync(file, "utf8");

// Remove duplicate imports/mounts first.
text = text
  .split("\n")
  .filter(line =>
    !line.includes('meshPublicRouter') &&
    !line.includes('MauriMesh public mesh intelligence routes')
  )
  .join("\n");

// Add import after imports.
const lines = text.split("\n");
let lastImport = -1;

for (let i = 0; i < lines.length; i++) {
  if (lines[i].startsWith("import ")) lastImport = i;
}

if (lastImport >= 0) {
  lines.splice(lastImport + 1, 0, 'import { meshPublicRouter } from "./meshPublic";');
} else {
  lines.unshift('import { meshPublicRouter } from "./meshPublic";');
}

text = lines.join("\n");

const marker = "router.use(requireAuth);";

if (!text.includes(marker)) {
  throw new Error("router.use(requireAuth); not found");
}

text = text.replace(
  marker,
  `// MauriMesh public mesh intelligence routes - mounted above global auth\nrouter.use(meshPublicRouter);\n\n${marker}`
);

fs.writeFileSync(file, text);
console.log("Mounted meshPublicRouter above requireAuth");
NODE

echo ""
echo "6. Verify order"
grep -n "Every route mounted below\|meshPublicRouter\|router.use(requireAuth)" "$ROUTES_INDEX"

echo ""
echo "7. Typecheck"
cd artifacts/api-server
npm run typecheck 2>/dev/null || npm run check 2>/dev/null || npx tsc -p tsconfig.json --noEmit
cd /home/runner/workspace

echo ""
echo "============================================================"
echo "REPAIR COMPLETE"
echo "Now press Replit Stop, then Play/Run."
echo "After restart, test:"
echo "curl -i https://mauri-mesh-messenger.replit.app/api/mesh-public/health"
echo "============================================================"
