# MauriMesh Two-Phone Proof Protocol

## Purpose

The two-phone proof is the minimum evidence required to demonstrate that MauriMesh
can deliver packets between two real Android devices over BLE without internet.
It uses the canonical `proof_event` packet type from the MauriMesh packet format.

See `docs/MAURIMESH_PACKET_FORMAT.md` for the full packet schema.

---

## Roles

| Role    | Responsibility                                           |
|---------|----------------------------------------------------------|
| Phone A | Sender — initiates discovery, sends `proof_event` packet |
| Phone B | Receiver — advertises presence, confirms delivery + ACK  |
| Phone C | (Optional) Relay — demonstrates multi-hop routing        |

---

## Minimum Proof Requirements

1. Both phones have the MauriMesh APK installed.
2. Both phones have BLE + Location permissions granted.
3. Phone B calls `startPeripheral()` — starts GATT server and BLE advertising.
4. Phone A calls `startScan()` — discovers Phone B.
5. Phone A sends a `proof_event` packet to Phone B via `sendPacketViaEngine()`.
6. Phone B receives and logs the packet (GATT write callback fires).
7. Phone B sends a reverse `ack` packet to Phone A.
8. Phone A receives the ACK and emits `message_received` event.
9. A Proof Ledger record is created via `POST /proof-ledger/record`.
10. Test report is exported via `GET /reports/system-state`.

---

## Canonical Proof Packet (`proof_event`)

Built via `PacketEngine.build()`:

```typescript
import { PacketEngine } from "@workspace/packet-engine";

const proofPacket = PacketEngine.build({
  packetType:  "proof_event",
  fromPeerId:  "phone-a-node-id",
  toPeerId:    "phone-b-node-id",
  payload:     "BLE-PROOF-PING",
  payloadType: "text",
  ackRequired: true,
  ttl:         3,
  ttlSeconds:  300,
});
```

Wire format (JSON sent over BLE GATT characteristic):

```json
{
  "protocolVersion": 1,
  "packetId": "<uuid-v4>",
  "packetType": "proof_event",
  "fromPeerId": "phone-a-node-id",
  "toPeerId": "phone-b-node-id",
  "ttl": 3,
  "hopIndex": 0,
  "createdAt": 1717300000000,
  "expiresAt": 1717300300000,
  "payloadType": "text",
  "payload": "BLE-PROOF-PING",
  "payloadHash": "<sha256-of-payload>",
  "ackRequired": true
}
```

## Canonical ACK Packet

Built via `PacketEngine.makeAck()`:

```typescript
const ack = PacketEngine.makeAck(proofPacket, "phone-b-node-id");
// → packetType: "ack", payload: '{"ackFor":"<proof-packetId>"}'
```

---

## Session State Machine

```
idle → advertising (Phone B) | scanning (Phone A)
     → connected
     → sent       (Phone A sends proof_event)
     → acked      (Phone A receives ack)
     → failed     (timeout / BLE error)
```

API:
```bash
# Phone B: start as receiver
POST /proof/two-phone/start  { "phoneId": "phone-b", "role": "receiver" }

# Phone A: start as sender
POST /proof/two-phone/start  { "phoneId": "phone-a", "role": "sender", "targetPeer": "phone-b" }

# Phone A: send proof packet
POST /proof/two-phone/send   { "sessionId": "...", "toPeer": "phone-b", "payload": "BLE-PROOF-PING" }

# Phone B: ACK
POST /proof/two-phone/ack    { "sessionId": "...", "packetId": "...", "fromPhone": "phone-b" }

# Check status
GET  /proof/two-phone/status?sessionId=...
```

---

## Logcat Proof Sequence (Phone A)

```
MauriMeshBle: rust_engine_ready
MauriMeshBle: scan_started
MauriMeshBle: Peer found: <Phone-B-address>
MauriMeshBle: Packet sent: <packetId> to <Phone-B-nodeId>
MauriMeshBle: message_received: {"packetType":"ack","ackFor":"<packetId>"}
```

## Logcat Proof Sequence (Phone B)

```
MauriMeshBle: rust_engine_ready
MauriMeshBle: BLE advertising started
MauriMeshBle: Central connected: <Phone-A-address>
MauriMeshBle: message_received: {"packetType":"proof_event","fromPeerId":"phone-a-node-id"}
MauriMeshBle: Packet sent: <ackId> (ack for <packetId>)
```

---

## ADB Commands

```bash
# Capture proof logs from Phone A
adb -s <phone-a-serial> logcat -s MauriMeshBle:D | tee proof-phone-a.log

# Capture from Phone B
adb -s <phone-b-serial> logcat -s MauriMeshBle:D | tee proof-phone-b.log
```

---

## Proof Ledger Record

After successful two-phone proof, record in the Proof Ledger:

```bash
curl -X POST https://<domain>/api/proof-ledger/record \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "eventType": "two_phone_proof",
    "runtimeMode": "real_native",
    "deviceId": "phone-a-node-id",
    "peerId": "phone-b-node-id",
    "packetId": "<proof-packetId>",
    "source": "physical_android",
    "verified": true,
    "rawLogExcerpt": "MauriMeshBle: ACK received for <packetId>"
  }'
```

---

## Failure Modes

| Failure | Cause | Fix |
|---|---|---|
| No peer found | BLE not enabled or permissions missing | Enable BLE, grant BLUETOOTH_SCAN |
| Packet sent but no ACK | Receiver not running or channel dropped | Check Phone B logcat, retry |
| `rust_engine_unavailable_kotlin_fallback` | NDK .so not included in APK | Rebuild with `./scripts/build-apk.sh release` |
| UUID mismatch warning | Rust returned different service UUID | Check `MeshBleUuids.SERVICE_UUID` vs Rust constant |
| Proof packet has `ttl=0` | Packet expired before delivery | Retry; check clock sync between devices |
