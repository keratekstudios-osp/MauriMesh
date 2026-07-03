# MauriMesh Native BLE/GATT Packet Logger Patch Report

Generated: 20260614-000418

## Files created or repaired

- src/maurimesh/native/nativeBlePacketLogger.ts
- src/maurimesh/proof/nativeBleGattProofVerdict.ts
- docs/native-proof/native-ble-gatt-packet-proof.md
- scripts/patch-proof-screens-native-ble-logger.cjs
- docs/native-proof/native-ble-gatt-file-scan-20260614-000418.txt

## Android native bridge files

Created if Android native source exists:

- android/app/src/main/java/com/maurimesh/messenger/MauriMeshNativeBlePacketModule.java
- android/app/src/main/java/com/maurimesh/messenger/MauriMeshNativeBlePacketPackage.java

## Required proof log format

```txt
MAURIMESH_NATIVE_BLE_PACKET | role=<PHONE_ROLE> | stage=<STAGE> | packetId=<PACKET_ID> | transport=<BLE_GATT> | detail=<DETAIL>
```

## Truth rule

Native BLE/GATT packet-bound PASS requires the same packetId inside native transport logs.

If packetId appears only in ReactNativeJS, bridge fallback, or proof-screen logs, verdict remains:

```txt
APK workflow proof only / native BLE-GATT packet-bound proof not yet confirmed
```

## Next required proof target

Build a new APK, install it on A06/S10/A16, run the native capture again, and search for:

```txt
MAURIMESH_NATIVE_BLE_PACKET
packetId=<same packet>
transport=BLE_GATT
```
