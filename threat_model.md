# Threat Model

## Project Overview

MauriMesh is currently deployed as a public Replit autoscale service that runs `server/index.ts` and serves a very small Express API. The repository also contains an Expo mobile client under `app/` plus shared TypeScript libraries under `lib/` and `src/`. For this scan, the production-relevant security boundary is the public HTTP API exposed by `server/index.ts` and the mobile application's handling of long-lived local secrets used for mesh identity and any local authentication features.

Production assumptions for this scan: the deployment is public on the internet, `NODE_ENV=production`, TLS is provided by the platform, and mockup/demo assets, backups, and legacy route files are out of scope unless they are imported into the deployed entrypoint. In particular, `server/index.ts` is authoritative for current server reachability; `server/maurimeshIntelligentApiDriver.cjs`, `server/maurimeshPublicIntelligenceRoutes.cjs`, backups, and `.migration-backup/**` should usually be ignored unless a live import path is found.

## Assets

- **Public deployment integrity and availability** — the live Express service is internet-facing. Even a small unauthenticated API can leak operational state or be abused for denial-of-service if it exposes shared mutable state or expensive work.
- **Mobile mesh signing identity** — the Ed25519 keypair created in `lib/lib/mesh/MeshCryptoIdentity.ts` is the app's long-lived node identity. Theft lets an attacker impersonate the device to peers and forge signed mesh packets.
- **Locally stored authenticators and user data** — any passphrases, session markers, peer registries, route metrics, message queues, or other data persisted with AsyncStorage on the mobile client are recoverable on a compromised device and must be classified by sensitivity.
- **Operational mesh telemetry** — node lists, route state, governance counters, and activity/proof data can reveal internal topology and runtime behavior even when they are not traditional PII.

## Trust Boundaries

- **Public client to Express API** — all requests into `server/index.ts` come from untrusted clients. Any sensitive route must enforce authentication and authorization server-side.
- **Mobile device storage boundary** — AsyncStorage and other client-local persistence are not a trusted secret store. They protect against casual loss, not malware, device compromise, backup extraction, or a determined local attacker.
- **Mesh peer trust boundary** — packets received from other devices are attacker-controlled until signature validation and message validation succeed. Node identifiers and packet metadata are not authoritative on their own.
- **Deployed code vs dormant repo code boundary** — many files in this repo are legacy, backup, or demo artifacts. Only code reachable from the deployed entrypoint or shipped mobile bundle should drive vulnerability reporting.

## Scan Anchors

- **Production entry points**: `server/index.ts`, Expo routes under `app/**`, and shared mobile/runtime helpers imported from `src/**` and `lib/**`.
- **Highest-risk areas**: `lib/lib/mesh/MeshCryptoIdentity.ts`, `lib/lib/mesh/useMeshTransport.ts`, local session/auth helpers under `lib/lib/auth/session.ts`, and any client helpers that call the live deployment.
- **Public vs authenticated surfaces**: the current server API appears public and read-only; the mobile app currently relies primarily on local state rather than a proven server-authenticated session model.
- **Usually ignore unless reachable**: `server/*.cjs` legacy routers, `src/**/*.bak-*`, backup directories, `.migration-backup/**`, and mock/demo-only surfaces not imported by `server/index.ts` or current app routes.

## Threat Categories

### Spoofing

The most important spoofing risk is mesh identity theft or misuse. The system must ensure that only the legitimate device controls its long-lived signing key, and that peer/node identifiers are not trusted without cryptographic verification. Client-supplied node IDs alone must never be treated as proof of identity.

### Tampering

Mesh packets, route state, and shared operational data all cross untrusted boundaries. The system must validate packet structure, bind signatures to the correct identity, and prevent untrusted inputs from silently rewriting shared state or decision logic.

### Information Disclosure

The project exposes runtime topology and stores sensitive client-side state. The required guarantee is that secrets such as private keys and user authenticators are not persisted in easily extractable plaintext client storage, and that public APIs do not reveal more operational state than intended.

### Denial of Service

Because the deployment is public, any internet-reachable route must do bounded work and avoid attacker-controlled amplification. The mobile app must also defend against unbounded local caches and malformed packets that could degrade the user experience or exhaust resources.

### Elevation of Privilege

The main elevation risk is not classic server-side RBAC today; it is gaining stronger identity or access than intended by stealing client-side secrets or bypassing local-only trust assumptions. Long-lived authenticators and signing keys must therefore be protected as security-critical material, not treated as ordinary app preferences.
