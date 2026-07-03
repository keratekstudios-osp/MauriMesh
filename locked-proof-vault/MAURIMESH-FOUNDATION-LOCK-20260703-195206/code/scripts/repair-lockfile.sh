#!/usr/bin/env bash
set -euo pipefail

# Stop broken install state
rm -rf node_modules

# Check package manager version
corepack enable
corepack prepare pnpm@9.15.4 --activate

# Regenerate lockfile so package.json overrides match pnpm-lock.yaml
pnpm install --no-frozen-lockfile

# Verify frozen install now passes locally
pnpm install --frozen-lockfile

# Commit the repaired lockfile
git add package.json pnpm-lock.yaml
git commit -m "fix pnpm lockfile overrides mismatch" || true
git push
