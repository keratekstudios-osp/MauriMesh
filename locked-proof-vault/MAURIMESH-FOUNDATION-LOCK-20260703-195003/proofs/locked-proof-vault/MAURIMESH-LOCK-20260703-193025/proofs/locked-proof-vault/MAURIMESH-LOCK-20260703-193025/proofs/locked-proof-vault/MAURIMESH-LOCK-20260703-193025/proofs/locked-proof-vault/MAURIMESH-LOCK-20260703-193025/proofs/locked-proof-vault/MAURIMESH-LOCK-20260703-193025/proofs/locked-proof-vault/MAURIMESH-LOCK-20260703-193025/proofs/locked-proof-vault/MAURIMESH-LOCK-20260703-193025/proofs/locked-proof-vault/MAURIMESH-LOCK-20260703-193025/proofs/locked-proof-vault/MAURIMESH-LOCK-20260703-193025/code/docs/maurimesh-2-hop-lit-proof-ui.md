# MauriMesh 2-Hop Lit Button Proof UI

## Route

`/proof-2-hop`

## Purpose

Guides two physical phones through a strict 2-hop proof:

1. A06 / PHONE A generates packetId.
2. A06 sends packet to S10.
3. S10 / PHONE B receives same packetId.
4. S10 sends ACK back to A06.
5. A06 confirms ACK returned.

## Colour logic

- Grey = locked
- Amber = ready to press now
- Blue = active / waiting
- Purple = ACK return stage
- Green = complete

## Truth rule

PASS only if the same packetId appears across:

- `TX_A06_TO_S10`
- `RX_S10_FROM_A06`
- `ACK_RELAY_S10_TO_A06`
- `ACK_BACK_TO_A06`

This screen does not fake BLE. It is an operator-guided proof UI. Real validation still requires APK + physical phone logs.
