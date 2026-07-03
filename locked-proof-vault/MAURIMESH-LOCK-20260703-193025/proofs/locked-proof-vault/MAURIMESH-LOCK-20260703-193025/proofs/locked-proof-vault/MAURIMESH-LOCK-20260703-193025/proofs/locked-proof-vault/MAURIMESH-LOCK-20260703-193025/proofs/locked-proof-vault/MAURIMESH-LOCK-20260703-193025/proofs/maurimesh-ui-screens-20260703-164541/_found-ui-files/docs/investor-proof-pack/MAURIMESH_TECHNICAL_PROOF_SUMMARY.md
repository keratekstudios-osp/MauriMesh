# MauriMesh Technical Proof Summary

## Devices

- PHONE_A: Samsung Galaxy A06 / Sender.
- PHONE_B: Samsung Galaxy S10 / Relay / Store-forward node.
- PHONE_C: Samsung Galaxy A16 / Receiver + ACK.

## Passed Proof Categories

### 1. Two-Device Relay

A06 sender to S10 relay with ACK return.

### 2. Three-Device Hop Relay

A06 sender to S10 relay to A16 receiver, with ACK return path.

Known indexed packet:

`MM3-JSY73G-JKDXYR`

### 3. Store-Forward Delay

A06 sender to S10 store-forward relay. A16 is unavailable, later returns, receives stored packet, ACKs S10, and S10 relays ACK back to A06.

Verified packet:

`MMSF-TEJFNH-K3FKYM`

## Store-Forward Verified Stage Order

1. PACKET_ID_CONFIRMED
2. TX_A06_TO_S10_STORE_REQUEST
3. S10_STORE_PACKET
4. A16_OFFLINE_CONFIRMED
5. S10_HOLD_DELAY
6. A16_RETURNS
7. S10_FORWARD_STORED_TO_A16
8. RX_A16_STORED_PACKET
9. ACK_A16_TO_S10_STORED
10. ACK_RELAY_S10_TO_A06_STORED
11. ACK_RECEIVED_A06_STORED

## Verification Scripts

```bash
node tools/proof-verifiers/verify-store-forward-proof.js
node tools/proof-verifiers/verify-store-forward-hash-manifest.js
node tools/proof-verifiers/verify-maurimesh-master-proof-index.js
node tools/proof-verifiers/verify-maurimesh-investor-proof-pack.js
```

## Expected Results

```text
Verdict: PASS
HASH VERDICT: PASS
MASTER INDEX VERDICT: PASS
PROOF PACK VERDICT: PASS
```
