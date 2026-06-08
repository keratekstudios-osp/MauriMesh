# Task #223 — Auto Promote Events to Proof Scope Once Real BLE Is Detected

Marker: `TASK_223_RUNTIME_TRUTH_ENGINE_AUTO_NATIVE_20260608_A`

## Installed

API:
- `RuntimeTruthEngine.markRealNative(features, attestation)`
- `RuntimeTruthEngine.acceptNativeAttestation(attestation)`
- `RuntimeTruthEngine.isProofCapable()`
- `/api/runtime/verify`
- `/api/runtime/truth`

Mobile:
- `nativeRuntimeAttestationClient.ts`
- `NativeBridgeContext.tsx`
- Connectivity boot attestation patch when `ConnectivityContext.tsx` exists

Root app:
- `src/maurimesh/runtime/nativeRuntimeAttestationClient.ts`

## Proof rule

The runtime becomes proof-capable only when:

- platform is `android`
- source is not `simulation`
- native module is present
- feature list includes `native_bridge`

`ble_scan` is added only when the native scan is active or discovered count is greater than zero.

## Truth boundary

This does not prove advertise, connect, TX/RX, ACK, relay, or store-forward.

It only unlocks proof-scope posting for features supported by real native attestation.

Simulation events must remain labelled as simulation.
