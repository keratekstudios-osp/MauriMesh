#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MauriMesh Shell Master Check"
echo "No Replit Agent Required"
echo "============================================================"
echo ""

ROOT="$(pwd)"
REPORT="$ROOT/MAURIMESH_SHELL_REPORT.md"

echo "# MauriMesh Shell Report" > "$REPORT"
echo "" >> "$REPORT"
echo "Generated: $(date)" >> "$REPORT"
echo "" >> "$REPORT"

echo "1. Checking project root..."
echo "Project root: $ROOT" | tee -a "$REPORT"

echo ""
echo "2. Listing main files..."
{
  echo "## Root files"
  ls -la
  echo ""
} >> "$REPORT"

echo ""
echo "3. Checking package.json..."
if [ -f package.json ]; then
  echo "package.json found" | tee -a "$REPORT"
  node -e "const p=require('./package.json'); console.log('name:',p.name||'none'); console.log('scripts:',Object.keys(p.scripts||{}).join(', ')||'none')" | tee -a "$REPORT" || true
else
  echo "package.json MISSING" | tee -a "$REPORT"
fi

echo ""
echo "4. Checking app routes..."
if [ -d app ]; then
  find app -maxdepth 3 -type f | sort | tee -a "$REPORT"
else
  echo "app folder MISSING" | tee -a "$REPORT"
fi

echo ""
echo "5. Checking source folders..."
for d in src lib components assets android ios; do
  if [ -d "$d" ]; then
    echo "$d found" | tee -a "$REPORT"
  else
    echo "$d missing" | tee -a "$REPORT"
  fi
done

echo ""
echo "6. Checking key MauriMesh files..."
KEY_FILES=(
  "app/index.tsx"
  "app/_layout.tsx"
  "package.json"
  "app.json"
  "eas.json"
  "tsconfig.json"
)

for f in "${KEY_FILES[@]}"; do
  if [ -f "$f" ]; then
    echo "FOUND: $f" | tee -a "$REPORT"
  else
    echo "MISSING: $f" | tee -a "$REPORT"
  fi
done

echo ""
echo "7. Checking dependencies..."
if [ -f package.json ]; then
  node - <<'NODE' | tee -a "$REPORT"
const fs = require("fs");
const p = JSON.parse(fs.readFileSync("package.json","utf8"));
const all = {...(p.dependencies||{}), ...(p.devDependencies||{})};
const required = [
  "expo",
  "expo-router",
  "react",
  "react-native",
  "react-native-ble-plx",
  "expo-status-bar",
  "typescript"
];
for (const r of required) {
  console.log(`${all[r] ? "FOUND" : "MISSING"}: ${r}${all[r] ? " -> " + all[r] : ""}`);
}
NODE
fi

echo ""
echo "8. Running npm install check..."
if [ -f package.json ]; then
  npm install --legacy-peer-deps || true
else
  echo "Skipped npm install: no package.json"
fi

echo ""
echo "9. Running TypeScript check..."
if [ -f package.json ]; then
  npx tsc --noEmit || true
fi

echo ""
echo "10. Running Expo diagnostics..."
if [ -f package.json ]; then
  npx expo-doctor || true
fi

echo ""
echo "11. Git status..."
if [ -d .git ]; then
  git status --short | tee -a "$REPORT"
else
  echo "No git repository found" | tee -a "$REPORT"
fi

echo ""
echo "============================================================"
echo "CHECK COMPLETE"
echo "Report saved to:"
echo "$REPORT"
echo "============================================================"
