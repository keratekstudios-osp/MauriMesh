# MM-PROOF-003-3DEVICE-HOP

Status: PASSED

Packet ID:

```txt
MM3-JSY73G-JKDXYR
```

Path:

```txt
A06 -> S10 -> A16 -> S10 -> A06 ACK
```

Stages:

```txt
PHONE_A / A06  | PACKET_ID_GENERATED
PHONE_A / A06  | TX_A06_TO_S10
PHONE_B / S10  | RX_S10_FROM_A06
PHONE_B / S10  | RELAY_S10_TO_A16
PHONE_C / A16  | RX_A16_FROM_S10
PHONE_C / A16  | ACK_A16_TO_S10
PHONE_B / S10  | ACK_RELAY_S10_TO_A06
PHONE_A / A06  | ACK_RECEIVED_A06
```

Proof class:

```txt
Physical APK/logcat 3-device relay proof
```

Lock rule:
Same packetId must appear across PHONE_A, PHONE_B, and PHONE_C proof logs.
