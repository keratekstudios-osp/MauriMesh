#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH FINAL APK BUILD GATE"
echo "Checks source before fresh APK build"
echo "No build yet."
echo "============================================================"
echo ""

echo "[1] Required files"
REQUIRED=(
  "app/_layout.tsx"
  "app/login.tsx"
  "app/dashboard.tsx"
  "src/components/MauriPanel.tsx"
  "package.json"
)

for f in "${REQUIRED[@]}"; do
  if [ -f "$f" ]; then
    echo "OK: $f"
  else
    echo "FAIL: missing $f"
    exit 1
  fi
done

echo ""
echo "[2] Confirm MauriPanel is safe React Native only"
grep -n "from \"react-native\"" src/components/MauriPanel.tsx
grep -n "export function MauriPanel" src/components/MauriPanel.tsx
grep -n "export default MauriPanel" src/components/MauriPanel.tsx

echo ""
echo "[3] Confirm Dashboard uses MauriPanel and no bad import"
grep -n "MauriPanel" app/dashboard.tsx | head -20
if grep -RIn "MauriPanel.*from.*lucide\|MauriPanel.*from.*expo\|MauriPanel.*from.*linear\|MauriPanel.*from.*blur" app src; then
  echo "FAIL: bad MauriPanel import remains"
  exit 1
else
  echo "OK: no bad MauriPanel import found"
fi

echo ""
echo "[4] Check package scripts"
cat package.json | grep -E '"(start|android|build|typecheck|check)"' || true

echo ""
echo "[5] TypeScript"
npx tsc --noEmit

echo ""
echo "[6] Expo config check"
npx expo config --type public >/tmp/maurimesh-expo-config.txt
head -60 /tmp/maurimesh-expo-config.txt

echo ""
echo "[7] Create build marker"
mkdir -p docs
cat > docs/MAURIPANEL_CRASH_FIX_READY_FOR_APK.md <<'TXT'
# MauriPanel Dashboard Crash Fix

Status: READY FOR FRESH APK BUILD

Cause found on A06:
React Native JavascriptException:
Element type is invalid, got undefined.

Crash stack:
MauriPanel -> AppShell -> DashboardScreen

Fix:
src/components/MauriPanel.tsx replaced with safe React Native-only component.
Dashboard and related imports patched.
TypeScript check passed before build.

Next:
Build fresh APK, install on A06/A16, open Dashboard, verify no crash.
TXT

echo ""
echo "============================================================"
echo "PASS: READY TO BUILD FRESH APK"
echo "============================================================"
echo "Next command after this:"
echo "npx eas-cli build --platform android --profile preview-apk --clear-cache"
echo "============================================================"
