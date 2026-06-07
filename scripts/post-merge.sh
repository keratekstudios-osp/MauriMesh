#!/bin/bash
set -e

# Post-merge setup: install dependencies and sync the database schema.
# Runs non-interactively (stdin is closed) and must be idempotent.

# Do not use --frozen-lockfile: a merged task may change package.json
# (e.g. dependency overrides) without regenerating the lockfile, and we want
# the install to reconcile rather than hard-fail.
npx --yes pnpm@9.15.4 install

# Push the Drizzle schema only when a database is configured. Use --force so it
# never waits for interactive confirmation (stdin is closed during post-merge).
if [ -n "$DATABASE_URL" ]; then
  npx --yes pnpm@9.15.4 --filter @workspace/db run push-force
fi
