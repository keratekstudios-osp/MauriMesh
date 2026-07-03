#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo "#192 Native Proof Event Bridge Audit"
echo "============================================================"

grep -RniE "TASK_192|MauriMeshRawPacketProofEvent|emitRawPacketProofEvent|startNativeProofEventBridge|EXPO_PUBLIC_MESH_API_URL|API Config" \
  android app src tests scripts docs 2>/dev/null || true

echo ""
echo "Required checks:"
grep -q "MauriMeshRawPacketProofEvent" android/app/src/main/java/com/maurimesh/messenger/MauriMeshBleModule.kt && echo "✅ Kotlin emits native proof event"
grep -q "emitRawPacketProofEvent" android/app/src/main/java/com/maurimesh/messenger/MauriMeshBleModule.kt && echo "✅ Kotlin event helper exists"
test -f src/maurimesh/live/nativeProofEventBridge.ts && echo "✅ JS native proof bridge exists"
test -f src/maurimesh/live/nativeProofEventBridgeConstants.ts && echo "✅ Node-safe bridge constants exist"
test -f src/maurimesh/config/apiConfig.ts && echo "✅ API config helper exists"
test -f app/api-config.tsx && echo "✅ API config screen exists"
grep -q "startNativeProofEventBridge" app/raw-packet-proof.tsx && echo "✅ raw packet proof starts bridge"
grep -q "API Config" app/dashboard.tsx && echo "✅ dashboard API Config link"
