---
name: MauriMesh live mesh screens pattern
description: How the app/mesh and app/network live screens are built and wired
---

The live mesh/network screens (`app/mesh/index`, `ble-discovery`, `peer-mapping`,
`signal-strength`, `store-forward-queue`, `ack-tracking`, `relay-analytics`,
`packet-analysis`, `app/network/route-health`, `latency-monitoring`,
`delivery-analytics`) are **self-contained**, built in the proven style of
`app/live-mesh-ops.tsx` and wired to the dependency-free live spine
`src/maurimesh/live/useLiveMesh`. There is no react-query/useQuery in this app —
"refetch interval" == `useLiveMesh(pollMs)`; tune per screen (signal/packet/ble 1s,
peer 2s, route/latency 3s, ack/relay/store-forward/delivery 5s).

**Analytics-screen truth constraint:** relay/delivery/ack/latency/packet metrics are
NOT physically proven — `meshMetricSnapshot` hardcodes relayCount/deliveryCount/
ackCount/averageLatencyMs to 0 (only discoveredCount/nodeCount/failureCount are real).
So those analytics screens MUST keep a "Truth Boundary" warning Card and honest empty
states; never present the zeros as if delivery/relay were measured.

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
