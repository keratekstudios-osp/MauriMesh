# Threat Model

## Project Overview

MauriMesh is a pnpm monorepo with a publicly reachable Express API (`artifacts/api-server`), an Expo mobile client (`artifacts/messenger-mobile`), and a web frontend (`artifacts/maurimesh`). In production, the dominant security boundary is the public HTTP API plus the mobile bootstrap and session flow that obtains bearer tokens for that API.

For this scan, production assumptions are: the deployment is public on the internet, `NODE_ENV=production`, TLS is provided by the platform, and `artifacts/mockup-sandbox/**`, manuals/slides apps, backups, and `.migration-backup/**` are not deployed unless production code explicitly serves or imports them.

## Assets

- **Mesh session tokens** — bearer tokens created by `artifacts/api-server/src/routes/auth.ts` and trusted by `requireAuth`. Compromise or overly broad issuance exposes the authenticated API surface.
- **Client-shipped bootstrap credentials and configuration** — any value exposed through `EXPO_PUBLIC_*` in the mobile app must be treated as recoverable by end users and attackers.
- **Persistent mobile signing identity** — Ed25519 private keys generated and reused by `artifacts/messenger-mobile/lib/mesh/MeshCryptoIdentity.ts`. Compromise enables long-lived node impersonation.
- **Operational mesh state** — peers, routes, delivery ledgers, trust records, queue state, proof ledgers, notifications, readiness state, and runtime truth maintained by the API server. Tampering can disrupt routing, monitoring, readiness decisions, and audit integrity.
- **Session store and backend database records** — server-side session rows and persisted ledgers are security-sensitive because they gate identity and expose shared operational history.

## Trust Boundaries

- **Public client to API boundary** — all requests into `artifacts/api-server/src/app.ts` and `artifacts/api-server/src/routes/index.ts` cross from untrusted clients into trusted server code. Every sensitive route must enforce both authentication and authorization server-side.
- **Client bundle exposure boundary** — anything embedded in the mobile bundle, especially `EXPO_PUBLIC_*` values, must be treated as public and unsuitable as a server-trusted shared secret.
- **Mobile device storage boundary** — tokens and keys persisted on the device, including material stored via SecureStore, must be treated as recoverable on compromised devices. Device storage protects against casual exposure, not a determined local attacker.
- **API to database/runtime boundary** — the API reads and writes both PostgreSQL-backed records and process-wide runtime singletons. Any route that mutates or reads shared state must scope access deliberately; bearer-token presence alone is not enough.
- **Operator vs ordinary authenticated user boundary** — many operational routes are only safe for operators or for the owning node/session. The main production risk is overprivileged authenticated access, not just anonymous access.
- **Production vs demo boundary** — demo assets, backups, and mockup projects are out of scope unless production code imports, serves, or links them into the deployed application.

## Scan Anchors

- **Production entry points**: `artifacts/api-server/src/app.ts`, `artifacts/api-server/src/routes/index.ts`, `artifacts/messenger-mobile/app/**`, `artifacts/messenger-mobile/src/lib/**`, and any `artifacts/maurimesh/**` surface that calls live `/api/**` endpoints.
- **Highest-risk areas**: authenticated API routes under `artifacts/api-server/src/routes/*.ts`, shared runtime state under `artifacts/api-server/src/runtime/*.ts`, and the mobile login/bootstrap flow under `artifacts/messenger-mobile/app/login.tsx` and `artifacts/messenger-mobile/src/lib/api.ts`.
- **Primary production concerns**: session issuance, route-level authorization, ownership scoping for shared state, spoofable node identity fields, proof/readiness integrity, and exposure of global operational telemetry.
- **Usually ignore unless reachable**: `.migration-backup/**`, manuals, slide apps, tests, and `artifacts/mockup-sandbox/**`. Treat `artifacts/maurimesh/**` as in scope only where it is wired to the live backend.

## Threat Categories

### Spoofing

The application uses bearer tokens and mesh/node identifiers across many routes. The required guarantee is that session issuance actually proves a legitimate user, device, or node identity, and that client-supplied node IDs or usernames are not accepted as authoritative without server-side binding.

### Tampering

The API exposes write surfaces for peers, routes, receive pipelines, trust, queues, proofs, readiness state, and other shared operational records. The required guarantee is that only authorized actors can change shared state, and that attacker-controlled fields cannot redefine global routing, delivery, audit, or readiness data.

### Information Disclosure

Mesh topology, peer metadata, proof ledgers, delivery events, diagnostics, and readiness data are operationally sensitive even when they are not classic PII. The required guarantee is that these views are scoped to the caller's legitimate need-to-know and not broadly exposed to any authenticated session.

### Denial of Service

Because the deployment is public, any route that can create unbounded queue entries, monopolize singleton runtime state, or trigger expensive global work can be abused for availability impact. The required guarantee is bounded work, scoped mutations, and appropriate privilege checks.

### Elevation of Privilege

The main privilege-escalation risk is broken function-level authorization after authentication succeeds. A valid token must not automatically grant read or write access to fleet-wide operational state, operator-only controls, or shared readiness/proof mechanisms.
