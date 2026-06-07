#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "FIX MAURIMESH API CONNECTION"
echo "Local engine first + API fallback + safe simulation"
echo "============================================================"
echo ""

mkdir -p src/lib server backup-before-api-fix-$(date +%Y%m%d-%H%M%S)

BACKUP="backup-before-api-fix-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP"

for f in src/lib/api.ts src/lib/meshClient.ts server/index.ts .env .env.local; do
  if [ -f "$f" ]; then
    mkdir -p "$BACKUP/$(dirname "$f")"
    cp "$f" "$BACKUP/$f"
  fi
done

# ------------------------------------------------------------
# 1. ENV — use same-origin / relative API where possible
# ------------------------------------------------------------

cat > .env <<'ENV'
EXPO_PUBLIC_MESH_API_URL=
REACT_APP_MESH_API_URL=
ENV

cat > .env.local <<'ENV'
EXPO_PUBLIC_MESH_API_URL=
REACT_APP_MESH_API_URL=
ENV

# ------------------------------------------------------------
# 2. SAFE API CLIENT
# ------------------------------------------------------------

cat > src/lib/api.ts <<'TS'
const DEFAULT_TIMEOUT_MS = 6000;

export type ApiResult<T> =
  | { ok: true; data: T; source: "live" }
  | { ok: false; error: string; source: "unavailable" };

function getApiBase(): string {
  const configured =
    process.env.EXPO_PUBLIC_MESH_API_URL ||
    process.env.REACT_APP_MESH_API_URL ||
    "";

  if (configured.trim()) return configured.trim().replace(/\/$/, "");

  // Browser/Replit same-origin fallback.
  if (typeof window !== "undefined" && window.location?.origin) {
    return window.location.origin;
  }

  return "";
}

export async function apiGet<T>(
  path: string,
  timeoutMs = DEFAULT_TIMEOUT_MS
): Promise<ApiResult<T>> {
  const base = getApiBase();

  if (!base) {
    return {
      ok: false,
      error: "Mesh API URL is not configured.",
      source: "unavailable",
    };
  }

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);

  try {
    const cleanPath = path.startsWith("/") ? path : `/${path}`;
    const res = await fetch(`${base}${cleanPath}`, {
      method: "GET",
      signal: controller.signal,
      headers: {
        Accept: "application/json",
      },
    });

    clearTimeout(timeout);

    if (!res.ok) {
      return {
        ok: false,
        error: `Mesh API returned HTTP ${res.status}.`,
        source: "unavailable",
      };
    }

    const data = (await res.json()) as T;
    return { ok: true, data, source: "live" };
  } catch (err) {
    clearTimeout(timeout);
    return {
      ok: false,
      error: err instanceof Error ? err.message : "Unknown API error.",
      source: "unavailable",
    };
  }
}
TS

# ------------------------------------------------------------
# 3. PATCH MESH CLIENT — local engine first
# ------------------------------------------------------------

cat > src/lib/meshClient.ts <<'TS'
import { apiGet } from "./api";
import { simulatedNodes, simulatedRoutes, SimNode, SimRoute } from "./simulation";

export type MeshStatus = {
  mode: "LIVE" | "SIMULATION" | "UNAVAILABLE";
  message: string;
  nodes: SimNode[];
  routes: SimRoute[];
};

async function getLocalEngineStatus(): Promise<MeshStatus | null> {
  try {
    const mod = await import("../maurimesh/ui/mauriUiEngine");
    const snapshot = mod.getUiEngineSnapshot();

    if (snapshot?.nodes?.length) {
      return {
        mode: "LIVE",
        message:
          "MauriMesh local invention engine is active. API connection is not required for Replit UI proof.",
        nodes: snapshot.nodes as SimNode[],
        routes: snapshot.routes as SimRoute[],
      };
    }
  } catch {
    // Engine bridge not installed yet. Continue to API/simulation fallback.
  }

  return null;
}

export async function getMeshStatus(): Promise<MeshStatus> {
  const local = await getLocalEngineStatus();
  if (local) return local;

  const result = await apiGet<{
    nodes?: SimNode[];
    routes?: SimRoute[];
    truth?: string;
    message?: string;
  }>("/api/mesh/status");

  if (result.ok) {
    return {
      mode: "LIVE",
      message:
        result.data.truth ||
        result.data.message ||
        "Connected to MauriMesh API.",
      nodes: result.data.nodes || [],
      routes: result.data.routes || [],
    };
  }

  return {
    mode: "SIMULATION",
    message:
      "Mesh API unavailable. Showing safe simulation fallback so UI stays connected.",
    nodes: simulatedNodes,
    routes: simulatedRoutes,
  };
}
TS

# ------------------------------------------------------------
# 4. SERVER API — keep endpoints alive
# ------------------------------------------------------------

cat > server/index.ts <<'TS'
import express from "express";

let engineBridge: any = null;
let essentials: any = null;
let systemBrain: any = null;

try {
  engineBridge = require("../src/maurimesh/ui/mauriUiEngine");
} catch {}

try {
  essentials = require("../src/lib/mauriEssentials");
} catch {}

try {
  systemBrain = require("../src/maurimesh/system-brain/systemBrain");
} catch {}

const app = express();
const port = Number(process.env.PORT || 3000);

app.use(express.json());

const fallbackNodes = [
  { id: "PHONE_A", label: "Device A", status: "online", signal: 96, x: 18, y: 30 },
  { id: "PHONE_B", label: "Relay B", status: "relay", signal: 82, x: 48, y: 54 },
  { id: "PHONE_C", label: "Device C", status: "offline", signal: 44, x: 78, y: 28 },
  { id: "GATEWAY_D", label: "Gateway D", status: "relay", signal: 89, x: 66, y: 78 },
];

const fallbackRoutes = [
  { from: "PHONE_A", to: "PHONE_B", quality: 88 },
  { from: "PHONE_B", to: "PHONE_C", quality: 62 },
  { from: "PHONE_B", to: "GATEWAY_D", quality: 81 },
];

function snapshot() {
  if (engineBridge?.getUiEngineSnapshot) {
    return engineBridge.getUiEngineSnapshot();
  }

  return {
    mode: "SIMULATION",
    message: "Fallback API active. Engine bridge not loaded.",
    nodes: fallbackNodes,
    routes: fallbackRoutes,
    ledgerCount: 0,
    trustCount: 0,
    routeMemoryCount: 0,
  };
}

app.get("/api/health", (_req, res) => {
  res.json({
    ok: true,
    service: "maurimesh-replit-api",
    mode: "development",
    truth: "API is reachable. Replit proof only; native BLE requires APK and phones.",
  });
});

app.get("/api/mesh/status", (_req, res) => {
  const s = snapshot();
  res.json({
    mode: s.mode || "LIVE_ENGINE",
    truth:
      s.message ||
      "MauriMesh API connected. Native BLE still requires APK/device proof.",
    nodes: s.nodes || fallbackNodes,
    routes: s.routes || fallbackRoutes,
    ledgerCount: s.ledgerCount || 0,
    trustCount: s.trustCount || 0,
    routeMemoryCount: s.routeMemoryCount || 0,
    lastResult: s.lastResult,
  });
});

app.get("/api/invention/status", (_req, res) => {
  res.json(snapshot());
});

app.post("/api/invention/demo", (req, res) => {
  if (engineBridge?.runDemoMessage) {
    engineBridge.runDemoMessage(
      typeof req.body?.body === "string"
        ? req.body.body
        : "Kia kaha emergency help message through MauriMesh."
    );
  }
  res.json(snapshot());
});

app.post("/api/invention/send", (req, res) => {
  if (engineBridge?.sendUiMessage) {
    engineBridge.sendUiMessage({
      from: typeof req.body?.from === "string" ? req.body.from : "PHONE_A",
      to: typeof req.body?.to === "string" ? req.body.to : "PHONE_C",
      body:
        typeof req.body?.body === "string"
          ? req.body.body
          : "MauriMesh test message.",
    });
  }
  res.json(snapshot());
});

app.post("/api/invention/ack", (_req, res) => {
  if (engineBridge?.ackLastRoute) engineBridge.ackLastRoute();
  res.json(snapshot());
});

app.post("/api/invention/fail", (_req, res) => {
  if (engineBridge?.failLastRoute) {
    engineBridge.failLastRoute("API-triggered failure simulation.");
  }
  res.json(snapshot());
});

app.get("/api/invention/register", (_req, res) => {
  res.json({
    count: essentials?.MAURIMESH_INVENTION_REGISTER?.length || 0,
    inventions: essentials?.MAURIMESH_INVENTION_REGISTER || [],
  });
});

app.get("/api/invention/audit", (_req, res) => {
  if (essentials?.getMauriCompletionAudit) {
    res.json(essentials.getMauriCompletionAudit());
    return;
  }

  res.json({
    score: 50,
    summary: "Audit fallback active. Essentials module not loaded.",
    items: [],
  });
});

app.get("/api/system-brain/status", (_req, res) => {
  if (systemBrain?.getSystemBrainSnapshot) {
    res.json(systemBrain.getSystemBrainSnapshot());
    return;
  }

  res.json({
    score: 50,
    summary: "System brain fallback active. Module not loaded.",
    recommendations: ["Run the system brain installer if this screen is required."],
  });
});

app.listen(port, "0.0.0.0", () => {
  console.log(`[MauriMesh] API running on 0.0.0.0:${port}`);
});
TS

# ------------------------------------------------------------
# 5. PACKAGE SCRIPTS
# ------------------------------------------------------------

node <<'NODE'
const fs = require("fs");
const path = "package.json";

if (!fs.existsSync(path)) {
  fs.writeFileSync(path, JSON.stringify({ scripts: {}, dependencies: {}, devDependencies: {} }, null, 2));
}

const pkg = JSON.parse(fs.readFileSync(path, "utf8"));
pkg.scripts = pkg.scripts || {};

pkg.scripts.api = "tsx server/index.ts";
pkg.scripts.check = "tsc --noEmit";
pkg.scripts.typecheck = "tsc --noEmit";
pkg.scripts.dev = pkg.scripts.dev || "expo start --web --host 0.0.0.0 --port 8082";
pkg.scripts.start = pkg.scripts.start || "expo start --web --host 0.0.0.0 --port 8082";

pkg.dependencies = pkg.dependencies || {};
pkg.devDependencies = pkg.devDependencies || {};

pkg.dependencies.express = pkg.dependencies.express || "latest";
pkg.devDependencies.tsx = pkg.devDependencies.tsx || "latest";
pkg.devDependencies.typescript = pkg.devDependencies.typescript || "latest";
pkg.devDependencies["@types/express"] = pkg.devDependencies["@types/express"] || "latest";
pkg.devDependencies["@types/node"] = pkg.devDependencies["@types/node"] || "latest";

fs.writeFileSync(path, JSON.stringify(pkg, null, 2));
console.log("package.json patched.");
NODE

echo ""
echo "============================================================"
echo "API CONNECTION FIX INSTALLED"
echo "============================================================"
echo ""
echo "Next:"
echo "  npm install"
echo "  npm run check"
echo ""
echo "Then run API in one Replit Shell:"
echo "  npm run api"
echo ""
echo "Run UI in another Replit Shell:"
echo "  npm run dev"
echo ""
echo "Test API:"
echo "  curl http://localhost:3000/api/health"
echo "  curl http://localhost:3000/api/mesh/status"
echo ""
