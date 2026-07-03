# MauriMesh Packet Format — v1

**Protocol Version:** 1 (integer literal)  
**Source of truth:** `lib/packet-engine/src/schema.ts`  
**Runtime engine:** `lib/packet-engine/src/PacketEngine.ts`  
**Schema endpoint:** `GET /packet-schema` (public, no auth required)

---

## Overview

Every packet that traverses the MauriMesh network — over BLE GATT, WiFi-LAN,
WebRTC, or store-forward — MUST conform to this schema.  The same schema is
validated at two independent layers:

1. **Rust JNI engine** (`artifacts/mesh-daemon/src/jni_bridge.rs`) — validates
   on the Android device before any BLE transmission.
2. **TypeScript PacketEngine** (`lib/packet-engine`) — validates at the API
   server and in mobile app logic before accepting or constructing a packet.

Import from the shared lib:
```typescript
import { PacketEngine, type CanonicalMeshPacket, type PacketType } from "@workspace/packet-engine";
```

---

## Field Reference

| Field | Type | Required | Description |
|---|---|---|---|
| `protocolVersion` | `1` (literal integer) | ✅ | Protocol schema version. Currently `1`. |
| `packetId` | UUID v4 string | ✅ | Unique per packet; used for deduplication and ACK correlation. |
| `packetType` | enum (see below) | ✅ | One of the 10 defined packet types. |
| `fromPeerId` | string (min 1) | ✅ | Node ID of the originating peer. |
| `toPeerId` | string (min 1) | ✅ | Node ID of the destination, or `"BROADCAST"` for flood. |
| `routeId` | string | optional | Route identifier assigned by the routing engine. |
| `ttl` | integer 0–255 | ✅ | Time-to-live. Decremented at each relay hop. Dropped at 0. |
| `hopIndex` | integer ≥ 0 | ✅ | Hops taken so far. Incremented at each relay. |
| `createdAt` | integer (Unix ms) | ✅ | Timestamp when the packet was first constructed. |
| `expiresAt` | integer (Unix ms) | ✅ | Timestamp after which the packet MUST be dropped regardless of TTL. |
| `payloadType` | enum (see below) | ✅ | Encoding hint for the `payload` field. |
| `payload` | string | ✅ | Packet body. Interpretation depends on `payloadType` and `packetType`. |
| `payloadHash` | 64-char hex string | ✅ | SHA-256 of the raw `payload` string. Always computed by `PacketEngine.build()`. |
| `signature` | string \| null | ✅ | Ed25519 signature. `null` until the E2E encryption task populates it. |
| `ackRequired` | boolean | ✅ | If true, the destination MUST send an `ack` packet on delivery. |
| `previousHopId` | string | optional | Node ID of the peer that forwarded this packet to us. |
| `nextHopId` | string | optional | Node ID this packet will be forwarded to next. |

---

## Packet Types

| Type | `ackRequired` default | Description |
|---|---|---|
| `discovery` | false | Peer announces its presence and public identity on the mesh. |
| `message` | **true** | User-originated chat or data payload. |
| `ack` | false | Delivery acknowledgement. Payload JSON: `{ "ackFor": "<packetId>" }`. |
| `route_probe` | false | ICMP-ping-style test. Receiver replies with `route_reply`. |
| `route_reply` | false | Response to a `route_probe`. Carries RTT and hop metadata. |
| `trust_event` | false | Trust record update: ban, vouch, decay, or verify. |
| `mesh_notification` | false | System-level alert: battery critical, congestion, OTA available. |
| `audio_frame` | false | Real-time audio chunk. `payloadType` = `audio_opus`. |
| `governance_event` | false | Route decision logged by RouteSafetyEngine. |
| `proof_event` | **true** | Two-phone BLE proof packet (see `TWO_PHONE_PROOF_PROTOCOL.md`). |

---

## Payload Types

| Type | Description |
|---|---|
| `text` | UTF-8 plaintext. |
| `binary` | Base64-encoded binary blob. |
| `json` | JSON-serialised object. Must be valid JSON. |
| `audio_opus` | Base64-encoded Opus audio frame. |
| `empty` | No meaningful payload (pure control packets). |

---

## TTL & Expiry Rules

- **Default TTL:** 7 hops. `proof_event` and `ack` use 3 hops.
- **Default TTL seconds:** 86 400 (24 h). `ack` and `proof_event` use 300 s (5 min).
- A relay MUST call `PacketEngine.decrement()` before forwarding.
- A node MUST call `PacketEngine.shouldDrop()` before forwarding or delivering.
  Drop if: `ttl === 0` OR `Date.now() >= expiresAt`.
- The Rust engine enforces TTL and dedup independently of TypeScript.

---

## Deduplication

Packets are identified by `packetId` (UUID v4). Engines MUST maintain a short
sliding window (≤ 500 entries, 60 s) of recently-seen `packetId` values and
silently discard duplicates.

---

## JSON Examples for All 10 Packet Types

All examples use `"payloadHash": "<sha256-hex>"` as a placeholder for the
64-character SHA-256 hex digest computed by `PacketEngine.build()`.

### 1. `discovery`

Peer announces itself to the mesh. Flooded to all nodes.

```json
{
  "protocolVersion": 1,
  "packetId": "c3d4e5f6-a7b8-4c9d-0e1f-2a3b4c5d6e7f",
  "packetType": "discovery",
  "fromPeerId": "node-charlie-003",
  "toPeerId": "BROADCAST",
  "ttl": 5,
  "hopIndex": 0,
  "createdAt": 1717300002000,
  "expiresAt": 1717300062000,
  "payloadType": "json",
  "payload": "{\"displayName\":\"Charlie\",\"publicKey\":\"ed25519-pub-abc123\"}",
  "payloadHash": "a3f2c1d4e5b6a7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2",
  "signature": null,
  "ackRequired": false
}
```

### 2. `message`

User chat or data payload. Requires ACK from the destination.

```json
{
  "protocolVersion": 1,
  "packetId": "a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d",
  "packetType": "message",
  "fromPeerId": "node-alice-001",
  "toPeerId": "node-bob-002",
  "ttl": 7,
  "hopIndex": 0,
  "createdAt": 1717300000000,
  "expiresAt": 1717386400000,
  "payloadType": "text",
  "payload": "Hello from the mesh!",
  "payloadHash": "b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2",
  "signature": null,
  "ackRequired": true
}
```

### 3. `ack`

Delivery acknowledgement. `payload` is JSON `{ "ackFor": "<original-packetId>" }`.

```json
{
  "protocolVersion": 1,
  "packetId": "b2c3d4e5-f6a7-4b8c-9d0e-1f2a3b4c5d6e",
  "packetType": "ack",
  "fromPeerId": "node-bob-002",
  "toPeerId": "node-alice-001",
  "ttl": 3,
  "hopIndex": 0,
  "createdAt": 1717300001000,
  "expiresAt": 1717300301000,
  "payloadType": "json",
  "payload": "{\"ackFor\":\"a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d\"}",
  "payloadHash": "c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3",
  "signature": null,
  "ackRequired": false
}
```

### 4. `route_probe`

ICMP-ping-style hop test. Receiver replies with `route_reply`.

```json
{
  "protocolVersion": 1,
  "packetId": "e5f6a7b8-c9d0-4e1f-2a3b-4c5d6e7f8a9b",
  "packetType": "route_probe",
  "fromPeerId": "node-alice-001",
  "toPeerId": "node-charlie-003",
  "routeId": "probe-alice-charlie-17173",
  "ttl": 5,
  "hopIndex": 0,
  "createdAt": 1717300010000,
  "expiresAt": 1717300070000,
  "payloadType": "json",
  "payload": "{\"probeSeq\":1,\"sentAt\":1717300010000}",
  "payloadHash": "d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4",
  "signature": null,
  "ackRequired": false
}
```

### 5. `route_reply`

Response to a `route_probe`. Carries RTT data back to the probe originator.

```json
{
  "protocolVersion": 1,
  "packetId": "f6a7b8c9-d0e1-4f2a-3b4c-5d6e7f8a9b0c",
  "packetType": "route_reply",
  "fromPeerId": "node-charlie-003",
  "toPeerId": "node-alice-001",
  "routeId": "probe-alice-charlie-17173",
  "ttl": 5,
  "hopIndex": 1,
  "createdAt": 1717300010050,
  "expiresAt": 1717300070050,
  "payloadType": "json",
  "payload": "{\"probeSeq\":1,\"origSentAt\":1717300010000,\"replyAt\":1717300010050,\"hopCount\":1}",
  "payloadHash": "e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5",
  "signature": null,
  "ackRequired": false,
  "previousHopId": "node-charlie-003"
}
```

### 6. `trust_event`

Trust record update emitted by TrustEngine. No ACK required.

```json
{
  "protocolVersion": 1,
  "packetId": "a7b8c9d0-e1f2-4a3b-4c5d-6e7f8a9b0c1d",
  "packetType": "trust_event",
  "fromPeerId": "node-alice-001",
  "toPeerId": "BROADCAST",
  "ttl": 4,
  "hopIndex": 0,
  "createdAt": 1717300020000,
  "expiresAt": 1717386420000,
  "payloadType": "json",
  "payload": "{\"action\":\"vouch\",\"targetPeerId\":\"node-charlie-003\",\"score\":0.85,\"reason\":\"successful_delivery\"}",
  "payloadHash": "f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6",
  "signature": null,
  "ackRequired": false
}
```

### 7. `mesh_notification`

System-level alert. Examples: low battery, BLE congestion, OTA update available.

```json
{
  "protocolVersion": 1,
  "packetId": "b8c9d0e1-f2a3-4b4c-5d6e-7f8a9b0c1d2e",
  "packetType": "mesh_notification",
  "fromPeerId": "node-dave-004",
  "toPeerId": "BROADCAST",
  "ttl": 3,
  "hopIndex": 0,
  "createdAt": 1717300030000,
  "expiresAt": 1717300390000,
  "payloadType": "json",
  "payload": "{\"notificationType\":\"battery_critical\",\"batteryPct\":8,\"willDisconnectInMs\":60000}",
  "payloadHash": "a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7",
  "signature": null,
  "ackRequired": false
}
```

### 8. `audio_frame`

Real-time audio chunk. `payloadType` must be `audio_opus`. Payload is base64 Opus.

```json
{
  "protocolVersion": 1,
  "packetId": "c9d0e1f2-a3b4-4c5d-6e7f-8a9b0c1d2e3f",
  "packetType": "audio_frame",
  "fromPeerId": "node-alice-001",
  "toPeerId": "node-bob-002",
  "ttl": 3,
  "hopIndex": 0,
  "createdAt": 1717300040000,
  "expiresAt": 1717300040080,
  "payloadType": "audio_opus",
  "payload": "T2dnUwACAAAAAAAA...",
  "payloadHash": "b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8",
  "signature": null,
  "ackRequired": false
}
```

### 9. `governance_event`

Route decision record emitted by RouteSafetyEngine. Logged to proof ledger.

```json
{
  "protocolVersion": 1,
  "packetId": "d0e1f2a3-b4c5-4d6e-7f8a-9b0c1d2e3f4a",
  "packetType": "governance_event",
  "fromPeerId": "node-alice-001",
  "toPeerId": "BROADCAST",
  "routeId": "alice-charlie-bob",
  "ttl": 2,
  "hopIndex": 0,
  "createdAt": 1717300050000,
  "expiresAt": 1717386450000,
  "payloadType": "json",
  "payload": "{\"decision\":\"route_blocked\",\"targetPeerId\":\"node-eve-099\",\"reason\":\"trust_score_below_threshold\",\"threshold\":0.3,\"actual\":0.12}",
  "payloadHash": "c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9",
  "signature": null,
  "ackRequired": false
}
```

### 10. `proof_event`

Two-phone BLE proof packet. Requires ACK. Recorded in the Proof Ledger.

```json
{
  "protocolVersion": 1,
  "packetId": "d4e5f6a7-b8c9-4d0e-1f2a-3b4c5d6e7f8a",
  "packetType": "proof_event",
  "fromPeerId": "phone-sender-001",
  "toPeerId": "phone-receiver-002",
  "routeId": "phone-sender-001\u2192phone-receiver-002",
  "ttl": 3,
  "hopIndex": 0,
  "createdAt": 1717300003000,
  "expiresAt": 1717300303000,
  "payloadType": "text",
  "payload": "BLE-PROOF-PING",
  "payloadHash": "d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0",
  "signature": null,
  "ackRequired": true
}
```

---

## PacketEngine API

```typescript
import { PacketEngine, sha256Hex } from "@workspace/packet-engine";

// Build a message packet (payloadHash is computed automatically)
const pkt = PacketEngine.build({
  packetType: "message",
  fromPeerId: "node-alice",
  toPeerId:   "node-bob",
  payload:    "Hello mesh!",
});
// pkt.payloadHash === sha256Hex("Hello mesh!")
// pkt.signature   === null

// Validate a raw object (e.g. from BLE or API body)
const result = PacketEngine.validate(rawObject);
if (result.ok) console.log(result.packet);

// Parse a JSON string from BLE characteristic write
const parsed = PacketEngine.parse(bleJsonString);

// Check before relay
if (PacketEngine.shouldDrop(pkt)) return;

// Relay: decrement TTL, record relay node, update hop metadata.
// Second arg is the ID of THIS node (the one doing the relaying), NOT the next hop.
// It is recorded as previousHopId so downstream nodes know who last forwarded.
const relayed = PacketEngine.decrement(pkt, myNodeId, nextHopNodeId);

// Build an ACK in response to a received message
const ack = PacketEngine.makeAck(pkt, myNodeId);

// Announce this node to the mesh
const discovery = PacketEngine.makeDiscovery({ fromPeerId: myNodeId, displayName: "Alice" });

// Compute SHA-256 manually (cross-platform, no Node.js crypto dependency)
const hash = sha256Hex("any string");
```

---

## Store-Forward Behaviour

If no route exists at time of send:
1. Packet is serialised to `store_forward_queue` (PostgreSQL).
2. Queue is polled on BLE peer discovery (`reportPeerSeen`).
3. The Rust engine flushes queued packets per peer when they come online.
4. After delivery, the packet is removed via `ackPacket(packetId)`.

---

## Versioning

When the packet schema changes:
1. Increment `PROTOCOL_VERSION` in `lib/packet-engine/src/schema.ts`.
2. Update the Rust `MeshPacket` struct in `artifacts/mesh-daemon/src/lib.rs`.
3. Update this document (all 10 JSON examples must remain valid).
4. The `GET /packet-schema` endpoint automatically reflects the new version.
