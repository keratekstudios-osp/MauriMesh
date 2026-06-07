#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "FINAL AUTH BYPASS - NO PYTHON REQUIRED"
echo "MauriMesh public mesh intelligence API"
echo "============================================================"
echo ""

BASE="https://mauri-mesh-messenger.replit.app"
BACKUP="backup-before-no-python-auth-bypass-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP"

echo "1. Find exact auth middleware files"

AUTH_FILES=$(grep -RIl \
  "Authentication required. Provide Authorization\|Bearer <token>\|req.headers.authorization\|authorization" \
  artifacts/api-server server backend src api \
  --exclude-dir=node_modules \
  --exclude-dir=.pnpm \
  --exclude-dir=dist \
  --exclude-dir=build \
  2>/dev/null || true)

echo "$AUTH_FILES"

if [ -z "$AUTH_FILES" ]; then
  echo "ERROR: No auth files found."
  exit 1
fi

echo ""
echo "2. Patch auth middleware with /api/mesh-public bypass"

for FILE in $AUTH_FILES; do
  echo ""
  echo "Checking: $FILE"

  if ! grep -q "Authentication required. Provide Authorization\|req.headers.authorization\|Bearer <token>" "$FILE"; then
    echo "Skipping unrelated file."
    continue
  fi

  SAFE=$(echo "$FILE" | sed 's#[/:]#_#g')
  cp "$FILE" "$BACKUP/$SAFE.bak" || true

  if grep -q "MAURIMESH_PUBLIC_MESH_AUTH_BYPASS" "$FILE"; then
    echo "Already patched."
    continue
  fi

  TMP="$(mktemp)"

  awk '
  BEGIN { inserted=0 }
  {
    if (inserted == 0 && (
      $0 ~ /req\.headers\.authorization/ ||
      $0 ~ /Authentication required\. Provide Authorization/ ||
      $0 ~ /Bearer <token>/
    )) {
      print "  // MAURIMESH_PUBLIC_MESH_AUTH_BYPASS";
      print "  if (req && (";
      print "    (req.path && req.path.indexOf(\"/api/mesh-public/\") === 0) ||";
      print "    (req.url && req.url.indexOf(\"/api/mesh-public/\") === 0)";
      print "  )) {";
      print "    return next();";
      print "  }";
      print "";
      inserted=1;
    }
    print $0;
  }
  ' "$FILE" > "$TMP"

  mv "$TMP" "$FILE"

  echo "Patched: $FILE"
  grep -n "MAURIMESH_PUBLIC_MESH_AUTH_BYPASS\|Authentication required\|authorization" "$FILE" | head -30 || true
done

echo ""
echo "3. Create public mesh intelligence route inside artifacts/api-server"

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

echo "Created: artifacts/api-server/src/routes/meshPublic.ts"

echo ""
echo "4. Mount route in artifacts/api-server/src/index.ts or server entry"

SERVER_FILE=""

for f in \
  artifacts/api-server/src/index.ts \
  artifacts/api-server/src/server.ts \
  artifacts/api-server/index.ts \
  server/index.ts \
  server/index.js
do
  if [ -f "$f" ]; then
    if grep -q "express\|app.use\|app.listen" "$f"; then
      SERVER_FILE="$f"
      break
    fi
  fi
done

if [ -z "$SERVER_FILE" ]; then
  SERVER_FILE=$(grep -RIl "app.listen\|express()\|app.use" artifacts/api-server/src server backend src api 2>/dev/null | head -1 || true)
fi

if [ -z "$SERVER_FILE" ]; then
  echo "ERROR: could not find server entry."
  exit 1
fi

echo "Server file: $SERVER_FILE"
cp "$SERVER_FILE" "$BACKUP/server-entry.bak"

if grep -q "meshPublicRouter" "$SERVER_FILE"; then
  echo "meshPublicRouter already mounted."
else
  TMP="$(mktemp)"

  awk '
  BEGIN { insertedImport=0; insertedMount=0 }
  {
    if (insertedImport == 0 && $0 !~ /^import /) {
      print "import { meshPublicRouter } from \"./routes/meshPublic\";";
      insertedImport=1;
    }

    print $0;

    if (insertedMount == 0 && $0 ~ /const app *= *express\(\)|let app *= *express\(\)|var app *= *express\(\)/) {
      print "";
      print "// MauriMesh public mesh intelligence routes - mounted before auth";
      print "app.use(meshPublicRouter);";
      insertedMount=1;
    }
  }
  END {
    if (insertedImport == 0) {
      print "import { meshPublicRouter } from \"./routes/meshPublic\";";
    }
  }
  ' "$SERVER_FILE" > "$TMP"

  mv "$TMP" "$SERVER_FILE"
  echo "Mounted meshPublicRouter in $SERVER_FILE"
fi

echo ""
echo "5. Show exact route/auth lines"

grep -RIn "meshPublicRouter\|MAURIMESH_PUBLIC_MESH_AUTH_BYPASS\|Authentication required" artifacts/api-server/src server backend src api \
  --exclude-dir=node_modules \
  --exclude-dir=.pnpm \
  2>/dev/null || true

echo ""
echo "6. Test deployed current state"

curl -sS -i --max-time 15 "$BASE/api/mesh-public/health" || true

echo ""
curl -sS -i --max-time 15 "$BASE/api/mesh-public/activity" || true

echo ""
echo "============================================================"
echo "DONE"
echo "If deployed still returns 401, press Replit Restart/Deploy."
echo "The code is patched locally, but deployment must reload it."
echo "============================================================"
