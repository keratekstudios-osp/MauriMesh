#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH FINAL CLEAN API INTELLIGENCE TEST"
echo "No pnpm store. No generated artifacts noise."
echo "============================================================"
echo ""

ROOT="$(pwd)"
BASE="https://mauri-mesh-messenger.replit.app"

echo "1. Kill noisy searches"
pkill -f "find-maurimesh-api-and-packet-drivers.sh" 2>/dev/null || true
pkill -f "grep -RIn" 2>/dev/null || true

echo ""
echo "2. Confirm clean env base URL"
echo "Expected:"
echo "EXPO_PUBLIC_API_BASE_URL=$BASE"
echo ""

for f in .env .env.local artifacts/messenger-mobile/.env artifacts/messenger-mobile/.env.local; do
  if [ -f "$f" ]; then
    echo "----- $f -----"
    cat "$f"
  fi
done

echo ""
echo "3. Check for wrong /api base URL"
BAD=$(grep -RIn "mauri-mesh-messenger.replit.app/api" \
  .env .env.local artifacts/messenger-mobile/.env artifacts/messenger-mobile/.env.local \
  2>/dev/null || true)

if [ -n "$BAD" ]; then
  echo "BAD URL FOUND:"
  echo "$BAD"
else
  echo "OK: no duplicated /api base URL in main env files."
fi

echo ""
echo "4. Show likely mobile API driver"
if [ -f "artifacts/messenger-mobile/src/lib/api.ts" ]; then
  echo "FOUND: artifacts/messenger-mobile/src/lib/api.ts"
  sed -n '1,120p' artifacts/messenger-mobile/src/lib/api.ts
elif [ -f "src/lib/api.ts" ]; then
  echo "FOUND: src/lib/api.ts"
  sed -n '1,120p' src/lib/api.ts
else
  echo "No src/lib/api.ts found. Searching cleanly..."
  find src app artifacts/messenger-mobile -type f \
    \( -name "api.ts" -o -name "api.js" -o -name "*Api*.ts" -o -name "*api*.ts" \) \
    -not -path "*/node_modules/*" \
    -not -path "*/.pnpm/*" \
    -not -path "*/dist/*" \
    -not -path "*/build/*" \
    2>/dev/null | head -40
fi

echo ""
echo "5. Check intelligent backend file exists"
if [ -f "server/maurimeshIntelligentApiDriver.cjs" ]; then
  echo "OK: server/maurimeshIntelligentApiDriver.cjs exists"
else
  echo "MISSING: server/maurimeshIntelligentApiDriver.cjs"
fi

echo ""
echo "6. Check if backend route is mounted"
grep -RIn "mauriMeshIntelligentApiDriverRouter\|/api/activity\|app.use" \
  server backend src/server api \
  --exclude-dir=node_modules \
  --exclude-dir=.pnpm \
  --exclude-dir=dist \
  --exclude-dir=build \
  2>/dev/null | head -120 || true

echo ""
echo "7. Test deployed API health"
curl -sS -i --max-time 15 "$BASE/api/health" || true

echo ""
echo "8. Test deployed intelligence activity"
curl -sS -i --max-time 15 "$BASE/api/activity" || true

echo ""
echo "9. Test deployed ingest"
curl -sS -i --max-time 15 -X POST "$BASE/api/activity/ingest" \
  -H "Content-Type: application/json" \
  -d '{
    "packetId":"MM-FINAL-CLEAN-TEST-001",
    "stage":"TX_BLE_START",
    "status":"SEND",
    "transport":"BLE",
    "fromPeerId":"PHONE-A",
    "toPeerId":"PHONE-B",
    "payloadBytes":128,
    "detail":"Final clean API intelligence test"
  }' || true

echo ""
echo "10. Test deployed packet decision"
curl -sS -i --max-time 15 -X POST "$BASE/api/mesh/packet/decision" \
  -H "Content-Type: application/json" \
  -d '{
    "packetId":"MM-FINAL-CLEAN-TEST-001",
    "payloadBytes":128,
    "preferredTransport":"BLE",
    "targetPeerId":"PHONE-B",
    "ttl":8
  }' || true

echo ""
echo "============================================================"
echo "RESULT GUIDE"
echo "200 JSON = connected"
echo "404 = route not mounted in deployed backend"
echo "401/403 = operator auth block"
echo "timeout = Replit backend not running/wrong URL"
echo "============================================================"
