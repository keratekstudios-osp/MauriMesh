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
