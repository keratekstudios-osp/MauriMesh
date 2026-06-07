#!/usr/bin/env bash
set -e

echo "=================================================="
echo "DELETE EAS-BLOCKING NON-SOURCE FILES"
echo "APP SOURCE PRESERVED"
echo "=================================================="

echo ""
echo "1. Disk before"
du -sh . 2>/dev/null || true
du -sh ./* ./.??* 2>/dev/null | sort -hr | head -40

echo ""
echo "2. Remove failed hold folders"
rm -rf "$HOME"/maurimesh-large-files-hold-* 2>/dev/null || true

echo ""
echo "3. Delete huge non-source/archive/cache files"
rm -rf .git
rm -rf .cache
rm -rf .local
rm -rf .config
rm -rf artifacts
rm -rf MauriMesh-backup.zip
rm -rf MAURIMESH_WIRING_REPORT.md
rm -rf maurimesh-driver-search-results.log
rm -rf dist-web-live
rm -rf dist-test-verify
rm -rf maurimesh-replit-merged.bundle
rm -rf maurimesh-source.zip
rm -rf dist
rm -rf .expo
rm -rf .eas
rm -rf android/.gradle
rm -rf android/build
rm -rf android/app/build
rm -rf node_modules/.cache
rm -rf /tmp/eas-* /tmp/expo-* /tmp/metro-* 2>/dev/null || true

echo ""
echo "4. Strong EAS ignore"
cat > .easignore <<'IGNORE'
.git
node_modules
.pnpm-store
.expo
.eas
dist
web-build
coverage
android/.gradle
android/build
android/app/build
ios/build
*.log
*.tmp
.DS_Store
backup-*
backups
*.tar
*.tar.gz
*.zip
artifacts
.cache
.local
.config
IGNORE

echo ""
echo "5. Confirm app source still exists"
test -f package.json && echo "package.json OK"
test -d app && echo "app/ OK"
test -d src && echo "src/ OK"
test -d android && echo "android/ OK"
test -f pnpm-lock.yaml && echo "pnpm-lock.yaml OK"

echo ""
echo "6. Confirm native BLE module repair still present"
grep -RniE "class MauriMeshBleModule|class MauriMeshBlePackage|MauriMeshBlePackage\\(\\)" android/app/src/main/java/com/maurimesh/messenger 2>/dev/null

echo ""
echo "7. TypeScript"
npx tsc --noEmit

echo ""
echo "8. Export"
npx expo export --platform android --clear

echo ""
echo "9. Disk after"
du -sh . 2>/dev/null || true
du -sh ./* ./.??* 2>/dev/null | sort -hr | head -40

echo ""
echo "=================================================="
echo "EAS BLOCKERS REMOVED"
echo "Now retry EAS once."
echo "=================================================="
