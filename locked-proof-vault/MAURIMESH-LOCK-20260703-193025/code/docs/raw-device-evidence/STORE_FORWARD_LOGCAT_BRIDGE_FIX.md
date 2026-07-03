# MauriMesh Store-Forward Logcat Bridge Fix

Status: **PATCHED**

Patch points: **56**

## Changed Files

- `app/proof-2-hop.tsx`\n- `app/store-forward-proof.tsx`\n- `src/maurimesh/full-mesh-test/FullMeshTestEngine.ts`\n- `src/maurimesh/proof/lockedProofVault.ts`\n- `src/maurimesh/proofs/lockedProofRegistry.ts`

## Candidate Files

- `app/dashboard.tsx`\n- `app/hardware-runtime.tsx`\n- `app/hybrid-wifi-ble-mesh.tsx`\n- `app/integration-hub.tsx`\n- `app/locked-proof-vault.tsx`\n- `app/mesh/index.tsx`\n- `app/mesh/store-forward-queue.tsx`\n- `app/next-proof-exam.tsx`\n- `app/pixel-calling-backup.tsx`\n- `app/pixel-calling.tsx`\n- `app/proof-2-hop.tsx`\n- `app/proof-metrics.tsx`\n- `app/store-forward-proof.tsx`\n- `app/store-forward-queue.tsx`\n- `src/ai/mauriAiIntelligenceRuntime.ts`\n- `src/ai/mauriAiTypes.ts`\n- `src/ai/validateMauriAiIntelligenceRuntime.ts`\n- `src/components/AiPixelReconstructionPanel.tsx`\n- `src/components/BleHardwareRuntimePanel.tsx`\n- `src/components/HardwareRuntimeControllerPanel.tsx`\n- `src/components/HybridWifiBleMeshPanel.tsx`\n- `src/components/PixelCallingBackupFallbackPanel.tsx`\n- `src/governance/aiGovernanceIntelligence.ts`\n- `src/integration/mauriRuntimeIntegrationBridge.ts`\n- `src/lib/mauriSystemBrainClient.ts`\n- `src/lib/uiBackupRoutes.ts`\n- `src/mauricore/packet/packetEngine.ts`\n- `src/mauricore/routing/routingEngine.ts`\n- `src/mauricore/types/core.types.ts`\n- `src/maurimesh/audit/buttonAuditRegistry.ts`\n- `src/maurimesh/ble-runtime/BleHardwareBackupPolicy.ts`\n- `src/maurimesh/ble-runtime/BleHardwareRuntimeAdapter.ts`\n- `src/maurimesh/device-hardware/DeviceHardwareStabilizer.ts`\n- `src/maurimesh/device-hardware/HardwareRuntimeController.ts`\n- `src/maurimesh/device-hardware/HardwareRuntimePolicy.ts`\n- `src/maurimesh/device-hardware/types.ts`\n- `src/maurimesh/full-mesh-test/FullMeshTestEngine.ts`\n- `src/maurimesh/full-mesh-test/GeneratedRouteRegistry.ts`\n- `src/maurimesh/hybrid-wifi-ble-mesh/BackupHybridWifiBleMeshEngine.ts`\n- `src/maurimesh/hybrid-wifi-ble-mesh/HybridWifiBleMeshTypes.ts`\n- `src/maurimesh/integration/allIntegrationsBridge.ts`\n- `src/maurimesh/intelligence/RouteIntelligence.ts`\n- `src/maurimesh/invention-engine/livingSelfGovernedAiMesh.ts`\n- `src/maurimesh/invention-engine/mauriAiRoutingConscience.ts`\n- `src/maurimesh/invention-engine/types.ts`\n- `src/maurimesh/live/proofMetricsSpine.ts`\n- `src/maurimesh/message-fallback/MessageAckFallbackEngine.ts`\n- `src/maurimesh/message-fallback/MessageFallbackQueue.ts`\n- `src/maurimesh/message-fallback/MessageFallbackTypes.ts`\n- `src/maurimesh/pixel-calling/AiPixelReconstructionEngine.ts`\n- `src/maurimesh/pixel-calling/AiPixelReconstructionTypes.ts`\n- `src/maurimesh/pixel-calling/PixelCallingBackupFallback.ts`\n- `src/maurimesh/pixel-calling/PixelCallingBackupTypes.ts`\n- `src/maurimesh/pixel-calling/PixelCallingRuntime.ts`\n- `src/maurimesh/pixel-calling/PixelCallingTypes.ts`\n- `src/maurimesh/proof/ble3DeviceProof.ts`\n- `src/maurimesh/proof/lockedProofVault.ts`\n- `src/maurimesh/proof/storeForwardProof.ts`\n- `src/maurimesh/proofs/lockedProofRegistry.ts`\n- `src/maurimesh/system-brain/buttonDecisionRouter.ts`\n- `src/maurimesh/system-brain/layerRegistry.ts`\n- `src/maurimesh/test-layer/MauriMeshFullTestEngine.ts`\n- `src/mesh/bluetoothMeshSuperEngine.ts`\n- `src/mesh/validateBluetoothMeshSuperEngine.ts`\n- `src/operating/mauri155LayerCatalog.ts`\n- `src/operating/mauri155OperatingRuntime.ts`\n- `src/operating/mauriOperatingTypes.ts`\n- `src/routing/hybridAiRoutingLogic.ts`\n- `src/routing/mauriAiRoutingIntelligence.ts`\n- `src/routing/storeForwardIntelligence.ts`

## Why This Was Needed

The Mac raw-device capture successfully connected A06, S10, and A16, but the verifier could not find packet ID `MMSF-RAW-LIVE-001` in Android logcat.

That means the Store-Forward proof existed in the app UI, but was not being emitted into Android logcat.

This patch adds a logcat bridge so Store-Forward proof stages are emitted through console log/warn/error.

## Required Next Step

Rebuild the APK and reinstall on:

- A06
- S10
- A16

Then rerun the Mac capture:

```bash
cd ~/maurimesh-raw-evidence
adb connect 192.168.1.7:5555
adb connect 192.168.1.10:5555
adb connect 192.168.1.4:5555
A06_SERIAL=192.168.1.7:5555 S10_SERIAL=192.168.1.10:5555 A16_SERIAL=192.168.1.4:5555 ./capture-maurimesh-raw-evidence.sh MMSF-RAW-LIVE-001 180
```
