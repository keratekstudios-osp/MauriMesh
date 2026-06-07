---
name: MauriMesh dependency vuln remediation
description: How the 12-14 dependency vulnerabilities are fixed and why the lockfile can't be regenerated in-sandbox
---

# MauriMesh dependency vulnerability remediation

The dependency-vuln fixes live as a `overrides:` block in `pnpm-workspace.yaml`
(NOT in root `package.json`). Every advisory finding is pinned there:
drizzle-orm, esbuild, postcss, qs, vite, ws, uuid. `runDependencyAudit()` reads
the **lockfile**, so it keeps reporting findings until the lockfile is regenerated
to apply those overrides.

**Why the lockfile stays stale:** this sandbox cannot complete `pnpm install`
(even `--lockfile-only`). It dies via OOM kills, silent process death (empty/
vanishing log), or `500` infra errors — tried ~9 ways (nohup/setsid/foreground,
system pnpm 10.26.1 vs `npx pnpm@9.15.4`, `minimumReleaseAge` 0 vs 1440, freeing
Metro memory). Regeneration must happen in a normal-resource env (e.g. the deploy
build, which runs a fresh `pnpm install`).

**How to apply:** when asked to "fix vulnerabilities," confirm each override range
satisfies the audit's `fix.version` target, then rely on deploy/normal-env install
to regenerate the lockfile. Do NOT hand-edit the v9.0 lockfile to collapse
transitive uuid 3.x/7.x → 11.x — the snapshot graph + override-hash changes make
manual edits corrupt the lockfile.

**Gotcha — self-kill:** `pkill -f "pnpm"` / `pgrep -f "pnpm" | xargs kill` matches
the *current bash session's own command line* when that command also contains
"pnpm install", so it SIGKILLs itself (exit 137). Never pre-kill by a pattern that
appears in the same command that launches pnpm.
