# MauriMesh Contributing Guidelines

## TypeScript Import Style in Shared Libs

### No `.js` extensions in relative imports inside `lib/`

**Rule:** All relative imports inside `lib/packet-engine/src/` and `lib/mauri-mesh-engine/src/` must **not** have a `.js` extension.

```typescript
// ✓ Correct
import { PacketEngine } from "./PacketEngine";
export * from "./schema";

// ✗ Wrong — crashes the Expo Metro bundler
import { PacketEngine } from "./PacketEngine.js";
export * from "./schema.js";
```

**Why:** TypeScript-ESM style `"./foo.js"` imports work in Node.js and Vite (which substitute `.js` → `.ts` during resolution), but Metro bundler reads the raw `.ts` source files via each lib's `package.json` `exports` field and **does not** perform extension substitution. Any `.js`-suffixed relative import will immediately crash the Expo bundler with `Unable to resolve ./foo.js`.

**History:** This caused a production Metro bundler crash (Task #178). The fix was stripping `.js` from all relative imports. Task #197 added this check to prevent regression.

**How to verify your imports are clean:**

```bash
pnpm run check:no-js-ext
```

This runs `scripts/src/check-no-js-extensions.ts`, which scans both lib source trees and exits 1 if any `.js`-suffixed relative imports are found.

**When this applies:** Only relative imports (`"./foo"`, `"../bar"`). Absolute package imports (`"zod"`, `"@workspace/db"`) are unaffected.

---

## Running the Check in CI / Pre-merge

Add `pnpm run check:no-js-ext` to your CI pipeline or pre-push hook. It is safe to run alongside `pnpm run typecheck`.

```bash
# Recommended pre-merge sequence for lib changes:
pnpm run check:no-js-ext   # Guard: no .js-extension imports
pnpm run typecheck          # Full workspace typecheck
```

---

## Module Resolution

- `tsconfig.base.json` uses `"moduleResolution": "bundler"` — do not change this.
- Lib packages (`lib/*`) are composite TypeScript projects. Do not make them leaf packages or add declaration emit to artifact packages.
- See the `pnpm-workspace` skill in `.local/skills/pnpm-workspace/SKILL.md` for the full workspace structure guide.
