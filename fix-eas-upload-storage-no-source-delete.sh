#!/usr/bin/env bash
set -e

echo "=================================================="
echo "FIX EAS UPLOAD STORAGE — NO SOURCE DELETE"
echo "=================================================="

echo ""
echo "1. Disk before"
df -h .
du -sh . 2>/dev/null || true
du -sh "$HOME"/maurimesh-router-backups 2>/dev/null || true

echo ""
echo "2. Create .easignore to keep archive small"
cat > .easignore <<'IGNORE'
.git
.expo
.eas
dist
web-build
node_modules/.cache
android/.gradle
android/build
android/app/build
ios/build
coverage
*.log
*.tmp
.DS_Store
backup-*
maurimesh-router-backups
IGNORE

echo ""
echo "3. Remove safe generated cache/build folders"
rm -rf .expo
rm -rf .eas
rm -rf dist
rm -rf web-build
rm -rf node_modules/.cache
rm -rf android/.gradle
rm -rf android/build
rm -rf android/app/build
rm -rf /tmp/eas-* /tmp/expo-* /tmp/metro-* 2>/dev/null || true

echo ""
echo "4. Compress old backup folders instead of uploading them"
if [ -d "$HOME/maurimesh-router-backups" ]; then
  mkdir -p "$HOME/maurimesh-router-backups-archived"
  find "$HOME/maurimesh-router-backups" -maxdepth 1 -type d -name "backup-*" -mtime +0 -print | head -50 | while read d; do
    base="$(basename "$d")"
    tar -czf "$HOME/maurimesh-router-backups-archived/$base.tar.gz" -C "$(dirname "$d")" "$base" 2>/dev/null || true
    rm -rf "$d" 2>/dev/null || true
  done
fi

echo ""
echo "5. Confirm native BLE repair still present"
grep -RniE "class MauriMeshBleModule|class MauriMeshBlePackage|MauriMeshBlePackage\\(\\)" android/app/src/main/java/com/maurimesh/messenger 2>/dev/null

echo ""
echo "6. TypeScript"
npx tsc --noEmit

echo ""
echo "7. Export"
npx expo export --platform android --clear

echo ""
echo "8. Disk after"
df -h .
du -sh . 2>/dev/null || true
du -sh "$HOME"/maurimesh-router-backups 2>/dev/null || true

echo ""
echo "=================================================="
echo "EAS UPLOAD STORAGE FIX COMPLETE — SOURCE PRESERVED"
echo "=================================================="
