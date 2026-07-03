# Task #62 — Platform Live BLE-Mesh Data Bridge

Marker: `PLATFORM_LIVE_BLE_MESH_BRIDGE_20260608_A`

## Installed foundation

Mobile:
- `artifacts/messenger-mobile/src/store/platformLiveMeshTypes.ts`
- `artifacts/messenger-mobile/src/store/platformLiveMeshBridge.ts`
- `artifacts/messenger-mobile/src/store/PlatformLiveMeshPanel.tsx`

Web:
- `artifacts/maurimesh/src/lib/platformLiveMeshTypes.ts`
- `artifacts/maurimesh/src/lib/platformLiveMeshBridge.ts`
- `artifacts/maurimesh/src/components/live/PlatformLiveMeshPanel.tsx`

API:
- `artifacts/api-server/platform-live-mesh-endpoint.ts`

Audit:
- `scripts/audit-task-62-platform-live-wiring.sh`

## Truth boundary

This bridge reads proven native BLE scan registry/metrics where available.

It does not claim:
- BLE advertising
- BLE connection
- packet TX/RX
- ACK
- relay
- store-forward delivery

Those must be connected in later phases.

## Done means

Every platform/advanced screen must import and display real values from the bridge or an explicit unavailable state. No unlabelled mock data should remain.
