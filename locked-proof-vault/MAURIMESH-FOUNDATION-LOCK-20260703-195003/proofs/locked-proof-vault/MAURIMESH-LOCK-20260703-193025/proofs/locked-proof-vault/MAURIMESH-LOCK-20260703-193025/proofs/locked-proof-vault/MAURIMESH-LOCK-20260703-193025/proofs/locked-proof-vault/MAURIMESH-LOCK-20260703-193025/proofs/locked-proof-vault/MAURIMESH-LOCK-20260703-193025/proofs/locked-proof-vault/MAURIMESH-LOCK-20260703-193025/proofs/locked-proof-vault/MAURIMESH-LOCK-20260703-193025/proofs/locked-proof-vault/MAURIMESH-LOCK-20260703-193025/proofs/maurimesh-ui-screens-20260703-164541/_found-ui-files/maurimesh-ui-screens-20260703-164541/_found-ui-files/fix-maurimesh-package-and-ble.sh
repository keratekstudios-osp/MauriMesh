#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MauriMesh Package Repair + BLE Dependency Restore"
echo "============================================================"
echo ""

ROOT="$(pwd)"
BACKUP_DIR="$ROOT/backups/package-repair-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

if [ ! -f package.json ]; then
  echo "ERROR: package.json not found."
  exit 1
fi

cp package.json "$BACKUP_DIR/package.json.backup"
[ -f pnpm-lock.yaml ] && cp pnpm-lock.yaml "$BACKUP_DIR/pnpm-lock.yaml.backup" || true
[ -f package-lock.json ] && cp package-lock.json "$BACKUP_DIR/package-lock.json.backup" || true

echo "Backup saved to: $BACKUP_DIR"
echo ""

node <<'NODE'
const fs = require("fs");

const path = "package.json";
const pkg = JSON.parse(fs.readFileSync(path, "utf8"));

pkg.scripts = pkg.scripts || {};
pkg.dependencies = pkg.dependencies || {};
pkg.devDependencies = pkg.devDependencies || {};

// Correct Expo 54 / React Native 0.81 baseline
const deps = {
  "expo": "~54.0.34",
  "expo-router": "~6.0.23",
  "react": "19.1.0",
  "react-dom": "19.1.0",
  "react-native": "0.81.5",
  "react-native-ble-plx": "^3.5.0",
  "expo-status-bar": "~3.0.9"
};

for (const [name, version] of Object.entries(deps)) {
  pkg.dependencies[name] = version;
}

pkg.devDependencies["typescript"] = pkg.devDependencies["typescript"] || "~5.9.2";
pkg.devDependencies["@types/react"] = pkg.devDependencies["@types/react"] || "~19.1.0";

// Remove npm-breaking overrides/catalog references
delete pkg.overrides;
delete pkg.resolutions;

if (pkg.pnpm && typeof pkg.pnpm === "object") {
  delete pkg.pnpm.overrides;
}

// Replace any remaining catalog: values inside common dependency blocks
const blocks = [
  "dependencies",
  "devDependencies",
  "peerDependencies",
  "optionalDependencies"
];

for (const block of blocks) {
  if (!pkg[block]) continue;
  for (const [name, value] of Object.entries(pkg[block])) {
    if (typeof value === "string" && value.startsWith("catalog:")) {
      if (name === "react") pkg[block][name] = "19.1.0";
      else if (name === "react-dom") pkg[block][name] = "19.1.0";
      else if (name === "react-native") pkg[block][name] = "0.81.5";
      else if (name === "expo") pkg[block][name] = "~54.0.34";
      else if (name === "expo-router") pkg[block][name] = "~6.0.23";
      else pkg[block][name] = "latest";
    }
  }
}

pkg.packageManager = "pnpm@10.11.1";

pkg.scripts["mauri:package:check"] =
  "node -e \"const p=require('./package.json'); console.log({expo:p.dependencies.expo, react:p.dependencies.react, rn:p.dependencies['react-native'], ble:p.dependencies['react-native-ble-plx']})\"";

fs.writeFileSync(path, JSON.stringify(pkg, null, 2) + "\n");
console.log("package.json repaired.");
NODE

echo ""
echo "Removing npm lock if present, because this project is using pnpm..."
rm -f package-lock.json

echo ""
echo "Ensuring pnpm is available..."
corepack enable 2>/dev/null || true
corepack prepare pnpm@10.11.1 --activate 2>/dev/null || true

if ! command -v pnpm >/dev/null 2>&1; then
  echo "pnpm not found through corepack. Installing local pnpm through npx path..."
  npm install -g pnpm@10.11.1 || true
fi

echo ""
echo "Installing dependencies with pnpm..."
pnpm install --no-frozen-lockfile

echo ""
echo "Checking repaired package versions..."
pnpm run mauri:package:check

echo ""
echo "Running TypeScript check..."
pnpm exec tsc --noEmit || true

echo ""
echo "Running Expo doctor..."
pnpm exec expo-doctor || true

echo ""
echo "Git status after repair..."
git status --short || true

echo ""
echo "============================================================"
echo "PACKAGE REPAIR COMPLETE"
echo "Next: send the TypeScript / Expo doctor errors if any remain."
echo "============================================================"
