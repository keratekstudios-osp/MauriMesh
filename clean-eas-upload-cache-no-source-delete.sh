#!/usr/bin/env bash
set -e

echo "=================================================="
echo "CLEAN EAS UPLOAD CACHE — SAFE, NO SOURCE DELETE"
echo "=================================================="

echo ""
echo "1. Disk usage before"
df -h .
du -sh . 2>/dev/null || true

echo ""
echo "2. Remove safe cache/build folders"
rm -rf .expo
rm -rf dist
rm -rf .eas
rm -rf android/.gradle
rm -rf android/build
rm -rf android/app/build
rm -rf node_modules/.cache
rm -rf /tmp/eas-* /tmp/expo-* /tmp/metro-* 2>/dev/null || true

echo ""
echo "3. Remove old local backup copies if they are huge"
du -sh "$HOME"/maurimesh-router-backups 2>/dev/null || true
find "$HOME"/maurimesh-router-backups -maxdepth 1 -type d -mtime +1 -print 2>/dev/null | head -20

echo ""
echo "4. Disk usage after cache cleanup"
df -h .
du -sh . 2>/dev/null || true

echo ""
echo "5. Confirm native BLE module repair still present"
grep -RniE "class MauriMeshBleModule|class MauriMeshBlePackage|MauriMeshBlePackage\\(\\)" android/app/src/main/java/com/maurimesh/messenger 2>/dev/null

echo ""
echo "6. TypeScript"
npx tsc --noEmit

echo ""
echo "7. Export check"
npx expo export --platform android --clear

echo ""
echo "=================================================="
echo "CACHE CLEAN COMPLETE — SOURCE PRESERVED"
echo "=================================================="
