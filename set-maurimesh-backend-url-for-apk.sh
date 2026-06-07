#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH BACKEND URL AUTO-CONNECT FIX"
echo "Sets API URL for Replit APK / Expo / Vite app"
echo "============================================================"
echo ""

ROOT="$(pwd)"
API_BASE="https://mauri-mesh-messenger.replit.app/api"
BACKEND_BASE="https://mauri-mesh-messenger.replit.app"
BACKUP="$ROOT/backup-before-api-url-fix-$(date +%Y%m%d-%H%M%S)"

mkdir -p "$BACKUP"

echo "Project root: $ROOT"
echo "API base: $API_BASE"
echo "Backend base: $BACKEND_BASE"
echo ""

cat > "$BACKUP/README.txt" <<TXT
Backup marker before MauriMesh backend URL fix.

Set API URL:
$API_BASE

This script updates environment/config files only.
It does not delete existing app code.
TXT

echo "1. Write root environment files"

cat > "$ROOT/.env" <<ENV
EXPO_PUBLIC_API_BASE_URL=$API_BASE
EXPO_PUBLIC_BACKEND_BASE_URL=$BACKEND_BASE
VITE_API_BASE_URL=$API_BASE
VITE_BACKEND_BASE_URL=$BACKEND_BASE
API_BASE_URL=$API_BASE
BACKEND_BASE_URL=$BACKEND_BASE
ENV

cat > "$ROOT/.env.local" <<ENV
EXPO_PUBLIC_API_BASE_URL=$API_BASE
EXPO_PUBLIC_BACKEND_BASE_URL=$BACKEND_BASE
VITE_API_BASE_URL=$API_BASE
VITE_BACKEND_BASE_URL=$BACKEND_BASE
API_BASE_URL=$API_BASE
BACKEND_BASE_URL=$BACKEND_BASE
ENV

echo "Wrote:"
echo "- .env"
echo "- .env.local"
echo ""

echo "2. Write app-specific env files if folders exist"

for DIR in \
  "$ROOT/artifacts/messenger-mobile" \
  "$ROOT/artifacts/maurimesh" \
  "$ROOT/artifacts/api-server" \
  "$ROOT/apps/mobile" \
  "$ROOT/mobile" \
  "$ROOT/app" \
  "$ROOT/src"
do
  if [ -d "$DIR" ]; then
    echo "Updating env in $DIR"
    cat > "$DIR/.env" <<ENV
EXPO_PUBLIC_API_BASE_URL=$API_BASE
EXPO_PUBLIC_BACKEND_BASE_URL=$BACKEND_BASE
VITE_API_BASE_URL=$API_BASE
VITE_BACKEND_BASE_URL=$BACKEND_BASE
API_BASE_URL=$API_BASE
BACKEND_BASE_URL=$BACKEND_BASE
ENV

    cat > "$DIR/.env.local" <<ENV
EXPO_PUBLIC_API_BASE_URL=$API_BASE
EXPO_PUBLIC_BACKEND_BASE_URL=$BACKEND_BASE
VITE_API_BASE_URL=$API_BASE
VITE_BACKEND_BASE_URL=$BACKEND_BASE
API_BASE_URL=$API_BASE
BACKEND_BASE_URL=$BACKEND_BASE
ENV
  fi
done

echo ""
echo "3. Create central API config helper"

mkdir -p "$ROOT/src/maurimesh/config"

cat > "$ROOT/src/maurimesh/config/apiBaseUrl.ts" <<TS
export const MAURIMESH_BACKEND_BASE_URL =
  process.env.EXPO_PUBLIC_BACKEND_BASE_URL ||
  process.env.VITE_BACKEND_BASE_URL ||
  "https://mauri-mesh-messenger.replit.app";

export const MAURIMESH_API_BASE_URL =
  process.env.EXPO_PUBLIC_API_BASE_URL ||
  process.env.VITE_API_BASE_URL ||
  process.env.API_BASE_URL ||
  "https://mauri-mesh-messenger.replit.app/api";

export function getMauriMeshApiBaseUrl(): string {
  return MAURIMESH_API_BASE_URL.replace(/\\/$/, "");
}

export function getMauriMeshBackendBaseUrl(): string {
  return MAURIMESH_BACKEND_BASE_URL.replace(/\\/$/, "");
}

export function buildMauriMeshApiUrl(path: string): string {
  const cleanPath = path.startsWith("/") ? path : \`/\${path}\`;
  return \`\${getMauriMeshApiBaseUrl()}\${cleanPath}\`;
}
TS

echo "Created src/maurimesh/config/apiBaseUrl.ts"
echo ""

echo "4. Patch common frontend API config files"

FILES_TO_PATCH="$(find . \
  -path ./node_modules -prune -o \
  -path ./.git -prune -o \
  -path ./android/.gradle -prune -o \
  -path ./ios/Pods -prune -o \
  -type f \( \
    -name '*.ts' -o \
    -name '*.tsx' -o \
    -name '*.js' -o \
    -name '*.jsx' -o \
    -name '*.mjs' -o \
    -name '*.json' -o \
    -name '*.env' -o \
    -name '*.env.local' \
  \) -print)"

while IFS= read -r FILE; do
  [ -f "$FILE" ] || continue

  if grep -qE "replit-objstore|127\.0\.0\.1:4300|localhost:4300|localhost:3000|http://127\.0\.0\.1|http://localhost" "$FILE"; then
    mkdir -p "$BACKUP/$(dirname "$FILE")"
    cp "$FILE" "$BACKUP/$FILE" 2>/dev/null || true

    perl -0pi -e "s#https?://replit-objstore-[A-Za-z0-9\\-_.:/?=&%]+#$API_BASE#g" "$FILE"
    perl -0pi -e "s#https?://127\\.0\\.0\\.1:4300(/api)?#$API_BASE#g" "$FILE"
    perl -0pi -e "s#https?://localhost:4300(/api)?#$API_BASE#g" "$FILE"
    perl -0pi -e "s#https?://localhost:3000(/api)?#$API_BASE#g" "$FILE"
    perl -0pi -e "s#http://127\\.0\\.0\\.1:[0-9]+(/api)?#$API_BASE#g" "$FILE"
    perl -0pi -e "s#http://localhost:[0-9]+(/api)?#$API_BASE#g" "$FILE"

    echo "Patched $FILE"
  fi
done <<< "$FILES_TO_PATCH"

echo ""
echo "5. Patch package/app config where possible"

if [ -f "$ROOT/app.config.js" ]; then
  cp "$ROOT/app.config.js" "$BACKUP/app.config.js" 2>/dev/null || true
  if ! grep -q "EXPO_PUBLIC_API_BASE_URL" "$ROOT/app.config.js"; then
    echo "NOTE: app.config.js exists. Env vars will be loaded at build time."
  fi
fi

if [ -f "$ROOT/app.json" ]; then
  cp "$ROOT/app.json" "$BACKUP/app.json" 2>/dev/null || true
  echo "NOTE: app.json exists. Env vars will be loaded by Expo at build time."
fi

echo ""
echo "6. Create API connection test script"

mkdir -p "$ROOT/scripts"

cat > "$ROOT/scripts/test-maurimesh-api-url.sh" <<SH
#!/usr/bin/env bash
set -euo pipefail

API="$API_BASE"

echo ""
echo "============================================================"
echo "TEST MAURIMESH API URL"
echo "============================================================"
echo ""
echo "API=\$API"
echo ""

echo "Testing health:"
curl -i "\$API/healthz" || true

echo ""
echo "Testing activity:"
curl -i "\$API/activity" || true

echo ""
echo "Result guide:"
echo "HTTP 200 = route works"
echo "HTTP 401 = route exists but login/operator token required"
echo "HTTP 404 = route missing"
echo "HTTP 502/503/timeout = API server not running"
echo ""
SH

chmod +x "$ROOT/scripts/test-maurimesh-api-url.sh"

echo ""
echo "7. Create Replit Agent follow-up prompt"

mkdir -p "$ROOT/docs"

cat > "$ROOT/docs/API_URL_APK_WIRING_AGENT_PROMPT.md" <<MD
# Replit Agent Task: Verify APK API URL Wiring

The backend API URL has been set to:

\`\`\`text
$API_BASE
\`\`\`

## Required verification

1. Search the app for all API base URL usage.
2. Ensure mobile app uses:
   - \`process.env.EXPO_PUBLIC_API_BASE_URL\`
   - fallback: \`https://mauri-mesh-messenger.replit.app/api\`

3. Ensure web/dashboard uses:
   - \`process.env.VITE_API_BASE_URL\`
   - fallback: \`https://mauri-mesh-messenger.replit.app/api\`

4. Remove all bad API base URLs:
   - \`replit-objstore-...\`
   - \`127.0.0.1:4300\`
   - \`localhost:4300\`
   - \`localhost:3000\` in mobile build code

5. Ensure dashboard calls:
   - \`$API_BASE/activity\`

6. Ensure login/auth calls:
   - \`$API_BASE/auth/login\`

7. Ensure readiness calls:
   - \`$API_BASE/readiness\`

8. Rebuild APK after env changes. Expo public variables are embedded at build time.

## Test commands

\`\`\`bash
bash scripts/test-maurimesh-api-url.sh
grep -R "replit-objstore\\|127.0.0.1:4300\\|localhost:4300\\|localhost:3000" -n . \\
  --exclude-dir=node_modules \\
  --exclude-dir=.git \\
  --exclude-dir=android/.gradle \\
  --exclude-dir=ios/Pods
\`\`\`

## Completion rule

Do not mark complete unless the installed APK points to:

\`\`\`text
$API_BASE
\`\`\`

and not to localhost, 127.0.0.1, or Replit object storage.
MD

echo ""
echo "8. Search remaining bad URLs"

BAD_FOUND=0

grep -R "replit-objstore\\|127.0.0.1:4300\\|localhost:4300\\|localhost:3000" -n . \
  --exclude-dir=node_modules \
  --exclude-dir=.git \
  --exclude-dir=android/.gradle \
  --exclude-dir=ios/Pods \
  --exclude-dir="$BACKUP" \
  --exclude="set-maurimesh-backend-url-for-apk.sh" \
  2>/dev/null | head -120 && BAD_FOUND=1 || true

echo ""
if [ "$BAD_FOUND" = "1" ]; then
  echo "WARNING: Some bad URLs may still remain above."
  echo "Give Replit Agent docs/API_URL_APK_WIRING_AGENT_PROMPT.md to clean exact app wiring."
else
  echo "PASS: No obvious bad backend URLs found in scanned files."
fi

echo ""
echo "9. Test public API URL"
bash "$ROOT/scripts/test-maurimesh-api-url.sh" || true

echo ""
echo "============================================================"
echo "API URL FIX COMPLETE"
echo "============================================================"
echo ""
echo "Set API URL to:"
echo "$API_BASE"
echo ""
echo "Created:"
echo "- .env"
echo "- .env.local"
echo "- src/maurimesh/config/apiBaseUrl.ts"
echo "- scripts/test-maurimesh-api-url.sh"
echo "- docs/API_URL_APK_WIRING_AGENT_PROMPT.md"
echo ""
echo "IMPORTANT:"
echo "For APK, rebuild the APK after this. Expo public env vars are embedded at build time."
echo ""
echo "Next Replit Agent instruction:"
echo "Open docs/API_URL_APK_WIRING_AGENT_PROMPT.md and verify the mobile APK API URL wiring."
echo ""
