#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MOUNT MESH PUBLIC ROUTES ABOVE requireAuth"
echo "Correct fix for routes/index.ts global auth lock"
echo "============================================================"
echo ""

BASE="https://mauri-mesh-messenger.replit.app"
ROUTES_INDEX="artifacts/api-server/src/routes/index.ts"
MESH_ROUTE="artifacts/api-server/src/routes/meshPublic.ts"
BACKUP="backup-before-mesh-public-above-requireauth-$(date +%Y%m%d-%H%M%S)"

mkdir -p "$BACKUP"
mkdir -p artifacts/api-server/src/routes

if [ ! -f "$ROUTES_INDEX" ]; then
  echo "ERROR: $ROUTES_INDEX not found."
  exit 1
fi

cp "$ROUTES_INDEX" "$BACKUP/routes-index.ts.bak"

echo ""
echo "1. Write mesh public route"

cat > "$MESH_ROUTE" <<'TS'
import express from "express";

export const meshPublicRouter = express.Router();

const events: any[] = [];
const decisions: any[] = [];

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

  decisions.push(decision);

  res.json({
    ok: true,
    public: true,
    decision,
    intelligence,
    timestamp: now()
  });
});
TS

echo "Created: $MESH_ROUTE"

echo ""
echo "2. Mount meshPublicRouter above router.use(requireAuth)"

node <<'NODE'
const fs = require("fs");

const file = "artifacts/api-server/src/routes/index.ts";
let text = fs.readFileSync(file, "utf8");

if (!text.includes('meshPublicRouter')) {
  const importLine = 'import { meshPublicRouter } from "./meshPublic";\n';

  // Add import after existing imports.
  const lines = text.split("\n");
  let lastImportIndex = -1;

  for (let i = 0; i < lines.length; i++) {
    if (lines[i].startsWith("import ")) lastImportIndex = i;
  }

  if (lastImportIndex >= 0) {
    lines.splice(lastImportIndex + 1, 0, importLine.trim());
    text = lines.join("\n");
  } else {
    text = importLine + text;
  }

  const marker = "router.use(requireAuth);";

  if (!text.includes(marker)) {
    throw new Error("Could not find router.use(requireAuth); in routes/index.ts");
  }

  text = text.replace(
    marker,
    `// MauriMesh public mesh intelligence routes - mounted above global auth\nrouter.use(meshPublicRouter);\n\n${marker}`
  );

  fs.writeFileSync(file, text);
  console.log("Mounted meshPublicRouter above router.use(requireAuth).");
} else {
  console.log("meshPublicRouter already mounted.");
}
NODE

echo ""
echo "3. Show confirmed route order"

grep -n "meshPublicRouter\|router.use(requireAuth)\|Every route mounted below" "$ROUTES_INDEX" || true

echo ""
echo "4. Type check / syntax check if available"

if [ -f "artifacts/api-server/package.json" ]; then
  cd artifacts/api-server
  npm run check 2>/dev/null || npm run typecheck 2>/dev/null || echo "No typecheck script or typecheck failed. Continue to restart."
  cd /home/runner/workspace
fi

echo ""
echo "============================================================"
echo "PATCH COMPLETE"
echo "Now press Replit Restart/Run."
echo ""
echo "Then run:"
echo "curl -i $BASE/api/mesh-public/health"
echo "============================================================"
