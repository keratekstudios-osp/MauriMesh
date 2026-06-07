---
name: MauriMesh wiring map
description: Which screens are live-wired to the API and which use simulation fallback.
---

## Live-wired screens (7)
| Screen | API calls |
|--------|-----------|
| login.tsx | POST /auth/login |
| chat.tsx | POST /mesh/ai-governance/send |
| diagnostic-logs.tsx | GET /mesh/events |
| living-mesh.tsx | GET /mesh/status + aiMeshClient (engine) |
| mesh/ble-discovery.tsx | POST /mesh/ai-governance/peer |
| mesh-status.tsx | GET /mesh/status |
| network/diagnostics.tsx | GET /healthz |

dashboard.tsx now also polls GET /mesh/status for the header status pill (added during audit).

## Simulation-only screens (63)
By design — offline-first platform. Screens like calling/, trust/, platform/, settings/ use hardcoded demo data or the local mauri-mesh-engine singleton. This is intentional.

## Architecture layers
- `src/lib/api.ts` — raw apiGet/apiPost with URL resolution
- `src/lib/meshClient.ts` — wraps apiGet("/api/mesh/status"), falls back to simulated nodes/routes
- `src/lib/aiMeshClient.ts` — thin bridge to @workspace/mauri-mesh-engine singleton
- `contexts/BackendConfigContext.tsx` — persists URL, calls setRuntimeApiBase()
- `lib/session.ts` — AsyncStorage token/session management

## DB tables (live)
mesh_peers, mesh_events, mesh_sessions, users, qa_history
All Drizzle ORM — camelCase field names map to snake_case columns automatically.
