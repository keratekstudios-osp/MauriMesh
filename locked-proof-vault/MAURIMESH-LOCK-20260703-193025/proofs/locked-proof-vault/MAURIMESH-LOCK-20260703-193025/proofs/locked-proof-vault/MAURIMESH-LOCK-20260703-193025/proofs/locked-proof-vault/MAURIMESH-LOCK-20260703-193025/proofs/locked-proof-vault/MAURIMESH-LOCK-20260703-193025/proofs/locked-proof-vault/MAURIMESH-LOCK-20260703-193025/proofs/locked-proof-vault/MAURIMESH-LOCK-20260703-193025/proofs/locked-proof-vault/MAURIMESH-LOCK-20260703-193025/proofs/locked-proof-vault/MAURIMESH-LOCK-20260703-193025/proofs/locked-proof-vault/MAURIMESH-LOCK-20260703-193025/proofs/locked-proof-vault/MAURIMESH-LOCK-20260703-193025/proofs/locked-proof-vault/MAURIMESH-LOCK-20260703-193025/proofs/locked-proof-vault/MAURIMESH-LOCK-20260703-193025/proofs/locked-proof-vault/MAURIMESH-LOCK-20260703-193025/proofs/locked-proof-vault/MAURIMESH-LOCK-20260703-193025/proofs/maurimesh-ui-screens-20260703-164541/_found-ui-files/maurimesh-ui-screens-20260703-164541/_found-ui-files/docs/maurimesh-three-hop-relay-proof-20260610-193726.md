# MauriMesh Three-Hop BLE Relay Proof Test

Generated: 20260610-193726

## Proof Identity

- proofId: MM-3HOP-20260610-193726
- packetId: pkt3hop-20260610-193726
- routeId: route-A-B-C-20260610-193726
- path: PHONE_A -> PHONE_B -> PHONE_C
- ack path: PHONE_C -> PHONE_B -> PHONE_A

## Required Evidence

A real 3-hop proof requires all of these exact stages:

1. PHONE_A_TX_BLE_START
2. PHONE_B_RX_BLE_FROM_A
3. PHONE_B_RELAY_TX_TO_C
4. PHONE_C_RX_BLE_FROM_B
5. PHONE_C_STRICT_ACK_SENT
6. PHONE_B_RELAY_ACK_FROM_C
7. PHONE_A_STRICT_OR_RELAY_ACK_RECEIVED

The same packetId and routeId must appear across all phones.

- [PASS] app/mauricore-ble-runtime.tsx exists
- [PASS] app/route-lab.tsx exists
- [PASS] app/message-fallback.tsx exists
- [PASS] app/proof-ledger.tsx exists
- [PASS] app/full-mesh-test-report.tsx exists
- [PASS] app/device-proof.tsx exists
- [PASS] Created three-hop proof template source file
- [PASS] Created /three-hop-relay-proof route

## Phone Setup

Use three phones:

### PHONE A — Sender
Open:
- /three-hop-relay-proof
- /mauricore-ble-runtime
- /route-lab

Action:
- Send packetId: pkt3hop-20260610-193726
- routeId: route-A-B-C-20260610-193726
- target path: PHONE_A -> PHONE_B -> PHONE_C

Expected log:
```txt
[MauriMesh3HopProof] proofId=MM-3HOP-20260610-193726 packetId=pkt3hop-20260610-193726 routeId=route-A-B-C-20260610-193726 phoneRole=PHONE_A stage=PHONE_A_TX_BLE_START
```

### PHONE B — Relay
Open:
- /mauricore-ble-runtime
- /message-fallback
- /proof-ledger

Action:
- Receive from PHONE_A.
- Relay same packetId and routeId to PHONE_C.
- Return ACK from PHONE_C back to PHONE_A.

Expected logs:
```txt
[MauriMesh3HopProof] proofId=MM-3HOP-20260610-193726 packetId=pkt3hop-20260610-193726 routeId=route-A-B-C-20260610-193726 phoneRole=PHONE_B stage=PHONE_B_RX_BLE_FROM_A
[MauriMesh3HopProof] proofId=MM-3HOP-20260610-193726 packetId=pkt3hop-20260610-193726 routeId=route-A-B-C-20260610-193726 phoneRole=PHONE_B stage=PHONE_B_RELAY_TX_TO_C
[MauriMesh3HopProof] proofId=MM-3HOP-20260610-193726 packetId=pkt3hop-20260610-193726 routeId=route-A-B-C-20260610-193726 phoneRole=PHONE_B stage=PHONE_B_RELAY_ACK_FROM_C
```

### PHONE C — Receiver
Open:
- /mauricore-ble-runtime
- /proof-ledger

Action:
- Receive packet from PHONE_B.
- Send strict ACK back through PHONE_B.

Expected logs:
```txt
[MauriMesh3HopProof] proofId=MM-3HOP-20260610-193726 packetId=pkt3hop-20260610-193726 routeId=route-A-B-C-20260610-193726 phoneRole=PHONE_C stage=PHONE_C_RX_BLE_FROM_B
[MauriMesh3HopProof] proofId=MM-3HOP-20260610-193726 packetId=pkt3hop-20260610-193726 routeId=route-A-B-C-20260610-193726 phoneRole=PHONE_C stage=PHONE_C_STRICT_ACK_SENT
```

### PHONE A Final ACK
Expected log:
```txt
[MauriMesh3HopProof] proofId=MM-3HOP-20260610-193726 packetId=pkt3hop-20260610-193726 routeId=route-A-B-C-20260610-193726 phoneRole=PHONE_A stage=PHONE_A_STRICT_OR_RELAY_ACK_RECEIVED
```

## PASS Rule

PASS only when all seven required stages appear with:
- same proofId
- same packetId
- same routeId
- correct phone roles
- no fatal AndroidRuntime / ReactNativeJS fatal crash

