#!/usr/bin/env bash
set -e

echo "=================================================="
echo "MOVE LARGE NON-SOURCE FILES OUT OF EAS WORKSPACE"
echo "SOURCE PRESERVED"
echo "=================================================="

HOLD="$HOME/maurimesh-large-files-hold-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$HOLD"

echo ""
echo "1. Disk before"
du -sh . 2>/dev/null || true
du -sh ./* ./.??* 2>/dev/null | sort -hr | head -30

echo ""
echo "2. Move huge non-source files/folders"

move_if_exists() {
  if [ -e "$1" ]; then
    echo "Moving: $1"
    mv "$1" "$HOLD/"
  fi
}

move_if_exists ".git"
move_if_exists ".cache"
move_if_exists ".local"
move_if_exists "artifacts"
move_if_exists "MauriMesh-backup.zip"
move_if_exists "MAURIMESH_WIRING_REPORT.md"
move_if_exists "maurimesh-driver-search-results.log"
move_if_exists "dist-web-live"
move_if_exists "dist-test-verify"
move_if_exists "maurimesh-replit-merged.bundle"
move_if_exists "maurimesh-source.zip"

echo ""
echo "3. Clean generated build/cache folders"
rm -rf .expo .eas dist web-build
rm -rf android/.gradle android/build android/app/build
rm -rf node_modules/.cache
rm -rf /tmp/eas-* /tmp/expo-* /tmp/metro-* 2>/dev/null || true

echo ""
echo "4. Strong .easignore"
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
IGNORE

echo ""
echo "5. Confirm source and native repair still present"
test -f package.json && echo "package.json OK"
test -d app && echo "app/ OK"
test -d src && echo "src/ OK"
test -d android && echo "android/ OK"

grep -RniE "class MauriMeshBleModule|class MauriMeshBlePackage|MauriMeshBlePackage\\(\\)" android/app/src/main/java/com/maurimesh/messenger 2>/dev/null

echo ""
echo "6. TypeScript"
npx tsc --noEmit

echo ""
echo "7. Export"
npx expo export --platform android --clear

echo ""
echo "8. Disk after"
du -sh . 2>/dev/null || true
du -sh ./* ./.??* 2>/dev/null | sort -hr | head -30

echo ""
echo "=================================================="
echo "LARGE FILES MOVED OUT OF EAS WORKSPACE"
echo "Hold folder: $HOLD"
echo "Now retry EAS once."
echo "=================================================="
