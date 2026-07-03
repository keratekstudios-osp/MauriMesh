# MauriMesh Native BLE/GATT PacketId Logging Snippets

Patch ID: MM-NATIVE-BLE-GATT-LOGGING-20260614-013511

## Truth Rule

Do not claim native BLE/GATT packet-bound PASS unless the same packetId appears directly inside native Android BLE/GATT logs.

Required stages:

```txt
advertise_start_packetId
scan_result_packetId
gatt_write_packetId
gatt_read_packetId
characteristic_changed_packetId
relay_packetId
ack_packetId
```

## Logger

Created helper:

```txt
/home/runner/workspace/android/app/src/main/java/com/maurimesh/messenger/MauriMeshNativeBlePacketLogger.kt
```

Android log tag:

```txt
MAURIMESH_NATIVE_BLE_GATT
```

## Kotlin call examples

### Advertise start

Place where BLE advertising begins and packetId is known:

```kt
MauriMeshNativeBlePacketLogger.advertiseStart(
    packetId,
    "advertise start serviceUuid=$serviceUuid"
)
```

### Scan result

Place inside ScanCallback / onScanResult:

```kt
MauriMeshNativeBlePacketLogger.scanResult(
    packetId,
    "scan result device=${result.device?.address}"
)
```

If packetId is inside manufacturer/service data as bytes:

```kt
MauriMeshNativeBlePacketLogger.eventFromBytes(
    "scan_result_packetId",
    serviceDataBytes,
    "scan service data"
)
```

### GATT write

Place before/after characteristic write:

```kt
MauriMeshNativeBlePacketLogger.gattWrite(
    characteristic.value,
    "write uuid=${characteristic.uuid}"
)
```

### GATT read

Place inside onCharacteristicRead:

```kt
MauriMeshNativeBlePacketLogger.gattRead(
    characteristic.value,
    "read uuid=${characteristic.uuid} status=$status"
)
```

### Characteristic changed

Place inside onCharacteristicChanged:

```kt
MauriMeshNativeBlePacketLogger.characteristicChanged(
    characteristic.value,
    "changed uuid=${characteristic.uuid}"
)
```

### Relay

Place when relay forwards packetId:

```kt
MauriMeshNativeBlePacketLogger.relay(
    packetId,
    "relay native bridge forward"
)
```

### ACK

Place when ACK is created, sent, received, or relayed:

```kt
MauriMeshNativeBlePacketLogger.ack(
    packetId,
    "ack native bridge"
)
```

## Required ADB proof query

```bash
adb logcat -d | grep "MAURIMESH_NATIVE_BLE_GATT" | grep "MM3-"
```

## PASS rule

Same packetId must appear with all required native stages:

```txt
advertise_start_packetId
scan_result_packetId
gatt_write_packetId
gatt_read_packetId
characteristic_changed_packetId
relay_packetId
ack_packetId
```

If any stage is missing, status remains:

```txt
NATIVE BLE/GATT PACKET-BOUND PASS NOT CLAIMED
```
