#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "FIX BACKEND CONNECT FOR APK / REPLIT"
echo "API health + mesh status + CORS + public base support"
echo "============================================================"
echo ""

mkdir -p server

cat > server/index.ts <<'TS'
import express from "express";

const app = express();
const port = Number(process.env.PORT || 3000);

app.use(express.json());

app.use((req, res, next) => {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "GET,POST,OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type,Authorization");
  if (req.method === "OPTIONS") {
    res.sendStatus(204);
    return;
  }
  next();
});

const nodes = [
  { id: "PHONE_A", label: "Device A", status: "online", signal: 96, x: 18, y: 30 },
  { id: "PHONE_B", label: "Relay B", status: "relay", signal: 82, x: 48, y: 54 },
  { id: "PHONE_C", label: "Device C", status: "offline", signal: 44, x: 78, y: 28 },
  { id: "GATEWAY_D", label: "Gateway D", status: "relay", signal: 89, x: 66, y: 78 },
];

const routes = [
  { from: "PHONE_A", to: "PHONE_B", quality: 88 },
  { from: "PHONE_B", to: "PHONE_C", quality: 62 },
  { from: "PHONE_B", to: "GATEWAY_D", quality: 81 },
];

app.get("/", (_req, res) => {
  res.json({
    ok: true,
    service: "MauriMesh Backend",
    message: "MauriMesh API is running.",
    endpoints: [
      "/api/health",
      "/api/mesh/status",
      "/api/invention/status",
    ],
  });
});

app.get("/api/health", (_req, res) => {
  res.json({
    ok: true,
    service: "maurimesh-backend",
    status: "connected",
    truth: "Backend API reachable. Native BLE still requires APK/device proof.",
  });
});

app.get("/api/mesh/status", (_req, res) => {
  res.json({
    ok: true,
    mode: "LIVE_BACKEND",
    truth: "Backend connected. This is API connectivity, not native BLE proof.",
    nodes,
    routes,
    ledgerCount: 0,
    trustCount: 0,
    routeMemoryCount: 0,
  });
});

app.get("/api/invention/status", (_req, res) => {
  res.json({
    ok: true,
    mode: "LIVE_BACKEND",
    message: "MauriMesh invention backend endpoint is reachable.",
    nodes,
    routes,
    ledgerCount: 0,
    trustCount: 0,
    routeMemoryCount: 0,
  });
});

app.listen(port, "0.0.0.0", () => {
  console.log(`[MauriMesh] Backend API running on 0.0.0.0:${port}`);
});
TS

node <<'NODE'
const fs = require("fs");
const path = "package.json";

if (!fs.existsSync(path)) {
  fs.writeFileSync(path, JSON.stringify({ scripts: {}, dependencies: {}, devDependencies: {} }, null, 2));
}

const pkg = JSON.parse(fs.readFileSync(path, "utf8"));

pkg.scripts = pkg.scripts || {};
pkg.scripts.api = "tsx server/index.ts";
pkg.scripts.check = pkg.scripts.check || "tsc --noEmit";

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
echo "BACKEND CONNECT PATCH COMPLETE"
echo "============================================================"
echo ""
echo "Now run:"
echo "  npm install"
echo "  npm run api"
echo ""
echo "Then open these in browser:"
echo "  /api/health"
echo "  /api/mesh/status"
echo ""
