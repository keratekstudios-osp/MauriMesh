# MauriMesh Two-Phone Hotspot Gateway Proof

Generated: 20260610-200534

## Proof Identity

- proofId: MM-HOTSPOT-2PHONE-20260610-200534
- packetId: pkt-hotspot-20260610-200534
- routeId: route-phoneB-phoneA-hotspot-20260610-200534
- path: PHONE_B_CLIENT -> PHONE_A_HOTSPOT_GATEWAY -> INTERNET_OR_API

## Phone Roles

### PHONE A
Role: hotspot/gateway

Required:
- Mobile data ON or internet available
- Hotspot ON
- MauriMesh APK open
- Open /two-phone-hotspot-proof
- Open /mauricore-ble-runtime or /route-lab if available

Expected stages:
```txt
PHONE_A_HOTSPOT_ON
PHONE_A_GATEWAY_READY
PHONE_A_GATEWAY_RX_FROM_B
PHONE_A_GATEWAY_FORWARD_ATTEMPT
PHONE_A_GATEWAY_FORWARD_SUCCESS
PHONE_A_GATEWAY_ACK_TO_B
```

### PHONE B
Role: client/sender

Required:
- Connect Wi-Fi to PHONE A hotspot
- MauriMesh APK open
- Open /two-phone-hotspot-proof
- Send proof packet

Expected stages:
```txt
PHONE_B_CONNECTED_TO_PHONE_A_HOTSPOT
PHONE_B_TX_PACKET_START
PHONE_B_ACK_RECEIVED
```

## PASS Rule

PASS only when logs show all required stages with the same:

- proofId: MM-HOTSPOT-2PHONE-20260610-200534
- packetId: pkt-hotspot-20260610-200534
- routeId: route-phoneB-phoneA-hotspot-20260610-200534

## Not 3-Hop

This is a two-phone gateway proof, not a three-hop BLE relay proof.
