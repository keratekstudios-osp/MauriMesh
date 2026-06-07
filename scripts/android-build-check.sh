#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo "MauriMesh Android Build Check"
echo "============================================================"

echo ""
echo "[1] Node / npm"
node -v  || echo "WARN: node not found"
npm  -v  || echo "WARN: npm not found"

echo ""
echo "[2] Java"
java -version 2>&1 || echo "WARN: java not found (required for Gradle builds)"

echo ""
echo "[3] Project files"
[ -f package.json ]    && echo "PASS  package.json"                   || echo "FAIL  package.json missing"
[ -f eas.json ]        && echo "PASS  eas.json"                       || echo "WARN  eas.json missing (EAS builds need this)"
[ -f app.json ]        && echo "PASS  app.json"                       || echo "WARN  app.json missing"

MOBILE="artifacts/messenger-mobile"
[ -d "$MOBILE" ]       && echo "PASS  artifacts/messenger-mobile/"    || echo "FAIL  artifacts/messenger-mobile/ not found"
[ -d "$MOBILE/android" ] && echo "PASS  android/ folder (prebuild done)" || echo "WARN  android/ folder missing — run: npx expo prebuild"

echo ""
echo "[4] Secret safety scan"
echo "Scanning for committed secrets..."
FOUND=0
for PAT in "*.keystore" "*.jks" "*.p12" "*.pem" "*service-account*.json" ".env"; do
  while IFS= read -r -d '' f; do
    echo "WARNING  Found: $f"
    FOUND=1
  done < <(find . -name "$PAT" -not -path "*/node_modules/*" -not -path "*/.git/*" -print0 2>/dev/null)
done
[ "$FOUND" -eq 0 ] && echo "PASS  No secret files found in repository"

echo ""
echo "[5] Android BLE permissions"
MANIFEST="$MOBILE/android/app/src/main/AndroidManifest.xml"
if [ -f "$MANIFEST" ]; then
  for PERM in "BLUETOOTH_SCAN" "BLUETOOTH_CONNECT" "BLUETOOTH_ADVERTISE" "ACCESS_FINE_LOCATION" "FOREGROUND_SERVICE"; do
    grep -q "$PERM" "$MANIFEST" && echo "PASS  $PERM" || echo "WARN  Missing: $PERM"
  done
else
  echo "SKIP  AndroidManifest.xml not found (run prebuild first)"
fi

echo ""
echo "[6] API health check"
if command -v curl &>/dev/null; then
  HTTP=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:80/api/healthz" 2>/dev/null || echo "000")
  [ "$HTTP" = "200" ] && echo "PASS  API /healthz → 200" || echo "WARN  API /healthz → $HTTP (start API server first)"
else
  echo "SKIP  curl not found"
fi

echo ""
echo "[7] Trust + Store-Forward DB tables"
if command -v curl &>/dev/null; then
  TRUST=$(curl -s "http://localhost:80/api/trust/status/db" 2>/dev/null || echo "{}")
  echo "$TRUST" | grep -q '"ok":true' && echo "PASS  trust_records table accessible" || echo "WARN  trust_records: $TRUST"
else
  echo "SKIP  curl not found"
fi

echo ""
echo "[8] Build commands reference"
echo "  Debug APK (EAS):    eas build -p android --profile development"
echo "  Release APK (EAS):  eas build -p android --profile production"
echo "  Local debug:        cd artifacts/messenger-mobile/android && ./gradlew :app:assembleDebug"
echo "  Logcat BLE proof:   adb logcat -s MauriMeshBle:D"
echo ""
echo "Build check complete."
