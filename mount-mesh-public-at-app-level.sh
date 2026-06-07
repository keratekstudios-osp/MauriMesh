#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MOUNT MAURIMESH PUBLIC API AT APP LEVEL"
echo "Bypasses route index + global requireAuth"
echo "============================================================"
echo ""

APP_FILE="artifacts/api-server/src/app.ts"
BACKUP="backup-before-app-level-mesh-public-$(date +%Y%m%d-%H%M%S)"
BASE="https://mauri-mesh-messenger.replit.app"

mkdir -p "$BACKUP"

if [ ! -f "$APP_FILE" ]; then
  echo "ERROR: $APP_FILE not found."
  exit 1
fi

cp "$APP_FILE" "$BACKUP/app.ts.bak"

node <<'NODE'
const fs = require("fs");

const file = "artifacts/api-server/src/app.ts";
let text = fs.readFileSync(file, "utf8");

const block = `

// ============================================================
// MauriMesh Public Mesh Intelligence API
// Mounted at app level before protected /api routes.
// No Bearer token required.
// ============================================================
const mauriMeshPublicEvents: any[] = [];

function mauriMeshNow() {
  return new Date().toISOString();
}

function mauriMeshSnapshot() {
  const recent = mauriMeshPublicEvents.slice(-100);
  const latestEvent = recent[recent.length - 1] || null;

  const failures = recent.filter((e: any) =>
    ["FAIL", "ERROR", "TIMEOUT", "TX_BLE_ERROR", "ACK_TIMEOUT"].includes(e.stage) ||
    ["FAIL", "ERROR", "TIMEOUT"].includes(e.status)
  );

  const acks = recent.filter((e: any) =>
    ["ACK", "RX_ACK", "DELIVERED", "TX_BLE_OK"].includes(e.stage) ||
    ["ACK", "OK", "DELIVERED"].includes(e.status)
  );

  const waiting = recent.filter((e: any) =>
    ["WAITING_FOR_ACK", "PENDING_ACK", "ACK_PENDING"].includes(e.stage) ||
    ["WAITING_FOR_ACK", "PENDING_ACK", "ACK_PENDING"].includes(e.status)
  );

  let meshState = latestEvent ? "active" : "no_activity_yet";
  let nextAction = latestEvent ? "continue_monitoring" : "start_packet_probe";

  if (waiting.length > 0) {
    meshState = "waiting_for_ack";
    nextAction = "verify_reverse_ack_path";
  }

  if (failures.length >= 3) {
    meshState = "degraded";
    nextAction = "repair_route_then_retry";
  }

  if (acks.length > 0 && failures.length === 0) {
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
    timestamp: mauriMeshNow()
  };
}

app.get("/api/mesh-public/health", (_req, res) => {
  res.json({
    ok: true,
    public: true,
    status: "online",
    service: "MauriMesh Public Mesh Intelligence",
    mounted: "app-level",
    timestamp: mauriMeshNow()
  });
});

app.get("/api/mesh-public/activity", (_req, res) => {
  res.json(mauriMeshSnapshot());
});

app.post("/api/mesh-public/activity/ingest", express.json({ limit: "1mb" }), (req, res) => {
  const saved = {
    id: \`evt_\${Date.now()}_\${Math.random().toString(16).slice(2)}\`,
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
    createdAt: mauriMeshNow()
  };

  mauriMeshPublicEvents.push(saved);

  res.json({
    ok: true,
    public: true,
    saved,
    intelligence: mauriMeshSnapshot(),
    timestamp: mauriMeshNow()
  });
});

app.post("/api/mesh-public/packet/decision", express.json({ limit: "1mb" }), (req, res) => {
  const body: any = req.body || {};
  const intelligence = mauriMeshSnapshot();

  res.json({
    ok: true,
    public: true,
    decision: {
      id: \`decision_\${Date.now()}_\${Math.random().toString(16).slice(2)}\`,
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
      createdAt: mauriMeshNow()
    },
    intelligence,
    timestamp: mauriMeshNow()
  });
});

`;

if (text.includes("MauriMesh Public Mesh Intelligence API")) {
  console.log("App-level mesh public API already mounted.");
  process.exit(0);
}

const appCreatePatterns = [
  /const\s+app\s*=\s*express\(\)\s*;/,
  /let\s+app\s*=\s*express\(\)\s*;/,
  /var\s+app\s*=\s*express\(\)\s*;/
];

let mounted = false;

for (const pattern of appCreatePatterns) {
  if (pattern.test(text)) {
    text = text.replace(pattern, (match) => `${match}${block}`);
    mounted = true;
    break;
  }
}

if (!mounted) {
  throw new Error("Could not find app = express(); in app.ts");
}

fs.writeFileSync(file, text);
console.log("Mounted app-level public mesh API in app.ts");
NODE

echo ""
echo "1. Verify app-level route exists"
grep -n "MauriMesh Public Mesh Intelligence API\|/api/mesh-public/health\|mounted: \"app-level\"" "$APP_FILE"

echo ""
echo "2. Typecheck/build API server"
cd artifacts/api-server

npm run typecheck 2>/dev/null || npm run check 2>/dev/null || npx tsc -p tsconfig.json --noEmit

cd /home/runner/workspace

echo ""
echo "============================================================"
echo "APP-LEVEL PATCH COMPLETE"
echo "Now redeploy MauriMesh Core System."
echo ""
echo "After deploy, test:"
echo "curl -i $BASE/api/mesh-public/health"
echo "============================================================"
