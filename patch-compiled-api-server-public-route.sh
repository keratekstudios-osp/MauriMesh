#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "PATCH COMPILED API SERVER PUBLIC ROUTE"
echo "Fix deployment still serving old protected route"
echo "============================================================"
echo ""

BASE="https://mauri-mesh-messenger.replit.app"
BACKUP="backup-before-compiled-public-route-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP"

echo ""
echo "1. Show API server scripts"
node -e "const p=require('./artifacts/api-server/package.json'); console.log(JSON.stringify(p.scripts||{},null,2))" 2>/dev/null || true

echo ""
echo "2. Find compiled route files"
find artifacts/api-server -type f \( -path "*/dist/*" -o -path "*/build/*" \) \
  \( -name "index.js" -o -name "app.js" -o -name "server.js" -o -name "*.js" \) \
  -not -path "*/node_modules/*" \
  2>/dev/null | grep -E "routes|server|app|index" | head -80 || true

echo ""
echo "3. Write source meshPublic.ts"

mkdir -p artifacts/api-server/src/routes

cat > artifacts/api-server/src/routes/meshPublic.ts <<'TS'
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

  res.json({
    ok: true,
    public: true,
    decision: {
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
    },
    intelligence,
    timestamp: now()
  });
});
TS

echo ""
echo "4. Mount source route above requireAuth"

node <<'NODE'
const fs = require("fs");
const file = "artifacts/api-server/src/routes/index.ts";

if (!fs.existsSync(file)) {
  console.error("Missing source routes index:", file);
  process.exit(1);
}

let text = fs.readFileSync(file, "utf8");
fs.copyFileSync(file, `${file}.bak-public-compiled-${Date.now()}`);

text = text
  .split("\n")
  .filter(line =>
    !line.includes('meshPublicRouter') &&
    !line.includes('MauriMesh public mesh intelligence routes')
  )
  .join("\n");

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

if (!text.includes("router.use(requireAuth);")) {
  console.error("Cannot find router.use(requireAuth);");
  process.exit(1);
}

text = text.replace(
  "router.use(requireAuth);",
  `// MauriMesh public mesh intelligence routes - mounted above global auth
router.use(meshPublicRouter);

router.use(requireAuth);`
);

fs.writeFileSync(file, text);
console.log("Source route mounted above requireAuth");
NODE

echo ""
echo "5. Build API server so dist gets updated"

cd artifacts/api-server

npm run build 2>/tmp/api-build.log || npm run typecheck 2>/tmp/api-build.log || npx tsc -p tsconfig.json 2>/tmp/api-build.log || {
  echo "Build failed. Showing log:"
  cat /tmp/api-build.log
  exit 1
}

cd /home/runner/workspace

echo ""
echo "6. If dist exists, verify compiled route order"

grep -RIn "meshPublicRouter\|requireAuth" artifacts/api-server/dist artifacts/api-server/build \
  --exclude-dir=node_modules \
  2>/dev/null | head -80 || true

echo ""
echo "7. Hard patch compiled dist if build did not include it"

DIST_INDEX=""

for f in \
  artifacts/api-server/dist/routes/index.js \
  artifacts/api-server/build/routes/index.js
do
  if [ -f "$f" ]; then
    DIST_INDEX="$f"
    break
  fi
done

if [ -n "$DIST_INDEX" ]; then
  echo "Compiled route index found: $DIST_INDEX"
  cp "$DIST_INDEX" "$BACKUP/dist-routes-index.js.bak"

  DIST_DIR="$(dirname "$DIST_INDEX")"

  cat > "$DIST_DIR/meshPublic.js" <<'JS'
"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.meshPublicRouter = void 0;

const express_1 = require("express");
exports.meshPublicRouter = express_1.default.Router();

const events = [];

function now() {
  return new Date().toISOString();
}

function snapshot() {
  const recent = events.slice(-100);
  const latestEvent = recent[recent.length - 1] || null;
  return {
    ok: true,
    public: true,
    service: "MauriMesh Public Mesh Intelligence",
    meshState: latestEvent ? "active" : "no_activity_yet",
    nextAction: latestEvent ? "continue_monitoring" : "start_packet_probe",
    latestEvent,
    transportDecision: {
      bestTransport: "BLE",
      bestScore: 55,
      scores: [
        { transport: "BLE", score: 55 },
        { transport: "WIFI", score: 50 },
        { transport: "INTERNET", score: 50 }
      ]
    },
    ackHealth: {
      waitingForAck: false,
      waitingAckCount: 0,
      recentAckCount: recent.filter(e => e.stage === "ACK" || e.status === "DELIVERED").length,
      recentFailureCount: recent.filter(e => e.stage === "FAIL" || e.status === "FAIL").length
    },
    activityFeed: recent,
    timestamp: now()
  };
}

exports.meshPublicRouter.get("/mesh-public/health", (_req, res) => {
  res.json({
    ok: true,
    public: true,
    status: "online",
    service: "MauriMesh Public Mesh Intelligence",
    timestamp: now()
  });
});

exports.meshPublicRouter.get("/mesh-public/activity", (_req, res) => {
  res.json(snapshot());
});

exports.meshPublicRouter.post("/mesh-public/activity/ingest", express_1.default.json({ limit: "1mb" }), (req, res) => {
  const saved = {
    id: `evt_${Date.now()}_${Math.random().toString(16).slice(2)}`,
    ...(req.body || {}),
    createdAt: now()
  };
  events.push(saved);
  res.json({ ok: true, public: true, saved, intelligence: snapshot(), timestamp: now() });
});

exports.meshPublicRouter.post("/mesh-public/packet/decision", express_1.default.json({ limit: "1mb" }), (req, res) => {
  const body = req.body || {};
  const intelligence = snapshot();
  res.json({
    ok: true,
    public: true,
    decision: {
      id: `decision_${Date.now()}_${Math.random().toString(16).slice(2)}`,
      packetId: body.packetId || "unknown_packet",
      transport: body.preferredTransport || "BLE",
      nextAction: intelligence.nextAction,
      requireAck: true,
      retryPolicy: {
        maxRetries: 3,
        retryBackoffMs: 750,
        strictReversePathAck: true
      },
      routePolicy: {
        ttl: Number.isFinite(Number(body.ttl)) ? Number(body.ttl) : 8,
        targetPeerId: body.targetPeerId || null,
        allowStoreAndForward: true,
        allowFallbackToInternet: true
      },
      createdAt: now()
    },
    intelligence,
    timestamp: now()
  });
});
JS

  node <<NODE
const fs = require("fs");
const file = "$DIST_INDEX";
let text = fs.readFileSync(file, "utf8");

if (!text.includes("meshPublic")) {
  text = 'const { meshPublicRouter } = require("./meshPublic");\\n' + text;
}

text = text
  .split("\\n")
  .filter(line => !line.includes("router.use(meshPublicRouter)") && !line.includes("MauriMesh public mesh intelligence routes"))
  .join("\\n");

const authPatterns = [
  /router\\.use\\(requireAuth\\);/,
  /router\\.use\\(requireAuth_1\\.requireAuth\\);/,
  /router\\.use\\(\\(0, requireAuth_1\\.requireAuth\\)\\);/
];

let changed = false;

for (const pattern of authPatterns) {
  if (pattern.test(text)) {
    text = text.replace(pattern, '// MauriMesh public mesh intelligence routes - mounted above global auth\\nrouter.use(meshPublicRouter);\\n\\n$&');
    changed = true;
    break;
  }
}

if (!changed) {
  console.error("Could not find compiled requireAuth mount in " + file);
  process.exit(1);
}

fs.writeFileSync(file, text);
console.log("Hard patched compiled route index:", file);
NODE
else
  echo "No dist/build route index found. Source build should be used."
fi

echo ""
echo "8. Final verify source + compiled"

echo ""
echo "Source order:"
grep -n "meshPublicRouter\|router.use(requireAuth)\|Every route mounted below" artifacts/api-server/src/routes/index.ts || true

echo ""
echo "Compiled order:"
grep -RIn "meshPublicRouter\|requireAuth" artifacts/api-server/dist artifacts/api-server/build \
  --exclude-dir=node_modules \
  2>/dev/null | head -80 || true

echo ""
echo "============================================================"
echo "PATCH COMPLETE"
echo "Now Redeploy MauriMesh Core System."
echo "After deploy, test:"
echo "curl -i $BASE/api/mesh-public/health"
echo "============================================================"
