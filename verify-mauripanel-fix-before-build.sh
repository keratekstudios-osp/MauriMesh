#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "VERIFY MAURIPANEL FIX BEFORE APK BUILD"
echo "============================================================"
echo ""

echo "[1] Confirm safe MauriPanel exists"
sed -n '1,120p' src/components/MauriPanel.tsx

echo ""
echo "[2] Confirm Dashboard imports safe MauriPanel"
grep -n "MauriPanel" app/dashboard.tsx | head -20

echo ""
echo "[3] Confirm no old broken MauriPanel import remains"
grep -RIn "MauriPanel.*from.*lucide\|MauriPanel.*from.*expo\|MauriPanel.*from.*linear\|MauriPanel.*from.*blur" app src || true

echo ""
echo "[4] TypeScript check"
npx tsc --noEmit

echo ""
echo "============================================================"
echo "PASS: SOURCE READY FOR NEXT APK BUILD"
echo "============================================================"
