---
name: MauriMesh JNI bridge pattern
description: Rust engine owns routing/crypto/store-forward; Kotlin owns BLE radio. JNI delegation rules and GATT wiring.
---

## Architecture rule
- Rust (libmaurimesh_engine.so) owns: routing, packet build+sign, dedup, store-forward, crypto.
- Kotlin owns: BLE scan, BLE advertise, GATT server/client, Android lifecycle.
- JNI is the delegation boundary — Kotlin calls Rust for every logic decision; Rust never calls Android APIs.

## Scan/advertise delegation
- `MauriMeshEngine.startScan()` returns `{"service_uuid":"..."}` — parse and pass UUID to `centralClient.startScan(durationMs, uuid)` so Rust is the authoritative source for the BLE service UUID.
- `MauriMeshEngine.startAdvertise(nodeId, pubKey)` returns advertise config JSON; Kotlin asserts the returned UUID matches `MeshBleUuids.SERVICE_UUID` and emits `rust_advertise_uuid_mismatch:` on divergence.
- Always call `MauriMeshEngine.stopScan()` / `stopAdvertise()` before the Kotlin-side stop.

## GATT inbound path
- `MeshGattServerManager` calls `MauriMeshEngine.receivePacket(json)` then fires an `onPacket` callback to `MauriMeshBleModule.handleInboundPacket()`.
- When JNI unavailable (`!MauriMeshEngine.isAvailable`), bypass Rust and pass `{"action":"delivered"}` directly to the callback — preserves Kotlin-only fallback.
- `handleInboundPacket` dispatches: `delivered` → `emitMessageReceived`; `broadcast` → emit + `broadcastRawPacket(updatedPacket)`; `relay` → `sendRawPacket(dst, updatedPacket)` with TTL-decremented packet from Rust; `queued` → status; `duplicate`/`expired`/`error` → discard.

## GATT outbound (sendRawPacket)
- `MeshCentralClient.deviceCache` (Map<address, BluetoothDevice>) is populated in scanCallback.
- `sendRawPacket(nodeId, bytes)` looks up deviceCache by MAC address, then GATT connect → discoverServices → writeCharacteristic → close.
- `broadcastRawPacket(bytes)` iterates all cached devices.
- `WRITE_TYPE_NO_RESPONSE` for low-latency; use `@Suppress("DEPRECATION")` on `char.value = bytes`.

## RuntimeTruthEngine wiring
- `POST /truth/report-engine-status` is mounted **publicly** (before `requireAuth`) in `routes/index.ts` — the mobile APK carries no Bearer token.
- Payload-validated: max 20 keys, whitelist of subsystem names and mode values enforced server-side.
- `android-readiness.tsx` calls `NativeModules.MauriMeshBle.getEngineStatus()` (Promise) and reports actual JNI subsystems — never hardcodes `real_native`.
- Subsystem → feature: routing→relay, packet_engine→p2p_send, store_forward→store_forward, crypto→encryption, ble_scan→ble_scan, ble_advertise→ble_advertise; `native_bridge` promoted automatically when any is real_native.

**Why:** btleplug cannot drive Android BLE from NDK without Java bridges, so clean split is Rust=logic, Kotlin=hardware. This avoids duplicating routing/dedup/crypto in Kotlin.
