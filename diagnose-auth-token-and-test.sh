#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH AUTH TOKEN DIAGNOSTIC + TEST"
echo "============================================================"
echo ""

BASE="https://mauri-mesh-messenger.replit.app"

echo "1. Show auth middleware source"
echo ""
for f in \
  artifacts/api-server/src/middleware/requireAuth.ts \
  artifacts/api-server/src/routes/auth.ts \
  artifacts/api-server/src/lib/logger.ts \
  server/middleware/requireAuth.ts \
  server/routes/auth.ts
do
  if [ -f "$f" ]; then
    echo ""
    echo "----- $f -----"
    sed -n '1,220p' "$f"
  fi
done

echo ""
echo "2. Search token/auth env names"
grep -RIn \
  "AUTH_TOKEN\|OPERATOR_TOKEN\|API_TOKEN\|JWT_SECRET\|SESSION_SECRET\|Bearer\|Authorization\|requireAuth" \
  .env .env.local artifacts/api-server/.env artifacts/api-server/.env.local artifacts/api-server/src server src api \
  --exclude-dir=node_modules \
  --exclude-dir=.pnpm \
  --exclude-dir=dist \
  --exclude-dir=build \
  2>/dev/null || true

echo ""
echo "3. Current env token values, if present"
for key in AUTH_TOKEN OPERATOR_TOKEN API_TOKEN ADMIN_TOKEN JWT_SECRET SESSION_SECRET; do
  val="$(printenv "$key" || true)"
  if [ -n "$val" ]; then
    echo "$key=$val"
  fi
done

echo ""
echo "4. Try common token env values from files"

TOKENS="$(grep -RhoE '(AUTH_TOKEN|OPERATOR_TOKEN|API_TOKEN|ADMIN_TOKEN|JWT_SECRET|SESSION_SECRET)=.+$' \
  .env .env.local artifacts/api-server/.env artifacts/api-server/.env.local 2>/dev/null \
  | cut -d= -f2- \
  | sed 's/^"//;s/"$//;s/^'\''//;s/'\''$//' \
  | sort -u || true)"

if [ -z "$TOKENS" ]; then
  echo "No token found in env files."
else
  for TOKEN in $TOKENS; do
    echo ""
    echo "Testing token: ${TOKEN:0:8}..."
    curl -sS -i --max-time 15 "$BASE/api/mesh-public/health" \
      -H "Authorization: Bearer $TOKEN" || true
  done
fi

echo ""
echo "============================================================"
echo "DONE"
echo "If one test returns HTTP 200, that token is the fix."
echo "If none return 200, send the requireAuth.ts output."
echo "============================================================"
