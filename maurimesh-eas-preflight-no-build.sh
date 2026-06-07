#!/usr/bin/env bash
set -e

echo "=================================================="
echo "MAURIMESH EAS PREFLIGHT — NO BUILD USED"
echo "=================================================="

echo ""
echo "1. Versions"
node -v || true
npm -v || true
npx expo --version || true
npx eas --version || true

echo ""
echo "2. Project files"
ls -la
echo ""
test -f package.json && echo "package.json FOUND" || echo "package.json MISSING"
test -f app.json && echo "app.json FOUND" || true
test -f app.config.js && echo "app.config.js FOUND" || true
test -f app.config.ts && echo "app.config.ts FOUND" || true
test -f eas.json && echo "eas.json FOUND" || echo "eas.json MISSING"

echo ""
echo "3. Package scripts"
node -e "const p=require('./package.json'); console.log(p.scripts || {})" || true

echo ""
echo "4. Expo config"
npx expo config --type public || true

echo ""
echo "5. Expo doctor"
npx expo-doctor || true

echo ""
echo "6. TypeScript"
npx tsc --noEmit || true

echo ""
echo "7. Search native blockers"
grep -R "from \"fs\"\\|from 'fs'\\|require(\"fs\")\\|require('fs')\\|from \"path\"\\|from 'path'" app src 2>/dev/null || true

echo ""
echo "8. Check EAS config"
if [ -f eas.json ]; then
  cat eas.json
else
  echo "No eas.json yet."
fi

echo ""
echo "9. Android config check"
grep -R "package\\|applicationId\\|bundleIdentifier\\|slug\\|name" app.json app.config.js app.config.ts android/app/build.gradle 2>/dev/null || true

echo ""
echo "=================================================="
echo "PREFLIGHT COMPLETE — NO EAS BUILD WAS STARTED"
echo "=================================================="
