# Route Safety Persistence

Marker:
- `ROUTE_SAFETY_PERSISTENCE_MOBILE_20260608_A`
- `ROUTE_SAFETY_PERSISTENCE_SERVER_20260608_A`

## Goal

Keep route safety protection alive across mobile/API restarts.

## What persists

Persistent:
- active blacklist entries
- route key
- reason
- failure count
- blacklist time
- expiry time

Not persisted:
- full seen-packet cache
- duplicate packet cache

The seen-packet cache stays memory-only because it can grow too large.

## Mobile

Files:
- `artifacts/messenger-mobile/lib/mesh/MeshRouteSafetyGuard.ts`
- `artifacts/messenger-mobile/lib/mesh/MeshRouteSafetyBlacklistStore.ts`

Uses AsyncStorage-compatible persistence. This can be swapped to SQLite later without changing the guard contract.

## Server

Files:
- `artifacts/api-server/src/runtime/RouteSafetyEngine.ts`
- `artifacts/api-server/src/runtime/RouteSafetyBlacklistStore.ts`
- `lib/db/src/schema/mesh.ts`

The runtime store uses a DB-safe JSONL fallback and adds a Drizzle schema table for the dedicated DB path.

## Completion proof

1. Force route failure until blacklist threshold is crossed.
2. Confirm route is blocked.
3. Restart mobile app or API server.
4. Confirm route remains blocked until cooldown expires.
5. Confirm duplicate seen-cache does not persist across restart.
