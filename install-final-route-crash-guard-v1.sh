#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH FINAL ROUTE CRASH GUARD v1"
echo "============================================================"

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
REPORT="$ROOT/docs/learner/final-route-crash-guard-v1-$STAMP.md"
mkdir -p "$ROOT/docs/learner"

ROUTES=(
  "app/dashboard.tsx"
  "app/locked-proof-vault.tsx"
  "app/proof-vault-health.tsx"
  "app/learner-core.tsx"
  "app/store-forward-proof.tsx"
  "app/3-device-proof.tsx"
  "app/ble-3-device-proof.tsx"
  "app/ble-2-hop-proof.tsx"
)

echo "# MauriMesh Final Route Crash Guard v1" > "$REPORT"
echo "" >> "$REPORT"
echo "Generated: $STAMP" >> "$REPORT"
echo "" >> "$REPORT"

MISSING=0

echo ""
echo "[1] Route file check"
echo "## Route file check" >> "$REPORT"

for f in "${ROUTES[@]}"; do
  if [ -f "$ROOT/$f" ]; then
    echo "PASS: $f"
    echo "- PASS: $f" >> "$REPORT"
  else
    echo "MISSING: $f"
    echo "- MISSING: $f" >> "$REPORT"
    MISSING=1
  fi
done

echo ""
echo "[2] Dashboard button route references"
echo "## Dashboard route references" >> "$REPORT"
grep -n "router.push" "$ROOT/app/dashboard.tsx" | tee -a "$REPORT" || true

echo ""
echo "[3] Risk marker scan"
echo "## Risk marker scan" >> "$REPORT"

grep -R "BLOCKED_PROOF_VAULT_UI\|throw new Error\|TODO_CRASH\|undefined is not" "$ROOT/app" "$ROOT/src" 2>/dev/null | tee -a "$REPORT" || true

echo ""
echo "[4] TypeScript check"
echo "## TypeScript check" >> "$REPORT"
npx tsc --noEmit 2>&1 | tee -a "$REPORT" || true

echo ""
echo "[5] Expo Android export"
echo "## Expo Android export" >> "$REPORT"
npx expo export --platform android --clear 2>&1 | tee -a "$REPORT"

echo ""
echo "============================================================"
echo "FINAL ROUTE CRASH GUARD COMPLETE"
echo "============================================================"
echo "Missing route files: $MISSING"
echo "Report: $REPORT"
echo ""
echo "Truth:"
echo "- Export pass means JS bundle builds."
echo "- Physical APK still must be tested on A06/S10/A16."
echo "- Native BLE/GATT PASS is not claimed by this guard."
echo "============================================================"
