#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH FULL INTELLIGENT API DRIVER INSTALLER"
echo "Unified API bridge + packet intelligence + activity route"
echo "============================================================"
echo ""

ROOT="$(pwd)"
BACKUP="$ROOT/backup-before-full-intelligent-api-driver-$(date +%Y%m%d-%H%M%S)"
SERVER_DIR="$ROOT/server"
CLIENT_DIR="$ROOT/src/maurimesh/api"
RUNTIME_DIR="$ROOT/.maurimesh/runtime"

mkdir -p "$BACKUP" "$SERVER_DIR" "$CLIENT_DIR" "$RUNTIME_DIR"

echo "Backup folder:"
echo "$BACKUP"

echo ""
echo "1. Writing backend intelligence engine..."

cat > "$SERVER_DIR/maurimeshIntelligentApiDriver.cjs" <<'JS'
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

function safeNumber(value, fallback = null) {
  const n = Number(value);
  return Number.isFinite(n) ? n : fallback;
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
    hopIndex: safeNumber(input.hopIndex),
    hopLimit: safeNumber(input.hopLimit),
    latencyMs: safeNumber(input.latencyMs),
    payloadBytes: safeNumber(input.payloadBytes),
    retryCount: safeNumber(input.retryCount, 0),
    error: input.error || null,
    detail: input.detail || null,
    raw: input.raw || null,
    createdAt: input.createdAt || now()
  };
}

function appendEvent(input) {
  const event = normalizeEvent(input);
  appendJsonLine(ledgerFile, event);
  return event;
}

function isSendEvent(event) {
  return [
    "SEND",
    "TX_START",
    "TX_BLE_START",
    "TX_WIFI_START",
    "TX_INTERNET_START",
    "DISCOVERY_START",
    "ROUTE_START"
  ].includes(event.stage);
}

function isAckEvent(event) {
  return [
    "ACK",
    "RX_ACK",
    "DELIVERED",
    "TX_BLE_OK",
    "TX_WIFI_OK",
    "TX_INTERNET_OK",
    "DELIVERY_CONFIRMED"
  ].includes(event.stage) || ["ACK", "OK", "DELIVERED"].includes(event.status);
}

function isFailEvent(event) {
  return [
    "FAIL",
    "ERROR",
    "TIMEOUT",
    "TX_BLE_ERROR",
    "TX_WIFI_ERROR",
    "TX_INTERNET_ERROR",
    "ACK_TIMEOUT",
    "ROUTE_FAILED"
  ].includes(event.stage) || ["FAIL", "ERROR", "TIMEOUT"].includes(event.status);
}

function isWaitingAck(event) {
  return [
    "WAITING_FOR_ACK",
    "PENDING_ACK",
    "ACK_PENDING"
  ].includes(event.stage) || [
    "WAITING_FOR_ACK",
    "PENDING_ACK",
    "ACK_PENDING"
  ].includes(event.status);
}

function scoreTransport(events, transport) {
  const relevant = events.filter((event) => event.transport === transport);

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

  const sends = relevant.filter(isSendEvent).length;
  const acks = relevant.filter(isAckEvent).length;
  const failures = relevant.filter(isFailEvent).length;
  const waitingAck = relevant.filter(isWaitingAck).length;

  const latencies = relevant
    .map((event) => event.latencyMs)
    .filter((value) => Number.isFinite(value) && value >= 0);

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
    else if (averageLatencyMs <= 750) score += 2;
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

function groupPacketStates(events) {
  const byPacket = new Map();

  for (const event of events) {
    if (!byPacket.has(event.packetId)) {
      byPacket.set(event.packetId, {
        packetId: event.packetId,
        events: [],
        latestStage: null,
        latestStatus: null,
        latestTransport: null,
        latestAt: null,
        delivered: false,
        failed: false,
        waitingForAck: false,
        retries: 0
      });
    }

    const packet = byPacket.get(event.packetId);
    packet.events.push(event);
    packet.latestStage = event.stage;
    packet.latestStatus = event.status;
    packet.latestTransport = event.transport;
    packet.latestAt = event.createdAt;
    packet.retries = Math.max(packet.retries, event.retryCount || 0);

    if (isAckEvent(event)) packet.delivered = true;
    if (isFailEvent(event)) packet.failed = true;
    if (isWaitingAck(event)) packet.waitingForAck = true;
  }

  return Array.from(byPacket.values()).slice(-50);
}

function detectPeers(events) {
  const peers = new Map();

  for (const event of events) {
    const ids = [event.peerId, event.fromPeerId, event.toPeerId].filter(Boolean);

    for (const id of ids) {
      if (!peers.has(id)) {
        peers.set(id, {
          peerId: id,
          eventCount: 0,
          lastSeenAt: null,
          transports: new Set(),
          ackCount: 0,
          failureCount: 0
        });
      }

      const peer = peers.get(id);
      peer.eventCount += 1;
      peer.lastSeenAt = event.createdAt;
      if (event.transport) peer.transports.add(event.transport);
      if (isAckEvent(event)) peer.ackCount += 1;
      if (isFailEvent(event)) peer.failureCount += 1;
    }
  }

  return Array.from(peers.values()).map((peer) => ({
    ...peer,
    transports: Array.from(peer.transports),
    health:
      peer.ackCount > 0 && peer.failureCount === 0
        ? "healthy"
        : peer.failureCount >= 3
          ? "degraded"
          : "unknown"
  }));
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

  const bestTransport = transportScores[0];

  const recentFailures = recent.filter(isFailEvent);
  const recentAcks = recent.filter(isAckEvent);
  const waitingAckEvents = recent.filter(isWaitingAck);
  const packetStates = groupPacketStates(events);
  const peers = detectPeers(recent);

  let meshState = "idle";
  let nextAction = "standby";
  const selfHealing = [];
  const intelligenceNotes = [];

  if (!latestEvent) {
    meshState = "no_activity_yet";
    nextAction = "start_packet_probe";
    selfHealing.push("No packet events received. Connect BLE/Wi-Fi/Internet driver events into /api/activity/ingest.");
  } else {
    meshState = "active";
    nextAction = "continue_monitoring";
  }

  if (waitingAckEvents.length > 0) {
    meshState = "waiting_for_ack";
    nextAction = "verify_reverse_ack_path";
    selfHealing.push("ACK is pending. Check receiver response path, packet ID match, and reverse route ledger.");
  }

  if (recentFailures.length >= 3) {
    meshState = "degraded";
    nextAction = "repair_route_then_retry";
    selfHealing.push("Failure cluster detected. Refresh peer discovery, reduce payload size, and retry with backoff.");
  }

  if (recentFailures.filter((e) => e.transport === "BLE").length >= 3) {
    selfHealing.push("BLE degradation detected. Increase scan window, restart advertiser, then retry BLE before switching transport.");
  }

  if (recentAcks.length > 0 && recentFailures.length === 0) {
    meshState = "healthy";
    nextAction = "continue_current_route";
  }

  if (bestTransport.score < 35) {
    nextAction = "full_transport_recovery";
    selfHealing.push("All transport scores are low. Run full driver recovery: BLE restart, Wi-Fi probe, then Internet fallback.");
  }

  if (peers.length === 0 && latestEvent) {
    intelligenceNotes.push("Packet activity exists, but no peer IDs are being reported. Add fromPeerId/toPeerId to driver events.");
  }

  return {
    ok: true,
    service: "MauriMesh Full Intelligent API Driver",
    route: "/api/activity",
    meshState,
    nextAction,
    latestEvent,
    packetDriver: {
      status: latestEvent ? "event_stream_connected" : "waiting_for_events",
      role: "intelligence_bridge",
      nativeTransportDriverRequired: true,
      explanation:
        "This API intelligence layer does not replace native BLE/Wi-Fi packet sending. It receives driver events, scores routes, decides next action, and feeds the UI/API."
    },
    transportDecision: {
      bestTransport: bestTransport.transport,
      bestScore: bestTransport.score,
      scores: transportScores
    },
    ackHealth: {
      waitingForAck: waitingAckEvents.length > 0,
      waitingAckCount: waitingAckEvents.length,
      recentAckCount: recentAcks.length,
      recentFailureCount: recentFailures.length
    },
    packets: packetStates.slice(-25),
    peers,
    selfHealing: {
      required: selfHealing.length > 0,
      actions: selfHealing
    },
    intelligenceNotes,
    activityFeed: recent.slice(-30),
    timestamp: now()
  };
}

function decidePacketRoute(packet = {}) {
  const snapshot = buildSnapshot();
  const preferred = packet.preferredTransport;
  const payloadBytes = safeNumber(packet.payloadBytes, 0);
  const failureCount = snapshot.ackHealth.recentFailureCount;

  let transport = snapshot.transportDecision.bestTransport;
  let reason = "highest_current_transport_score";

  if (preferred) {
    const preferredScore = snapshot.transportDecision.scores.find((s) => s.transport === preferred);
    if (preferredScore && preferredScore.score >= 40) {
      transport = preferred;
      reason = "preferred_transport_allowed";
    }
  }

  if (payloadBytes > 180 && transport === "BLE") {
    const wifi = snapshot.transportDecision.scores.find((s) => s.transport === "WIFI" || s.transport === "LOCAL_WIFI");
    const internet = snapshot.transportDecision.scores.find((s) => s.transport === "INTERNET");

    if (wifi && wifi.score >= 40) {
      transport = wifi.transport;
      reason = "payload_too_large_for_ble_wifi_preferred";
    } else if (internet && internet.score >= 40) {
      transport = "INTERNET";
      reason = "payload_too_large_for_ble_internet_fallback";
    }
  }

  const decision = {
    id: `decision_${Date.now()}_${Math.random().toString(16).slice(2)}`,
    packetId: packet.packetId || "unknown_packet",
    transport,
    reason,
    meshState: snapshot.meshState,
    nextAction: snapshot.nextAction,
    requireAck: true,
    requireLedgerWrite: true,
    retryPolicy: {
      maxRetries: failureCount >= 3 ? 5 : 3,
      retryBackoffMs: failureCount >= 3 ? 2500 : 750,
      switchTransportAfterFailures: 2,
      strictReversePathAck: true
    },
    routePolicy: {
      ttl: safeNumber(packet.ttl, 8),
      preferKnownPeer: Boolean(packet.targetPeerId),
      targetPeerId: packet.targetPeerId || null,
      allowFallbackToInternet: true,
      allowStoreAndForward: true
    },
    createdAt: now()
  };

  appendJsonLine(decisionFile, decision);

  return {
    ok: true,
    decision,
    intelligence: snapshot,
    timestamp: now()
  };
}

router.get("/api/health", (req, res) => {
  res.json({
    ok: true,
    service: "MauriMesh API",
    status: "online",
    timestamp: now()
  });
});

router.get("/api/activity", (req, res) => {
  try {
    res.json(buildSnapshot());
  } catch (error) {
    res.status(500).json({
      ok: false,
      route: "/api/activity",
      error: error instanceof Error ? error.message : "Unknown activity error",
      timestamp: now()
    });
  }
});

router.get("/api/activity/intelligence", (req, res) => {
  try {
    res.json(buildSnapshot());
  } catch (error) {
    res.status(500).json({
      ok: false,
      route: "/api/activity/intelligence",
      error: error instanceof Error ? error.message : "Unknown intelligence error",
      timestamp: now()
    });
  }
});

router.post("/api/activity/ingest", express.json({ limit: "1mb" }), (req, res) => {
  try {
    const saved = appendEvent(req.body || {});
    res.json({
      ok: true,
      saved,
      intelligence: buildSnapshot(),
      timestamp: now()
    });
  } catch (error) {
    res.status(500).json({
      ok: false,
      route: "/api/activity/ingest",
      error: error instanceof Error ? error.message : "Unknown ingest error",
      timestamp: now()
    });
  }
});

router.post("/api/mesh/packet/decision", express.json({ limit: "1mb" }), (req, res) => {
  try {
    res.json(decidePacketRoute(req.body || {}));
  } catch (error) {
    res.status(500).json({
      ok: false,
      route: "/api/mesh/packet/decision",
      error: error instanceof Error ? error.message : "Unknown decision error",
      timestamp: now()
    });
  }
});

router.get("/api/mesh/packet/decisions", (req, res) => {
  try {
    res.json({
      ok: true,
      decisions: readJsonLines(decisionFile, 100),
      timestamp: now()
    });
  } catch (error) {
    res.status(500).json({
      ok: false,
      route: "/api/mesh/packet/decisions",
      error: error instanceof Error ? error.message : "Unknown decisions error",
      timestamp: now()
    });
  }
});

module.exports = {
  mauriMeshIntelligentApiDriverRouter: router,
  buildMauriMeshSnapshot: buildSnapshot,
  appendMauriMeshEvent: appendEvent,
  decideMauriMeshPacketRoute: decidePacketRoute
};
JS

echo "Created:"
echo "  server/maurimeshIntelligentApiDriver.cjs"

echo ""
echo "2. Writing frontend API client..."

cat > "$CLIENT_DIR/intelligentApiDriver.ts" <<'TS'
export type MauriMeshTransport =
  | "BLE"
  | "WIFI"
  | "WIFI_DIRECT"
  | "LOCAL_WIFI"
  | "INTERNET"
  | "UNKNOWN"
  | string;

export type MauriMeshActivityEvent = {
  id?: string;
  packetId: string;
  stage:
    | "SEND"
    | "TX_START"
    | "TX_BLE_START"
    | "TX_BLE_FOUND"
    | "TX_BLE_CONNECT"
    | "TX_BLE_OK"
    | "TX_WIFI_START"
    | "TX_WIFI_OK"
    | "TX_INTERNET_START"
    | "TX_INTERNET_OK"
    | "RX_BLE"
    | "WAITING_FOR_ACK"
    | "PENDING_ACK"
    | "RX_ACK"
    | "ACK"
    | "DELIVERED"
    | "FAIL"
    | "ERROR"
    | "TIMEOUT"
    | "ACK_TIMEOUT"
    | string;
  status?: string;
  transport: MauriMeshTransport;
  fromPeerId?: string | null;
  toPeerId?: string | null;
  peerId?: string | null;
  routeId?: string | null;
  hopIndex?: number | null;
  hopLimit?: number | null;
  latencyMs?: number | null;
  payloadBytes?: number | null;
  retryCount?: number;
  error?: string | null;
  detail?: string | null;
  raw?: unknown;
  createdAt?: string;
};

const API_BASE =
  process.env.EXPO_PUBLIC_API_BASE_URL ||
  process.env.EXPO_PUBLIC_BACKEND_BASE_URL ||
  process.env.VITE_API_BASE_URL ||
  process.env.VITE_BACKEND_BASE_URL ||
  "";

function getApiBase(): string {
  if (!API_BASE) {
    throw new Error(
      "Missing MauriMesh API base URL. Set EXPO_PUBLIC_API_BASE_URL or EXPO_PUBLIC_BACKEND_BASE_URL."
    );
  }

  return API_BASE.replace(/\/$/, "");
}

async function parseJsonResponse(response: Response) {
  const text = await response.text();

  try {
    const json = text ? JSON.parse(text) : null;

    if (!response.ok) {
      throw new Error(
        `MauriMesh API failed ${response.status}: ${JSON.stringify(json)}`
      );
    }

    return json;
  } catch (error) {
    if (!response.ok) {
      throw new Error(`MauriMesh API failed ${response.status}: ${text}`);
    }

    throw error;
  }
}

export async function getMauriMeshActivity() {
  const response = await fetch(`${getApiBase()}/api/activity`, {
    method: "GET",
    headers: {
      Accept: "application/json"
    }
  });

  return parseJsonResponse(response);
}

export async function getMauriMeshIntelligence() {
  const response = await fetch(`${getApiBase()}/api/activity/intelligence`, {
    method: "GET",
    headers: {
      Accept: "application/json"
    }
  });

  return parseJsonResponse(response);
}

export async function ingestMauriMeshActivity(event: MauriMeshActivityEvent) {
  const response = await fetch(`${getApiBase()}/api/activity/ingest`, {
    method: "POST",
    headers: {
      Accept: "application/json",
      "Content-Type": "application/json"
    },
    body: JSON.stringify(event)
  });

  return parseJsonResponse(response);
}

export async function getMauriMeshPacketDecision(packet: {
  packetId: string;
  payloadBytes?: number;
  preferredTransport?: MauriMeshTransport;
  targetPeerId?: string;
  ttl?: number;
}) {
  const response = await fetch(`${getApiBase()}/api/mesh/packet/decision`, {
    method: "POST",
    headers: {
      Accept: "application/json",
      "Content-Type": "application/json"
    },
    body: JSON.stringify(packet)
  });

  return parseJsonResponse(response);
}

export async function reportBleSendStart(input: {
  packetId: string;
  fromPeerId?: string;
  toPeerId?: string;
  payloadBytes?: number;
  detail?: string;
}) {
  return ingestMauriMeshActivity({
    ...input,
    stage: "TX_BLE_START",
    status: "SEND",
    transport: "BLE"
  });
}

export async function reportBleAck(input: {
  packetId: string;
  fromPeerId?: string;
  toPeerId?: string;
  latencyMs?: number;
  detail?: string;
}) {
  return ingestMauriMeshActivity({
    ...input,
    stage: "ACK",
    status: "DELIVERED",
    transport: "BLE"
  });
}

export async function reportBleFail(input: {
  packetId: string;
  fromPeerId?: string;
  toPeerId?: string;
  error?: string;
  retryCount?: number;
  detail?: string;
}) {
  return ingestMauriMeshActivity({
    ...input,
    stage: "TX_BLE_ERROR",
    status: "FAIL",
    transport: "BLE"
  });
}
TS

echo "Created:"
echo "  src/maurimesh/api/intelligentApiDriver.ts"

echo ""
echo "3. Writing environment files..."

BACKEND_URL="${BACKEND_URL:-https://mauri-mesh-messenger.replit.app}"

cat > "$ROOT/.env" <<ENV
EXPO_PUBLIC_API_BASE_URL=$BACKEND_URL
EXPO_PUBLIC_BACKEND_BASE_URL=$BACKEND_URL
VITE_API_BASE_URL=$BACKEND_URL
VITE_BACKEND_BASE_URL=$BACKEND_URL
API_BASE_URL=$BACKEND_URL
BACKEND_BASE_URL=$BACKEND_URL
ENV

cat > "$ROOT/.env.local" <<ENV
EXPO_PUBLIC_API_BASE_URL=$BACKEND_URL
EXPO_PUBLIC_BACKEND_BASE_URL=$BACKEND_URL
VITE_API_BASE_URL=$BACKEND_URL
VITE_BACKEND_BASE_URL=$BACKEND_URL
API_BASE_URL=$BACKEND_URL
BACKEND_BASE_URL=$BACKEND_URL
ENV

echo "Environment set to:"
cat "$ROOT/.env"

echo ""
echo "4. Finding and wiring backend server entry..."

SERVER_FILE=""

for f in \
  "$ROOT/server/index.js" \
  "$ROOT/server/index.ts" \
  "$ROOT/backend/index.js" \
  "$ROOT/backend/index.ts" \
  "$ROOT/src/server/index.js" \
  "$ROOT/src/server/index.ts" \
  "$ROOT/api/index.js" \
  "$ROOT/api/index.ts" \
  "$ROOT/index.js" \
  "$ROOT/index.ts"
do
  if [ -f "$f" ]; then
    if grep -q "express" "$f" || grep -q "app.listen" "$f" || grep -q "createServer" "$f"; then
      SERVER_FILE="$f"
      break
    fi
  fi
done

if [ -z "$SERVER_FILE" ]; then
  SERVER_FILE="$(grep -RIl "app.listen\|express()" "$ROOT/server" "$ROOT/backend" "$ROOT/src" "$ROOT/api" 2>/dev/null | head -1 || true)"
fi

if [ -n "$SERVER_FILE" ]; then
  echo "Server entry found:"
  echo "$SERVER_FILE"

  cp "$SERVER_FILE" "$BACKUP/$(basename "$SERVER_FILE").bak"

  if grep -q "mauriMeshIntelligentApiDriverRouter" "$SERVER_FILE"; then
    echo "Intelligent API driver already wired."
  else
    SERVER_DIR_REL="$(dirname "$SERVER_FILE")"

    if [ "$SERVER_DIR_REL" = "$ROOT/server" ]; then
      REQUIRE_PATH="./maurimeshIntelligentApiDriver.cjs"
    else
      REQUIRE_PATH="$ROOT/server/maurimeshIntelligentApiDriver.cjs"
    fi

    cat >> "$SERVER_FILE" <<WIRE

// ============================================================
// MauriMesh Full Intelligent API Driver
// Mounts:
//   GET  /api/health
//   GET  /api/activity
//   GET  /api/activity/intelligence
//   POST /api/activity/ingest
//   POST /api/mesh/packet/decision
//   GET  /api/mesh/packet/decisions
// ============================================================
try {
  const { mauriMeshIntelligentApiDriverRouter } = require("$REQUIRE_PATH");
  app.use(mauriMeshIntelligentApiDriverRouter);
  console.log("[MauriMesh] Full Intelligent API Driver mounted.");
} catch (error) {
  console.error("[MauriMesh] Failed to mount Full Intelligent API Driver:", error);
}
WIRE

    echo "Wired driver into:"
    echo "$SERVER_FILE"
  fi
else
  echo "WARNING: Could not automatically find backend server entry."
  echo "The intelligent API driver was created but must be mounted manually."
  echo ""
  echo "Add this to your Express server after app is created:"
  echo 'const { mauriMeshIntelligentApiDriverRouter } = require("./server/maurimeshIntelligentApiDriver.cjs");'
  echo "app.use(mauriMeshIntelligentApiDriverRouter);"
fi

echo ""
echo "5. Writing test script..."

cat > "$ROOT/test-maurimesh-full-intelligent-api-driver.sh" <<'TEST'
#!/usr/bin/env bash
set -euo pipefail

BASE="${1:-http://localhost:3000}"

echo ""
echo "============================================================"
echo "TESTING MAURIMESH FULL INTELLIGENT API DRIVER"
echo "BASE: $BASE"
echo "============================================================"
echo ""

pretty() {
  node -e 'let s="";process.stdin.on("data",d=>s+=d);process.stdin.on("end",()=>{try{console.log(JSON.stringify(JSON.parse(s),null,2))}catch(e){console.log(s)}})'
}

echo ""
echo "1. Health check"
curl -sS "$BASE/api/health" | pretty || true

echo ""
echo "2. Ingest BLE send event"
curl -sS -X POST "$BASE/api/activity/ingest" \
  -H "Content-Type: application/json" \
  -d '{
    "packetId":"MM-INTEL-TEST-001",
    "stage":"TX_BLE_START",
    "status":"SEND",
    "transport":"BLE",
    "fromPeerId":"PHONE-A",
    "toPeerId":"PHONE-B",
    "payloadBytes":128,
    "detail":"Test BLE packet send into intelligent API driver"
  }' | pretty || true

echo ""
echo "3. Ingest waiting ACK event"
curl -sS -X POST "$BASE/api/activity/ingest" \
  -H "Content-Type: application/json" \
  -d '{
    "packetId":"MM-INTEL-TEST-001",
    "stage":"WAITING_FOR_ACK",
    "status":"PENDING_ACK",
    "transport":"BLE",
    "fromPeerId":"PHONE-A",
    "toPeerId":"PHONE-B",
    "detail":"Testing ACK intelligence state"
  }' | pretty || true

echo ""
echo "4. Read activity intelligence"
curl -sS "$BASE/api/activity" | pretty || true

echo ""
echo "5. Request packet route decision"
curl -sS -X POST "$BASE/api/mesh/packet/decision" \
  -H "Content-Type: application/json" \
  -d '{
    "packetId":"MM-INTEL-TEST-001",
    "payloadBytes":128,
    "preferredTransport":"BLE",
    "targetPeerId":"PHONE-B",
    "ttl":8
  }' | pretty || true

echo ""
echo "6. Ingest ACK delivered event"
curl -sS -X POST "$BASE/api/activity/ingest" \
  -H "Content-Type: application/json" \
  -d '{
    "packetId":"MM-INTEL-TEST-001",
    "stage":"ACK",
    "status":"DELIVERED",
    "transport":"BLE",
    "fromPeerId":"PHONE-B",
    "toPeerId":"PHONE-A",
    "latencyMs":42,
    "detail":"Test ACK delivered into intelligent API driver"
  }' | pretty || true

echo ""
echo "7. Final activity state"
curl -sS "$BASE/api/activity" | pretty || true

echo ""
echo "============================================================"
echo "TEST COMPLETE"
echo "============================================================"
TEST

chmod +x "$ROOT/test-maurimesh-full-intelligent-api-driver.sh"

echo ""
echo "6. Writing driver search diagnostic..."

cat > "$ROOT/find-maurimesh-api-and-packet-drivers.sh" <<'DIAG'
#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH API + PACKET DRIVER SEARCH"
echo "============================================================"
echo ""

echo "1. API env vars:"
grep -RIn \
  "EXPO_PUBLIC_API_BASE_URL\|EXPO_PUBLIC_BACKEND_BASE_URL\|VITE_API_BASE_URL\|VITE_BACKEND_BASE_URL\|API_BASE_URL\|BACKEND_BASE_URL" \
  . \
  --exclude-dir=node_modules \
  --exclude-dir=.git \
  --exclude-dir=android \
  --exclude-dir=ios \
  2>/dev/null || true

echo ""
echo "2. /api/activity references:"
grep -RIn "/api/activity\|api/activity" \
  . \
  --exclude-dir=node_modules \
  --exclude-dir=.git \
  --exclude-dir=android \
  --exclude-dir=ios \
  2>/dev/null || true

echo ""
echo "3. Packet / BLE / ACK driver references:"
grep -RIn \
  "TX_BLE\|RX_BLE\|WAITING_FOR_ACK\|ACK\|packetId\|MeshPacket\|routePacket\|sendPacket\|ble.*send\|BlePlx\|react-native-ble-plx" \
  src app server backend android \
  --exclude-dir=node_modules \
  --exclude-dir=.git \
  2>/dev/null | head -240 || true

echo ""
echo "4. Backend routes:"
grep -RIn "app.get\|app.post\|router.get\|router.post\|/api/" \
  server backend src api \
  --exclude-dir=node_modules \
  --exclude-dir=.git \
  2>/dev/null | head -240 || true

echo ""
echo "5. Done."
DIAG

chmod +x "$ROOT/find-maurimesh-api-and-packet-drivers.sh"

echo ""
echo "7. Seed one local intelligence event so /api/activity has data..."

node - <<'NODE'
const fs = require("fs");
const path = require("path");

const runtimeDir = path.join(process.cwd(), ".maurimesh", "runtime");
const ledgerFile = path.join(runtimeDir, "activity-ledger.jsonl");

fs.mkdirSync(runtimeDir, { recursive: true });

const event = {
  id: `seed_${Date.now()}`,
  packetId: "MM-SEED-INTELLIGENCE-001",
  stage: "SYSTEM_READY",
  status: "ONLINE",
  transport: "UNKNOWN",
  fromPeerId: "API",
  toPeerId: "MESH_DRIVER",
  detail: "MauriMesh intelligent API driver installed and ready to ingest packet events.",
  createdAt: new Date().toISOString()
};

fs.appendFileSync(ledgerFile, JSON.stringify(event) + "\n");
console.log("Seeded:", event);
NODE

echo ""
echo "============================================================"
echo "INSTALL COMPLETE"
echo "============================================================"
echo ""
echo "Created:"
echo "  server/maurimeshIntelligentApiDriver.cjs"
echo "  src/maurimesh/api/intelligentApiDriver.ts"
echo "  .env"
echo "  .env.local"
echo "  test-maurimesh-full-intelligent-api-driver.sh"
echo "  find-maurimesh-api-and-packet-drivers.sh"
echo ""
echo "Routes added:"
echo "  GET  /api/health"
echo "  GET  /api/activity"
echo "  GET  /api/activity/intelligence"
echo "  POST /api/activity/ingest"
echo "  POST /api/mesh/packet/decision"
echo "  GET  /api/mesh/packet/decisions"
echo ""
echo "Next commands:"
echo "  1. Restart backend / Replit server"
echo "  2. Test local:"
echo "     ./test-maurimesh-full-intelligent-api-driver.sh http://localhost:3000"
echo "  3. Test Replit deployment:"
echo "     ./test-maurimesh-full-intelligent-api-driver.sh https://mauri-mesh-messenger.replit.app"
echo "  4. Search existing drivers:"
echo "     ./find-maurimesh-api-and-packet-drivers.sh"
echo ""
echo "Important:"
echo "  This adds intelligence to the API bridge."
echo "  Your native BLE/Wi-Fi packet sender must still call /api/activity/ingest"
echo "  and request /api/mesh/packet/decision before or during packet send."
echo "============================================================"
