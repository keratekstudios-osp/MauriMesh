# Task #192 — Native RX/ACK Event Bridge + API URL Check

Marker: `TASK_192_NATIVE_PROOF_EVENT_BRIDGE_20260608_A`

## Installed

- Kotlin native event emitter for raw packet proof events.
- JS listener for `MauriMeshRawPacketProofEvent`.
- Native RX/ACK events feed the proof metrics spine.
- API config helper.
- `/api-config` screen.
- Dashboard API Config link.

## Why

The UI already showed live BLE scan data, but ACK/delivery metrics stayed at zero.
This task connects the native RX/ACK event layer into the metrics spine.

## Physical proof requirement

Metrics rise only after:
- receiver is started on both phones
- Phone A sends packet
- Phone B receives `RX_RAW_PACKET`
- Phone B emits `ack_sent`
- JS bridge records the native event
