# MauriMesh Guarded Native BLE/GATT PacketId Wiring Report

Generated: 2026-06-14T01:38:56.271261+00:00

## Truth

This patch wires native packetId logging only where safe Kotlin patterns were detected.

Native BLE/GATT packet-bound PASS is still **NOT CLAIMED**.

## Changes

- /home/runner/workspace/android/app/src/main/java/com/maurimesh/messenger/MauriMeshBleModule.kt: inserted ack_packetId near packetId/ack line
- /home/runner/workspace/android/app/src/main/java/com/maurimesh/messenger/MauriMeshBleModule.kt: inserted ack_packetId near packetId/ack line
- /home/runner/workspace/android/app/src/main/java/com/maurimesh/messenger/MauriMeshBleModule.kt: inserted ack_packetId near packetId/ack line
- /home/runner/workspace/android/app/src/main/java/com/maurimesh/messenger/MeshCentralClient.kt: inserted before writeCharacteristic(characteristic...)

## Warnings / Skipped

- No safe patch inserted for: /home/runner/workspace/android/app/src/main/java/com/maurimesh/mesh/MeshEngine.kt
- No safe patch inserted for: /home/runner/workspace/android/app/src/main/java/com/maurimesh/messenger/MeshRawPacketGattServer.kt
- No safe patch inserted for: /home/runner/workspace/android/app/src/main/java/com/maurimesh/messenger/maurimesh/blehardware/MauriMeshHardwareBleScanService.kt

## Required Stages

- advertise_start_packetId
- scan_result_packetId
- gatt_write_packetId
- gatt_read_packetId
- characteristic_changed_packetId
- relay_packetId
- ack_packetId

## Next Validation

Run:

```bash
./scripts/inspect-native-ble-gatt-packetid-logging.sh
```

Then build APK and run:

```bash
PACKET_ID=MM3-YOURID-HERE ./scripts/validate-native-ble-gatt-packet-bound-proof.sh
```

