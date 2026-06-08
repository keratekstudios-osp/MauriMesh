---
name: MauriMesh message store / zustand gap
description: Why active screens use the useLiveMesh spine, not the zustand meshStore
---

The chat/message store `useMeshStore` (in `lib/lib/store/meshStore.ts`) imports
`zustand`, which is **not installed** in the project root (`node_modules` has no
zustand, package.json doesn't list it). Importing `useMeshStore` from any screen
that actually gets bundled breaks the Metro bundle with
`UnableToResolveError: zustand`.

**Why:** the whole `lib/lib/mesh/*` message-transport subsystem (useBleTransport,
useMeshTransport, useMeshStore) is currently NOT mounted by any active screen, so
the missing dep never surfaces until you import it into an `app/` route.

**How to apply:** for live mesh UI, prefer the dependency-free live spine
`src/maurimesh/live/useLiveMesh` (real native BLE scan registry + metrics) as the
data source. It exposes real scanned `nodes` (address/lastRssi/lastSeenAt/seenCount)
and `metrics` (relay/delivery/ack/failure counts, all gated by truthLevel). Only
wire `useMeshStore` after zustand is added AND the transport is actually mounted —
real message TX/ACK is owned by separate tasks (persist chat, delivery receipts).
