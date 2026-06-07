---
name: MauriMesh governance counters — single shared source
description: Where the self-healing / traffic-control counters come from and how clients consume them
---

# Governance counters: one shared server-side source

The governance counters (`rehabilitations`, `trafficShapedRoutes`,
`quarantinedPeers`) are produced by ONE server-side instance of the real lib
`SelfGovernanceRoutingEngine`, driven on a single interval in `server/index.ts`
and exposed as `governance` on `GET /api/mesh/status`.

**Rule:** clients must PREFER the API's `governance` (one source of truth so web
and every phone show identical numbers) and only fall back to the local
`tickMeshGovernanceSim()` simulation when the API governance is unavailable.

**Why:** before this, each client ran its own client-side sim, so the web
preview and each phone computed independent, divergent numbers. Do not
re-introduce per-client simulation as the primary source.

**Rolling history / timeline:** `src/lib/governanceHistory.ts`
`createGovernanceHistory(maxEntries)` is a pure fixed-size buffer; the server
records one snapshot per governance tick and exposes `governanceHistory` on the
same status endpoint. Clients prefer it, else keep a local capped buffer.

**Sub-rule (one tick per cycle):** in `app/mesh-status.tsx` compute counters
ONCE per poll (`const currentCounters = status.governance ?? tickMeshGovernanceSim()`)
and reuse that single value for BOTH the displayed "now" number AND the history
append. Calling `tickMeshGovernanceSim()` separately for display and for history
double-advances the local sim (~2x cadence) and desyncs the latest timeline
sample from the shown counter. (Caught in code review.)

**How to apply:**
- `src/lib/meshGovernanceSim.ts` exports `createMeshGovernanceSim()` (factory →
  `tick()` / `read()`); each instance owns its own engine. The server creates the
  shared instance; `tickMeshGovernanceSim()` is a default singleton used ONLY as
  the client fallback.
- `src/lib/meshClient.ts` `MeshStatus.governance` is optional; passes through
  `result.data.governance` when the API is reachable.
- The truth boundary still holds: keep `[SIMULATION - NOT LIVE BLE]`; a reachable
  HTTP API never proves live BLE.
