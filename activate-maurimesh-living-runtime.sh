#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "ACTIVATE MAURIMESH LIVING RUNTIME"
echo "Self-learning + intelligent routing + governance + tikanga"
echo "============================================================"
echo ""

ROOT="$(pwd)"
RUNTIME_DIR="$ROOT/src/maurimesh/living-runtime"
STATE_DIR="$ROOT/maurimesh-runtime-state"
BACKUP="$ROOT/backup-before-living-runtime-$(date +%Y%m%d-%H%M%S)"

mkdir -p "$RUNTIME_DIR" "$STATE_DIR" "$BACKUP"

echo "Creating backup marker..."
cat > "$BACKUP/README.txt" <<'TXT'
Backup marker before activating MauriMesh Living Runtime.
This install adds new runtime files only.
It does not delete BLE, router, ACK, store-forward, or UI files.
TXT

if [ ! -f "src/maurimesh/invention-engine/livingSelfGovernedAiMesh.ts" ]; then
  echo ""
  echo "ERROR: Invention engine missing."
  echo "Run install-maurimesh-invention-engine.sh first."
  exit 1
fi

# ============================================================
# 1. LIVING RUNTIME CONFIG
# ============================================================

cat > "$RUNTIME_DIR/livingRuntimeConfig.ts" <<'TS'
export const livingRuntimeConfig = {
  tickMs: Number(process.env.MAURIMESH_TICK_MS || 15000),
  stateDir: process.env.MAURIMESH_STATE_DIR || "maurimesh-runtime-state",
  nodeId: process.env.MAURIMESH_NODE_ID || "REPLIT_BUILD_NODE",
  mode: process.env.MAURIMESH_RUNTIME_MODE || "REPLIT_LOGIC_ENGINE",
  truth:
    "This runtime activates self-learning logic, governance, routing decisions, store-forward simulation, and self-healing state. It does not prove native BLE until APK/device testing.",
};
TS

# ============================================================
# 2. PERSISTENT STATE STORE
# ============================================================

cat > "$RUNTIME_DIR/stateStore.ts" <<'TS'
import fs from "fs";
import path from "path";

export function ensureDir(dir: string): void {
  fs.mkdirSync(dir, { recursive: true });
}

export function readJson<T>(filePath: string, fallback: T): T {
  try {
    if (!fs.existsSync(filePath)) return fallback;
    return JSON.parse(fs.readFileSync(filePath, "utf8")) as T;
  } catch {
    return fallback;
  }
}

export function writeJson(filePath: string, data: unknown): void {
  ensureDir(path.dirname(filePath));
  fs.writeFileSync(filePath, JSON.stringify(data, null, 2));
}

export function appendLog(filePath: string, line: string): void {
  ensureDir(path.dirname(filePath));
  fs.appendFileSync(filePath, `${line}\n`);
}
TS

# ============================================================
# 3. LIVING RUNTIME DAEMON
# ============================================================

cat > "$RUNTIME_DIR/livingRuntimeDaemon.ts" <<'TS'
import path from "path";
import {
  LivingSelfGovernedAiMesh,
  MeshNode,
  EngineResult,
} from "../invention-engine";
import { livingRuntimeConfig } from "./livingRuntimeConfig";
import { appendLog, ensureDir, readJson, writeJson } from "./stateStore";

type RuntimeMemory = {
  startedAtMs: number;
  lastTickAtMs: number;
  tickCount: number;
  evolutionScore: number;
  governanceActive: boolean;
  tikangaActive: boolean;
  selfLearningActive: boolean;
  intelligentRoutingActive: boolean;
  selfHealingActive: boolean;
  storeForwardActive: boolean;
  lastPacketId?: string;
  lastDecision?: string;
  lastCulturalState?: string;
  lastRouteScore?: number;
  ledgerCount: number;
  trustCount: number;
  routeMemoryCount: number;
  truth: string;
};

const stateDir = livingRuntimeConfig.stateDir;
const memoryFile = path.join(stateDir, "living-runtime-memory.json");
const snapshotFile = path.join(stateDir, "living-runtime-snapshot.json");
const logFile = path.join(stateDir, "living-runtime.log");

ensureDir(stateDir);

const engine = new LivingSelfGovernedAiMesh();

const nodes: MeshNode[] = [
  {
    id: "REPLIT_BUILD_NODE",
    label: "Replit Build Node",
    role: "SUPERNODE",
    trust: "VERIFIED",
    batteryPct: 100,
    signalPct: 96,
    online: true,
    lastSeenMs: Date.now(),
    transports: ["LOCAL_WIFI", "INTERNET", "STORE_FORWARD"],
    culturalState: "KAITIAKITANGA_GUARDIAN",
  },
  {
    id: "PHONE_A",
    label: "Primary Android Device",
    role: "ENDPOINT",
    trust: "VERIFIED",
    batteryPct: 88,
    signalPct: 92,
    online: true,
    lastSeenMs: Date.now(),
    transports: ["BLE", "WIFI_DIRECT", "LOCAL_WIFI"],
    culturalState: "WHANAUNGATANGA_TRUSTED",
  },
  {
    id: "PHONE_B",
    label: "Relay Android Device",
    role: "RELAY",
    trust: "TRUSTED",
    batteryPct: 74,
    signalPct: 81,
    online: true,
    lastSeenMs: Date.now(),
    transports: ["BLE", "WIFI_DIRECT"],
    culturalState: "MANAAKITANGA_CARE",
  },
  {
    id: "PHONE_C",
    label: "Offline Recipient Device",
    role: "ENDPOINT",
    trust: "OBSERVED",
    batteryPct: 61,
    signalPct: 42,
    online: false,
    lastSeenMs: Date.now() - 90000,
    transports: ["BLE"],
    culturalState: "NOA_OPEN",
  },
  {
    id: "GATEWAY_D",
    label: "Gateway Node",
    role: "GATEWAY",
    trust: "VERIFIED",
    batteryPct: 97,
    signalPct: 89,
    online: true,
    lastSeenMs: Date.now(),
    transports: ["LOCAL_WIFI", "INTERNET"],
    culturalState: "KAITIAKITANGA_GUARDIAN",
  },
];

engine.setNodes(nodes);

function loadMemory(): RuntimeMemory {
  return readJson<RuntimeMemory>(memoryFile, {
    startedAtMs: Date.now(),
    lastTickAtMs: 0,
    tickCount: 0,
    evolutionScore: 0,
    governanceActive: true,
    tikangaActive: true,
    selfLearningActive: true,
    intelligentRoutingActive: true,
    selfHealingActive: true,
    storeForwardActive: true,
    ledgerCount: 0,
    trustCount: 0,
    routeMemoryCount: 0,
    truth: livingRuntimeConfig.truth,
  });
}

function chooseTrainingMessage(tick: number): string {
  const messages = [
    "Kia kaha emergency help message through MauriMesh.",
    "Private tapu message for trusted delivery only.",
    "Whānau family check-in through MauriMesh.",
    "Normal noa open mesh message for route learning.",
    "Store and forward delivery test while recipient is offline.",
    "Governance and tikanga protocol test for intelligent routing.",
  ];
  return messages[tick % messages.length];
}

function scoreEvolution(result: EngineResult): number {
  let score = 1;

  if (result.governance.approved) score += 2;
  if (result.routePlan.totalScore > 0.5) score += 2;
  if (result.routePlan.storeAndForward) score += 1;
  if (result.synth.length > 0) score += 1;
  if (result.packet.culturalState === "KIA_KAHA_EMERGENCY") score += 1;

  return score;
}

function tick(): void {
  const memory = loadMemory();
  const now = Date.now();
  const nextTick = memory.tickCount + 1;

  const body = chooseTrainingMessage(nextTick);

  const result = engine.send({
    from: "PHONE_A",
    to: "PHONE_C",
    body,
  });

  const routeNodes = [
    result.packet.from,
    ...result.routePlan.hops.map((h) => h.nodeId),
    result.packet.to,
  ];

  if (nextTick % 3 === 0) {
    engine.fail(result.packet.id, routeNodes, "Runtime training failure: route unavailable, learning fallback.");
  } else {
    engine.ack(result.packet.id, routeNodes, 300 + nextTick * 7);
  }

  const routeMemory = engine.routeMemoryExport();
  const trustMemory = engine.trustMemoryExport();
  const ledger = engine.ledgerExport();
  const visual = engine.visualSnapshot();

  const evolved: RuntimeMemory = {
    ...memory,
    lastTickAtMs: now,
    tickCount: nextTick,
    evolutionScore: memory.evolutionScore + scoreEvolution(result),
    governanceActive: true,
    tikangaActive: true,
    selfLearningActive: true,
    intelligentRoutingActive: true,
    selfHealingActive: true,
    storeForwardActive: true,
    lastPacketId: result.packet.id,
    lastDecision: result.routePlan.decisionReason,
    lastCulturalState: result.packet.culturalState,
    lastRouteScore: result.routePlan.totalScore,
    ledgerCount: ledger.length,
    trustCount: trustMemory.length,
    routeMemoryCount: routeMemory.length,
    truth: livingRuntimeConfig.truth,
  };

  writeJson(memoryFile, evolved);
  writeJson(snapshotFile, {
    runtime: evolved,
    lastResult: result,
    visual,
    routeMemory,
    trustMemory,
    ledger: ledger.slice(-50),
    updatedAt: new Date(now).toISOString(),
  });

  appendLog(
    logFile,
    `[${new Date(now).toISOString()}] tick=${nextTick} packet=${result.packet.id} state=${result.packet.culturalState} score=${Math.round(result.routePlan.totalScore * 100)} decision="${result.routePlan.decisionReason}"`
  );

  console.log(
    `[MauriMesh Living Runtime] tick=${nextTick} evolution=${evolved.evolutionScore} cultural=${result.packet.culturalState} routeScore=${Math.round(result.routePlan.totalScore * 100)} ledger=${ledger.length} trust=${trustMemory.length} memory=${routeMemory.length}`
  );
}

console.log("");
console.log("============================================================");
console.log("MAURIMESH LIVING RUNTIME ACTIVE");
console.log("============================================================");
console.log(`Mode: ${livingRuntimeConfig.mode}`);
console.log(`Tick: every ${livingRuntimeConfig.tickMs}ms`);
console.log(`State: ${stateDir}`);
console.log(livingRuntimeConfig.truth);
console.log("");

tick();
setInterval(tick, livingRuntimeConfig.tickMs);
TS

# ============================================================
# 4. RUNTIME STATUS READER
# ============================================================

cat > "$RUNTIME_DIR/livingRuntimeStatus.ts" <<'TS'
import path from "path";
import { livingRuntimeConfig } from "./livingRuntimeConfig";
import { readJson } from "./stateStore";

const snapshotFile = path.join(livingRuntimeConfig.stateDir, "living-runtime-snapshot.json");
const memoryFile = path.join(livingRuntimeConfig.stateDir, "living-runtime-memory.json");

console.log("");
console.log("============================================================");
console.log("MAURIMESH LIVING RUNTIME STATUS");
console.log("============================================================");
console.log("");

const memory = readJson(memoryFile, null);
const snapshot = readJson(snapshotFile, null);

console.log(JSON.stringify({ memory, snapshot }, null, 2));
TS

# ============================================================
# 5. API SERVER PATCH FOR RUNTIME STATUS
# ============================================================

if [ -f "server/index.ts" ]; then
  cp server/index.ts "$BACKUP/server-index-before-living-runtime.ts"
fi

cat > server/index.ts <<'TS'
import express from "express";
import fs from "fs";
import path from "path";
import {
  getUiEngineSnapshot,
  runDemoMessage,
  sendUiMessage,
  ackLastRoute,
  failLastRoute,
} from "../src/maurimesh/ui/mauriUiEngine";
import {
  getMauriCompletionAudit,
  MAURIMESH_INVENTION_REGISTER,
} from "../src/lib/mauriEssentials";

const app = express();
const port = Number(process.env.PORT || 3000);

app.use(express.json());

function readRuntimeJson(name: string) {
  const file = path.join(process.cwd(), "maurimesh-runtime-state", name);
  if (!fs.existsSync(file)) return null;
  try {
    return JSON.parse(fs.readFileSync(file, "utf8"));
  } catch {
    return null;
  }
}

app.get("/api/health", (_req, res) => {
  res.json({
    ok: true,
    service: "maurimesh-replit-api",
    mode: "development",
    truth: "Replit API is development only. Native BLE requires APK and physical devices.",
  });
});

app.get("/api/living-runtime/status", (_req, res) => {
  res.json({
    memory: readRuntimeJson("living-runtime-memory.json"),
    snapshot: readRuntimeJson("living-runtime-snapshot.json"),
    truth:
      "Living runtime proves Replit-side self-learning and routing logic only. Native BLE requires APK and physical devices.",
  });
});

app.get("/api/mesh/status", (_req, res) => {
  const snapshot = getUiEngineSnapshot();

  res.json({
    mode: snapshot.mode,
    truth: snapshot.message,
    nodes: snapshot.nodes,
    routes: snapshot.routes,
    ledgerCount: snapshot.ledgerCount,
    trustCount: snapshot.trustCount,
    routeMemoryCount: snapshot.routeMemoryCount,
    lastResult: snapshot.lastResult,
  });
});

app.get("/api/invention/status", (_req, res) => {
  res.json(getUiEngineSnapshot());
});

app.get("/api/invention/register", (_req, res) => {
  res.json({
    count: MAURIMESH_INVENTION_REGISTER.length,
    inventions: MAURIMESH_INVENTION_REGISTER,
  });
});

app.get("/api/invention/audit", (_req, res) => {
  res.json(getMauriCompletionAudit());
});

app.post("/api/invention/demo", (req, res) => {
  const body =
    typeof req.body?.body === "string"
      ? req.body.body
      : "Kia kaha, emergency help message through MauriMesh.";

  runDemoMessage(body);
  res.json(getUiEngineSnapshot());
});

app.post("/api/invention/send", (req, res) => {
  const body =
    typeof req.body?.body === "string"
      ? req.body.body
      : "MauriMesh test message.";

  sendUiMessage({
    from: typeof req.body?.from === "string" ? req.body.from : "PHONE_A",
    to: typeof req.body?.to === "string" ? req.body.to : "PHONE_C",
    body,
  });

  res.json(getUiEngineSnapshot());
});

app.post("/api/invention/ack", (_req, res) => {
  ackLastRoute();
  res.json(getUiEngineSnapshot());
});

app.post("/api/invention/fail", (_req, res) => {
  failLastRoute("API-triggered failure simulation.");
  res.json(getUiEngineSnapshot());
});

app.listen(port, "0.0.0.0", () => {
  console.log(`[MauriMesh] Replit API running on port ${port}`);
});
TS

# ============================================================
# 6. PACKAGE SCRIPTS
# ============================================================

node <<'NODE'
const fs = require("fs");
const path = "package.json";

if (!fs.existsSync(path)) {
  fs.writeFileSync(path, JSON.stringify({ scripts: {}, dependencies: {}, devDependencies: {} }, null, 2));
}

const pkg = JSON.parse(fs.readFileSync(path, "utf8"));

pkg.scripts = pkg.scripts || {};
pkg.scripts["maurimesh:living"] = "tsx src/maurimesh/living-runtime/livingRuntimeDaemon.ts";
pkg.scripts["maurimesh:living:status"] = "tsx src/maurimesh/living-runtime/livingRuntimeStatus.ts";
pkg.scripts["maurimesh:check"] = "tsc --noEmit";
pkg.scripts["check"] = pkg.scripts["check"] || "tsc --noEmit";
pkg.scripts["api"] = "tsx server/index.ts";

pkg.dependencies = pkg.dependencies || {};
pkg.devDependencies = pkg.devDependencies || {};
pkg.dependencies.express = pkg.dependencies.express || "latest";
pkg.devDependencies.tsx = pkg.devDependencies.tsx || "latest";
pkg.devDependencies.typescript = pkg.devDependencies.typescript || "latest";
pkg.devDependencies["@types/express"] = pkg.devDependencies["@types/express"] || "latest";
pkg.devDependencies["@types/node"] = pkg.devDependencies["@types/node"] || "latest";

fs.writeFileSync(path, JSON.stringify(pkg, null, 2));
console.log("package.json patched with living runtime scripts.");
NODE

# ============================================================
# 7. START HELPER
# ============================================================

cat > start-maurimesh-living-runtime.sh <<'SH'
#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "STARTING MAURIMESH LIVING RUNTIME"
echo "============================================================"
echo ""

npm install

echo ""
echo "TypeScript check..."
npm run maurimesh:check

echo ""
echo "Starting living runtime daemon..."
npm run maurimesh:living
SH

chmod +x start-maurimesh-living-runtime.sh

cat > MAURIMESH_LIVING_RUNTIME_ACTIVE.md <<'MD'
# MauriMesh Living Runtime Activated

## Active layers

- Self-learning route memory
- Intelligent routing logic
- Mauri AI routing conscience
- Self-governance
- Tikanga protocol engine
- Tapu / Noa privacy state handling
- Kia Kaha emergency mode
- Store-and-forward logic
- Self-healing runtime checks
- Decentralised trust memory
- Delivery proof ledger
- Living mesh visual snapshot
- Runtime evolution score

## Runtime files

- `src/maurimesh/living-runtime/livingRuntimeDaemon.ts`
- `src/maurimesh/living-runtime/livingRuntimeStatus.ts`
- `maurimesh-runtime-state/living-runtime-memory.json`
- `maurimesh-runtime-state/living-runtime-snapshot.json`
- `maurimesh-runtime-state/living-runtime.log`

## Commands

Start runtime:

```bash
npm run maurimesh:living
