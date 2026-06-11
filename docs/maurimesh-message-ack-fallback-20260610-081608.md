# MauriMesh Message Queue + ACK Fallback

Generated: 20260610-081608

## Added

- MessageFallbackTypes.ts
- MessageFallbackQueue.ts
- AckFallbackEngine.ts
- MessageAckFallbackEngine.ts
- MessageFallbackPanel.tsx
- /message-fallback route
- Dashboard button
- Backup route registry entry
- Embedded panel in MauriCore BLE Runtime
- Embedded panel in BLE Hardware Runtime
- Embedded panel in Device Proof
- Embedded panel in Proof Ledger
- Checker

## Fallback path

LIVE_SEND
→ STORE_FORWARD_QUEUE
→ RETRY_WAITING
→ DELIVERED_PENDING_ACK
→ DELIVERY_PENDING_PROOF
→ OFFLINE_HOLD

## ACK fallback path

STRICT_ACK
→ DELAYED_ACK
→ RELAY_ACK
→ ROUTE_OBSERVED_ACK
→ DELIVERY_PENDING_PROOF
→ NO_ACK_YET

## Final Truth

This fallback protects message delivery honesty.
It does not claim real delivery until strict device ACK proof exists.
