#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo "#223 Auto Proof Scope Audit"
echo "============================================================"

echo ""
echo "1. RuntimeTruthEngine methods"
grep -RniE "markRealNative|acceptNativeAttestation|isProofCapable|getRuntimeTruthState|TASK_223_RUNTIME_TRUTH" \
  artifacts/api-server/src/runtime 2>/dev/null || true

echo ""
echo "2. Runtime verify route"
grep -RniE "registerRuntimeVerifyRoute|/api/runtime/verify|/api/runtime/truth|TASK_223_RUNTIME_VERIFY" \
  artifacts/api-server/src/routes 2>/dev/null || true

echo ""
echo "3. Activity proof-scope guard"
grep -RniE "task223NormalizeActivityTruth|proofScopeBlocked|proofScopeAccepted|simulation_labelled|physical_proof" \
  artifacts/api-server/src/routes/activity.ts 2>/dev/null || true

echo ""
echo "4. Mobile attestation"
grep -RniE "sendNativeRuntimeAttestation|NativeBridgeProvider|TASK_223_NATIVE_ATTESTATION|TASK_223_CONNECTIVITY_NATIVE_ATTESTATION_BOOT" \
  artifacts/messenger-mobile src 2>/dev/null || true

echo ""
echo "5. Simulation protection search"
grep -RniE "truthLevel.*physical|physical_proof|simulation_labelled|proofScope" \
  artifacts/api-server/src artifacts/messenger-mobile src 2>/dev/null | head -250 || true

echo ""
echo "============================================================"
echo "#223 Audit complete"
echo "============================================================"
