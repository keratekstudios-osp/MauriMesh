---
name: MauriMesh DB schema (mixed dialects)
description: lib/db/src/schema/mesh.ts mixes Postgres and SQLite drizzle dialects in one file — editing it risks import collisions.
---

- mesh.ts holds nearly all tables as `pgTable` (mesh_peers, mesh_events,
  mesh_users, mesh_sessions, trust_records, store_forward_queue, proof_ledger,
  runtime_errors, api_activity_events) PLUS one `sqliteTable`
  (`route_safety_blacklist`, added by the route-safety task).

- **Dual-dialect import hazard:** the file imports from BOTH
  `drizzle-orm/pg-core` and `drizzle-orm/sqlite-core`. Both export `text` and
  `integer`. Importing both unaliased = TS2300 duplicate-identifier (breaks
  typecheck/build). Fix: alias the sqlite ones (`text as sqliteText`,
  `integer as sqliteInteger`) and use the aliases only inside sqliteTable defs;
  leave pg-core `text`/`integer` unaliased for the pgTables.
  **Why:** a merged task re-imported pg names without aliasing and broke the
  shared schema typecheck. **How to apply:** any time you add columns to either
  dialect's tables in this file, keep the sqlite/pg helper names distinct.

- proofLedger has NO `type`/jsonb column. Evidence "type" is stored in
  `eventType` and the full JSON verbatim in `rawLogExcerpt` (text). Don't assume
  a jsonb/type column exists when writing proof rows.
