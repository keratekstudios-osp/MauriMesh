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
