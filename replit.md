# Workspace

## Overview

pnpm workspace monorepo using TypeScript. Each package manages its own dependencies.

## Stack

- **Monorepo tool**: pnpm workspaces
- **Node.js version**: 24
- **Package manager**: pnpm
- **TypeScript version**: 5.9
- **API framework**: Express 5
- **Database**: PostgreSQL + Drizzle ORM
- **Validation**: Zod (`zod/v4`), `drizzle-zod`
- **API codegen**: Orval (from OpenAPI spec)
- **Build**: esbuild (CJS bundle)

## Key Commands

- `pnpm run typecheck` — full typecheck across all packages
- `pnpm run build` — typecheck + build all packages
- `pnpm --filter @workspace/api-spec run codegen` — regenerate API hooks and Zod schemas from OpenAPI spec
- `pnpm --filter @workspace/db run push` — push DB schema changes (dev only)
- `pnpm --filter @workspace/api-server run dev` — run API server locally

See the `pnpm-workspace` skill for workspace structure, TypeScript setup, and package details.

## Artifacts

### `artifacts/maurimesh/` — MauriMesh Core System (web)

The main messenger/chat frontend. A React + Vite app ported from the legacy project.

- **Preview path**: `/`
- **Theme**: Dark, green primary accent (`hsl(142 71% 45%)`), Inter + JetBrains Mono fonts
- **Routing**: wouter with `base={import.meta.env.BASE_URL}`
- **Key pages**: `Messenger` (main chat view), `Settings` (radio + system config)
- **Mesh API**: Connects to `VITE_MESH_API_BASE` (default `http://127.0.0.1:4300`) — the native Rust daemon endpoint
- **Key files**: `src/lib/maurimesh-client.ts`, `src/lib/maurimesh-bridge-contract.ts`, `src/lib/queryClient.ts`
- **Custom Vite plugin**: `vite-plugin-meta-images.ts` — updates OG/Twitter meta image URLs at build time

### `artifacts/api-server/` — API Server (api)

Express 5 backend. Currently has a health check route and the users schema from the original project.

- **Preview path**: `/api`
- **Routes**: `src/routes/routes.ts` (app routes), `src/routes/health.ts` (health check)
- **Storage**: `src/storage.ts` — in-memory `MemStorage` for users

### `artifacts/messenger-mobile/` — Messenger Mobile (Expo React Native)

Offline BLE mesh messenger for Android. Custom native BLE module (Kotlin) + React Native JS layer.

- **Preview path**: Expo Go / EAS Build (mobile only)
- **BLE UUIDs**: Service `7f9a0001-…`, Characteristic `7f9a0002-…`
- **State management**: Zustand (`lib/store/meshStore.ts`) — single source of truth for messages, peers, transport status
- **Transport layers**: BLE (react-native-ble-plx + Kotlin GATT server/advertiser) → HTTP bridge → store-and-forward queue
- **Packet routing**: `IntelligentMeshRouter` with multi-hop relay, TTL, dedup, trust scoring, dynamic priority (`packetPriority()`)
- **Packet types**: CHAT_MESSAGE, ACK, READ_ACK, ROUTE_BEACON, NODE_DISCOVERY, STORE_FORWARD, PIXEL_FRAME, CALL_INVITE
- **Native Kotlin plugin**: `plugins/android-src/com/maurimesh/ble/` — copied to `android/` during `expo prebuild` via `plugins/withMauriMeshBle.js`
  - `MauriMeshBleModule` — startPeripheral, stopPeripheral, startScan, stopScan, checkPermissions, requestPermissions
  - `MeshGattServerManager` — GATT peripheral server (receives incoming BLE writes)
  - `MeshAdvertiser` — BLE LE advertising
  - `MeshCentralClient` — BLE LE scanner (Kotlin-side, used by foreground service)
  - `MeshForegroundService` — Android foreground service; keeps BLE alive when app is backgrounded
  - `MeshBleEventEmitter` — emits MauriMeshBleMessageReceived, MauriMeshBleStatus, MauriMeshBlePeerSeen, MauriMeshBleError
- **Power management**: `lib/mesh/power-manager.ts` — AppState + expo-battery adaptive scan duty cycle (HIGH/BALANCED/LOW_POWER)
- **Stale peer expiry**: Peers not seen in 60 s are pruned every 15 s heartbeat interval
- **FlashList**: `@shopify/flash-list` replaces FlatList in the messenger screen; `MessageItem` is wrapped in `React.memo`
- **READ_ACK**: `onViewableItemsChanged` sends READ_ACK packets when other-sender messages become visible
- **Theme**: Dark/light toggle via `ThemeContext`; login screen, settings fully theme-aware
- **Key files**: `app/(tabs)/index.tsx`, `app/(tabs)/settings.tsx`, `lib/mesh/useMeshTransport.ts`, `lib/mesh/useBleTransport.ts`, `lib/store/meshStore.ts`

### `artifacts/mockup-sandbox/` — Canvas (design)

Pre-existing mockup/design sandbox. Not modified during port.

## Known warnings

These warnings appear on `pnpm install` but cannot be resolved without breaking changes and are safe to ignore:

- `@ungap/structured-clone@1.3.0` — deprecated (used transitively by `@stardazed/streams-text-encoding`); no replacement required for Expo 54.
- `glob@7/10`, `inflight`, `rimraf@3`, `text-encoding`, `uuid@3/7` — deprecated transitive subdependencies pulled in by Expo/React Native tooling; not directly controlled by this project.

## Libraries

- `lib/db/` — Drizzle schema (users table), DB connection
- `lib/api-spec/` — OpenAPI spec (health check only)
- `lib/api-client-react/` — Generated React Query hooks
- `lib/api-zod/` — Generated Zod schemas

## Foundation Protection Ruleset

Every agent session must classify each file it intends to touch before making any change, then run the pre-change checklist, make the change, run the post-change checklist, and only trigger a build once all quality gates pass.

### File Categories

#### Category A — Foundation (never touch carelessly)

These systems are load-bearing. A mistake here can silently break BLE connectivity, message delivery, or the entire build pipeline. Require the highest scrutiny.

- **BLE layer** — `lib/mesh/useBleTransport.ts`, Kotlin plugin files under `plugins/android-src/com/maurimesh/ble/` (`MauriMeshBleModule`, `MeshGattServerManager`, `MeshAdvertiser`, `MeshCentralClient`, `MeshForegroundService`, `MeshBleEventEmitter`), and `plugins/withMauriMeshBle.js`
- **Packet routing & relay** — `IntelligentMeshRouter`, `lib/mesh/useMeshTransport.ts`, TTL/dedup logic, `packetPriority()`
- **ACK & delivery receipts** — ACK, READ_ACK packet handling; `onViewableItemsChanged` READ_ACK emission
- **Fragmentation** — any packet-splitting/reassembly logic
- **Auth & access control** — login guards, session management, any route protection
- **Native module bridge** — `MauriMeshBleModule` JS↔Kotlin bridge, event emitter registration
- **Expo / EAS config** — `app.json`, `eas.json`, `expo-plugins`, `withMauriMeshBle.js`, `metro.config.js`
- **State store** — `lib/store/meshStore.ts` (Zustand single source of truth for messages, peers, transport)
- **Power manager** — `lib/mesh/power-manager.ts` (adaptive scan duty cycle)

#### Category B — Integration (edit with care)

These files wire Category A systems together or expose them to the UI. Changes here can have non-obvious ripple effects.

- **Mesh API client** — `src/lib/maurimesh-client.ts`, `src/lib/maurimesh-bridge-contract.ts`, `src/lib/queryClient.ts`
- **API routes** — `artifacts/api-server/src/routes/routes.ts`, `artifacts/api-server/src/routes/health.ts`
- **DB schema & migrations** — `lib/db/` (Drizzle schema, push scripts)
- **OpenAPI spec & codegen outputs** — `lib/api-spec/`, `lib/api-client-react/`, `lib/api-zod/`
- **Stale-peer expiry** — heartbeat/prune logic (60 s peer TTL, 15 s interval)
- **Peer discovery & advertisement** — public-key advertisement, friend-discovery entries
- **Store-and-forward queue** — STORE_FORWARD packet type handling

#### Category C — Visual / UI (lower risk, standard care)

Presentation-only code. Changes here should not affect transport, routing, or data integrity.

- **Screens & components** — `app/(tabs)/index.tsx`, `app/(tabs)/settings.tsx`, `MessageItem`, `FlashList` wrapper
- **Theme system** — `ThemeContext`, dark/light toggle, login screen styling, settings styling
- **Web frontend** — `artifacts/maurimesh/src/` pages and components (Messenger, Settings views)
- **Canvas / mockup sandbox** — `artifacts/mockup-sandbox/`
- **Meta images plugin** — `vite-plugin-meta-images.ts`

---

### Mandatory Pre-Change Checklist (8 questions)

Answer all eight before writing a single line of code:

1. **Category** — Which category (A / B / C) does this file belong to?
2. **Blast radius** — If this change is wrong, what is the worst-case impact (BLE down? messages lost? build broken? UI glitch only)?
3. **Reversibility** — Can this change be reverted in under 5 minutes without data loss?
4. **Dependencies** — Does anything in Category A or B depend on the behaviour I am about to change?
5. **Native boundary** — Does this change cross the JS↔Kotlin bridge or touch Expo prebuild output? If yes, a full `expo prebuild` + fresh Android build is required to validate.
6. **State integrity** — Could this change corrupt or silently drop data in `meshStore.ts` or the DB schema?
7. **Smallest change** — Am I making the minimal change that achieves the goal, or am I refactoring opportunistically?
8. **Test signal** — What observable signal will confirm the change is correct (log line, UI element, BLE event, API response)?

### Mandatory Post-Change Checklist (7 verification points)

Complete all seven before declaring the task done:

1. **TypeScript** — `pnpm run typecheck` passes with zero new errors.
2. **Lint** — No new lint warnings introduced in changed files.
3. **Packet flow** — If Category A was touched, manually verify or describe the expected BLE packet flow end-to-end.
4. **State store** — `meshStore.ts` shape is unchanged (no field renames, no silent drops) unless the task explicitly required a schema change.
5. **Native module** — If the Kotlin plugin or `withMauriMeshBle.js` was modified, confirm `expo prebuild` still completes without error and the plugin copies correctly into `android/`.
6. **No regression** — Any file listed in Category A that was *not* supposed to be modified is byte-for-byte identical to before the change.
7. **Commit message** — The `.local/.commit_message` accurately describes every file changed and why.

### Build Gate

A build (EAS Build / `expo prebuild` / `pnpm run build`) must **not** be triggered until:

- [ ] All 8 pre-change questions are answered.
- [ ] All 7 post-change verification points pass.
- [ ] No Category A file was modified without explicit task-level justification.
- [ ] TypeScript reports zero errors (`pnpm run typecheck`).

If any gate fails, fix the issue first — do not submit a build hoping it will pass.

### Final Rule

> **Protect the working foundation above all else. Enhance without destruction.**

---

## Agent Safety Protocol

Before making **any** modification to this repository, every agent must:

1. **Read `AGENTS.md`** — the authoritative protocol document encoding the mandatory pre-change checklist, safe order of operations, the NEVER list, the break-recovery checklist, and cross-category audit rules.

2. **Run the checkpoint script** to capture the current safe state:
   ```bash
   pnpm --filter @workspace/scripts run checkpoint -- --label "pre-<task-slug>"
   ```

3. **Run the pre-change audit** when touching multiple file types:
   ```bash
   pnpm --filter @workspace/scripts run checkpoint -- --audit
   ```

4. **Roll back** to the last checkpoint if a change breaks the build:
   ```bash
   pnpm --filter @workspace/scripts run rollback
   ```

Scripts live in `scripts/src/checkpoint.ts` and `scripts/src/rollback.ts`.
See `AGENTS.md` for full usage and the complete protocol.
