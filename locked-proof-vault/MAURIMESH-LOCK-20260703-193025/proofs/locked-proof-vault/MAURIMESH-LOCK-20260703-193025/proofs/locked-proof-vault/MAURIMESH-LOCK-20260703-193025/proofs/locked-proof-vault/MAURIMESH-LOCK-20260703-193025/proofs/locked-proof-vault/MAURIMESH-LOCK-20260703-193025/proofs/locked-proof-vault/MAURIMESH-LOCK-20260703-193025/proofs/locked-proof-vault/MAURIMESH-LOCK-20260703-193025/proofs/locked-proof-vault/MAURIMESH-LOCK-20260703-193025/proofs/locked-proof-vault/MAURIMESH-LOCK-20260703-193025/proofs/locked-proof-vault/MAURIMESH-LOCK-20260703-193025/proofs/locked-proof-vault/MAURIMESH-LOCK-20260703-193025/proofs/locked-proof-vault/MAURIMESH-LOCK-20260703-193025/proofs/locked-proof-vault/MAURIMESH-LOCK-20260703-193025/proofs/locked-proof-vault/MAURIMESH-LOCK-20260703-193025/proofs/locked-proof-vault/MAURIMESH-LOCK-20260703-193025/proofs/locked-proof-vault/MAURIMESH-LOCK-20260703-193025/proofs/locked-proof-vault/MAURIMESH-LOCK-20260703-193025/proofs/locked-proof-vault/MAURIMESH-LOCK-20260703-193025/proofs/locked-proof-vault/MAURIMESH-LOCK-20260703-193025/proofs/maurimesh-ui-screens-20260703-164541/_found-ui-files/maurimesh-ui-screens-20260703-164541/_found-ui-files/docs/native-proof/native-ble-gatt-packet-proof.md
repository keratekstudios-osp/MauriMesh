# MauriMesh Native BLE/GATT Packet-Bound Proof

## Purpose

This document defines the next proof level after APK proof-screen workflow logs.

## Current truth standard

MauriMesh has locked APK proof-screen + ReactNativeJS monitor proof for:
- 2-hop relay ACK
- 3-device relay path
- native BLE/GATT capture attempt

Native BLE/GATT packet-bound PASS is not claimed until the same packetId appears inside native BLE/GATT transport logs.

## Required log format

```txt
MAURIMESH_NATIVE_BLE_PACKET | role=<PHONE_ROLE> | stage=<STAGE> | packetId=<PACKET_ID> | transport=<BLE_GATT> | detail=<DETAIL>
Native PASS rule

Native BLE/GATT packet-bound PASS requires the same packetId inside lines that include native transport markers such as:

BluetoothGatt
BtGatt
GATT
GattService
onScanResult
AdvertiseCallback
AdvertisingSet
writeCharacteristic
readCharacteristic
onCharacteristicWrite
onCharacteristicRead
onCharacteristicChanged
onServicesDiscovered
connectGatt
MAURIMESH_NATIVE_BLE_PACKET with transport=BLE_GATT
Not enough for native PASS

These prove app workflow only:

ReactNativeJS
MAURIMESH_3_DEVICE_PROOF
MAURIMESH_STORE_FORWARD_PROOF
EXAM_APPROVED
MAURIMESH_NATIVE_BLE_PACKET_FALLBACK
transport=REACT_NATIVE_FALLBACK
transport=BRIDGE_LOG_ONLY
Next engineering target

Patch real Android BLE/GATT callbacks so packetId appears at:

advertise
scan
GATT connect
service discovery
write
read
characteristic changed
relay
ACK
