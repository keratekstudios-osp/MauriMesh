#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH SAFE DASHBOARD APK BUILD NOW"
echo "============================================================"
echo "This build should include:"
echo "- Safe Dashboard Entry v2"
echo "- Store-Forward vault save call"
echo "- Proof Vault Health route"
echo "- Learner Core route"
echo "- Raw Proof Vault route"
echo "- Proof vault storage helpers"
echo "============================================================"

STAMP="$(date +%Y%m%d-%H%M%S)"
REPORT="docs/runtime-crash/MAURIMESH_SAFE_DASHBOARD_EAS_BUILD_START_$STAMP.md"
mkdir -p docs/runtime-crash archives

{
  echo "# MauriMesh Safe Dashboard EAS Build Start"
  echo ""
  echo "Generated: $STAMP"
  echo ""
  echo "## Required markers"
  echo ""
  echo "### Dashboard"
  grep -n "Safe Dashboard\|MAURIMESH_SAFE_DASHBOARD_OPEN\|locked-proof-vault\|proof-vault-health\|learner-core\|store-forward-proof\|3-device-proof\|ble-2-hop-proof" app/dashboard.tsx || true
  echo ""
  echo "### Store-Forward vault save"
  grep -n "MAURIMESH_STORE_FORWARD_VAULT_SAVE_CALL_V1\|maurimesh_proof_store_forward" app/store-forward-proof.tsx || true
  echo ""
  echo "### Proof Vault Health"
  grep -n "MAURIMESH_PROOF_VAULT_HEALTH\|Proof Vault Health" app/proof-vault-health.tsx || true
  echo ""
  echo "## Truth"
  echo ""
  echo "This build should fix the Open Dashboard crash path by using Safe Dashboard v2."
  echo "Native BLE/GATT packet-bound PASS is not claimed."
} | tee "$REPORT"

echo ""
echo "============================================================"
echo "FINAL EXPORT CHECK BEFORE EAS"
echo "============================================================"
npx expo export --platform android --clear

echo ""
echo "============================================================"
echo "STARTING EAS BUILD"
echo "============================================================"

if command -v eas >/dev/null 2>&1; then
  eas build -p android --profile preview --clear-cache
else
  npx eas-cli build -p android --profile preview --clear-cache
fi
