#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo "RUN ROUTE SAFETY RESTART PROOF"
echo "============================================================"

if command -v tsx >/dev/null 2>&1; then
  tsx scripts/route-safety-proof/route-safety-restart-proof.ts
else
  npx tsx scripts/route-safety-proof/route-safety-restart-proof.ts
fi
