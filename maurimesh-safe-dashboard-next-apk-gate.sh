#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH SAFE DASHBOARD NEXT APK GATE"
echo "============================================================"

STAMP="$(date +%Y%m%d-%H%M%S)"
REPORT="docs/runtime-crash/MAURIMESH_SAFE_DASHBOARD_NEXT_APK_GATE_$STAMP.md"
mkdir -p docs/runtime-crash

{
  echo "# MauriMesh Safe Dashboard Next APK Gate"
  echo ""
  echo "Generated: $STAMP"
  echo ""
  echo "## Required in next APK"
  echo ""
  echo "- Safe Dashboard Entry v2"
  echo "- Store-Forward proof vault save call"
  echo "- Proof Vault Health route"
  echo "- Learner Core route"
  echo "- Raw Proof Vault route"
  echo ""
  echo "## Route markers"
  echo ""
  grep -n "Safe Dashboard\|MAURIMESH_SAFE_DASHBOARD_OPEN\|locked-proof-vault\|proof-vault-health\|learner-core\|store-forward-proof\|3-device-proof\|ble-2-hop-proof" app/dashboard.tsx || true
  echo ""
  echo "## Store-Forward vault save call"
  echo ""
  grep -n "MAURIMESH_STORE_FORWARD_VAULT_SAVE_CALL_V1\|maurimesh_proof_store_forward" app/store-forward-proof.tsx || true
  echo ""
  echo "## Proof Vault Health route"
  echo ""
  grep -n "Proof Vault Health\|MAURIMESH_PROOF_VAULT_HEALTH" app/proof-vault-health.tsx || true
  echo ""
  echo "## Truth"
  echo ""
  echo "This gate confirms source readiness only."
  echo "Physical APK must still be installed and tested on A06/S10/A16."
  echo "Native BLE/GATT packet-bound PASS is not claimed."
} | tee "$REPORT"

echo ""
echo "============================================================"
echo "VALIDATE EXPORT"
echo "============================================================"
npx expo export --platform android --clear

echo ""
echo "============================================================"
echo "NEXT APK GATE COMPLETE"
echo "Report: $REPORT"
echo "============================================================"
