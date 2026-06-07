# MauriMesh Live Mesh Data Spine

Marker: `LIVE_MESH_DATA_SPINE_20260608_A`

## Covers

- #56 Real BLE scanning data spine
- #59 Shared live data hook for dashboard screens
- #61 Persistent records foundation using AsyncStorage
- #62 Platform screens can read the same live state
- #64 Persistent mesh node registry
- #86 Initial test coverage foundation

## Truth boundary

This layer consumes native BLE scan proof status only.

It does not claim:

- BLE advertising
- BLE connection
- message TX/RX
- ACK
- relay
- store-forward delivery
- full mesh delivery

Those must be proven in later phases.

## Screens

- `/live-mesh-ops`

## Core modules

- `src/maurimesh/live/types.ts`
- `src/maurimesh/live/meshEventBus.ts`
- `src/maurimesh/live/meshNodeRegistry.ts`
- `src/maurimesh/live/meshMetricsStore.ts`
- `src/maurimesh/live/nativeBleLiveSource.ts`
- `src/maurimesh/live/useLiveMesh.ts`
