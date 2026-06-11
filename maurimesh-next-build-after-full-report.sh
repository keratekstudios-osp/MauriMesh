#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH NEXT BUILD AFTER FULL MESH REPORT FIX"
echo "Verifies /full-mesh-test-report, commits, then prepares APK build"
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
LOG="$ROOT/docs/maurimesh-next-build-after-full-report-$STAMP.log"
LATEST="$ROOT/docs/maurimesh-next-build-after-full-report-latest.log"

mkdir -p "$ROOT/docs"

exec > >(tee -a "$LOG") 2>&1

if [ ! -f "$ROOT/package.json" ]; then
  echo "ERROR: package.json not found. Run from /home/runner/workspace."
  exit 1
fi

echo ""
echo "============================================================"
echo "1. VERIFY REQUIRED ROUTE FILE"
echo "============================================================"

if [ -f "$ROOT/app/full-mesh-test-report.tsx" ]; then
  echo "PASS: app/full-mesh-test-report.tsx exists"
else
  echo "FAIL: app/full-mesh-test-report.tsx missing"
  echo "Run the installer again before building."
  exit 1
fi

echo ""
echo "============================================================"
echo "2. VERIFY ROUTE REFERENCES"
echo "============================================================"

grep -RIn "full-mesh-test-report" "$ROOT/app" "$ROOT/src" 2>/dev/null || true

echo ""
echo "============================================================"
echo "3. ROUTE INVENTORY SNAPSHOT"
echo "============================================================"

find "$ROOT/app" -type f -name "*.tsx" \
  | sed "s|$ROOT/||" \
  | sort \
  | tee "$ROOT/docs/maurimesh-route-inventory-after-full-report-$STAMP.txt"

cp "$ROOT/docs/maurimesh-route-inventory-after-full-report-$STAMP.txt" \
   "$ROOT/docs/maurimesh-route-inventory-after-full-report-latest.txt"

echo ""
echo "============================================================"
echo "4. PACKAGE CHECK"
echo "============================================================"

if [ -f pnpm-lock.yaml ] && command -v pnpm >/dev/null 2>&1; then
  echo "Using pnpm."
  pnpm install --frozen-lockfile || pnpm install
elif [ -f package-lock.json ]; then
  echo "Using npm ci/install."
  npm ci || npm install
else
  echo "No lockfile detected. Running npm install."
  npm install
fi

echo ""
echo "============================================================"
echo "5. TYPESCRIPT CHECK"
echo "============================================================"

if [ -f tsconfig.json ]; then
  if [ -f pnpm-lock.yaml ] && command -v pnpm >/dev/null 2>&1; then
    pnpm exec tsc --noEmit || true
  else
    npx tsc --noEmit || true
  fi
else
  echo "No tsconfig.json found. Skipping TypeScript check."
fi

echo ""
echo "============================================================"
echo "6. EXPO ROUTER EXPORT / BUNDLE SANITY CHECK"
echo "============================================================"

if [ -f app.json ] || [ -f app.config.js ] || [ -f app.config.ts ]; then
  npx expo export --platform android --output-dir dist-apk-route-check || true
else
  echo "No Expo config detected. Skipping expo export."
fi

echo ""
echo "============================================================"
echo "7. GIT STATUS + COMMIT"
echo "============================================================"

git status --short || true

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git add app/full-mesh-test-report.tsx app/dashboard.tsx docs || true

  if git diff --cached --quiet; then
    echo "No staged changes to commit."
  else
    git commit -m "Add full mesh test report route" || true
  fi
else
  echo "Not inside a git repo. Skipping commit."
fi

echo ""
echo "============================================================"
echo "8. BUILD COMMAND"
echo "============================================================"

cat <<'BUILD'

Run this now if the checks above did not show a fatal blocker:

npx eas-cli build --platform android --profile preview-apk --clear-cache

After APK installs, open these screens:

/full-mesh-test-report
/dashboard
/test-layer
/native-telemetry
/mauricore-ble-runtime
/device-proof
/proof-ledger

Expected report change:

FROM:
MISSING | REQUIRED | /full-mesh-test-report | MISSING

TO:
PRESENT | REQUIRED | /full-mesh-test-report | app/full-mesh-test-report.tsx

BUILD

echo ""
echo "============================================================"
echo "DONE"
echo "Latest log:"
echo "$LATEST"
echo "============================================================"

cp "$LOG" "$LATEST"
