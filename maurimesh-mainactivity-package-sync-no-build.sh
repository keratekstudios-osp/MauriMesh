#!/usr/bin/env bash
set -e

echo "=================================================="
echo "MAURIMESH MAINACTIVITY PACKAGE SYNC — NO BUILD"
echo "=================================================="

BACKUP="backup-before-mainactivity-package-sync-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP"

OLD_DIR="android/app/src/main/java/com/anonymous/workspace"
NEW_DIR="android/app/src/main/java/com/maurimesh/messenger"

if [ -d "$OLD_DIR" ]; then
  mkdir -p "$BACKUP/android/app/src/main/java/com/anonymous"
  cp -R "$OLD_DIR" "$BACKUP/android/app/src/main/java/com/anonymous/workspace"
  echo "Backed up old MainActivity folder."
fi

mkdir -p "$NEW_DIR"

if [ -f "$OLD_DIR/MainActivity.kt" ]; then
  cp "$OLD_DIR/MainActivity.kt" "$NEW_DIR/MainActivity.kt"
  sed -i 's/package com\.anonymous\.workspace/package com.maurimesh.messenger/g' "$NEW_DIR/MainActivity.kt"
  echo "Created: $NEW_DIR/MainActivity.kt"
fi

if [ -f "$OLD_DIR/MainApplication.kt" ]; then
  cp "$OLD_DIR/MainApplication.kt" "$NEW_DIR/MainApplication.kt"
  sed -i 's/package com\.anonymous\.workspace/package com.maurimesh.messenger/g' "$NEW_DIR/MainApplication.kt"
  echo "Created: $NEW_DIR/MainApplication.kt"
fi

echo ""
echo "1. Patch AndroidManifest activity references if needed"

for f in \
  android/app/src/main/AndroidManifest.xml \
  android/app/src/debug/AndroidManifest.xml \
  android/app/src/profile/AndroidManifest.xml
do
  if [ -f "$f" ]; then
    cp "$f" "$BACKUP/$(basename "$f").bak" 2>/dev/null || true
    sed -i 's/com\.anonymous\.workspace/com.maurimesh.messenger/g' "$f"
    sed -i 's/com\.anonymous\.MauriMesh/com.maurimesh.messenger/g' "$f"
  fi
done

echo ""
echo "2. Verify no old package references remain"

grep -R "com.anonymous.workspace\|com.anonymous.MauriMesh" android/app/src android/app/build.gradle 2>/dev/null || true

echo ""
echo "3. Verify new package references"

grep -R "com.maurimesh.messenger" android/app/src android/app/build.gradle 2>/dev/null || true

echo ""
echo "4. Run checks — NO EAS BUILD"

npx expo-doctor || true
npx tsc --noEmit || true

echo ""
echo "=================================================="
echo "MAINACTIVITY PACKAGE SYNC COMPLETE — NO EAS BUILD USED"
echo "Backup: $BACKUP"
echo "=================================================="
