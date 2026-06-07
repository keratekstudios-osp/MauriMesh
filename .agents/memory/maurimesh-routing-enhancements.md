---
name: MauriMesh routing engine enhancement layers
description: Adaptive layers (self-healing, traffic control) on the AI routing engine and the constraints they impose.
---

The AI routing engine carries adaptive layers on top of base score-driven routing:
self-learning (per-peer trust/latency learned from delivery outcomes), self-healing
(a peer whose trust collapses is quarantined with a cooldown, then autonomously
rehabilitated onto probation — or immediately on a recovering success), and traffic
control (relay candidates, never the direct target, get a congestion penalty so load
spreads instead of pinning one relay).

**Why:** before this, a quarantined peer was excluded forever (no recovery) and routing
was greedy (always the single top relay). The layers make the mesh recover lost nodes
and load-balance.

**How to apply:**
- These layers keep per-peer transient state (recent-send windows, quarantine timers).
  Any such map MUST be garbage-collected against the live peer set and on peer removal,
  or it leaks on peer churn. This was the one issue code review caught.
- New governance counters are exposed as OPTIONAL snapshot fields so older consumers
  don't break — keep that pattern when adding more.
- Still simulation/dev-grade: real BLE delivery outcomes must feed the learning on
  physical devices for the scores to reflect reality. Nothing here proves live BLE.
