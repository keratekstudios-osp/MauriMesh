#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "FINAL APK BUILD AFTER FULL MESH REPORT ROUTE FIX"
echo "Target: /full-mesh-test-report"
echo "============================================================"
echo ""

if [ ! -f package.json ]; then
  echo "ERROR: package.json missing. Wrong folder."
  exit 1
fi

if [ ! -f app/full-mesh-test-report.tsx ]; then
  echo "ERROR: app/full-mesh-test-report.tsx missing."
  exit 1
fi

echo "PASS: full mesh report route exists."

echo ""
echo "Dashboard route reference:"
grep -RIn "full-mesh-test-report" app/dashboard.tsx app/test-layer.tsx app/full-mesh-test-report.tsx 2>/dev/null || true

echo ""
echo "============================================================"
echo "QUICK ROUTE INVENTORY"
echo "============================================================"
find app -type f -name "*.tsx" | sort | sed 's#^#- #'

echo ""
echo "============================================================"
echo "GIT STATUS BEFORE BUILD"
echo "============================================================"
git status --short || true

echo ""
echo "============================================================"
echo "STARTING EAS APK BUILD"
echo "============================================================"
echo "This build will upload to EAS."
echo "When it finishes, use the Expo build link/QR to install on your phone."
echo "Do not choose emulator install inside Replit."
echo ""

npx eas-cli build --platform android --profile preview-apk --clear-cache --non-interactive

echo ""
echo "============================================================"
echo "BUILD COMMAND COMPLETE"
echo "============================================================"
echo ""
echo "After installing APK on phone, open:"
echo "1. /dashboard"
echo "2. Full Mesh Test Report button"
echo "3. /full-mesh-test-report"
echo ""
echo "Expected report fix:"
echo "PRESENT | REQUIRED | /full-mesh-test-report | app/full-mesh-test-report.tsx"
echo "============================================================"
