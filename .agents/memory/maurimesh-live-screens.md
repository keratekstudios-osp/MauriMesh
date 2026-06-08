---
name: MauriMesh live mesh screens pattern
description: How the app/mesh and app/network live screens are built and wired
---

The live mesh/network screens (`app/mesh/index`, `ble-discovery`, `peer-mapping`,
`signal-strength`, `store-forward-queue`, `ack-tracking`, `app/network/route-health`)
are **self-contained**, built in the proven style of `app/live-mesh-ops.tsx` and
wired to the dependency-free live spine `src/maurimesh/live/useLiveMesh`.

**Why:** the older rich screens under
`backup-before-isolating-router-layouts-*/` were never git-tracked and depend on
`src/components/mesh/*` + a `DS` design-token module that have since been reduced to
minimal stubs with diverged prop APIs — so they can't be restored verbatim.

**How to apply:**
- Shared UI/format helpers live in `src/maurimesh/live/liveMeshUi.tsx`
  (LiveScreen, Card, Line, StatRow, Bars, Pill, EmptyNote, LiveButton, COLORS) and
  `src/maurimesh/live/liveMeshFormat.ts` (timeAgo, isFresh, rssiQuality,
  deriveRouteHealth, nodeDisplayName).
- Import path from `app/mesh/*` or `app/network/*`:
  `../../src/maurimesh/live/...`.
- Do NOT add expo-router route groups `(tabs)` or nested `_layout` under app/mesh —
  that nesting caused the earlier router crash; plain route files are safe.
- Truth-boundary ethos: never fabricate latency/packet-loss. route-health derives a
  score from real rssi + recency + seenCount only and states latency is unmeasured.
