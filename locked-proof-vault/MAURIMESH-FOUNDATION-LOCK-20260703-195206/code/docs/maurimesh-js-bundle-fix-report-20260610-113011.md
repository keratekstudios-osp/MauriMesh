# MauriMesh JS Bundle Duplicate Import Fix

Generated: 20260610-113011

## Import Header
import {
  MauriMeshFullTestReport,
  MauriMeshTestStep,
  ThreeHopBleProofPlan,
  OneRealDeviceApkProofPlan,
} from "./MauriMeshTestTypes";

export const REQUIRED_ROUTES = [
  "/login",
  "/dashboard",
  "/chat",
  "/settings",
  "/add-friend",
  "/living-mesh",
  "/mesh-status",
  "/pixel-calling",

## Duplicate Count
- OneRealDeviceApkProofPlan line count: 2
- [x] TypeScript passed
# MauriMesh Test Layer Report

Generated: 20260610-113012

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
- [x] PASS/WARN/FAIL result exists
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
- Complete: 37
- Warnings: 0
- Missing/failed: 0
- Score: 100%
- Status: **COMPLETE**

## Final Truth

This test layer provides one-button in-app process testing for MauriMesh.
It validates known UI, route, messaging, ACK, 3-hop BLE proof requirements,
Pixel Calling fallback, AI pixel reconstruction truth labels, and APK proof gates.

It does not fake real BLE pass. Real 3-hop BLE pass requires physical phones and APK/logcat evidence.

============================================================
MAURIMESH TEST LAYER CHECK COMPLETE
Status: COMPLETE
Score:  100%
Report: /home/runner/workspace/docs/maurimesh-test-layer-report-latest.md
============================================================
- [x] Test layer checker passed
[33m[1mWarning: [22mRoot-level [1m"expo"[22m object found. Ignoring extra keys in Expo config: "owner", "extra"
[90mLearn more: https://expo.fyi/root-expo-object[0m[0m
Starting Metro Bundler
Android node_modules/.pnpm/expo-router@6.0.24_@expo+metro-runtime@6.1.2_@types+react-dom@19.2.3_@types+react@19.1.17__@t_fngvj2q4gqenhcjlgrxxtoujku/node_modules/expo-router/entry.js ░░░░░░░░░░░░░░░░  0.0% (0/1)
Android node_modules/.pnpm/expo-router@6.0.24_@expo+metro-runtime@6.1.2_@types+react-dom@19.2.3_@types+react@19.1.17__@t_fngvj2q4gqenhcjlgrxxtoujku/node_modules/expo-router/entry.js ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░ 99.9% (1119/1119)
Android Bundled 4640ms node_modules/.pnpm/expo-router@6.0.24_@expo+metro-runtime@6.1.2_@types+react-dom@19.2.3_@types+react@19.1.17__@t_fngvj2q4gqenhcjlgrxxtoujku/node_modules/expo-router/entry.js (1119 modules)

› Assets (24):
node_modules/.pnpm/@react-navigation+elements@2.9.19_@react-navigation+native@7.2.5_react-native@0.81.5_@babel+c_o5xhxhhziuspmnzkys54devyi4/node_modules/@react-navigation/elements/lib/module/assets/back-icon-mask.png (653 B)
node_modules/.pnpm/@react-navigation+elements@2.9.19_@react-navigation+native@7.2.5_react-native@0.81.5_@babel+c_o5xhxhhziuspmnzkys54devyi4/node_modules/@react-navigation/elements/lib/module/assets/back-icon.png (4 variations | 152 B)
node_modules/.pnpm/@react-navigation+elements@2.9.19_@react-navigation+native@7.2.5_react-native@0.81.5_@babel+c_o5xhxhhziuspmnzkys54devyi4/node_modules/@react-navigation/elements/lib/module/assets/clear-icon.png (4 variations | 425 B)
node_modules/.pnpm/@react-navigation+elements@2.9.19_@react-navigation+native@7.2.5_react-native@0.81.5_@babel+c_o5xhxhhziuspmnzkys54devyi4/node_modules/@react-navigation/elements/lib/module/assets/close-icon.png (4 variations | 235 B)
node_modules/.pnpm/@react-navigation+elements@2.9.19_@react-navigation+native@7.2.5_react-native@0.81.5_@babel+c_o5xhxhhziuspmnzkys54devyi4/node_modules/@react-navigation/elements/lib/module/assets/search-icon.png (4 variations | 599 B)
node_modules/.pnpm/expo-router@6.0.24_@expo+metro-runtime@6.1.2_@types+react-dom@19.2.3_@types+react@19.1.17__@t_fngvj2q4gqenhcjlgrxxtoujku/node_modules/expo-router/assets/arrow_down.png (9.46 kB)
node_modules/.pnpm/expo-router@6.0.24_@expo+metro-runtime@6.1.2_@types+react-dom@19.2.3_@types+react@19.1.17__@t_fngvj2q4gqenhcjlgrxxtoujku/node_modules/expo-router/assets/error.png (469 B)
node_modules/.pnpm/expo-router@6.0.24_@expo+metro-runtime@6.1.2_@types+react-dom@19.2.3_@types+react@19.1.17__@t_fngvj2q4gqenhcjlgrxxtoujku/node_modules/expo-router/assets/file.png (138 B)
node_modules/.pnpm/expo-router@6.0.24_@expo+metro-runtime@6.1.2_@types+react-dom@19.2.3_@types+react@19.1.17__@t_fngvj2q4gqenhcjlgrxxtoujku/node_modules/expo-router/assets/forward.png (188 B)
node_modules/.pnpm/expo-router@6.0.24_@expo+metro-runtime@6.1.2_@types+react-dom@19.2.3_@types+react@19.1.17__@t_fngvj2q4gqenhcjlgrxxtoujku/node_modules/expo-router/assets/pkg.png (364 B)
node_modules/.pnpm/expo-router@6.0.24_@expo+metro-runtime@6.1.2_@types+react-dom@19.2.3_@types+react@19.1.17__@t_fngvj2q4gqenhcjlgrxxtoujku/node_modules/expo-router/assets/sitemap.png (465 B)
node_modules/.pnpm/expo-router@6.0.24_@expo+metro-runtime@6.1.2_@types+react-dom@19.2.3_@types+react@19.1.17__@t_fngvj2q4gqenhcjlgrxxtoujku/node_modules/expo-router/assets/unmatched.png (4.75 kB)

› android bundles (1):
_expo/static/js/android/entry-3fcc6ea6aa1af0f07e0a493c1d56cda0.hbc (2.97 MB)

› Files (1):
metadata.json (1.79 kB)

Exported: /home/runner/workspace/.maurimesh-export-after-js-fix-20260610-113011
- [x] Expo Android JS bundle export passed

## Status
READY_FOR_EAS_BUILD
