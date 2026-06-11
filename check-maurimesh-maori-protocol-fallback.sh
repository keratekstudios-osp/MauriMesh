#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
REPORT="$ROOT/docs/maurimesh-maori-protocol-fallback-report-$STAMP.md"
LATEST="$ROOT/docs/maurimesh-maori-protocol-fallback-report-latest.md"
EXPORT_DIR="$ROOT/.maurimesh-maori-protocol-export-$STAMP"

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
  echo "# MauriMesh Māori Protocol Fallback Report"
  echo ""
  echo "Generated: $STAMP"
  echo ""
  echo "## Files"
} >> "$REPORT"

check_file "Protocol types" "src/maurimesh/protocols/MaoriProtocolTypes.ts"
check_file "Protocol registry" "src/maurimesh/protocols/MaoriProtocolRegistry.ts"
check_file "Fallback engine" "src/maurimesh/protocols/MaoriProtocolFallbackEngine.ts"
check_file "Protocol index" "src/maurimesh/protocols/index.ts"
check_file "Protocol panel" "src/components/MaoriProtocolPanel.tsx"
check_file "Māori protocols route" "app/maori-protocols.tsx"

{
  echo ""
  echo "## Required Te Reo / Tikanga Terms"
} >> "$REPORT"

check_contains "Tikanga term" "src/maurimesh/protocols/MaoriProtocolRegistry.ts" "Tikanga"
check_contains "Tapu term" "src/maurimesh/protocols/MaoriProtocolRegistry.ts" "Tapu"
check_contains "Noa term" "src/maurimesh/protocols/MaoriProtocolRegistry.ts" "Noa"
check_contains "Mana term" "src/maurimesh/protocols/MaoriProtocolRegistry.ts" "Mana"
check_contains "Mauri term" "src/maurimesh/protocols/MaoriProtocolRegistry.ts" "Mauri"
check_contains "Whakapapa Ara term" "src/maurimesh/protocols/MaoriProtocolRegistry.ts" "Whakapapa Ara"
check_contains "Kaitiakitanga term" "src/maurimesh/protocols/MaoriProtocolRegistry.ts" "Kaitiakitanga"
check_contains "Rangatiratanga term" "src/maurimesh/protocols/MaoriProtocolRegistry.ts" "Rangatiratanga"
check_contains "Whanaungatanga term" "src/maurimesh/protocols/MaoriProtocolRegistry.ts" "Whanaungatanga"
check_contains "Arotake term" "src/maurimesh/protocols/MaoriProtocolRegistry.ts" "Arotake"
check_contains "Kāore anō kia whakamātau term" "src/maurimesh/protocols/MaoriProtocolRegistry.ts" "Kāore anō kia whakamātau"
check_contains "Me whakamātau ki te APK term" "src/maurimesh/protocols/MaoriProtocolRegistry.ts" "Me whakamātau ki te APK"

{
  echo ""
  echo "## Fallback + Backup"
} >> "$REPORT"

check_contains "Primary source exists" "src/maurimesh/protocols/MaoriProtocolTypes.ts" "PRIMARY_TIKANGA_ENGINE"
check_contains "Backup source exists" "src/maurimesh/protocols/MaoriProtocolTypes.ts" "BACKUP_PROTOCOL_REGISTRY"
check_contains "Safe fallback source exists" "src/maurimesh/protocols/MaoriProtocolTypes.ts" "SAFE_FALLBACK_PROTOCOL"
check_contains "Fallback summary exists" "src/maurimesh/protocols/MaoriProtocolFallbackEngine.ts" "MAORI_PROTOCOL_FALLBACK_READY"

{
  echo ""
  echo "## UI Wiring"
} >> "$REPORT"

check_contains "Dashboard has protocol panel" "app/dashboard.tsx" "MaoriProtocolPanel"
check_contains "Tikanga screen has protocol panel" "app/tikanga-engine.tsx" "MaoriProtocolPanel"
check_contains "JumpCode screen has protocol panel" "app/jumpcode-proof.tsx" "MaoriProtocolPanel"
check_contains "Test Layer has protocol panel" "app/test-layer.tsx" "MaoriProtocolPanel"
check_contains "Proof Ledger has protocol panel" "app/proof-ledger.tsx" "MaoriProtocolPanel"
check_contains "Device Proof has protocol panel" "app/device-proof.tsx" "MaoriProtocolPanel"
check_contains "Message Fallback has protocol panel" "app/message-fallback.tsx" "MaoriProtocolPanel"
check_contains "Route Lab has protocol panel" "app/route-lab.tsx" "MaoriProtocolPanel"
check_contains "MauriCore Governance has protocol panel" "app/mauricore-governance.tsx" "MaoriProtocolPanel"
check_contains "Dashboard route marker" "app/dashboard.tsx" "/maori-protocols"
check_contains "Backup registry route marker" "src/lib/uiBackupRoutes.ts" "/maori-protocols"
check_contains "Test layer route marker" "src/maurimesh/test-layer/MauriMeshFullTestEngine.ts" "/maori-protocols"

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
if [ -n "$BUNDLE_FILE" ] && strings "$BUNDLE_FILE" | grep -Ei "TE REO / TIKANGA|Tikanga|Whakapapa Ara|Kaitiakitanga|Rangatiratanga|MAORI_PROTOCOL_FALLBACK_READY|Me whakam" >> "$REPORT" 2>&1; then
  echo "- [x] Māori protocol markers found in Android bundle" >> "$REPORT"
  PASS=$((PASS+1))
else
  echo "- [ ] Māori protocol markers not confirmed in Android bundle" >> "$REPORT"
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
  echo "Māori protocol visibility has been restored with primary, backup, and safe fallback layers."
  echo "This restores te reo Māori/Tikanga proof labels in the UI and bundle."
  echo "It does not by itself prove real BLE delivery, real ACK, native telemetry, or installed APK success."
} >> "$REPORT"

cp "$REPORT" "$LATEST"
cat "$REPORT"

echo ""
echo "============================================================"
echo "MĀORI PROTOCOL FALLBACK CHECK COMPLETE"
echo "Status: $STATUS"
echo "Score: $SCORE%"
echo "Report: $LATEST"
echo "============================================================"

if [ "$STATUS" != "COMPLETE" ]; then
  exit 1
fi
