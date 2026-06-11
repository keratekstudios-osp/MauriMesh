# MM-PROOF-004-STORE-FORWARD

Status: PASSED

Packet ID:

```txt
MMSF-KVM5AQ-ZK423E
```

Path:

```txt
A06 -> S10 STORE -> A16 OFFLINE -> A16 RETURNS -> S10 FORWARD -> A16 ACK -> S10 -> A06 ACK
```

Stages:

```txt
PHONE_A / A06  | PACKET_ID_CONFIRMED
PHONE_A / A06  | TX_A06_TO_S10_STORE_REQUEST
PHONE_B / S10  | S10_STORE_PACKET
PHONE_C / A16  | A16_OFFLINE_CONFIRMED
PHONE_B / S10  | S10_HOLD_DELAY
PHONE_C / A16  | A16_RETURNS
PHONE_B / S10  | S10_FORWARD_STORED_TO_A16
PHONE_C / A16  | RX_A16_STORED_PACKET
PHONE_C / A16  | ACK_A16_TO_S10_STORED
PHONE_B / S10  | ACK_RELAY_S10_TO_A06_STORED
PHONE_A / A06  | ACK_RECEIVED_A06_STORED
```

Proof class:

```txt
Physical APK/logcat store-forward delay proof
```

Lock rule:
Same packetId must appear across store, hold, rediscovery, forward, receiver RX, ACK relay, and final A06 ACK.
