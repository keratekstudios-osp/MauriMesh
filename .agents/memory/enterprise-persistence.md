---
name: Enterprise persistence layer (operators / accepted_docs / admin_commands)
description: Where operator/legal/admin records live and how their routes are secured
---
This Expo/React Native repo has a small Express simulation server (`server/`) plus a
Drizzle/Postgres layer (`lib/db/`). Persistent enterprise records (operator clearance,
legal-doc acceptance, admin command history) live in their own Drizzle schema and are
served by an Express router mounted under `/api/enterprise`.

**Auth rule (durable):** privileged `/api/enterprise/*` routes must be gated against a
valid, non-expired `mesh_sessions` row whose `role` is operator/admin. There is no
login flow in this server that mints operator sessions, so the gate is fail-closed —
without an operator session every route returns 401/403 by design.
**Why:** a code review flagged these admin actions (suspend operator, flush queue,
accept NDA) as broken access control when left open.

**Pipeline gotchas:**
- The server imports the db client by RELATIVE path because `@workspace/db` is not
  linked in node_modules here; its deps resolve from `lib/db/node_modules`.
- DB changes need BOTH a `drizzle-kit push` AND a committed hand-written SQL file in
  `lib/db/drizzle/` (push-based dev, file-based prod) — there is no `meta/_journal`.
- New API routes should be added to `lib/api-spec/openapi.yaml` and regenerated via
  the api-spec `codegen` script (orval) so the react-query + zod clients stay in sync.
