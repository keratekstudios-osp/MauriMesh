# MauriMesh Native GATT Bridge Correct Placement v5

Timestamp: 20260617-024651

## Status

READY_CHECKED_WITH_NATIVE_COMPILE_GATE_ATTEMPTED

## Critical Correction

The previous v4 patch inserted React Native bridge methods into:

```
MainApplication.kt
```

That is usually the wrong location for `@ReactMethod`.

This v5 repair restores MainApplication if needed and places the bridge into a proper React Native native module:

```
MauriMeshNativeBlePacketModule.kt
```

Registered through:

```
MauriMeshNativeBlePacketPackage.kt
```

## Native Module Name

```
MauriMeshNativeBlePacket
```

## Methods Exposed

```
triggerGattPacketPayloadProof
triggerNativeGattPacketPayload
triggerGattPacketPayload
writeGattPacketProof
sendGattPacketProof
runGattPacketProof
```

## Expected Logcat After APK Install

Minimum bridge marker:

```
GATT_TRIGGER_NATIVE_METHOD_ENTERED
```

Helper marker:

```
GATT_HELPER_METHOD_CALLED
```

Final target markers:

```
GATT_CLIENT_WRITE_ATTEMPT
GATT_PACKET_PAYLOAD
GATT_SERVER_WRITE_RECEIVED
nativePacketBound=true
```

## Truth Rule

Final native BLE/GATT packet-bound PASS is not claimed by this patch.

Final PASS requires same packetId inside native BLE/GATT transport payload/log evidence across the physical device path.

## Gates

- TypeScript: PASS if command completed above.
- Expo Android export: PASS if command completed above.
- Gradle native compile gate: FAIL

Gradle log:

```
/home/runner/workspace/archives/native-ble-gatt/gradle-native-compile-20260617-024651.log
```

## Mac Test Script After APK Install

```
/home/runner/workspace/docs/native-ble-gatt/MAC_TEST_NATIVE_GATT_BRIDGE_V5_AFTER_INSTALL_20260617-024651.sh
```
