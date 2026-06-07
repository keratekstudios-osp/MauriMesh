#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH API DRIVER URL FIX + INTELLIGENCE TEST"
echo "============================================================"
echo ""

ROOT="$(pwd)"
BACKUP="$ROOT/backup-before-api-url-driver-fix-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP"

echo "1. Find real API driver files without pnpm/node_modules noise"
echo ""

grep -RIn \
  "EXPO_PUBLIC_API_BASE_URL\|EXPO_PUBLIC_BACKEND_BASE_URL\|VITE_API_BASE_URL\|VITE_BACKEND_BASE_URL\|fetch(.*api\|/api/activity\|api/activity\|baseURL\|API_BASE_URL" \
  "$ROOT/src" "$ROOT/app" "$ROOT/server" "$ROOT/backend" "$ROOT/api" "$ROOT/artifacts" \
  --exclude-dir=node_modules \
  --exclude-dir=.git \
  --exclude-dir=.pnpm \
  --exclude-dir=.local \
  --exclude-dir=android \
  --exclude-dir=ios \
  2>/dev/null | tee maurimesh-clean-api-driver-results.log || true

echo ""
echo "2. Fix env files: API base must be ROOT URL, not /api URL"
echo ""

BACKEND_ROOT="https://mauri-mesh-messenger.replit.app"

for ENV_FILE in \
  "$ROOT/.env" \
  "$ROOT/.env.local" \
  "$ROOT/artifacts/api-server/.env" \
  "$ROOT/artifacts/api-server/.env.local" \
  "$ROOT/artifacts/maurimesh/.env" \
  "$ROOT/artifacts/maurimesh/.env.local" \
  "$ROOT/artifacts/messenger-mobile/.env" \
  "$ROOT/artifacts/messenger-mobile/.env.local"
do
  if [ -f "$ENV_FILE" ]; then
    mkdir -p "$BACKUP/$(dirname "$ENV_FILE" | sed 's#^/##')"
    cp "$ENV_FILE" "$BACKUP/$(echo "$ENV_FILE" | sed 's#^/##').bak" 2>/dev/null || true
  fi

  mkdir -p "$(dirname "$ENV_FILE")"

  cat > "$ENV_FILE" <<ENV
EXPO_PUBLIC_API_BASE_URL=$BACKEND_ROOT
EXPO_PUBLIC_BACKEND_BASE_URL=$BACKEND_ROOT
VITE_API_BASE_URL=$BACKEND_ROOT
VITE_BACKEND_BASE_URL=$BACKEND_ROOT
API_BASE_URL=$BACKEND_ROOT
BACKEND_BASE_URL=$BACKEND_ROOT
ENV

  echo "Wrote $ENV_FILE"
done

echo ""
echo "3. Patch common API client files so base URL never ends with /api"
echo ""

API_FILES="$(find "$ROOT/src" "$ROOT/app" "$ROOT/artifacts" -type f -name "api.ts" -o -name "api.js" -o -name "*api*.ts" -o -name "*api*.js" \
  -not -path "*/node_modules/*" \
  -not -path "*/.git/*" \
  -not -path "*/.pnpm/*" \
  -not -path "*/.local/*" \
  2>/dev/null || true)"

for FILE in $API_FILES; do
  if grep -q "EXPO_PUBLIC_API_BASE_URL\|VITE_API_BASE_URL\|API_BASE_URL\|/api/activity\|/api/" "$FILE"; then
    SAFE_NAME="$(echo "$FILE" | sed 's#[/:]#_#g')"
    cp "$FILE" "$BACKUP/$SAFE_NAME.bak" 2>/dev/null || true

    perl -0pi -e 's#\.replace/\\\/\$/, ""#.replace(/\/$/, "").replace(/\/api$/, "")#g' "$FILE" 2>/dev/null || true
    perl -0pi -e 's#replace/\\\/\$/, ""#replace(/\/$/, "").replace(/\/api$/, "")#g' "$FILE" 2>/dev/null || true

    echo "Checked/patched: $FILE"
  fi
done

echo ""
echo "4. Show likely API driver files"
echo ""

for FILE in \
  "$ROOT/src/lib/api.ts" \
  "$ROOT/src/lib/api.js" \
  "$ROOT/artifacts/messenger-mobile/src/lib/api.ts" \
  "$ROOT/artifacts/messenger-mobile/src/lib/api.js" \
  "$ROOT/src/maurimesh/api/intelligentApiDriver.ts"
do
  if [ -f "$FILE" ]; then
    echo ""
    echo "----- $FILE -----"
    sed -n '1,140p' "$FILE"
  fi
done

echo ""
echo "5. Confirm intelligent backend route file exists"
echo ""

ls -la "$ROOT/server/maurimeshIntelligentApiDriver.cjs" 2>/dev/null || true

echo ""
echo "6. Confirm backend server mounted the route"
echo ""

grep -RIn \
  "mauriMeshIntelligentApiDriverRouter\|/api/activity\|/api/mesh/packet/decision\|app.use" \
  "$ROOT/server" "$ROOT/backend" "$ROOT/src/server" "$ROOT/api" \
  --exclude-dir=node_modules \
  --exclude-dir=.git \
  2>/dev/null || true

echo ""
echo "7. Test deployed API routes"
echo ""

echo ""
echo "Testing health:"
curl -i --max-time 15 "$BACKEND_ROOT/api/health" || true

echo ""
echo "Testing activity:"
curl -i --max-time 15 "$BACKEND_ROOT/api/activity" || true

echo ""
echo "Testing ingest:"
curl -i --max-time 15 -X POST "$BACKEND_ROOT/api/activity/ingest" \
  -H "Content-Type: application/json" \
  -d '{
    "packetId":"MM-API-FIX-TEST-001",
    "stage":"TX_BLE_START",
    "status":"SEND",
    "transport":"BLE",
    "fromPeerId":"PHONE-A",
    "toPeerId":"PHONE-B",
    "detail":"Testing fixed API base URL and intelligent ingest"
  }' || true

echo ""
echo "Testing decision:"
curl -i --max-time 15 -X POST "$BACKEND_ROOT/api/mesh/packet/decision" \
  -H "Content-Type: application/json" \
  -d '{
    "packetId":"MM-API-FIX-TEST-001",
    "payloadBytes":128,
    "preferredTransport":"BLE",
    "targetPeerId":"PHONE-B"
  }' || true

echo ""
echo "============================================================"
echo "DONE"
