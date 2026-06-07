#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "DIRECT PATCH requireAuth.ts ABOVE token LINE"
echo "============================================================"
echo ""

REQ_AUTH="artifacts/api-server/src/middleware/requireAuth.ts"
AUTH_TS="artifacts/api-server/src/routes/auth.ts"
ROUTES_INDEX="artifacts/api-server/src/routes/index.ts"
BACKUP="backup-before-direct-token-line-patch-$(date +%Y%m%d-%H%M%S)"

mkdir -p "$BACKUP"

cp "$REQ_AUTH" "$BACKUP/requireAuth.ts.bak"
cp "$AUTH_TS" "$BACKUP/auth.ts.bak"
cp "$ROUTES_INDEX" "$BACKUP/routes-index.ts.bak"

echo "1. Clean bad bypass from routes/auth.ts"

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
  console.log("Cleaned routes/auth.ts");
}
NODE

echo ""
echo "2. Direct patch middleware/requireAuth.ts before token extraction"

node <<'NODE'
const fs = require("fs");

const file = "artifacts/api-server/src/middleware/requireAuth.ts";
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

const target = 'const token = authHeader.startsWith("Bearer ")';

if (!text.includes(target)) {
  console.error("Could not find exact token line.");
  console.error("Showing requireAuth.ts:");
  console.error(text.slice(0, 4000));
  process.exit(1);
}

text = text.replace(target, bypass + target);

fs.writeFileSync(file, text);
console.log("Direct patched requireAuth.ts above token extraction.");
NODE

echo ""
echo "3. Confirm route order is still correct"

grep -n "meshPublicRouter\|router.use(requireAuth)\|Every route mounted below" "$ROUTES_INDEX"

echo ""
echo "4. Confirm bypass location"

grep -n "MAURIMESH_PUBLIC_MESH_AUTH_BYPASS\|const token = authHeader" "$REQ_AUTH"

echo ""
echo "5. Confirm no bad next patch remains in routes/auth.ts"

grep -n "MAURIMESH_PUBLIC_MESH_AUTH_BYPASS\|return next()" "$AUTH_TS" 2>/dev/null || echo "OK: routes/auth.ts is clean."

echo ""
echo "6. Typecheck API server"

cd artifacts/api-server
npm run typecheck 2>/dev/null || npm run check 2>/dev/null || npx tsc -p tsconfig.json --noEmit
cd /home/runner/workspace

echo ""
echo "============================================================"
echo "PATCH COMPLETE"
echo "Now redeploy MauriMesh Core System."
echo ""
echo "After deploy, test:"
echo "curl -i https://mauri-mesh-messenger.replit.app/api/mesh-public/health"
echo "============================================================"
