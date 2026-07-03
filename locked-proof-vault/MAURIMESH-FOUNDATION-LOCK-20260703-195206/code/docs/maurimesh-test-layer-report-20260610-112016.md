# MauriMesh Test Layer Report

Generated: 20260610-112016

## Files
- [x] Test types exists: src/maurimesh/test-layer/MauriMeshTestTypes.ts
- [x] Test engine exists: src/maurimesh/test-layer/MauriMeshFullTestEngine.ts
- [x] Test index exists: src/maurimesh/test-layer/index.ts
- [x] Test panel exists: src/components/MauriMeshTestLayerPanel.tsx
- [x] Test route exists: app/test-layer.tsx

## One Button Test Capability
- [x] One-button run function exists
- [x] Messaging beginning-to-end test exists
- [x] 3-hop BLE proof plan exists
- [x] Phone A sender required
- [x] Phone B relay required
- [x] Phone C receiver required
- [x] Strict ACK required
- [x] Relay ACK required
- [x] Proof ledger hash required
- [x] Raw 32K false truth included
- [x] Native Android proof required
- [x] One real device APK proof plan exists
- [x] One real device APK test function exists
- [x] APK install required
- [x] No fatal exception required
- [x] All routes load on APK
- [x] Multi-device BLE proof still required

## UI Wiring
- [x] Route screen uses test panel
- [x] Dashboard has /test-layer marker
- [x] Backup registry has /test-layer marker
- [x] Button label exists
- [ ] MISSING: PASS/WARN/FAIL result exists
- [x] One real device test button exists
- [x] One real device instructions visible

## Existing Important Integration Markers
- [x] Message fallback engine exists: src/maurimesh/message-fallback/MessageAckFallbackEngine.ts
- [x] Hybrid Wi-Fi BLE engine exists: src/maurimesh/hybrid-wifi-ble-mesh/BackupHybridWifiBleMeshEngine.ts
- [x] BLE runtime adapter exists: src/maurimesh/ble-runtime/BleHardwareRuntimeAdapter.ts
- [x] Native telemetry bridge exists: src/maurimesh/device-hardware/NativeHardwareTelemetry.ts
- [x] Pixel calling backup exists: src/maurimesh/pixel-calling/PixelCallingBackupFallback.ts
- [x] AI pixel reconstruction exists: src/maurimesh/pixel-calling/AiPixelReconstructionEngine.ts
- [x] One real device APK script exists: maurimesh-one-real-device-apk-test.sh

## TypeScript
- [x] TypeScript passed

## Summary

- Total: 37
- Complete: 36
- Warnings: 0
- Missing/failed: 1
- Score: 97%
- Status: **FAILED**

## Final Truth

This test layer provides one-button in-app process testing for MauriMesh.
It validates known UI, route, messaging, ACK, 3-hop BLE proof requirements,
Pixel Calling fallback, AI pixel reconstruction truth labels, and APK proof gates.

It does not fake real BLE pass. Real 3-hop BLE pass requires physical phones and APK/logcat evidence.
