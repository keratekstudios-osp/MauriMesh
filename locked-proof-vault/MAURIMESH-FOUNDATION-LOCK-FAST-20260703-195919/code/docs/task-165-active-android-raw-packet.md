# Task #165 — Active Android Raw Packet Transport

Marker: `TASK_165_MESHCENTRAL_RAW_PACKET_TRANSPORT_20260608_ACTIVE_ANDROID_A`

## Installed

- `android/app/src/main/java/com/maurimesh/messenger/MeshCentralClient.kt`
- `android/app/src/main/java/com/maurimesh/messenger/MeshRawPacketTypes.kt`
- `MauriMeshBleModule.kt` bridge methods:
  - `sendRawPacket(nodeId, base64Payload)`
  - `broadcastRawPacket(base64Payload)`
  - `getRawPacketPeerCount()`
- JS client:
  - `src/maurimesh/ble/rawPacketClient.ts`

## Truth boundary

This installs central-side BLE GATT write submission.

It does not prove:
- receiver GATT server exists
- characteristic exists on receiver
- packet received
- ACK returned
- relay completed

Next proof requires receiver GATT server and two-phone ACK proof.
