---
name: MauriMesh has two separate mesh engines
description: Which engine owns governance counters vs. which one the UI screens actually render — they are different.
---

MauriMesh contains **two distinct mesh/routing engines** that are easy to confuse:

1. **`lib/mauri-mesh-engine`** (`SelfGovernanceRoutingEngine`, `MauriMeshP2PEngine`)
   — owns the governance counters (`rehabilitations`, `trafficShapedRoutes`,
   `quarantinedPeers`), tunable `RoutingEngineConfig`, jump codes, hybrid
   transport. Exercised by `tests/` and the (un-wired) `server/maurimeshIntelligentApiDriver.cjs`.
   It is RN-bundle-safe (pure TS/Math/Date; only `validate.ts` uses node `process`, and it is not re-exported by index).

2. **`src/maurimesh/invention-engine`** (`LivingSelfGovernedAiMesh`)
   — what the **UI screens actually render**, via `src/maurimesh/ui/mauriUiEngine.ts`
   (`getUiEngineSnapshot()` → ledger/trust/route-memory counts). Has NO governance counters.

**Why this matters:** the running dev server `server/index.ts` (`/api/mesh/status`)
is static simulation and does NOT run the lib engine. The app's `app/mesh-status.tsx`
reads that HTTP API (needs `EXPO_PUBLIC_MESH_API_URL`, else falls back to local sim).
So to surface lib-engine data (e.g. governance) live in the UI without depending on
API config, instantiate the lib engine client-side and drive it (see
`src/lib/meshGovernanceSim.ts`).

**How to apply:** if a task says "show engine X's stat in the dashboard", first confirm
which of the two engines owns that stat, and remember the UI does not use the lib engine
by default. Driving the lib `SelfGovernanceRoutingEngine` for a simulation: to make the
quarantine→self-heal cycle observably return `quarantinedPeers` to 0, skip re-applying
the failure on the exact tick `rehabilitations` increments (the self-heal pass runs
inside `decideRoute`).
