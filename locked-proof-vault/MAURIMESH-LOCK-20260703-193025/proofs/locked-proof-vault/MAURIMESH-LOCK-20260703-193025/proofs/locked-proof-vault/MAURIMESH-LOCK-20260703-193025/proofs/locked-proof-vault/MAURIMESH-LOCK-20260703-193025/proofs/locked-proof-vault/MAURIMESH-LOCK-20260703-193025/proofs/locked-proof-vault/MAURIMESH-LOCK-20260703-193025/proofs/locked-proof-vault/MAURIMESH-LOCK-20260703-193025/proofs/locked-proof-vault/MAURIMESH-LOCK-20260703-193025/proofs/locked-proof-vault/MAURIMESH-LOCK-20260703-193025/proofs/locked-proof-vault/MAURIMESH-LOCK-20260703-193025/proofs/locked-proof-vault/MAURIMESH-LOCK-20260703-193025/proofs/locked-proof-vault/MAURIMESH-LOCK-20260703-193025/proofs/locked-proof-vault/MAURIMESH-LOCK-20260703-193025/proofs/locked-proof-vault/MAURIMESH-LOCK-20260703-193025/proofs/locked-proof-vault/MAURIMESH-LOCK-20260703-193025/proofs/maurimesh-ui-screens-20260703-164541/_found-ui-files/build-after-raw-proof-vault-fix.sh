#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH BUILD AFTER RAW PROOF VAULT FIX"
echo "============================================================"
echo "Goal:"
echo "- Verify Raw Proof Vault crash-safe patch exists"
echo "- Run TypeScript check"
echo "- Confirm EAS readiness"
echo "- Start Android APK build"
echo "- Do NOT claim native BLE/GATT packet-bound proof"
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +"%Y%m%d-%H%M%S")"
PATCH_ID="MM-BUILD-AFTER-RAW-PROOF-VAULT-FIX-$STAMP"

OUT_DIR="$ROOT/docs/build-gates"
ARCHIVE_DIR="$ROOT/archives"
mkdir -p "$OUT_DIR" "$ARCHIVE_DIR"

ROUTE="$ROOT/app/locked-proof-vault.tsx"
REPORT="$OUT_DIR/MAURIMESH_BUILD_AFTER_RAW_PROOF_VAULT_FIX_$STAMP.md"
TSC_OUT="$OUT_DIR/typecheck-after-raw-proof-vault-fix-build-$STAMP.txt"
EAS_OUT="$OUT_DIR/eas-build-after-raw-proof-vault-fix-$STAMP.log"

echo "[1/6] Checking project root..."

if [ ! -f "$ROOT/package.json" ]; then
  echo "ERROR: package.json not found."
  echo "Run this from /home/runner/workspace."
  exit 1
fi

echo "Project root OK: $ROOT"

echo ""
echo "[2/6] Checking Raw Proof Vault safe route..."

if [ ! -f "$ROUTE" ]; then
  echo "ERROR: Missing route:"
  echo "$ROUTE"
  exit 1
fi

if grep -q "Crash-safe vault view" "$ROUTE" && grep -q "Native BLE/GATT packet-bound PASS: not claimed" "$ROUTE"; then
  VAULT_STATUS="PASS"
  echo "Raw Proof Vault safe screen: PASS"
else
  VAULT_STATUS="WARN"
  echo "WARNING: Raw Proof Vault safe markers not found."
  echo "Build can continue, but verify app/locked-proof-vault.tsx manually."
fi

echo ""
echo "[3/6] Running TypeScript check..."

set +e
npx tsc --noEmit > "$TSC_OUT" 2>&1
TSC_CODE="$?"
set -e

if [ "$TSC_CODE" -eq 0 ]; then
  TSC_STATUS="PASS"
  echo "TypeScript: PASS"
else
  TSC_STATUS="FAILED"
  echo "TypeScript: FAILED"
  tail -120 "$TSC_OUT" || true
  echo ""
  echo "STOPPING: Fix TypeScript before EAS build."
  exit 1
fi

echo ""
echo "[4/6] Checking EAS CLI..."

if npx eas-cli --version >/dev/null 2>&1; then
  EAS_STATUS="PASS"
  echo "EAS CLI: PASS"
else
  EAS_STATUS="FAILED"
  echo "ERROR: EAS CLI not available through npx."
  exit 1
fi

echo ""
echo "[5/6] Selecting build profile..."

PROFILE="preview-apk"

if [ -f "$ROOT/eas.json" ]; then
  if grep -q "\"preview-apk\"" "$ROOT/eas.json"; then
    PROFILE="preview-apk"
  elif grep -q "\"preview\"" "$ROOT/eas.json"; then
    PROFILE="preview"
  elif grep -q "\"development\"" "$ROOT/eas.json"; then
    PROFILE="development"
  else
    PROFILE="production"
  fi
fi

echo "Selected EAS profile: $PROFILE"

cat > "$REPORT" <<MD
# MauriMesh Build After Raw Proof Vault Fix

Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")

## Patch ID

\`\`\`txt
$PATCH_ID
\`\`\`

## Checks

Raw Proof Vault route:

\`\`\`txt
$VAULT_STATUS
\`\`\`

TypeScript:

\`\`\`txt
$TSC_STATUS
\`\`\`

EAS CLI:

\`\`\`txt
$EAS_STATUS
\`\`\`

Selected profile:

\`\`\`txt
$PROFILE
\`\`\`

## Truth

This build is to verify the Raw Proof Vault runtime crash fix.

Native BLE/GATT packet-bound PASS is **NOT CLAIMED**.
MD

echo ""
echo "[6/6] Starting EAS Android build..."
echo ""
echo "============================================================"
echo "THIS WILL SPEND ONE EAS BUILD"
echo "============================================================"
echo ""

set +e
npx eas-cli build \
  --platform android \
  --profile "$PROFILE" \
  --non-interactive \
  --clear-cache 2>&1 | tee "$EAS_OUT"

EAS_CODE="${PIPESTATUS[0]}"
set -e

if [ "$EAS_CODE" -eq 0 ]; then
  BUILD_STATUS="STARTED_OR_COMPLETED"
else
  BUILD_STATUS="FAILED_TO_START_OR_FAILED"
fi

cat >> "$REPORT" <<MD

## EAS Build Status

\`\`\`txt
$BUILD_STATUS
\`\`\`

## EAS Log

\`\`\`txt
$EAS_OUT
\`\`\`

## Final Truth

EAS build was requested.

Raw Proof Vault fix must still be tested on the installed APK.

Native BLE/GATT packet-bound PASS is **NOT CLAIMED**.
MD

ARCHIVE="$ARCHIVE_DIR/maurimesh-build-after-raw-proof-vault-fix-$STAMP.tar.gz"
tar -czf "$ARCHIVE" \
  -C "$ROOT" \
  "app/locked-proof-vault.tsx" \
  "docs/build-gates" \
  >/dev/null 2>&1 || true

echo ""
echo "============================================================"
echo "MAURIMESH BUILD AFTER RAW PROOF VAULT FIX COMPLETE"
echo "============================================================"
echo "Patch ID:"
echo "$PATCH_ID"
echo ""
echo "Raw Proof Vault route:"
echo "$VAULT_STATUS"
echo ""
echo "TypeScript:"
echo "$TSC_STATUS"
echo ""
echo "EAS build status:"
echo "$BUILD_STATUS"
echo ""
echo "Selected profile:"
echo "$PROFILE"
echo ""
echo "Report:"
echo "$REPORT"
echo ""
echo "EAS log:"
echo "$EAS_OUT"
echo ""
echo "Archive:"
echo "$ARCHIVE"
echo ""
echo "FINAL TRUTH:"
echo "Build requested after Raw Proof Vault crash fix."
echo "Install the APK and press Raw Proof Vault first."
echo "Native BLE/GATT packet-bound PASS is NOT claimed."
echo "============================================================"

exit "$EAS_CODE"
