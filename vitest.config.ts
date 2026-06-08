import { defineConfig } from "vitest/config";
import { createRequire } from "node:module";
import path from "node:path";

// tweetnacl / tweetnacl-util are pulled in by lib/lib/mesh/MeshCryptoIdentity but
// are not hoisted to the workspace root under pnpm, so vite cannot resolve them by
// bare specifier. The crypto-identity tests need the real signing primitives (no
// mocked crypto), so resolve each package explicitly: prefer normal node resolution
// (works automatically if the dep is ever hoisted/installed at the root), and only
// fall back to pnpm's public virtual-store location when that fails.
const require = createRequire(import.meta.url);
const pnpmModules = path.resolve(__dirname, "node_modules/.pnpm/node_modules");

function resolveDep(pkg: string): string {
  try {
    // Resolve to the package directory (dirname of its package.json).
    return path.dirname(require.resolve(`${pkg}/package.json`));
  } catch {
    return path.join(pnpmModules, pkg);
  }
}

export default defineConfig({
  resolve: {
    alias: {
      tweetnacl: resolveDep("tweetnacl"),
      "tweetnacl-util": resolveDep("tweetnacl-util"),
      // proof route tests import the router (which imports drizzle-orm); resolve
      // it from pnpm's virtual store the same way as tweetnacl.
      "drizzle-orm": resolveDep("drizzle-orm"),
    },
  },
  test: {
    globals: true,
    environment: "node",
    include: ["tests/**/*.test.ts"],
    reporters: ["default", "json"],
    outputFile: {
      json: "./qa-results/vitest-results.json",
    },
  },
});
