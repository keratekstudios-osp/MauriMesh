#!/usr/bin/env bash
set -e

echo "=================================================="
echo "MAURIMESH FINAL NATIVE CLEAN — NO BUILD"
echo "=================================================="

BACKUP="backup-before-final-native-clean-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP"

OLD_DIR="android/app/src/main/java/com/anonymous/workspace"
NEW_DIR="android/app/src/main/java/com/maurimesh/messenger"

echo ""
echo "1. Verify new native package exists"

if [ ! -f "$NEW_DIR/MainActivity.kt" ]; then
  echo "ERROR: Missing $NEW_DIR/MainActivity.kt"
  exit 1
fi

grep -R "package com.maurimesh.messenger" "$NEW_DIR" || {
  echo "ERROR: New native files do not use com.maurimesh.messenger"
  exit 1
}

echo ""
echo "2. Backup and remove old anonymous native folder"

if [ -d "$OLD_DIR" ]; then
  mkdir -p "$BACKUP/android/app/src/main/java/com/anonymous"
  cp -R "$OLD_DIR" "$BACKUP/android/app/src/main/java/com/anonymous/workspace"
  rm -rf "$OLD_DIR"
  echo "Removed old folder: $OLD_DIR"
else
  echo "Old anonymous folder already removed."
fi

echo ""
echo "3. Verify no old anonymous package references remain"

if grep -R "com.anonymous.workspace\|com.anonymous.MauriMesh" android app.json app.config.js app.config.ts 2>/dev/null; then
  echo "WARNING: old anonymous reference still found above."
else
  echo "PASS: no old anonymous package references found."
fi

echo ""
echo "4. Verify final identity"

grep -R "namespace\|applicationId" android/app/build.gradle 2>/dev/null || true
grep -R "package com.maurimesh.messenger" android/app/src/main/java 2>/dev/null || true
npx expo config --type public | grep -E "name:|slug:|scheme:|package:|bundleIdentifier:" || true

echo ""
echo "5. Final checks — NO EAS BUILD"

npx expo-doctor || true
npx tsc --noEmit || true

echo ""
echo "=================================================="
echo "FINAL NATIVE CLEAN COMPLETE — NO EAS BUILD USED"
echo "Backup: $BACKUP"
echo "=================================================="
