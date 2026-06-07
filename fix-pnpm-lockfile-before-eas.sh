#!/usr/bin/env bash
set -e

echo "=================================================="
echo "FIX PNPM LOCKFILE CONFIG MISMATCH — NO EAS BUILD"
echo "=================================================="

BACKUP="backup-before-pnpm-lockfix-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP"

for f in package.json pnpm-lock.yaml pnpm-workspace.yaml eas.json; do
  if [ -f "$f" ]; then
    cp "$f" "$BACKUP/$f"
    echo "Backed up: $f"
  fi
done

echo ""
echo "1. Confirm package manager files"
ls -la package.json pnpm-lock.yaml pnpm-workspace.yaml 2>/dev/null || true

echo ""
echo "2. Update pnpm lockfile to match package.json overrides"
pnpm install --no-frozen-lockfile

echo ""
echo "3. Verify frozen install now works locally"
pnpm install --frozen-lockfile

echo ""
echo "4. Verify TypeScript"
npx tsc --noEmit

echo ""
echo "5. Verify no old anonymous package references"
grep -R "com.anonymous.workspace\|com.anonymous.MauriMesh" android app.json app.config.js app.config.ts 2>/dev/null || echo "PASS: no old anonymous package references"

echo ""
echo "=================================================="
echo "PNPM LOCKFILE FIX COMPLETE — NO EAS BUILD USED"
echo "Backup: $BACKUP"
echo "=================================================="
