# MauriMesh Rust Engine Architecture

## Overview

The `mesh-daemon` Cargo package compiles into **two targets**:

| Target | Feature flag | Output | Purpose |
|--------|-------------|--------|---------|
| `mesh-daemon` binary | `linux-daemon` | ELF executable | Linux BLE mesh daemon (BlueZ + axum) |
| `libmaurimesh_engine.so` | `android-jni` | Android NDK shared lib | JNI routing engine for Android |

The two targets share the **core logic** (`router`, `types` modules) but differ in their BLE and I/O layers. On Linux, `bluer` drives the BLE peripheral role and `axum` exposes the HTTP bridge. On Android, the Kotlin layer owns all BLE operations, and Rust owns routing, packet serialisation, deduplication, store-forward, and crypto.

---

## Crate Structure

```
artifacts/mesh-daemon/
├── Cargo.toml             # Package manifest with [lib] + [[bin]] + features
├── build-android.sh       # NDK build script (cargo-ndk)
└── src/
    ├── lib.rs             # Library crate root — declares all modules
    ├── main.rs            # Binary entry point (linux-daemon feature)
    ├── types.rs           # Shared types: MeshNode, MeshMessage, OutboundMessage
    ├── router.rs          # Shared: MeshState — peer upsert, message delivery, dedup
    ├── ble.rs             # Linux only: btleplug central role (scan + tx_loop)
    ├── peripheral.rs      # Linux only: bluer GATT server + BLE advertisement
    ├── bridge.rs          # Linux only: axum HTTP bridge (127.0.0.1:4300)
    └── jni_bridge.rs      # Android JNI only: 10 JNI functions + engine state
```

### Feature flags

```toml
linux-daemon = [bluer, axum, axum-extra, tower, tower-http, btleplug, futures]
android-jni  = [jni, sha2, hex]
```

---

## JNI Surface Contract

All JNI functions are in `src/jni_bridge.rs`. They map to Kotlin `external fun` declarations in `MauriMeshEngine.kt` (object `com.maurimesh.ble.MauriMeshEngine`).

The `.so` is loaded by Kotlin with `System.loadLibrary("maurimesh_engine")`. When the `.so` is absent (Expo Go, debug builds without an NDK output), `MauriMeshEngine.isAvailable` returns `false` and all calls are silent no-ops, keeping the app functional in Kotlin-only mode.

### Function table

| Kotlin external | Rust JNI symbol | Description |
|----------------|-----------------|-------------|
| `nativeInitEngine(nodeId, publicKey)` | `Java_com_maurimesh_ble_MauriMeshEngine_nativeInitEngine` | Set node identity; must be called before any other method |
| `nativeReceivePacket(packetJson)` | `Java_..._nativeReceivePacket` | Process inbound BLE packet; returns action descriptor JSON |
| `nativeBuildPacket(dst, payload)` | `Java_..._nativeBuildPacket` | Build & sign a canonical MeshPacket JSON for BLE transmission |
| `nativeGetPendingPackets(nodeId)` | `Java_..._nativeGetPendingPackets` | Flush store-forward queue for a now-reachable peer |
| `nativeAckPacket(packetId)` | `Java_..._nativeAckPacket` | Mark packet delivered; remove from store-forward queue |
| `nativeReportPeerSeen(peerJson)` | `Java_..._nativeReportPeerSeen` | Update routing table with a peer discovered by BLE scan |
| `nativeGetPeers()` | `Java_..._nativeGetPeers` | Return JSON array of known peers |
| `nativeGetRoutes()` | `Java_..._nativeGetRoutes` | Return routing table as JSON array |
| `nativeGetEngineStatus()` | `Java_..._nativeGetEngineStatus` | Return per-subsystem status JSON |
| `nativeHashPayload(payload)` | `Java_..._nativeHashPayload` | SHA-256 hex digest of input |

### Canonical MeshPacket format

```json
{
  "id":        "550e8400-e29b-41d4-a716-446655440000",
  "src":       "node-alice",
  "dst":       "node-bob",
  "payload":   "Hello, mesh!",
  "timestamp": 1717200000000,
  "ttl":       7,
  "hop_count": 0,
  "signature": "a3f5c9..."
}
```

`signature` = `SHA-256(id || src || dst || payload)` as a hex string. Built and signed by `nativeBuildPacket`. Kotlin transmits the JSON bytes verbatim over the GATT characteristic.

### `nativeReceivePacket` action descriptor

```json
{ "action": "delivered" }
{ "action": "relay", "dst": "node-id" }
{ "action": "broadcast", "packet": { ...updatedPacket } }
{ "action": "queued" }
{ "action": "duplicate" }
{ "action": "expired" }
{ "action": "error", "msg": "..." }
```

### `nativeGetEngineStatus` response

```json
{
  "initialized": true,
  "engine_mode": "jni_native",
  "node_id":     "node-alice",
  "peer_count":  3,
  "queue_depth": 1,
  "inbox_depth": 42,
  "seen_ids":    156,
  "subsystems": {
    "routing":       "real_native",
    "packet_engine": "real_native",
    "store_forward": "real_native",
    "crypto":        "real_native",
    "ble_scan":      "kotlin_native",
    "ble_advertise": "kotlin_native",
    "gatt_server":   "kotlin_native"
  }
}
```

---

## Kotlin Bridge Pattern

```
JS (React Native)
    ↕  NativeModule bridge
MauriMeshBleModule.kt          — @ReactMethod entry points
    ↕  MauriMeshEngine.isAvailable guard
MauriMeshEngine.kt             — object with external fun declarations
    ↕  JNI  (System.loadLibrary)
libmaurimesh_engine.so         — Rust routing engine
    (routing, dedup, store-forward, crypto)
    ↕  return JSON
MauriMeshBleModule.kt          — interprets action, calls Kotlin BLE
MeshCentralClient.kt           — BLE GATT write to peer
MeshGattServerManager.kt       — GATT write receive → receivePacketFromGatt()
```

### Key integration points

1. **startPeripheral** — starts GATT server + advertiser, then calls `initRustEngine()` to load identity and initialise the Rust engine.

2. **sendPacketViaEngine(dst, payload, promise)** — calls `MauriMeshEngine.buildPacket(dst, payload)` to get a signed canonical packet, then transmits via `MeshCentralClient.sendRawPacket(dst, bytes)`.

3. **receivePacketFromGatt(json, promise)** — calls `MauriMeshEngine.receivePacket(json)`, interprets the action descriptor, and:
   - `delivered` → emits `MauriMeshBleMessageReceived` to JS
   - `relay` → forwards via `MeshCentralClient.sendRawPacket(dst, bytes)`
   - `broadcast` → emits to JS + floods via `MeshCentralClient.broadcastRawPacket(bytes)`
   - `queued` / `duplicate` / `expired` → silent discard

4. **reportPeerSeen(peerJson, promise)** — called by `MeshCentralClient` on scan result. Updates Rust routing table and flushes any queued store-forward packets for the newly-seen peer.

5. **MeshForegroundService.startMesh()** — calls `MauriMeshEngine.initEngine(nodeId, pubKey)` loaded from SharedPreferences after starting BLE subsystems.

### Adding new JNI functions

1. Add `external fun newMethod(...)` to `MauriMeshEngine.kt`
2. Add `private external fun nativeNewMethod(...)` (or rename pattern) for the JNI declaration
3. Add `#[no_mangle] pub extern "C" fn Java_com_maurimesh_ble_MauriMeshEngine_nativeNewMethod<'local>(...)` to `src/jni_bridge.rs`
4. Rebuild with `./build-android.sh --copy <expo_dir>`

---

## Android NDK Build

### Prerequisites

```bash
# Install cargo-ndk
cargo install cargo-ndk

# Add Android targets
rustup target add aarch64-linux-android armv7-linux-androideabi

# Set NDK path
export ANDROID_NDK_HOME=$HOME/Library/Android/sdk/ndk/<version>
```

### Build

```bash
cd artifacts/mesh-daemon

# Build both ABIs and copy to Expo Android project
./build-android.sh --copy ../messenger-mobile

# Build arm64 only (faster iteration)
./build-android.sh --abi arm64 --copy ../messenger-mobile
```

Output `.so` locations:
```
target/aarch64-linux-android/release/libmaurimesh_engine.so
target/armv7-linux-androideabi/release/libmaurimesh_engine.so
```

Copied to:
```
artifacts/messenger-mobile/android/app/src/main/jniLibs/arm64-v8a/libmaurimesh_engine.so
artifacts/messenger-mobile/android/app/src/main/jniLibs/armeabi-v7a/libmaurimesh_engine.so
```

After copying, rebuild the Expo Android app:
```bash
eas build --platform android
# or for local builds:
./build-apk.sh
```

---

## Linux Daemon Mode

The Linux daemon remains unchanged from the pre-unification codebase. Build and run:

```bash
cd artifacts/mesh-daemon
cargo build --features linux-daemon --release
MESH_NODE_ID=my-laptop ./target/release/mesh-daemon
```

The HTTP bridge at `127.0.0.1:4300` remains available for web and desktop preview:

| Route | Method | Description |
|-------|--------|-------------|
| `/healthz` | GET | Liveness probe |
| `/mesh/nodes` | GET | All known nodes + inboxes |
| `/messenger/send` | POST | Send a message; enqueues for BLE TX |

---

## BLE Service UUIDs

The canonical UUIDs are defined in `src/ble.rs` and should be used by all components:

| UUID | Purpose |
|------|---------|
| `4d617572-694d-6573-6800-000000000001` | MauriMesh Service |
| `4d617572-694d-6573-6800-000000000002` | MauriMesh Message Characteristic |

> Note: `MeshBleUuids.kt` currently uses different UUIDs (`7f9a0001-...`). Unifying to the Rust canonical UUIDs is a follow-up task.

---

## Store-Forward Queue

Packets destined for offline peers are queued in the Rust engine with a 24-hour expiry. When `reportPeerSeen` is called (peer comes online), `MauriMeshBleModule` calls `getPendingPackets(nodeId)` and flushes the queued batch via BLE.

Queue entries are cleared by:
- `ackPacket(packetId)` — explicit delivery confirmation
- Expiry (24 h TTL enforced on every `getPendingPackets` call)
- `receivePacket` — adds incoming packet IDs to the seen-set automatically

---

## Crypto

All cryptographic operations live in Rust:
- **Packet signing**: `SHA-256(id || src || dst || payload)` → hex string in `signature` field
- **Payload hashing**: `nativeHashPayload(s)` returns `SHA-256(s)` for comparing content without revealing it

Full asymmetric E2E encryption (identity key pairs, ECDH session keys, AES-GCM payload encryption) is defined in Task #5 and will extend the JNI surface with additional crypto functions.
