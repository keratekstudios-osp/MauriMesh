#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "WIRE UI ROADMAP BUTTON TO DASHBOARD"
echo "Target: app/dashboard.tsx"
echo "Route:  /ui-roadmap"
echo "============================================================"
echo ""

ROOT="$(pwd)"
DASH="$ROOT/app/dashboard.tsx"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$ROOT/backup-before-ui-roadmap-button-$STAMP"

if [ ! -f "$ROOT/package.json" ]; then
  echo "ERROR: package.json not found. Run this from the Replit project root."
  exit 1
fi

if [ ! -f "$DASH" ]; then
  echo "ERROR: app/dashboard.tsx not found."
  exit 1
fi

if [ ! -f "$ROOT/app/ui-roadmap.tsx" ]; then
  echo "ERROR: app/ui-roadmap.tsx not found."
  echo "Run design-maurimesh-ui-remainder.sh first."
  exit 1
fi

mkdir -p "$BACKUP"
cp "$DASH" "$BACKUP/dashboard.tsx"

node <<'NODE'
const fs = require("fs");

const dashPath = "app/dashboard.tsx";
let src = fs.readFileSync(dashPath, "utf8");

if (src.includes("/ui-roadmap")) {
  console.log("UI Roadmap button already exists in dashboard.");
  process.exit(0);
}

const buttonLine =
`        <MauriButton title="UI Roadmap" onPress={() => router.push("/ui-roadmap")} />`;

const settingsButtonRegex =
/(\s*<MauriButton\s+title=["']Settings["'][\s\S]*?router\.push\(["']\/settings["']\)[\s\S]*?\/>\s*)/;

if (settingsButtonRegex.test(src)) {
  src = src.replace(settingsButtonRegex, `$1\n${buttonLine}\n`);
} else {
  const gridCloseRegex = /(\s*<\/View>\s*\n\s*<\/AppShell>)/;
  if (!gridCloseRegex.test(src)) {
    console.error("ERROR: Could not find safe insert location in dashboard.");
    process.exit(1);
  }
  src = src.replace(gridCloseRegex, `\n${buttonLine}\n$1`);
}

fs.writeFileSync(dashPath, src);
console.log("Inserted UI Roadmap dashboard button.");
NODE

echo ""
echo "Running TypeScript check..."
if command -v npx >/dev/null 2>&1; then
  npx tsc --noEmit
else
  echo "WARN: npx not found. Skipping TypeScript check."
fi

echo ""
echo "============================================================"
echo "DONE"
echo "Dashboard now has:"
echo "  UI Roadmap -> /ui-roadmap"
echo ""
echo "Backup saved:"
echo "  $BACKUP/dashboard.tsx"
echo ""
echo "Next:"
echo "  Open the app dashboard."
echo "  Press UI Roadmap."
echo "============================================================"
