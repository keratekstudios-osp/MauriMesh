---
name: MauriMesh server unit-test pattern (DB-free extraction)
description: Why server route modules that import drizzle/db can't be imported in vitest, and how to make their logic testable.
---

# Server route logic must be extracted DB-free to be unit-testable

Vitest in this repo cannot import any module that (transitively) imports
`drizzle-orm` or the Postgres pool (`lib/db/src/index`): pnpm does not hoist
`drizzle-orm` to the root `node_modules`, so vite fails with "Cannot find
package 'drizzle-orm'". Importing the db module also opens a real Pool at import
time (side effect).

**Rule:** put pure validation/shaping logic in its own module with NO drizzle /
no `lib/db` import (e.g. `server/proofEvidence.ts`), and have the Express router
(`server/proofRoutes.ts`) import it. Unit tests import only the pure module.

**Why:** the only vitest-resolvable deps are aliased explicitly in
`vitest.config.ts` (see the tweetnacl alias note in that file). Rather than alias
drizzle, keep DB out of the unit under test.

**How to apply:** for any new Express route backed by Drizzle, split out the
request→row normalization (and any business rules) into a DB-free file and test
that. Route-level POST/GET behavior currently has no automated harness
(supertest is not a dependency); it is smoke-tested with curl against the running
server on port 5000.
