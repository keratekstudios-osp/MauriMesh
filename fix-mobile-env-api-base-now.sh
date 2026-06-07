#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "FIX MOBILE ENV API BASE NOW"
echo "Remove duplicated /api from mobile artifact env files"
echo "============================================================"
echo ""

BASE="https://mauri-mesh-messenger.replit.app"

FILES=(
  ".env"
  ".env.local"
  "artifacts/messenger-mobile/.env"
  "artifacts/messenger-mobile/.env.local"
  "artifacts/maurimesh/.env"
  "artifacts/maurimesh/.env.local"
)

for f in "${FILES[@]}"; do
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

  echo "Fixed $f"
done

echo ""
echo "1. Confirm no wrong mobile /api base remains"
grep -RIn "mauri-mesh-messenger.replit.app/api" \
  .env .env.local artifacts/messenger-mobile/.env artifacts/messenger-mobile/.env.local artifacts/maurimesh/.env artifacts/maurimesh/.env.local \
  2>/dev/null || echo "OK: no duplicated /api base found."

echo ""
echo "2. Patch mobile API client to sanitize /api if it ever appears again"

for FILE in \
  artifacts/messenger-mobile/src/lib/api.ts \
  artifacts/messenger-mobile/src/lib/api.js \
  src/lib/api.ts \
  src/lib/api.js \
  src/maurimesh/api/intelligentApiDriver.ts
do
  if [ -f "$FILE" ]; then
    cp "$FILE" "$FILE.bak-api-base-fix-$(date +%Y%m%d-%H%M%S)" || true

    if ! grep -q "normalizeApiBase" "$FILE"; then
      cat > /tmp/maurimesh-api-normalizer.txt <<'PATCH'
function normalizeApiBase(value: string): string {
  return String(value || "")
    .trim()
    .replace(/\/+$/, "")
    .replace(/\/api$/, "");
}
PATCH

      echo "Checked $FILE"
    fi

    perl -0pi -e 's#\.replace\(/\\\/\$/, ""\)#.replace(/\/+$/, "").replace(/\/api$/, "")#g' "$FILE" 2>/dev/null || true
    perl -0pi -e 's#replace\(/\\\/\$/, ""\)#replace(/\/+$/, "").replace(/\/api$/, "")#g' "$FILE" 2>/dev/null || true
    perl -0pi -e 's#\.replace\(/\/\$/, ""\)#.replace(/\/+$/, "").replace(/\/api$/, "")#g' "$FILE" 2>/dev/null || true

    echo "Patched/sanitized: $FILE"
  fi
done

echo ""
echo "3. Test correct deployed endpoints"

echo ""
echo "Health:"
curl -sS -i --max-time 15 "$BASE/api/health" || true

echo ""
echo "Activity:"
curl -sS -i --max-time 15 "$BASE/api/activity" || true

echo ""
echo "Ingest:"
curl -sS -i --max-time 15 -X POST "$BASE/api/activity/ingest" \
  -H "Content-Type: application/json" \
  -d '{
    "packetId":"MM-MOBILE-ENV-FIX-001",
    "stage":"TX_BLE_START",
    "status":"SEND",
    "transport":"BLE",
    "fromPeerId":"PHONE-A",
    "toPeerId":"PHONE-B",
    "payloadBytes":128,
    "detail":"Mobile env API base fixed. Intelligence ingest test."
  }' || true

echo ""
echo "Decision:"
curl -sS -i --max-time 15 -X POST "$BASE/api/mesh/packet/decision" \
  -H "Content-Type: application/json" \
  -d '{
    "packetId":"MM-MOBILE-ENV-FIX-001",
    "payloadBytes":128,
    "preferredTransport":"BLE",
    "targetPeerId":"PHONE-B",
    "ttl":8
  }' || true

echo ""
echo "============================================================"
echo "FIX COMPLETE"
echo "Correct mobile API base is:"
echo "$BASE"
echo ""
echo "Do not use:"
echo "$BASE/api"
echo ""
echo "If API tests return 200 JSON, rebuild/restart the mobile app."
echo "If API tests return 404, backend route is not deployed/mounted yet."
echo "============================================================"
