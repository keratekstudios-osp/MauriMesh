#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo "#189 Hardware Proof Evidence Ledger Audit"
echo "============================================================"

grep -RniE "TASK_189|/api/proof/evidence|two_phone_hardware_evidence|saveHardwareProofEvidenceToServerLedger|registerProofEvidenceRoute" \
  artifacts/api-server lib/db artifacts/messenger-mobile artifacts/maurimesh docs scripts 2>/dev/null || true

echo ""
echo "Required files:"
test -f artifacts/api-server/src/routes/proof-evidence.ts && echo "✅ API route file"
test -f artifacts/api-server/src/runtime/saveHardwareProofEvidence.ts && echo "✅ API save runtime"
test -f artifacts/messenger-mobile/src/lib/proofEvidenceClient.ts && echo "✅ Mobile evidence client"
test -f artifacts/maurimesh/src/components/proof/HardwareEvidenceLedgerPanel.tsx && echo "✅ Web evidence panel"
