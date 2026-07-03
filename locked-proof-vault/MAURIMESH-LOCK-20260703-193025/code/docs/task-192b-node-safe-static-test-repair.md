# Task #192B — Node-Safe Static Test Repair

Marker: `TASK_192_NATIVE_PROOF_EVENT_BRIDGE_20260608_A`

## Fixed

The previous static test imported `nativeProofEventBridge.ts`, which imports `react-native`.
Plain Node/tsx cannot transform React Native's package entry in this environment.

Repair:
- Added `nativeProofEventBridgeConstants.ts`
- Native bridge imports constants from that file
- Static test imports only the constants file and API config helper
- Expo/Android bridge remains intact

## Truth boundary

This fixes Replit/Node validation only.
Native proof events still require a new APK build and physical two-phone RX/ACK test.
