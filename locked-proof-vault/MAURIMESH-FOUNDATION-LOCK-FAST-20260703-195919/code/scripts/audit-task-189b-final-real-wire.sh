#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo "#189B Final Real Wire Audit"
echo "============================================================"

grep -RniE "TASK_189B|two_phone_hardware_evidence|POST /api/proof/evidence|GET /api/proof/evidence|Save to Proof Ledger|createProofRouter|/api/proof" \
  server app tests docs scripts 2>/dev/null || true

echo ""
echo "Required checks:"
grep -q 'app.use("/api/proof", createProofRouter())' server/index.ts && echo "✅ server/index.ts mounts /api/proof"
grep -q 'router.post("/evidence"' server/proofRoutes.ts && echo "✅ POST /api/proof/evidence route"
grep -q 'router.get("/evidence"' server/proofRoutes.ts && echo "✅ GET /api/proof/evidence route"
grep -q 'two_phone_hardware_evidence' server/proofEvidence.ts && echo "✅ canonical evidence type"
grep -q 'Save to Proof Ledger' app/ble-proof.tsx && echo "✅ Save button text exists"
grep -q 'Proof Ledger' app/proof-ledger.tsx && echo "✅ Proof Ledger screen exists"
