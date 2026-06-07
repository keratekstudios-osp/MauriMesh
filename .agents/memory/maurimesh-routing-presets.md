---
name: MauriMesh routing sensitivity presets
description: How the user-tunable routing config is structured, applied, and persisted
---

# Routing sensitivity presets

Users tune how aggressively the mesh reroutes via three presets — `stable`,
`balanced`, `aggressive` — that map to a `Partial<RoutingEngineConfig>`.

**Key invariants (do not break):**
- `balanced` carries NO overrides (`{}`) so it resolves to `DEFAULT_ROUTING_CONFIG`
  exactly. **Why:** existing users who never touch the setting must see zero
  behaviour change.
- `MauriMeshP2PEngine.setConfig()` REPLACES overrides (it does not merge) and
  rebuilds the governance engine — so switching back to `balanced` ({}) cleanly
  restores defaults, and any peer-learning state resets on a config change (same
  tradeoff already accepted by `setLocalNodeId`).

**How to apply:**
- Pure preset logic lives in the engine package (`routingPresets.ts`) with NO RN
  deps, so it is testable in the node vitest env. Persistence
  (`@react-native-async-storage/async-storage`) lives separately in
  `lib/lib/routingConfig.ts` — keep that split or node tests break on the RN import.
- Persisted preset is applied to the shared `mauriMeshEngine` singleton on
  startup via `initRoutingConfig()` (called from `app/_layout.tsx` useEffect);
  invalid/missing stored values fall back to the default preset.
- To unit-test the AsyncStorage path in node, mock it with `vi.hoisted` + an
  in-memory Map (vi.mock factory cannot close over a normal const).
