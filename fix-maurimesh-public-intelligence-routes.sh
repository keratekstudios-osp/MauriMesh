#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH PUBLIC INTELLIGENCE ROUTE FIX"
echo "Fix 401 auth block for mesh packet intelligence API"
echo "============================================================"
echo ""

ROOT="$(pwd)"
BACKUP="$ROOT/backup-before-public-intelligence-routes-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP"

INTEL_FILE="server/maurimeshPublicIntelligenceRoutes.cjs"

echo "1. Create public intelligence routes that do not require operator auth"

cat > "$INTEL_FILE" <<'JS'
const express = require("express");
const fs = require("fs");
const path = require("path");

const router = express.Router();

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

function readJsonLines(file, limit = 300) {
  ensureRuntime();

  const raw = fs.readFileSync(file, "utf8").trim();
  if (!raw) return [];

  return raw
    .split("\n")
    .slice(-limit)
    .map((line) => {
      try {
        return JSON.parse(line);
      } catch {
        return null;
      }
    })
    .filter(Boolean);
}

function appendJsonLine(file, value) {
  ensureRuntime();
  fs.appendFileSync(file, JSON.stringify(value) + "\n");
}

function normalizeEvent(input = {}) {
  return {
    id: input.id || `evt_${Date.now()}_${Math.random().toString(16).slice(2)}`,
    packetId: input.packetId || input.packet_id || "unknown_packet",
    stage: input.stage || "UNKNOWN",
    status: input.status || "UNKNOWN",
    transport: input.transport || "UNKNOWN",
    fromPeerId: input.fromPeerId || input.from || null,
    toPeerId: input.toPeerId || input.to || input.peerId || null,
    peerId: input.peerId || input.toPeerId || input.fromPeerId || null,
    routeId: input.routeId || null,
    hopIndex: Number.isFinite(Number(input.hopIndex)) ? Number(input.hopIndex) : null,
    hopLimit: Number.isFinite(Number(input.hopLimit)) ? Number(input.hopLimit) : null,
    latencyMs: Number.isFinite(Number(input.latencyMs)) ? Number(input.latencyMs) : null,
    payloadBytes: Number.isFinite(Number(input.payloadBytes)) ? Number(input.payloadBytes) : null,
    retryCount: Number.isFinite(Number(input.retryCount)) ? Number(input.retryCount) : 0,
    error: input.error || null,
    detail: input.detail || null,
    createdAt: input.createdAt || now()
  };
}

function isAck(event) {
  return ["ACK", "RX_ACK", "DELIVERED", "TX_BLE_OK", "DELIVERY_CONFIRMED"].includes(event.stage) ||
    ["ACK", "OK", "DELIVERED"].includes(event.status);
}

function isFail(event) {
  return ["FAIL", "ERROR", "TIMEOUT", "TX_BLE_ERROR", "ACK_TIMEOUT", "ROUTE_FAILED"].includes(event.stage) ||
    ["FAIL", "ERROR", "TIMEOUT"].includes(event.status);
}

function isWaitingAck(event) {
  return ["WAITING_FOR_ACK", "PENDING_ACK", "ACK_PENDING"].includes(event.stage) ||
    ["WAITING_FOR_ACK", "PENDING_ACK", "ACK_PENDING"].includes(event.status);
}

function scoreTransport(events, transport) {
  const relevant = events.filter((e) => e.transport === transport);

  if (relevant.length === 0) {
    return {
      transport,
      score: transport === "BLE" ? 55 : 50,
      sends: 0,
      acks: 0,
      failures: 0,
      waitingAck: 0,
      averageLatencyMs: null,
      confidence: "cold_start"
    };
  }

  const sends = relevant.filter((e) =>
    ["SEND", "TX_START", "TX_BLE_START", "TX_WIFI_START", "TX_INTERNET_START"].includes(e.stage)
  ).length;

  const acks = relevant.filter(isAck).length;
  const failures = relevant.filter(isFail).length;
  const waitingAck = relevant.filter(isWaitingAck).length;

  const latencies = relevant
    .map((e) => e.latencyMs)
    .filter((n) => Number.isFinite(n) && n >= 0);

  const averageLatencyMs =
    latencies.length > 0
      ? Math.round(latencies.reduce((a, b) => a + b, 0) / latencies.length)
      : null;

  let score = 50;
  score += acks * 14;
  score -= failures * 20;
  score -= waitingAck * 6;

  if (sends > 0 && acks === 0) score -= 18;

  if (averageLatencyMs !== null) {
    if (averageLatencyMs <= 80) score += 15;
    else if (averageLatencyMs <= 250) score += 9;
    else if (averageLatencyMs > 1000) score -= 14;
  }

  if (transport === "BLE") score += 4;

  score = Math.max(0, Math.min(100, score));

  return {
    transport,
    score,
    sends,
    acks,
    failures,
    waitingAck,
    averageLatencyMs,
    confidence: relevant.length >= 10 ? "trained" : "warming_up"
  };
}

function buildSnapshot() {
  const events = readJsonLines(ledgerFile, 500);
  const recent = events.slice(-100);
  const latestEvent = events[events.length - 1] || null;

  const transportScores = [
    scoreTransport(recent, "BLE"),
    scoreTransport(recent, "WIFI"),
    scoreTransport(recent, "WIFI_DIRECT"),
    scoreTransport(recent, "LOCAL_WIFI"),
    scoreTransport(recent, "INTERNET")
  ].sort((a, b) => b.score - a.score);

  const recentFailures = recent.filter(isFail);
  const recentAcks = recent.filter(isAck);
  const waitingAckEvents = recent.filter(isWaitingAck);

  let meshState = latestEvent ? "active" : "no_activity_yet";
  let nextAction = latestEvent ? "continue_monitoring" : "start_packet_probe";
  const selfHealing = [];

  if (!latestEvent) {
    selfHealing.push("No packet events received. Native packet driver must send events to /api/activity/ingest.");
  }

  if (waitingAckEvents.length > 0) {
    meshState = "waiting_for_ack";
    nextAction = "verify_reverse_ack_path";
    selfHealing.push("ACK pending. Check reverse-path ACK, packet ID match, and receiver route ledger.");
  }

  if (recentFailures.length >= 3) {
    meshState = "degraded";
    nextAction = "repair_route_then_retry";
    selfHealing.push("Failure cluster detected. Refresh peer discovery, reduce payload size, and retry with backoff.");
  }

  if (recentAcks.length > 0 && recentFailures.length === 0) {
    meshState = "healthy";
    nextAction = "continue_current_route";
  }

  return {
    ok: true,
    public: true,
    service: "MauriMesh Public Intelligent API Driver",
    meshState,
    nextAction,
    latestEvent,
    packetDriver: {
      status: latestEvent ? "event_stream_connected" : "waiting_for_events",
      role: "public_mesh_intelligence_bridge",
      authRequired: false
    },
    transportDecision: {
      bestTransport: transportScores[0].transport,
      bestScore: transportScores[0].score,
      scores: transportScores
    },
    ackHealth: {
      waitingForAck: waitingAckEvents.length > 0,
      waitingAckCount: waitingAckEvents.length,
      recentAckCount: recentAcks.length,
      recentFailureCount: recentFailures.length
    },
    selfHealing: {
      required: selfHealing.length > 0,
      actions: selfHealing
    },
    activityFeed: recent.slice(-30),
    timestamp: now()
  };
}

function appendEvent(input) {
  const event = normalizeEvent(input);
  appendJsonLine(ledgerFile, event);
  return event;
}

function decidePacket(packet = {}) {
  const snapshot = buildSnapshot();

  const decision = {
    id: `decision_${Date.now()}_${Math.random().toString(16).slice(2)}`,
    packetId: packet.packetId || "unknown_packet",
    transport: packet.preferredTransport || snapshot.transportDecision.bestTransport || "BLE",
    meshState: snapshot.meshState,
    nextAction: snapshot.nextAction,
    requireAck: true,
    requireLedgerWrite: true,
    retryPolicy: {
      maxRetries: snapshot.ackHealth.recentFailureCount >= 3 ? 5 : 3,
      retryBackoffMs: snapshot.ackHealth.recentFailureCount >= 3 ? 2500 : 750,
      switchTransportAfterFailures: 2,
      strictReversePathAck: true
    },
    routePolicy: {
      ttl: Number.isFinite(Number(packet.ttl)) ? Number(packet.ttl) : 8,
      targetPeerId: packet.targetPeerId || null,
      allowFallbackToInternet: true,
      allowStoreAndForward: true
    },
    createdAt: now()
  };

  appendJsonLine(decisionFile, decision);

  return {
    ok: true,
    public: true,
    decision,
    intelligence: snapshot,
    timestamp: now()
  };
}

router.get("/api/mesh-public/health", (req, res) => {
  res.json({
    ok: true,
    public: true,
    service: "MauriMesh Public Intelligence",
    status: "online",
    timestamp: now()
  });
});

router.get("/api/mesh-public/activity", (req, res) => {
  res.json(buildSnapshot());
});

router.post("/api/mesh-public/activity/ingest", express.json({ limit: "1mb" }), (req, res) => {
  const saved = appendEvent(req.body || {});
  res.json({
    ok: true,
    public: true,
    saved,
    intelligence: buildSnapshot(),
    timestamp: now()
  });
});

router.post("/api/mesh-public/packet/decision", express.json({ limit: "1mb" }), (req, res) => {
  res.json(decidePacket(req.body || {}));
});

module.exports = {
  mauriMeshPublicIntelligenceRouter: router
};
JS

echo "Created: $INTEL_FILE"

echo ""
echo "2. Find backend server entry"

SERVER_FILE=""

for f in \
  server/index.js \
  server/index.ts \
  backend/index.js \
  backend/index.ts \
  src/server/index.js \
  src/server/index.ts \
  api/index.js \
  api/index.ts \
  index.js \
  index.ts
do
  if [ -f "$f" ]; then
    if grep -q "express\|app.listen\|app.use" "$f"; then
      SERVER_FILE="$f"
      break
    fi
  fi
done

if [ -z "$SERVER_FILE" ]; then
  SERVER_FILE="$(grep -RIl "express()\|app.listen\|app.use" server backend src api 2>/dev/null | head -1 || true)"
fi

if [ -z "$SERVER_FILE" ]; then
  echo "ERROR: Could not find backend server entry."
  echo "Run:"
  echo "grep -RIn \"express()\\|app.listen\\|app.use\" server backend src api"
  exit 1
fi

echo "Server entry: $SERVER_FILE"
cp "$SERVER_FILE" "$BACKUP/$(basename "$SERVER_FILE").bak"

echo ""
echo "3. Mount public route at TOP of server file before auth middleware"

if grep -q "mauriMeshPublicIntelligenceRouter" "$SERVER_FILE"; then
  echo "Public intelligence router already mounted."
else
  TMP_FILE="$(mktemp)"

  cat > "$TMP_FILE" <<'TOP'
// ============================================================
// MauriMesh Public Intelligence Routes
// Mounted before auth middleware so mesh packet intelligence
// can connect from mobile/native drivers without operator token.
// Public endpoints:
//   GET  /api/mesh-public/health
//   GET  /api/mesh-public/activity
//   POST /api/mesh-public/activity/ingest
//   POST /api/mesh-public/packet/decision
// ============================================================
try {
  const { mauriMeshPublicIntelligenceRouter } = require("./maurimeshPublicIntelligenceRoutes.cjs");
  if (typeof app !== "undefined") {
    app.use(mauriMeshPublicIntelligenceRouter);
    console.log("[MauriMesh] Public Intelligence Routes mounted before auth.");
  } else {
    global.__MAURIMESH_PUBLIC_INTELLIGENCE_PENDING__ = mauriMeshPublicIntelligenceRouter;
  }
} catch (error) {
  console.error("[MauriMesh] Failed to mount Public Intelligence Routes:", error);
}

TOP

  cat "$SERVER_FILE" >> "$TMP_FILE"
  mv "$TMP_FILE" "$SERVER_FILE"

  echo "Inserted public route block at top of $SERVER_FILE"
fi

echo ""
echo "4. If app variable was created after the inserted block, add fallback mount after app creation"

if ! grep -q "__MAURIMESH_PUBLIC_INTELLIGENCE_PENDING__" "$SERVER_FILE"; then
  echo "Fallback pending marker not found, skipping."
else
  if grep -q "Mounted pending MauriMesh Public Intelligence Routes" "$SERVER_FILE"; then
    echo "Fallback mount already exists."
  else
    perl -0pi -e 's#(const\s+app\s*=\s*express\(\)\s*;|let\s+app\s*=\s*express\(\)\s*;|var\s+app\s*=\s*express\(\)\s*;)#$1\ntry {\n  if (global.__MAURIMESH_PUBLIC_INTELLIGENCE_PENDING__) {\n    app.use(global.__MAURIMESH_PUBLIC_INTELLIGENCE_PENDING__);\n    console.log("[MauriMesh] Mounted pending MauriMesh Public Intelligence Routes.");\n  }\n} catch (error) {\n  console.error("[MauriMesh] Pending Public Intelligence mount failed:", error);\n}\n#s' "$SERVER_FILE" || true
  fi
fi

echo ""
echo "5. Create mobile client public API bridge"

mkdir -p src/maurimesh/api artifacts/messenger-mobile/src/maurimesh/api

cat > src/maurimesh/api/publicIntelligenceClient.ts <<'TS'
const API_BASE =
  process.env.EXPO_PUBLIC_API_BASE_URL ||
  process.env.EXPO_PUBLIC_BACKEND_BASE_URL ||
  process.env.EXPO_PUBLIC_MESH_API_URL ||
  "";

function baseUrl(): string {
  return String(API_BASE || "")
    .trim()
    .replace(/\/+$/, "")
    .replace(/\/api$/, "");
}

async function json(response: Response) {
  const text = await response.text();
  const data = text ? JSON.parse(text) : null;

  if (!response.ok) {
    throw new Error(`MauriMesh public intelligence API failed ${response.status}: ${text}`);
  }

  return data;
}

export async function getPublicMeshActivity() {
  return json(await fetch(`${baseUrl()}/api/mesh-public/activity`));
}

export async function ingestPublicMeshActivity(event: Record<string, unknown>) {
  return json(
    await fetch(`${baseUrl()}/api/mesh-public/activity/ingest`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json"
      },
      body: JSON.stringify(event)
    })
  );
}

export async function getPublicPacketDecision(packet: Record<string, unknown>) {
  return json(
    await fetch(`${baseUrl()}/api/mesh-public/packet/decision`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json"
      },
      body: JSON.stringify(packet)
    })
  );
}
TS

cp src/maurimesh/api/publicIntelligenceClient.ts artifacts/messenger-mobile/src/maurimesh/api/publicIntelligenceClient.ts 2>/dev/null || true

echo ""
echo "6. Test public deployed routes"

BASE="https://mauri-mesh-messenger.replit.app"

echo ""
echo "Public health:"
curl -sS -i --max-time 15 "$BASE/api/mesh-public/health" || true

echo ""
echo "Public activity:"
curl -sS -i --max-time 15 "$BASE/api/mesh-public/activity" || true

echo ""
echo "Public ingest:"
curl -sS -i --max-time 15 -X POST "$BASE/api/mesh-public/activity/ingest" \
  -H "Content-Type: application/json" \
  -d '{
    "packetId":"MM-PUBLIC-AUTH-FIX-001",
    "stage":"TX_BLE_START",
    "status":"SEND",
    "transport":"BLE",
    "fromPeerId":"PHONE-A",
    "toPeerId":"PHONE-B",
    "payloadBytes":128,
    "detail":"Public intelligence route auth bypass test"
  }' || true

echo ""
echo "Public decision:"
curl -sS -i --max-time 15 -X POST "$BASE/api/mesh-public/packet/decision" \
  -H "Content-Type: application/json" \
  -d '{
    "packetId":"MM-PUBLIC-AUTH-FIX-001",
    "payloadBytes":128,
    "preferredTransport":"BLE",
    "targetPeerId":"PHONE-B",
    "ttl":8
  }' || true

echo ""
echo "============================================================"
echo "FIX COMPLETE"
echo "New public no-token routes:"
echo "  GET  /api/mesh-public/health"
echo "  GET  /api/mesh-public/activity"
echo "  POST /api/mesh-public/activity/ingest"
echo "  POST /api/mesh-public/packet/decision"
echo ""
echo "If deployed still returns 401/404, restart/redeploy Replit."
echo "============================================================"
