#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
REPORT="$ROOT/docs/maurimesh-evolution-layer-report-$STAMP.md"
LATEST="$ROOT/docs/maurimesh-evolution-layer-report-latest.md"
EXPORT_DIR="$ROOT/.maurimesh-evolution-export-$STAMP"

mkdir -p "$ROOT/docs"
: > "$REPORT"

TOTAL=0
PASS=0
FAIL=0

check_file() {
  local label="$1"
  local file="$2"
  TOTAL=$((TOTAL+1))
  if [ -f "$ROOT/$file" ]; then
    echo "- [x] $label exists: $file" >> "$REPORT"
    PASS=$((PASS+1))
  else
    echo "- [ ] MISSING: $label: $file" >> "$REPORT"
    FAIL=$((FAIL+1))
  fi
}

check_contains() {
  local label="$1"
  local file="$2"
  local needle="$3"
  TOTAL=$((TOTAL+1))
  if [ -f "$ROOT/$file" ] && grep -q "$needle" "$ROOT/$file"; then
    echo "- [x] $label" >> "$REPORT"
    PASS=$((PASS+1))
  else
    echo "- [ ] MISSING: $label" >> "$REPORT"
    FAIL=$((FAIL+1))
  fi
}

{
  echo "# MauriMesh Evolution Layer Report"
  echo ""
  echo "Generated: $STAMP"
  echo ""
  echo "## Files"
} >> "$REPORT"

check_file "Evolution types" "src/maurimesh/evolution/EvolutionTypes.ts"
check_file "Evolution engine" "src/maurimesh/evolution/EvolutionEngine.ts"
check_file "Evolution index" "src/maurimesh/evolution/index.ts"
check_file "Evolution panel" "src/components/EvolutionLayerPanel.tsx"
check_file "Evolution route" "app/evolution-layer.tsx"

{
  echo ""
  echo "## Safety / Governance Markers"
} >> "$REPORT"

check_contains "Operator approval gate" "src/maurimesh/evolution/EvolutionTypes.ts" "BLOCK_AUTONOMOUS_CHANGE"
check_contains "canAutoApply false" "src/maurimesh/evolution/EvolutionTypes.ts" "canAutoApply: false"
check_contains "Primary evolution source" "src/maurimesh/evolution/EvolutionTypes.ts" "PRIMARY_EVOLUTION_ENGINE"
check_contains "Backup evolution source" "src/maurimesh/evolution/EvolutionTypes.ts" "BACKUP_EVOLUTION_MEMORY"
check_contains "Safe fallback evolution source" "src/maurimesh/evolution/EvolutionTypes.ts" "SAFE_FALLBACK_EVOLUTION"
check_contains "Tikanga notes present" "src/maurimesh/evolution/EvolutionEngine.ts" "tikangaNotes"
check_contains "No silent rewrite truth boundary" "src/maurimesh/evolution/EvolutionEngine.ts" "does not silently rewrite code"
check_contains "No fake BLE proof boundary" "src/maurimesh/evolution/EvolutionEngine.ts" "fake BLE proof"

{
  echo ""
  echo "## UI Wiring"
} >> "$REPORT"

check_contains "Evolution route uses panel" "app/evolution-layer.tsx" "EvolutionLayerPanel"
check_contains "Evolution panel uses MaoriProtocolPanel" "src/components/EvolutionLayerPanel.tsx" "MaoriProtocolPanel"
check_contains "Dashboard references /evolution-layer" "app/dashboard.tsx" "/evolution-layer"
check_contains "Backup registry references /evolution-layer" "src/lib/uiBackupRoutes.ts" "/evolution-layer"
check_contains "Test layer references /evolution-layer" "src/maurimesh/test-layer/MauriMeshFullTestEngine.ts" "/evolution-layer"

{
  echo ""
  echo "## TypeScript"
} >> "$REPORT"

TOTAL=$((TOTAL+1))
if npx tsc --noEmit >> "$REPORT" 2>&1; then
  echo "- [x] TypeScript passed" >> "$REPORT"
  PASS=$((PASS+1))
else
  echo "- [ ] TypeScript failed" >> "$REPORT"
  FAIL=$((FAIL+1))
fi

{
  echo ""
  echo "## Expo Android Export"
} >> "$REPORT"

TOTAL=$((TOTAL+1))
rm -rf "$EXPORT_DIR"
if NODE_ENV=production npx expo export --platform android --output-dir "$EXPORT_DIR" >> "$REPORT" 2>&1; then
  echo "- [x] Expo Android export passed" >> "$REPORT"
  PASS=$((PASS+1))
else
  echo "- [ ] Expo Android export failed" >> "$REPORT"
  FAIL=$((FAIL+1))
fi

BUNDLE_FILE="$(find "$EXPORT_DIR" -type f \( -name '*.hbc' -o -name '*.js' \) | head -1 || true)"

{
  echo ""
  echo "## Bundle Marker Search"
} >> "$REPORT"

TOTAL=$((TOTAL+1))
if [ -n "$BUNDLE_FILE" ] && strings "$BUNDLE_FILE" | grep -Ei "MAURIMESH EVOLUTION LAYER|Evolution Layer|PRIMARY_EVOLUTION_ENGINE|BACKUP_EVOLUTION_MEMORY|SAFE_FALLBACK_EVOLUTION|BLOCK_AUTONOMOUS_CHANGE|canAutoApply" >> "$REPORT" 2>&1; then
  echo "- [x] Evolution markers found in Android bundle" >> "$REPORT"
  PASS=$((PASS+1))
else
  echo "- [ ] Evolution markers not confirmed in Android bundle" >> "$REPORT"
  FAIL=$((FAIL+1))
fi

SCORE=$(( PASS * 100 / TOTAL ))
STATUS="COMPLETE"
if [ "$FAIL" -gt 0 ]; then
  STATUS="FAILED"
fi

{
  echo ""
  echo "## Summary"
  echo ""
  echo "- Total: $TOTAL"
  echo "- Complete: $PASS"
  echo "- Missing/failed: $FAIL"
  echo "- Score: $SCORE%"
  echo "- Status: **$STATUS**"
  echo ""
  echo "## Final Truth"
  echo ""
  echo "The Evolution Layer is a controlled self-improvement layer."
  echo "It observes system signals, scores readiness, recommends next improvements, and requires operator approval."
  echo "It does not silently rewrite code, fake BLE proof, bypass Android protections, or claim APK/device success without evidence."
} >> "$REPORT"

cp "$REPORT" "$LATEST"
cat "$REPORT"

echo ""
echo "============================================================"
echo "EVOLUTION LAYER CHECK COMPLETE"
echo "Status: $STATUS"
echo "Score: $SCORE%"
echo "Report: $LATEST"
echo "============================================================"

if [ "$STATUS" != "COMPLETE" ]; then
  exit 1
fi
