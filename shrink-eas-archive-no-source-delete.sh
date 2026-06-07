#!/usr/bin/env bash
set -e

echo "=================================================="
echo "SHRINK EAS ARCHIVE — NO SOURCE DELETE"
echo "=================================================="

echo ""
echo "1. Biggest folders"
du -sh ./* ./.??* 2>/dev/null | sort -hr | head -30

echo ""
echo "2. Write stronger .easignore"
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
maurimesh-router-backups
*.tar
*.tar.gz
*.zip
IGNORE

echo ""
echo "3. Confirm .easignore"
cat .easignore

echo ""
echo "4. Native BLE repair still present"
grep -RniE "class MauriMeshBleModule|class MauriMeshBlePackage|MauriMeshBlePackage\\(\\)" android/app/src/main/java/com/maurimesh/messenger 2>/dev/null

echo ""
echo "5. TypeScript"
npx tsc --noEmit

echo ""
echo "6. Export"
rm -rf dist .expo
npx expo export --platform android --clear

echo ""
echo "=================================================="
echo "EAS ARCHIVE SHRINK READY — NO SOURCE DELETE"
echo "Now retry EAS once."
echo "=================================================="
