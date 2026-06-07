---
name: MauriMesh operator role
description: How operator privilege is issued and enforced in the API server session system.
---

## Rule
Sessions are issued with `role = "user"` by default. An operator session requires supplying a valid `MESH_OPERATOR_KEY` in the login body (separate from `MESH_API_KEY`).

## How to apply
- `POST /auth/login` accepts optional `operatorKey` field; sets `role="operator"` when it matches the `MESH_OPERATOR_KEY` env var (timing-safe compare).
- `requireOperator` middleware in `artifacts/api-server/src/middleware/requireOperator.ts` returns 403 if `req.meshSession.role !== "operator"`.
- Operator-only routes: `POST /qa/run`, `POST /qa/history`, `GET /qa/run/:runId/stream`, `GET /store-forward/queue`, `GET /notifications/mesh/history`, `POST /integrity/record`, `POST /errors/resolve`.
- Ownership-scoped (non-operator): `POST /store-forward/mark-delivered` (toPeerId=nodeId), `POST /notifications/mesh/ack` (toPeerId=nodeId), `POST /calls/accept|reject|end` (initiatorNodeId), `GET|POST /proof/two-phone/*` (session.phoneId=nodeId).
- Trust: `manual_boost` and `manual_reduce` event types are operator-only; other observation events are open to any authenticated user.

**Why:** Any bearer token holder previously had full administrative capabilities including spawning server-side QA runs, poisoning history, reading all users' queued message bodies, and mutating global state (calls, proof sessions, trust scores, error records).
