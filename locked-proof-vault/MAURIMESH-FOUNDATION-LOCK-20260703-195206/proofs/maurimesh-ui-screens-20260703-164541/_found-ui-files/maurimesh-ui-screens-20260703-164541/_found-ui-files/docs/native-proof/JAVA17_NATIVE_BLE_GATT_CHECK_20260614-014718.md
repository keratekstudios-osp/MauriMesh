# MauriMesh Java 17 Native BLE/GATT Check

Generated: 2026-06-14T01:48:21Z

## Java 17

Java report:

```txt
/home/runner/workspace/docs/native-proof/java17-check-20260614-014718.txt
```

## Gradle Kotlin Compile

Status:

```txt
FAILED
```

Gradle output:

```txt
/home/runner/workspace/docs/native-proof/gradle-java17-compile-20260614-014718.txt
```

## Native BLE/GATT Logger Coverage

Coverage output:

```txt
/home/runner/workspace/docs/native-proof/native-ble-gatt-java17-coverage-20260614-014718.txt
```

## Truth

Native BLE/GATT packet-bound PASS is **NOT CLAIMED**.

This check only verifies whether the native Kotlin code can compile and which native packet logger stages are actually wired.

## Current Known Coverage Before Further Wiring

Expected from last check:

```txt
gatt_write_packetId: WIRED
ack_packetId: WIRED
advertise_start_packetId: missing
scan_result_packetId: missing
gatt_read_packetId: missing
characteristic_changed_packetId: missing
relay_packetId: missing
```

## Next Rule

If Gradle passes, wire the missing actual native stages.

If Gradle fails with Kotlin errors, patch those errors first.

If Java 17 is unavailable, fix Replit environment before native compile proof.
