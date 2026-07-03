# Task #223 — Auto Promote Events to Proof Scope Once Real BLE Is Detected

Marker: `TASK_223_RUNTIME_TRUTH_ENGINE_AUTO_NATIVE_20260608_A`

## Added

API:
- `RuntimeTruthEngine.markRealNative(features, attestation)`
- `RuntimeTruthEngine.acceptNativeAttestation(attestation)`
- `RuntimeTruthEngine.isProofCapable(feature?)`
- `GET /api/runtime/truth`
- `POST /api/runtime/verify`

Mobile:
- `nativeRuntimeAttestationClient.ts`
- `NativeBridgeContext.tsx`
- Connectivity boot attestation when `ConnectivityContext.tsx` exists

Root app:
- `src/maurimesh/runtime/nativeRuntimeAttestationClient.ts`

## Promotion rule

Runtime becomes proof-capable only when:

- platform is `android`
- source is not `simulation`
- native module is present
- features include `native_bridge`

`ble_scan` is accepted only when the native module reports scan active or discovered count greater than zero.

## Truth boundary

This does not prove advertise, connect, TX/RX, ACK, relay, or store-forward.

It only unlocks proof-scope posting for features supported by real native attestation.

Simulation events remain labelled as simulation.
