/**
 * check-no-js-extensions.ts
 *
 * Guards against .js-suffixed relative imports being reintroduced in the
 * shared libs (lib/packet-engine, lib/mauri-mesh-engine).
 *
 * Metro bundler cannot resolve "./foo.js" → "./foo.ts" substitution, so any
 * relative import ending in ".js" inside these libs will crash the Expo bundler.
 *
 * Usage:
 *   pnpm --filter @workspace/scripts run check-no-js-ext
 *   OR via root shortcut:
 *   pnpm run check:no-js-ext
 *
 * Exit 0 = clean. Exit 1 = violations found (prints each offending file:line).
 */

import { readdirSync, readFileSync, statSync } from "node:fs";
import { dirname, join, relative } from "node:path";
import { fileURLToPath } from "node:url";

// ── Config ────────────────────────────────────────────────────────────────────

// Anchor to workspace root regardless of what cwd is when pnpm invokes this.
// Script lives at scripts/src/check-no-js-extensions.ts → ../../ = workspace root.
const WORKSPACE_ROOT = join(dirname(fileURLToPath(import.meta.url)), "../..");

const SCAN_ROOTS = [
  join(WORKSPACE_ROOT, "lib/packet-engine/src"),
  join(WORKSPACE_ROOT, "lib/mauri-mesh-engine/src"),
];

// Matches: import ... from "./foo.js" or export ... from "./foo.js"
// Also catches: } from "./foo.js" (multi-line imports)
const JS_EXT_IMPORT = /from\s+["'](\.[^"']*\.js)["']/g;

// ── Walker ────────────────────────────────────────────────────────────────────

function walkTs(dir: string): string[] {
  const results: string[] = [];
  for (const entry of readdirSync(dir)) {
    const full = join(dir, entry);
    if (statSync(full).isDirectory()) {
      results.push(...walkTs(full));
    } else if (entry.endsWith(".ts") || entry.endsWith(".tsx")) {
      results.push(full);
    }
  }
  return results;
}

// ── Main ──────────────────────────────────────────────────────────────────────

const cwd = process.cwd();
const violations: string[] = [];

for (const root of SCAN_ROOTS) {
  let files: string[];
  try {
    files = walkTs(root);
  } catch {
    console.warn(`⚠  Skipping ${root} — directory not found.`);
    continue;
  }

  for (const file of files) {
    const src   = readFileSync(file, "utf8");
    const lines = src.split("\n");

    lines.forEach((line, idx) => {
      JS_EXT_IMPORT.lastIndex = 0;
      const match = JS_EXT_IMPORT.exec(line);
      if (match) {
        const rel = relative(cwd, file);
        violations.push(`  ${rel}:${idx + 1}  →  ${match[1]}`);
      }
    });
  }
}

if (violations.length === 0) {
  console.log("✓  check-no-js-extensions: no .js-suffixed relative imports found.");
  process.exit(0);
} else {
  console.error(
    `✗  check-no-js-extensions: ${violations.length} violation(s) found.\n` +
    `   Metro bundler cannot resolve .js → .ts. Remove the .js suffix from each import below:\n`
  );
  for (const v of violations) console.error(v);
  console.error(
    "\n   See docs/CONTRIBUTING.md for context on why .js extensions are forbidden in lib imports."
  );
  process.exit(1);
}
