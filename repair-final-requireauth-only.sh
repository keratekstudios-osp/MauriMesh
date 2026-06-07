#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "FINAL REPAIR: CLEAN auth.ts + PATCH requireAuth.ts ONLY"
echo "============================================================"

ROUTES_INDEX="artifacts/api-server/src/routes/index.ts"
AUTH_TS="artifacts/api-server/src/routes/auth.ts"
REQ_AUTH="artifacts/api-server/src/middleware/requireAuth.ts"
BACKUP="backup-before-final-requireauth-only-$(date +%Y%m%d-%H%M%S)"

mkdir -p "$BACKUP"

[ -f "$AUTH_TS" ] && cp "$AUTH_TS" "$BACKUP/auth.ts.bak"
[ -f "$REQ_AUTH" ] && cp "$REQ_AUTH" "$BACKUP/requireAuth.ts.bak"
[ -f "$ROUTES_INDEX" ] && cp "$ROUTES_INDEX" "$BACKUP/routes-index.ts.bak"

echo ""
echo "1. Remove bad next() bypass from routes/auth.ts"

node <<'NODE'
const fs = require("fs");

const file = "artifacts/api-server/src/routes/auth.ts";

if (fs.existsSync(file)) {
  let text = fs.readFileSync(file, "utf8");

  text = text.replace(
    /\s*\/\/ MAURIMESH_PUBLIC_MESH_AUTH_BYPASS[\s\S]*?return next\(\);\s*\}\s*/g,
    "\n"
  );

  fs.writeFileSync(file, text);
  console.log("Cleaned auth.ts");
}
NODE

echo ""
echo "2. Patch middleware/requireAuth.ts with safe public bypass"

node <<'NODE'
const fs = require("fs");

const file = "artifacts/api-server/src/middleware/requireAuth.ts";

if (!fs.existsSync(file)) {
  throw new Error("requireAuth.ts not found");
}

let text = fs.readFileSync(file, "utf8");

text = text.replace(
  /\s*\/\/ MAURIMESH_PUBLIC_MESH_AUTH_BYPASS[\s\S]*?return next\(\);\s*\}\s*/g,
  "\n"
);

const bypass = `
  // MAURIMESH_PUBLIC_MESH_AUTH_BYPASS
  if (
    req &&
    (
      (req.path && req.path.startsWith("/mesh-public/")) ||
      (req.url && req.url.startsWith("/mesh-public/")) ||
      (req.path && req.path.startsWith("/api/mesh-public/")) ||
      (req.url && req.url.startsWith("/api/mesh-public/"))
    )
  ) {
    return next();
  }

`;

const patterns = [
  /export\s+function\s+requireAuth\s*\([^)]*req[^)]*res[^)]*next[^)]*\)\s*\{/,
  /function\s+requireAuth\s*\([^)]*req[^)]*res[^)]*next[^)]*\)\s*\{/,
  /export\s+const\s+requireAuth\s*=\s*\([^)]*req[^)]*res[^)]*next[^)]*\)\s*=>\s*\{/,
  /const\s+requireAuth\s*=\s*\([^)]*req[^)]*res[^)]*next[^)]*\)\s*=>\s*\{/
];

let patched = false;

for (const pattern of patterns) {
  if (pattern.test(text)) {
    text = text.replace(pattern, (m) => m + bypass);
    patched = true;
    break;
  }
}

if (!patched) {
  throw new Error("Could not safely patch requireAuth function");
}

fs.writeFileSync(file, text);
console.log("Patched requireAuth.ts");
NODE

echo ""
echo "3. Confirm meshPublicRouter is above requireAuth"

grep -n "meshPublicRouter\|router.use(requireAuth)\|Every route mounted below" "$ROUTES_INDEX"

echo ""
echo "4. Confirm bad next() is gone from auth.ts"

grep -n "MAURIMESH_PUBLIC_MESH_AUTH_BYPASS\|return next()" "$AUTH_TS" 2>/dev/null || echo "OK: no bad next() in auth.ts"

echo ""
echo "5. Confirm bypass exists only in requireAuth.ts"

grep -n "MAURIMESH_PUBLIC_MESH_AUTH_BYPASS\|return next()" "$REQ_AUTH"

echo ""
echo "6. Build/typecheck API server"

cd artifacts/api-server
npm run typecheck 2>/dev/null || npm run check 2>/dev/null || npx tsc -p tsconfig.json --noEmit
cd /home/runner/workspace

echo ""
echo "============================================================"
echo "REPAIR COMPLETE"
echo "Now Redeploy MauriMesh Core System."
echo "Then test:"
echo "curl -i https://mauri-mesh-messenger.replit.app/api/mesh-public/health"
echo "============================================================"
