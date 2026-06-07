#!/usr/bin/env bash
set -e

echo "=================================================="
echo "ADD API FALLBACK + SIMULATION LAYER — NO EAS BUILD"
echo "=================================================="

BACKUP="$HOME/maurimesh-router-backups/backup-before-api-fallback-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP"
cp -R app "$BACKUP/app-current" 2>/dev/null || true
cp -R src "$BACKUP/src-current" 2>/dev/null || true
cp -R server "$BACKUP/server-current" 2>/dev/null || true

mkdir -p src/lib server

echo ""
echo "1. Create safe API client"

cat > src/lib/api.ts <<'TS'
const DEFAULT_TIMEOUT_MS = 6000;

export type ApiResult<T> =
  | { ok: true; data: T; source: "live" }
  | { ok: false; error: string; source: "unavailable" };

export const API_BASE =
  process.env.EXPO_PUBLIC_MESH_API_URL ||
  process.env.REACT_APP_MESH_API_URL ||
  "";

export async function apiGet<T>(
  path: string,
  timeoutMs = DEFAULT_TIMEOUT_MS
): Promise<ApiResult<T>> {
  if (!API_BASE) {
    return {
      ok: false,
      error: "Mesh API URL is not configured.",
      source: "unavailable",
    };
  }

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);

  try {
    const res = await fetch(`${API_BASE}${path}`, {
      method: "GET",
      signal: controller.signal,
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

echo ""
echo "2. Create labelled simulation data"

cat > src/lib/simulation.ts <<'TS'
export type SimNode = {
  id: string;
  label: string;
  status: "online" | "relay" | "offline";
  signal: number;
  x: number;
  y: number;
};

export type SimRoute = {
  from: string;
  to: string;
  quality: number;
};

export const simulatedNodes: SimNode[] = [
  { id: "A", label: "Device A", status: "online", signal: 96, x: 18, y: 30 },
  { id: "B", label: "Relay B", status: "relay", signal: 82, x: 48, y: 54 },
  { id: "C", label: "Device C", status: "online", signal: 74, x: 78, y: 28 },
  { id: "D", label: "Stored D", status: "offline", signal: 31, x: 66, y: 78 },
];

export const simulatedRoutes: SimRoute[] = [
  { from: "A", to: "B", quality: 92 },
  { from: "B", to: "C", quality: 84 },
  { from: "B", to: "D", quality: 38 },
];
TS

echo ""
echo "3. Create mesh client"

cat > src/lib/meshClient.ts <<'TS'
import { apiGet } from "./api";
import { simulatedNodes, simulatedRoutes, SimNode, SimRoute } from "./simulation";

export type MeshStatus = {
  mode: "LIVE" | "SIMULATION" | "UNAVAILABLE";
  message: string;
  nodes: SimNode[];
  routes: SimRoute[];
};

export async function getMeshStatus(): Promise<MeshStatus> {
  const result = await apiGet<{
    nodes?: SimNode[];
    routes?: SimRoute[];
  }>("/api/mesh/status");

  if (result.ok) {
    return {
      mode: "LIVE",
      message: "Connected to Mesh API.",
      nodes: result.data.nodes || [],
      routes: result.data.routes || [],
    };
  }

  return {
    mode: "SIMULATION",
    message:
      "Mesh API unavailable in APK/Replit preview. Showing labelled simulation only. This is not live BLE.",
    nodes: simulatedNodes,
    routes: simulatedRoutes,
  };
}
TS

echo ""
echo "4. Create Replit development API server"

cat > server/index.ts <<'TS'
import express from "express";

const app = express();
const port = Number(process.env.PORT || 3000);

app.use(express.json());

app.get("/api/health", (_req, res) => {
  res.json({
    ok: true,
    service: "maurimesh-replit-api",
    mode: "development",
    truth: "Replit API is development only. It does not prove live BLE.",
  });
});

app.get("/api/mesh/status", (_req, res) => {
  res.json({
    mode: "SIMULATION",
    truth: "Replit API simulation only. Not live BLE.",
    nodes: [
      { id: "A", label: "Device A", status: "online", signal: 96, x: 18, y: 30 },
      { id: "B", label: "Relay B", status: "relay", signal: 82, x: 48, y: 54 },
      { id: "C", label: "Device C", status: "online", signal: 74, x: 78, y: 28 },
      { id: "D", label: "Stored D", status: "offline", signal: 31, x: 66, y: 78 },
    ],
    routes: [
      { from: "A", to: "B", quality: 92 },
      { from: "B", to: "C", quality: 84 },
      { from: "B", to: "D", quality: 38 },
    ],
  });
});

app.listen(port, "0.0.0.0", () => {
  console.log(`[MauriMesh] Replit API running on port ${port}`);
});
TS

cat > .env.example <<'ENV'
EXPO_PUBLIC_MESH_API_URL=
ENV

echo ""
echo "5. Upgrade mesh-status screen to use fallback client"

cat > app/mesh-status.tsx <<'TSX'
import React, { useEffect, useState } from "react";
import { ScrollView, StyleSheet, Text, View } from "react-native";
import { getMeshStatus, MeshStatus } from "../src/lib/meshClient";

const MARKER = "API_FALLBACK_MESH_STATUS_20260607_A";

export default function MeshStatusScreen() {
  const [mesh, setMesh] = useState<MeshStatus | null>(null);

  useEffect(() => {
    let alive = true;
    getMeshStatus()
      .then((status) => {
        if (alive) setMesh(status);
      })
      .catch(() => {
        if (alive) {
          setMesh({
            mode: "UNAVAILABLE",
            message: "Mesh status failed safely.",
            nodes: [],
            routes: [],
          });
        }
      });
    return () => {
      alive = false;
    };
  }, []);

  const mode = mesh?.mode || "UNAVAILABLE";
  const tone =
    mode === "LIVE"
      ? "#00D084"
      : mode === "SIMULATION"
        ? "#F59E0B"
        : "#EF4444";

  return (
    <ScrollView style={styles.screen} contentContainerStyle={styles.content}>
      <Text style={styles.brand}>MauriMesh</Text>
      <Text style={styles.title}>Mesh Status</Text>
      <Text style={styles.marker}>{MARKER}</Text>

      <View style={[styles.statusPill, { borderColor: tone }]}>
        <Text style={[styles.statusText, { color: tone }]}>{mode}</Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>API Fallback</Text>
        <Text style={styles.cardText}>
          {mesh?.message || "Checking mesh fallback status..."}
        </Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Nodes Visible</Text>
        <Text style={styles.cardText}>{mesh?.nodes.length || 0} node(s)</Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Routes Visible</Text>
        <Text style={styles.cardText}>{mesh?.routes.length || 0} route(s)</Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Truth Boundary</Text>
        <Text style={styles.cardText}>
          This screen can show live API data only if EXPO_PUBLIC_MESH_API_URL is configured.
          Otherwise it shows labelled simulation. It does not claim live BLE.
        </Text>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: "#020617" },
  content: { padding: 24, paddingTop: 72 },
  brand: { color: "#00D084", fontSize: 38, fontWeight: "900", marginBottom: 8 },
  title: { color: "#FFFFFF", fontSize: 28, fontWeight: "900", marginBottom: 8 },
  marker: { color: "#38BDF8", fontSize: 12, fontWeight: "800", marginBottom: 18 },
  statusPill: {
    alignSelf: "flex-start",
    borderWidth: 1,
    borderRadius: 999,
    paddingVertical: 7,
    paddingHorizontal: 14,
    marginBottom: 18,
    backgroundColor: "rgba(255,255,255,0.04)",
  },
  statusText: { fontSize: 12, fontWeight: "900", letterSpacing: 1 },
  card: {
    backgroundColor: "rgba(255,255,255,0.06)",
    borderColor: "rgba(0,208,132,0.28)",
    borderWidth: 1,
    borderRadius: 18,
    padding: 16,
    marginBottom: 12,
  },
  cardTitle: { color: "#FFFFFF", fontSize: 17, fontWeight: "900", marginBottom: 8 },
  cardText: { color: "rgba(255,255,255,0.78)", fontSize: 14, lineHeight: 22 },
});
TSX

echo ""
echo "6. Update package scripts safely"

node <<'NODE'
const fs = require("fs");
const path = "package.json";
const pkg = JSON.parse(fs.readFileSync(path, "utf8"));
pkg.scripts = pkg.scripts || {};
pkg.scripts.api = pkg.scripts.api || "tsx server/index.ts";
pkg.scripts.typecheck = pkg.scripts.typecheck || "tsc --noEmit";
pkg.scripts.check = pkg.scripts.check || "tsc --noEmit";
pkg.dependencies = pkg.dependencies || {};
pkg.devDependencies = pkg.devDependencies || {};
pkg.dependencies.express = pkg.dependencies.express || "latest";
pkg.devDependencies.tsx = pkg.devDependencies.tsx || "latest";
pkg.devDependencies["@types/express"] = pkg.devDependencies["@types/express"] || "latest";
fs.writeFileSync(path, JSON.stringify(pkg, null, 2));
NODE

echo ""
echo "7. Install only if dependencies are missing"

if [ -f pnpm-lock.yaml ]; then
  pnpm install --no-frozen-lockfile
elif [ -f package-lock.json ]; then
  npm install
else
  npm install
fi

echo ""
echo "8. Crash-risk scan"
grep -R "unstable-native-tabs\|NativeTabs\|SplashScreen\|preventAutoHide\|hideAsync\|useFonts\|_layout.backup" app 2>/dev/null && {
  echo "FAIL: risky startup pattern found."
  exit 1
} || echo "PASS: no known risky startup patterns"

echo ""
echo "9. TypeScript"
npx tsc --noEmit

echo ""
echo "10. Clean export"
rm -rf dist .expo
npx expo export --platform android --clear

echo ""
echo "11. Marker check"
grep -R "API_FALLBACK_MESH_STATUS_20260607_A" app dist .expo 2>/dev/null || true

echo ""
echo "=================================================="
echo "API FALLBACK + SIMULATION LAYER READY — NO EAS BUILD USED"
echo "Backup: $BACKUP"
echo "=================================================="
