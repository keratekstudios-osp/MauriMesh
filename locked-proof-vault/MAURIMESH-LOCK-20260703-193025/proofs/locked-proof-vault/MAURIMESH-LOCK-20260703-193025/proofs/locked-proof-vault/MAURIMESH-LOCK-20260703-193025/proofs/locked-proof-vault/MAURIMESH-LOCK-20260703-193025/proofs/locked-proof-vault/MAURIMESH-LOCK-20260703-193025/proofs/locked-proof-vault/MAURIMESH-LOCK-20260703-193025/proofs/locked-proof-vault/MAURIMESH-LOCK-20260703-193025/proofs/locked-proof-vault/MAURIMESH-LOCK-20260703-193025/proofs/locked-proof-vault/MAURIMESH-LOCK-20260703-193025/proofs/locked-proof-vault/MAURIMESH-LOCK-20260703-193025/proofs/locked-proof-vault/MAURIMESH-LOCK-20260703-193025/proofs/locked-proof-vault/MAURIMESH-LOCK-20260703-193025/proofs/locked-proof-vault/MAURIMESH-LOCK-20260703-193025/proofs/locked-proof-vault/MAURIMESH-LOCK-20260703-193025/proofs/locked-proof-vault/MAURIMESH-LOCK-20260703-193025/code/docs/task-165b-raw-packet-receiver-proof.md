# Task #165B — Raw Packet Receiver + ACK Proof

Markers:
- `TASK_165B_RAW_PACKET_GATT_SERVER_20260608_A`
- `TASK_165B_RAW_PACKET_RECEIVER_BRIDGE_20260608_A`
- `TASK_165B_RAW_PACKET_PROOF_CLIENT_20260608_A`
- `TASK_165B_RAW_PACKET_PROOF_SCREEN_20260608_A`

## Installed

- Native Android GATT server for MauriMesh raw packet service.
- Writable raw packet characteristic.
- Receiver bridge methods:
  - `startRawPacketReceiver()`
  - `stopRawPacketReceiver()`
  - `getRawPacketReceiverStatus()`
  - `sendRawPacketUtf8(nodeId, text)`
- ACK attempt: receiver sends ACK payload back to sender address through `MeshCentralClient.sendRawPacket`.
- Raw Packet Proof screen.
- Logcat proof helper.

## Two-phone proof rule

To mark real packet delivery complete, capture logs showing:

1. Phone B `RAW_PACKET_GATT_SERVER_STARTED`
2. Phone A `sendRawPacket write submitted`
3. Phone B `RX_RAW_PACKET`
4. Phone B `ACK_SENT=true`
5. Phone A `RX_RAW_PACKET` with ACK payload
6. UI receiver status shows receivedCount increased

## Truth boundary

This installs the most likely native receiver + ACK proof path.

It still requires:
- new APK build
- install on two physical phones
- Bluetooth permissions granted
- both phones running receiver server
- physical two-phone proof logs
