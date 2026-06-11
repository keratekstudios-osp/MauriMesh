#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH ROUTE FILE AUDIT"
echo "============================================================"
echo ""

ROUTES=(
  "app/dashboard.tsx"
  "app/ble-2-hop-proof.tsx"
  "app/ble-3-device-proof.tsx"
  "app/store-forward-proof.tsx"
  "app/next-proof-exam.tsx"
  "app/chat.tsx"
  "app/living-mesh.tsx"
  "app/mesh-status.tsx"
  "app/add-friend.tsx"
  "app/pixel-calling.tsx"
  "app/settings.tsx"
  "app/button-audit.tsx"
)

FAIL=0

for f in "${ROUTES[@]}"; do
  if [ -f "$f" ]; then
    echo "OK: $f"
  else
    echo "MISSING: $f"
    FAIL=1
  fi
done

echo ""
echo "TypeScript check:"
npx tsc --noEmit

if [ "$FAIL" -eq 0 ]; then
  echo ""
  echo "ROUTE FILE AUDIT: PASS"
else
  echo ""
  echo "ROUTE FILE AUDIT: FAIL"
  exit 1
fi
