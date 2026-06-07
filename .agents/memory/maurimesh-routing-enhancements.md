---
name: MauriMesh routing engine enhancement layers
description: Self-healing + traffic-control behaviors layered onto the AI self-governance routing engine, and why they exist.
---

The AI routing engine (`lib/mauri-mesh-engine/src/selfGovernanceRoutingEngine.ts`) carries three learned/adaptive layers on top of the base score-driven `decideRoute`:

- **Self-learning** — `applyDeliveryOutcome` updates per-peer trust/latency/counts; `calculateRouteScore` is the weighted blend.
- **Self-healing** — a peer whose trust drops below `TRUST_BLOCK_THRESHOLD` is quarantined ("blocked") with a `blockedUntil` cooldown. `selfHeal(now)` runs at the top of every `decideRoute` and rehabilitates peers back onto probation (trust → `REHAB_TRUST`) once the cooldown elapses; a recovering successful delivery rehabilitates immediately with an accelerated trust gain.
- **Traffic control** — relay candidates (never the direct target) get a sliding-window congestion penalty from `recentSends` so load spreads instead of pinning one relay.

**Why:** before this, a blocked peer was filtered out forever (no recovery path) and routing was greedy (always the single top-scored relay). These layers make the mesh recover lost nodes and load-balance.

**How to apply:**
- New per-peer transient maps (`recentSends`, `blockedUntil`) must stay bounded by the live peer set. `pruneTransientState(now)` (called from `selfHeal`) GCs them, and `removePeer(id)` is the lifecycle cleanup that clears all three maps. Any future per-peer map needs the same GC, or it leaks on peer churn.
- Governance counters are surfaced via `getGovernanceStats()` and the optional `MeshSnapshot.governance` fields (`rehabilitations`, `trafficShapedRoutes`, `quarantinedPeers`) — optional so older consumers don't break.
- These are still simulation/dev-grade; real BLE delivery outcomes must feed `applyDeliveryOutcome` on physical devices for the learning to reflect reality.
