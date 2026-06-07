#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "PATCH FRONTEND TO USE PUBLIC MESH API"
echo "============================================================"
echo ""

BASE="https://mauri-mesh-messenger.replit.app"

echo "1. Fix env base URLs"

for f in \
  .env \
  .env.local \
  artifacts/messenger-mobile/.env \
  artifacts/messenger-mobile/.env.local \
  artifacts/maurimesh/.env \
  artifacts/maurimesh/.env.local
do
  mkdir -p "$(dirname "$f")"

  cat > "$f" <<ENV
EXPO_PUBLIC_API_BASE_URL=$BASE
EXPO_PUBLIC_BACKEND_BASE_URL=$BASE
EXPO_PUBLIC_MESH_API_URL=$BASE
EXPO_PUBLIC_MESH_API_BASE=$BASE
VITE_API_BASE_URL=$BASE
VITE_BACKEND_BASE_URL=$BASE
API_BASE_URL=$BASE
BACKEND_BASE_URL=$BASE
ENV

  echo "Wrote $f"
done

echo ""
echo "2. Replace protected mesh activity paths with public paths"

FILES=$(find \
  src app artifacts/messenger-mobile artifacts/maurimesh \
  -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \) \
  -not -path "*/node_modules/*" \
  -not -path "*/.pnpm/*" \
  -not -path "*/dist/*" \
  -not -path "*/build/*" \
  2>/dev/null || true)

for file in $FILES; do
  if grep -q "/api/activity\|/api/mesh/packet/decision\|/activity\|/mesh/packet/decision" "$file"; then
    cp "$file" "$file.bak-public-mesh-api-$(date +%Y%m%d-%H%M%S)" || true

    sed -i \
      -e 's#/api/activity/ingest#/api/mesh-public/activity/ingest#g' \
      -e 's#/api/activity/intelligence#/api/mesh-public/activity#g' \
      -e 's#/api/activity#/api/mesh-public/activity#g' \
      -e 's#/api/mesh/packet/decision#/api/mesh-public/packet/decision#g' \
      -e 's#"/activity/ingest"#"/mesh-public/activity/ingest"#g' \
      -e 's#"/activity"#"/mesh-public/activity"#g' \
      -e 's#"/mesh/packet/decision"#"/mesh-public/packet/decision"#g' \
      "$file"

    echo "Patched: $file"
  fi
done

echo ""
echo "3. Show remaining protected API references"

grep -RIn \
  "/api/activity\|/api/mesh/packet/decision" \
  src app artifacts/messenger-mobile artifacts/maurimesh \
  --exclude-dir=node_modules \
  --exclude-dir=.pnpm \
  --exclude-dir=dist \
  --exclude-dir=build \
  2>/dev/null || echo "OK: no protected mesh API paths found."

echo ""
echo "4. Test live public route"

curl -i "$BASE/api/mesh-public/health" || true

echo ""
echo "============================================================"
echo "PATCH COMPLETE"
echo "Now redeploy/restart Messenger Mobile and MauriMesh Core System."
echo "============================================================"
