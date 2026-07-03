# Task #192C — Clean Duplicate Kotlin Native Proof Events

## Fixed

Removed duplicate native proof metric emit blocks from:

- `MauriMeshBleModule.kt`

Expected final state:

- one `rx_packet` native event emit block
- one `ack_sent` native event emit block
- one `MauriMeshRawPacketProofEvent` JS event name

## Why

Rerunning #192 created duplicate RX/ACK event calls. That could double-count proof metrics after real hardware packet receipt.

## Truth boundary

This cleanup prevents double counting. It still requires physical two-phone proof to confirm real RX/ACK delivery.
