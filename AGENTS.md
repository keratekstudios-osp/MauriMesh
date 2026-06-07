# AGENTS.md — MauriMesh Agent Protocol

All agents operating in this repository **must** read and follow this document before making any change.

---

## 1. Mandatory Pre-Change Checklist

Answer all eight questions before writing a single line of code:

1. **Category** — Which category (A / B / C) does this file belong to? (See `replit.md` for the full file-category table.)
2. **Blast radius** — If this change is wrong, what is the worst-case impact? (BLE down? Messages lost? Build broken? UI glitch only?)
3. **Reversibility** — Can this change be reverted in under 5 minutes without data loss?
4. **Dependencies** — Does anything in Category A or B depend on the behaviour being changed?
5. **Native boundary** — Does this change cross the JS↔Kotlin bridge or touch Expo prebuild output? If yes, a full `expo prebuild` + fresh Android build is required to validate.
6. **State integrity** — Could this change corrupt or silently drop data in `meshStore.ts` or the DB schema?
7. **Smallest change** — Is this the minimal change that achieves the goal, or is there opportunistic refactoring creeping in?
8. **Test signal** — What observable signal will confirm the change is correct? (Log line, UI element, BLE event, API response.)

**Before touching any file, run the checkpoint script to capture the current safe state:**

```bash
pnpm --filter @workspace/scripts run checkpoint -- --label "pre-<task-slug>"
```

---

## 2. Safe Order of Operations

When building or modifying features, follow this sequence strictly. Do **not** skip ahead or work across multiple layers simultaneously:

1. **Audit** — review what exists, read category assignments
2. **Inventory** — list every file that will be touched
3. **Design system** — tokens, colours, fonts (Category C only)
4. **Shared components** — reusable UI primitives (Category C)
5. **Login / Auth** — authentication screens and guards (Category A)
6. **Dashboard** — top-level navigation and layout (Category C)
7. **Chat** — messaging UI and store wiring (Category B/C)
8. **Settings** — user-facing config screens (Category C)
9. **Mesh UI** — visualisations and peer panels wired to live data (Category B)
10. **Diagnostics** — observability and debug tooling (Category B/C)
11. **Telemetry** — metrics sinks and aggregation (Category B)
12. **Operator** — admin/enterprise screens (Category C)
13. **Hardening** — Category A security and resilience changes
14. **Validation** — full typecheck, expo-doctor, export validation
15. **Build** — EAS / pnpm build (only after all gates pass)

---

## 3. The NEVER List

These actions are **strictly prohibited** at all times:

- **NEVER** modify BLE transport, GATT server, or Kotlin plugin files without explicit task-level justification and Category A sign-off.
- **NEVER** rename or remove fields in `meshStore.ts` without a matching migration for persisted data.
- **NEVER** change `app.json`, `eas.json`, `metro.config.js`, or `babel.config.js` without checking that `expo-doctor` still passes.
- **NEVER** touch more than one of {dependencies, config, UI, routing} in a single commit without running `--audit` first and resolving all warnings.
- **NEVER** trigger an EAS build or `expo prebuild` until all 7 post-change checks pass.
- **NEVER** leave a half-finished migration in `lib/db/` — schema and data migration must land together.
- **NEVER** hard-delete peers or messages from the store without a recovery path.
- **NEVER** commit with `--no-verify` or skip the checkpoint flow when making structural changes.
- **NEVER** use purple, orange, or violet in MauriMesh UI — brand palette is green (#39FF14), sky blue (#00BFFF), amber (#FACC15), red (#EF4444).

---

## 4. Break-Recovery Checklist

When a change breaks the build or runtime behaviour:

1. **Identify last changed files** — `git diff HEAD~1 --name-only`
2. **Identify the first error** — read the first error in the typecheck / build output; do not chase symptoms.
3. **Classify the cause**:
   - `TYPE` — TypeScript inference / contract mismatch
   - `IMPORT` — missing or circular import
   - `RUNTIME` — logic error visible only at runtime
   - `NATIVE` — JS↔Kotlin bridge contract broken
   - `CONFIG` — misconfigured `app.json` / `eas.json` / Vite config
4. **Revert smallest surface** — revert only the file(s) that introduced the first error:
   ```bash
   git checkout HEAD~1 -- path/to/broken/file.ts
   ```
5. **Re-test** — run `pnpm run typecheck`; confirm the error is gone before proceeding.
6. **Roll back further if needed** — if the error persists, use the rollback script to return to the last checkpoint:
   ```bash
   pnpm --filter @workspace/scripts run rollback
   ```

---

## 5. Pre-Change Audit (--audit flag)

Before a commit that touches multiple file categories, run:

```bash
pnpm --filter @workspace/scripts run checkpoint -- --audit
```

The audit flag inspects the working-tree diff and warns (but does not block) if it detects simultaneous changes across more than one of these high-risk categories:

| Category | Files matched |
|----------|--------------|
| `deps`   | `package.json`, `pnpm-lock.yaml`, `pnpm-workspace.yaml` |
| `config` | `app.json`, `eas.json`, `metro.config.js`, `babel.config.js`, `vite.config.*`, `tsconfig*.json` |
| `ui`     | `app/**/*.tsx`, `src/pages/**/*.tsx`, `src/components/**/*.tsx`, `artifacts/*/src/**/*.tsx` |
| `routing`| `App.tsx`, `_layout.tsx`, `app/(tabs)/`, `src/App.tsx`, `artifacts/*/src/App.tsx` |

If two or more categories are touched simultaneously, the audit prints a warning. Fix or explicitly acknowledge before committing.

---

## 6. Checkpoint / Rollback Quick Reference

```bash
# Capture current safe state before making changes
pnpm --filter @workspace/scripts run checkpoint -- --label "pre-ui-polish"

# Inspect working-tree diff across risk categories (no commit)
pnpm --filter @workspace/scripts run checkpoint -- --audit

# List recent checkpoint commits and optionally roll back
pnpm --filter @workspace/scripts run rollback

# Roll back to a specific SHA immediately (skips interactive prompt)
pnpm --filter @workspace/scripts run rollback -- --sha <sha>
```

---

## 7. Category A Sign-Off

Any change to a Category A file requires explicit task-level justification written in the commit message. The message must include:

```
[Category A change] <filename> — <reason>
Pre-change checklist: answered all 8 questions (see task description).
Blast radius: <description>
Reversibility: <yes/no — reason>
```

---

## 8. Reference

- Full file-category table → `replit.md` §"Foundation Protection Ruleset"
- Checkpoint script → `scripts/src/checkpoint.ts`
- Rollback script → `scripts/src/rollback.ts`
- npm script invocations → `scripts/package.json`
