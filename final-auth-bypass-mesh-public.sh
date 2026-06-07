#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "FINAL AUTH BYPASS FOR MAURIMESH PUBLIC MESH API"
echo "============================================================"
echo ""

ROOT="$(pwd)"
BACKUP="$ROOT/backup-before-final-auth-bypass-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP"

echo "1. Find exact auth files"
AUTH_FILES=$(grep -RIl \
  "Authentication required. Provide Authorization\|Bearer <token>\|req.headers.authorization\|authorization" \
  server backend src api artifacts \
  --exclude-dir=node_modules \
  --exclude-dir=.pnpm \
  --exclude-dir=dist \
  --exclude-dir=build \
  2>/dev/null || true)

echo "$AUTH_FILES"

if [ -z "$AUTH_FILES" ]; then
  echo "ERROR: Could not find auth middleware."
  exit 1
fi

echo ""
echo "2. Patch every auth middleware with mesh-public bypass"

for FILE in $AUTH_FILES; do
  echo ""
  echo "Patching: $FILE"
  SAFE=$(echo "$FILE" | sed 's#[/:]#_#g')
  cp "$FILE" "$BACKUP/$SAFE.bak" || true

  if ! grep -q "MAURIMESH_PUBLIC_MESH_AUTH_BYPASS" "$FILE"; then
    python3 - "$FILE" <<'PY'
import sys, re, pathlib

file = pathlib.Path(sys.argv[1])
text = file.read_text()

bypass = '''
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

'''

patterns = [
    r'(const\s+authHeader\s*=\s*req\.headers\.authorization\s*;)',
    r'(const\s+authorization\s*=\s*req\.headers\.authorization\s*;)',
    r'(const\s+token\s*=\s*req\.headers\.authorization\s*;)',
    r'(if\s*\(\s*!req\.headers\.authorization\s*\)\s*\{)',
    r'(if\s*\(\s*!authHeader\s*\)\s*\{)',
    r'(if\s*\(\s*!authorization\s*\)\s*\{)',
    r'(if\s*\(\s*!token\s*\)\s*\{)',
]

changed = False

for pat in patterns:
    if re.search(pat, text):
        text = re.sub(pat, bypass + r'\1', text, count=1)
        changed = True
        break

# Fallback: place before the exact error response if no header pattern found.
if not changed and "Authentication required. Provide Authorization" in text:
    text = text.replace(
        'res.status(401).json({',
        bypass + 'res.status(401).json({',
        1
    )
    changed = True

if changed:
    file.write_text(text)
    print("patched")
else:
    print("no safe patch point found")
PY
  else
    echo "Already patched."
  fi

  grep -n "MAURIMESH_PUBLIC_MESH_AUTH_BYPASS\|Authentication required\|authorization" "$FILE" | head -40 || true
done

echo ""
echo "3. Create/refresh public mesh route in all likely backend roots"

for DIR in server artifacts/api-server backend api; do
  mkdir -p "$DIR"

  cat > "$DIR/maurimeshPublicMeshRoutes.cjs" <<'JS'
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

function readLines(file, limit = 300) {
  ensureRuntime();
  const raw = fs.readFileSync(file, "utf8").trim();
  if (!raw) return [];
  return raw.split("\n").slice(-limit).map((line) => {
    try { return JSON.parse(line); } catch { return null; }
  }).filter(Boolean);
}

function append(file, data) {
  ensureRuntime();
  fs.appendFileSync(file, JSON.stringify(data) + "\n");
}

function event(input = {}) {
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

function isAck(e) {
  return ["ACK", "RX_ACK", "DELIVERED", "TX_BLE_OK"].includes(e.stage) ||
    ["ACK", "OK", "DELIVERED"].includes(e.status);
}

function isFail(e) {
  return ["FAIL", "ERROR", "TIMEOUT", "TX_BLE_ERROR", "ACK_TIMEOUT"].includes(e.stage) ||
    ["FAIL", "ERROR", "TIMEOUT"].includes(e.status);
}

function isWaiting(e) {
  return ["WAITING_FOR_ACK", "PENDING_ACK", "ACK_PENDING"].includes(e.stage) ||
    ["WAITING_FOR_ACK", "PENDING_ACK", "ACK_PENDING"].includes(e.status);
}

function score(events, transport) {
  const r = events.filter(e => e.transport === transport);
  const acks = r.filter(isAck).length;
  const fails = r.filter(isFail).length;
  const waits = r.filter(isWaiting).length;
  let s = 50 + acks * 14 - fails * 20 - waits * 6;
  if (transport === "BLE") s += 4;
  s = Math.max(0, Math.min(100, s));
  return { transport, score: s, acks, failures: fails, waitingAck: waits };
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

router.get("/api/mesh-public/health", (req, res) => {
  res.json({ ok: true, public: true, status: "online", service: "MauriMesh Public Mesh Intelligence", timestamp: now() });
});

router.get("/api/mesh-public/activity", (req, res) => {
  res.json(snapshot());
});

router.post("/api/mesh-public/activity/ingest", express.json({ limit: "1mb" }), (req, res) => {
  const saved = event(req.body || {});
  append(ledgerFile, saved);
  res.json({ ok: true, public: true, saved, intelligence: snapshot(), timestamp: now() });
});

router.post("/api/mesh-public/packet/decision", express.json({ limit: "1mb" }), (req, res) => {
  const body = req.body || {};
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
  res.json({ ok: true, public: true, decision, intelligence: snap, timestamp: now() });
});

module.exports = { mauriMeshPublicMeshRouter: router };
JS

  echo "Wrote $DIR/maurimeshPublicMeshRoutes.cjs"
done

echo ""
echo "4. Mount route in active Express server files"

SERVER_FILES=$(grep -RIl "express()\|app.listen\|app.use" \
  server backend src api artifacts \
  --exclude-dir=node_modules \
  --exclude-dir=.pnpm \
  --exclude-dir=dist \
  --exclude-dir=build \
  2>/dev/null || true)

for FILE in $SERVER_FILES; do
  if grep -q "mauriMeshPublicMeshRouter" "$FILE"; then
    echo "Already mounted in $FILE"
    continue
  fi

  if grep -q "const app = express()\|const app=express()\|let app = express()\|var app = express()" "$FILE"; then
    echo "Mounting in $FILE"
    SAFE=$(echo "$FILE" | sed 's#[/:]#_#g')
    cp "$FILE" "$BACKUP/$SAFE.server.bak" || true

    DIR=$(dirname "$FILE")
    REQUIRE_PATH="./maurimeshPublicMeshRoutes.cjs"

    python3 - "$FILE" "$REQUIRE_PATH" <<'PY'
import sys, re, pathlib
file = pathlib.Path(sys.argv[1])
require_path = sys.argv[2]
text = file.read_text()

mount = f'''
try {{
  const {{ mauriMeshPublicMeshRouter }} = require("{require_path}");
  app.use(mauriMeshPublicMeshRouter);
  console.log("[MauriMesh] Public Mesh Intelligence routes mounted.");
}} catch (error) {{
  console.error("[MauriMesh] Public Mesh route mount failed:", error);
}}

'''

patterns = [
    r'(const\s+app\s*=\s*express\(\)\s*;)',
    r'(let\s+app\s*=\s*express\(\)\s*;)',
    r'(var\s+app\s*=\s*express\(\)\s*;)',
]
for pat in patterns:
    if re.search(pat, text):
        text = re.sub(pat, r'\1\n' + mount, text, count=1)
        file.write_text(text)
        print("mounted")
        break
PY
  fi
done

echo ""
echo "5. Restart local server"

pkill -f "node|tsx|ts-node|vite" 2>/dev/null || true
sleep 2

if npm run dev >/tmp/maurimesh-final-server.log 2>&1 &
then
  echo "Started npm run dev"
else
  npm start >/tmp/maurimesh-final-server.log 2>&1 &
  echo "Started npm start"
fi

sleep 8

echo ""
echo "Server log:"
tail -80 /tmp/maurimesh-final-server.log || true

echo ""
echo "6. Test local ports"

for PORT in 3000 5000 5173 8080; do
  echo ""
  echo "Testing localhost:$PORT"
  curl -sS -i --max-time 5 "http://localhost:$PORT/api/mesh-public/health" || true
done

echo ""
echo "7. Test deployed URL"

BASE="https://mauri-mesh-messenger.replit.app"

curl -sS -i --max-time 15 "$BASE/api/mesh-public/health" || true

echo ""
curl -sS -i --max-time 15 "$BASE/api/mesh-public/activity" || true

echo ""
curl -sS -i --max-time 15 -X POST "$BASE/api/mesh-public/activity/ingest" \
  -H "Content-Type: application/json" \
  -d '{"packetId":"MM-FINAL-AUTH-BYPASS-001","stage":"TX_BLE_START","status":"SEND","transport":"BLE","fromPeerId":"PHONE-A","toPeerId":"PHONE-B","payloadBytes":128,"detail":"Final auth bypass test"}' || true

echo ""
curl -sS -i --max-time 15 -X POST "$BASE/api/mesh-public/packet/decision" \
  -H "Content-Type: application/json" \
  -d '{"packetId":"MM-FINAL-AUTH-BYPASS-001","payloadBytes":128,"preferredTransport":"BLE","targetPeerId":"PHONE-B","ttl":8}' || true

echo ""
echo "============================================================"
echo "DONE"
echo "If local is 200 but deployed is still 401, press Replit Deploy/Restart."
echo "If deployed is 200, API intelligence is connected."
echo "============================================================"
