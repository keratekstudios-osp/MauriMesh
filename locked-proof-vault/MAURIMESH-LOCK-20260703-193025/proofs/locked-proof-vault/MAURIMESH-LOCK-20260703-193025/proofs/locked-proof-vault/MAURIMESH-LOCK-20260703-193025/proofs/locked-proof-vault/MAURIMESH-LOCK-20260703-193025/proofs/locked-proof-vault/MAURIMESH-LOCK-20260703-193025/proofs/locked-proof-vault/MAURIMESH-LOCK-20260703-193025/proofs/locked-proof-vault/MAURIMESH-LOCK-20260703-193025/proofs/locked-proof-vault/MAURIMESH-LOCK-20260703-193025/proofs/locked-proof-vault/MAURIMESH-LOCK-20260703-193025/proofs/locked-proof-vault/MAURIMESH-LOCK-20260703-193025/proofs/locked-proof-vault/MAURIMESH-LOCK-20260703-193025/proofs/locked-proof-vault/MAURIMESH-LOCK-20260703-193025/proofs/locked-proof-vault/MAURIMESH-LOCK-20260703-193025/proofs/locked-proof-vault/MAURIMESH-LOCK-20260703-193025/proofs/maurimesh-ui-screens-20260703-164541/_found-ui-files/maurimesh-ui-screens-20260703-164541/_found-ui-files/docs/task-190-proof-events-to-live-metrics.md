# Task #190 — Hardware Proof Events to Live Metrics Spine

Marker: `TASK_190_PROOF_METRICS_SPINE_20260608_A`

## Installed

- Shared proof metrics spine.
- Persistent local proof metric events.
- `useProofMetrics()` live hook.
- `/proof-metrics` screen.
- Raw packet proof send attempts record:
  - `send_attempt`
  - `send_submitted`
  - `delivery_failed`
- BLE proof ledger save can record:
  - `ack_received`
  - `delivery_failed`

## What this changes

Screens that previously showed zero delivery/ACK metrics now have a live spine that can be consumed by delivery, ACK, latency, store-forward, and route-health screens.

## Truth boundary

This records proof events only when instrumentation runs.

It still does not claim real delivery until:
- Phone A sends raw packet
- Phone B logs `RX_RAW_PACKET`
- Phone B logs `ACK_SENT=true`
- Phone A receives ACK
- Evidence is saved to Proof Ledger
