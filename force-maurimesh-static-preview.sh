#!/usr/bin/env bash
set -e

echo "=================================================="
echo "FORCE MAURIMESH STATIC PREVIEW MODE"
echo "No API wait. No fetch hang. Instant simulation."
echo "=================================================="

BACKUP="backup-before-force-static-preview-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP"

for f in src/lib/api.ts src/lib/meshClient.ts src/lib/mauriSystemBrainClient.ts app/dashboard.tsx; do
  if [ -f "$f" ]; then
    mkdir -p "$BACKUP/$(dirname "$f")"
    cp "$f" "$BACKUP/$f"
    echo "Backed up: $f"
  fi
done

mkdir -p src/lib

cat > src/lib/api.ts <<'TS'
export type ApiResult<T> =
  | { ok: true; data: T; source: "live" }
  | { ok: false; error: string; source: "unavailable" };

export const API_BASE = "";

export async function apiGet<T>(_path: string): Promise<ApiResult<T>> {
  return {
    ok: false,
    error: "Static Replit preview mode. Network API disabled by design.",
    source: "unavailable"
  };
}
TS

cat > src/lib/meshClient.ts <<'TS'
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

export type MeshStatus = {
  mode: "LIVE" | "SIMULATION" | "UNAVAILABLE";
  message: string;
  nodes: SimNode[];
  routes: SimRoute[];
};

export const staticPreviewNodes: SimNode[] = [
  { id: "A", label: "Phone A", status: "online", signal: 96, x: 18, y: 30 },
  { id: "B", label: "Relay B", status: "relay", signal: 82, x: 48, y: 54 },
  { id: "C", label: "Phone C", status: "online", signal: 74, x: 78, y: 28 },
  { id: "D", label: "Store Forward D", status: "offline", signal: 31, x: 66, y: 78 }
];

export const staticPreviewRoutes: SimRoute[] = [
  { from: "A", to: "B", quality: 92 },
  { from: "B", to: "C", quality: 84 },
  { from: "B", to: "D", quality: 38 }
];

export async function getMeshStatus(): Promise<MeshStatus> {
  return {
    mode: "SIMULATION",
    message:
      "MauriMesh static Replit preview is running. Mesh API and live BLE are disabled here; labelled simulation fallback is active.",
    nodes: staticPreviewNodes,
    routes: staticPreviewRoutes
  };
}
TS

cat > src/lib/mauriSystemBrainClient.ts <<'TS'
export type MauriSystemBrainSnapshot = {
  mode: "BROWSER_SAFE" | "NATIVE_PENDING" | "SERVER_PENDING";
  status: "READY" | "SIMULATION" | "UNAVAILABLE";
  message: string;
  layers: {
    name: string;
    status: "active" | "protected" | "pending-native" | "server-only";
  }[];
  truth: string;
};

export async function getMauriSystemBrainSnapshot(): Promise<MauriSystemBrainSnapshot> {
  return {
    mode: "BROWSER_SAFE",
    status: "SIMULATION",
    message:
      "MauriMesh System Brain is running in browser-safe static preview mode.",
    layers: [
      { name: "Messenger UI", status: "active" },
      { name: "Dashboard", status: "active" },
      { name: "Living Mesh Preview", status: "active" },
      { name: "Mesh Status UI", status: "active" },
      { name: "BLE Runtime", status: "pending-native" },
      { name: "ACK / Routing / Store-Forward", status: "protected" },
      { name: "Tikanga Governance", status: "protected" },
      { name: "Self-Healing Runtime", status: "protected" },
      { name: "System Brain File Ledger", status: "server-only" }
    ],
    truth:
      "This proves the Replit web UI layer. Real BLE, native ACK routing, and offline phone-to-phone proof require APK/device validation."
  };
}

export async function runMauriSystemBrainDemo() {
  return {
    ok: true,
    mode: "BROWSER_SAFE",
    message: "Demo route prepared in static simulation mode."
  };
}

export async function ackMauriSystemBrainRoute() {
  return {
    ok: true,
    mode: "BROWSER_SAFE",
    message: "ACK simulated in static preview mode."
  };
}

export async function failMauriSystemBrainRoute() {
  return {
    ok: true,
    mode: "BROWSER_SAFE",
    message: "Failure simulated in static preview mode."
  };
}
TS

echo ""
echo "Searching for hard fetch/failure text..."
grep -R "Fetching mesh data\\|Could not reach the mesh API\\|fetch(" app src 2>/dev/null || true

echo ""
echo "Patch visible hard text if present..."
python3 <<'PY'
from pathlib import Path

replacements = {
    "Could not reach the mesh API.": "Static Replit preview running with labelled simulation fallback.",
    "Fetching mesh data...": "Loading static MauriMesh preview..."
}

for root in ["app", "src"]:
    base = Path(root)
    if not base.exists():
        continue
    for f in base.rglob("*"):
        if f.suffix not in [".ts", ".tsx", ".js", ".jsx"]:
            continue
        text = f.read_text(errors="ignore")
        old = text
        for a, b in replacements.items():
            text = text.replace(a, b)
        if text != old:
            f.write_text(text)
            print("Patched:", f)
PY

echo ""
echo "TypeScript check..."
npx tsc --noEmit || true

echo ""
echo "Rebuilding static web..."
rm -rf dist .expo node_modules/.cache
npx expo export --platform web --clear

echo ""
echo "Serving dist on port 3000..."
npx serve dist -l tcp://0.0.0.0:3000
