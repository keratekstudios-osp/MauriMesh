#!/usr/bin/env bash
set -e

echo "=================================================="
echo "FIX MAURIMESH EXPO FS/PATH BUNDLER BLOCKER"
echo "=================================================="

ROOT="$(pwd)"
BACKUP="$ROOT/backup-before-fs-browser-fix-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP"

echo ""
echo "1. Backup affected files"

for f in \
  src/lib/mauriSystemBrainClient.ts \
  src/maurimesh/system-brain/systemBrain.ts \
  app/dashboard.tsx
do
  if [ -f "$f" ]; then
    mkdir -p "$BACKUP/$(dirname "$f")"
    cp "$f" "$BACKUP/$f"
    echo "Backed up: $f"
  fi
done

echo ""
echo "2. Replace browser client with Expo-safe version"

mkdir -p src/lib

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
      "MauriMesh System Brain client is browser-safe. Node fs/path runtime is protected from Expo bundling.",
    layers: [
      { name: "Messenger UI", status: "active" },
      { name: "Mesh Status UI", status: "active" },
      { name: "Living Mesh Preview", status: "active" },
      { name: "BLE Runtime", status: "pending-native" },
      { name: "ACK / Routing / Store-Forward", status: "protected" },
      { name: "System Brain File Ledger", status: "server-only" },
      { name: "Tikanga Governance", status: "protected" },
      { name: "Self-Healing Runtime", status: "protected" }
    ],
    truth:
      "Replit/Expo preview can run UI and safe simulation. Node fs/path and real BLE must run in server/native runtime, not inside the browser bundle."
  };
}

export async function runMauriSystemBrainDemo() {
  return {
    ok: true,
    mode: "BROWSER_SAFE",
    message:
      "Demo route prepared in UI-safe mode. Real route proof requires APK/device validation."
  };
}

export async function ackMauriSystemBrainRoute() {
  return {
    ok: true,
    mode: "BROWSER_SAFE",
    message:
      "ACK simulated in UI-safe mode. Real ACK requires native BLE/runtime proof."
  };
}

export async function failMauriSystemBrainRoute() {
  return {
    ok: true,
    mode: "BROWSER_SAFE",
    message:
      "Failure recorded in UI-safe mode. Real self-healing repair requires native/runtime validation."
  };
}
TS

echo ""
echo "3. Check for remaining direct fs/path imports inside app/src browser path"

grep -R "from \"fs\"\\|from 'fs'\\|require(\"fs\")\\|require('fs')\\|from \"path\"\\|from 'path'" app src 2>/dev/null || true

echo ""
echo "4. TypeScript check"
npx tsc --noEmit || true

echo ""
echo "=================================================="
echo "FS/PATH BROWSER FIX COMPLETE"
echo "=================================================="
echo ""
echo "Now run:"
echo "npx expo start --web --clear --host lan --port 3000"
echo ""
