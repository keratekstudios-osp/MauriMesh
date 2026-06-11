#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
REPORT="$ROOT/docs/maurimesh-full-mesh-test-report-$STAMP.md"
LATEST="$ROOT/docs/maurimesh-full-mesh-test-report-latest.md"
EXPORT_DIR="$ROOT/.maurimesh-full-mesh-test-export-$STAMP"

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
  echo "# MauriMesh Full Mesh Test Report Install Check"
  echo ""
  echo "Generated: $STAMP"
  echo ""
  echo "## Files"
} >> "$REPORT"

check_file "Generated route registry" "src/maurimesh/full-mesh-test/GeneratedRouteRegistry.ts"
check_file "Full Mesh Test types" "src/maurimesh/full-mesh-test/FullMeshTestTypes.ts"
check_file "Full Mesh Test engine" "src/maurimesh/full-mesh-test/FullMeshTestEngine.ts"
check_file "Full Mesh Test index" "src/maurimesh/full-mesh-test/index.ts"
check_file "Full Mesh Test panel" "src/components/FullMeshTestReportPanel.tsx"
check_file "Full Mesh Test route" "app/full-mesh-test-report.tsx"

{
  echo ""
  echo "## Markers"
} >> "$REPORT"

check_contains "Copy block marker" "src/maurimesh/full-mesh-test/FullMeshTestEngine.ts" "MAURIMESH FULL MESH TEST REPORT"
check_contains "Final truth boundary" "src/maurimesh/full-mesh-test/FullMeshTestEngine.ts" "does not by itself prove real BLE"
check_contains "Two-phone proof gate" "src/maurimesh/full-mesh-test/FullMeshTestEngine.ts" "TWO_PHONE_REQUIRED"
check_contains "Three-hop proof gate" "src/maurimesh/full-mesh-test/FullMeshTestEngine.ts" "THREE_PHONE_REQUIRED"
check_contains "Native proof gate" "src/maurimesh/full-mesh-test/FullMeshTestEngine.ts" "NATIVE_REQUIRED"
check_contains "Rust proof gate" "src/maurimesh/full-mesh-test/FullMeshTestEngine.ts" "Rust APK bridge proof"
check_contains "Māori protocol panel included" "src/components/FullMeshTestReportPanel.tsx" "MaoriProtocolPanel"
check_contains "TextInput copy box included" "src/components/FullMeshTestReportPanel.tsx" "TextInput"
check_contains "Share report included" "src/components/FullMeshTestReportPanel.tsx" "Share.share"
check_contains "Dashboard route marker" "app/dashboard.tsx" "/full-mesh-test-report"
check_contains "Backup route marker" "src/lib/uiBackupRoutes.ts" "/full-mesh-test-report"

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
if [ -n "$BUNDLE_FILE" ] && strings "$BUNDLE_FILE" | grep -Ei "MAURIMESH FULL MESH TEST REPORT|Full Mesh Test Report|TWO_PHONE_REQUIRED|THREE_PHONE_REQUIRED|NATIVE_REQUIRED|does not by itself prove real BLE" >> "$REPORT" 2>&1; then
  echo "- [x] Full Mesh Test Report markers found in Android bundle" >> "$REPORT"
  PASS=$((PASS+1))
else
  echo "- [ ] Full Mesh Test Report markers not confirmed in Android bundle" >> "$REPORT"
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
  echo "The Full Mesh Test Report screen is installed."
  echo "It provides one copyable in-APK activity/proof report block."
  echo "It does not fake BLE, ACK, relay, native telemetry, Rust, or Pixel Calling proof."
} >> "$REPORT"

cp "$REPORT" "$LATEST"
cat "$REPORT"

echo ""
echo "============================================================"
echo "FULL MESH TEST REPORT CHECK COMPLETE"
echo "Status: $STATUS"
echo "Score: $SCORE%"
echo "Report: $LATEST"
echo "============================================================"

if [ "$STATUS" != "COMPLETE" ]; then
  exit 1
fi
