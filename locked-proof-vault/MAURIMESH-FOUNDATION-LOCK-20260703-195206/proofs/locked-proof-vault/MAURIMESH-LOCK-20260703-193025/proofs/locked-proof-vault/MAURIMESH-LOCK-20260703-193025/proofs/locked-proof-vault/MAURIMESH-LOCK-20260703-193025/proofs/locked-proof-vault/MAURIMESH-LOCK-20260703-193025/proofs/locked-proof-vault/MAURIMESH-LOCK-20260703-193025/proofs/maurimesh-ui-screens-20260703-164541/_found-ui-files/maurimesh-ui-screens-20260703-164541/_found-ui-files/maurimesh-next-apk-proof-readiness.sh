#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH APK PROOF READINESS GATE"
echo "Checks 2-hop proof UI before APK rebuild"
echo "============================================================"
echo ""

REPORT="docs/maurimesh-apk-proof-readiness-report.md"
STAMP="$(date +%Y%m%d-%H%M%S)"

mkdir -p docs

PASS=true

check_file() {
  local f="$1"
  if [ -f "$f" ]; then
    echo "OK: $f"
  else
    echo "MISSING: $f"
    PASS=false
  fi
}

check_contains() {
  local f="$1"
  local text="$2"
  local label="$3"

  if grep -q "$text" "$f" 2>/dev/null; then
    echo "OK: $label"
  else
    echo "MISSING: $label"
    PASS=false
  fi
}

echo "[1] Required files"
check_file app/dashboard.tsx
check_file app/proof-2-hop.tsx
check_file app/_layout.tsx
check_file package.json

echo ""
echo "[2] Dashboard route"
check_contains app/dashboard.tsx "proof-2-hop" "Dashboard links to /proof-2-hop"

echo ""
echo "[3] Proof event names"
check_contains app/proof-2-hop.tsx "PACKET_ID_GENERATED" "PACKET_ID_GENERATED"
check_contains app/proof-2-hop.tsx "TX_A06_TO_S10" "TX_A06_TO_S10"
check_contains app/proof-2-hop.tsx "PACKET_ID_CONFIRMED_ON_S10" "PACKET_ID_CONFIRMED_ON_S10"
check_contains app/proof-2-hop.tsx "RX_S10_FROM_A06" "RX_S10_FROM_A06"
check_contains app/proof-2-hop.tsx "ACK_RELAY_S10_TO_A06" "ACK_RELAY_S10_TO_A06"
check_contains app/proof-2-hop.tsx "ACK_BACK_TO_A06" "ACK_BACK_TO_A06"

echo ""
echo "[4] Stage UI"
check_contains app/proof-2-hop.tsx "NEXT STAGE READY" "Next-stage banner"
check_contains app/proof-2-hop.tsx "Alert.alert" "Operator popup alert"
check_contains app/proof-2-hop.tsx "A06_SENDER" "A06 sender role"
check_contains app/proof-2-hop.tsx "S10_RELAY" "S10 relay role"
check_contains app/proof-2-hop.tsx "#F59E0B" "Amber ready colour"
check_contains app/proof-2-hop.tsx "#A855F7" "Purple ACK colour"
check_contains app/proof-2-hop.tsx "#22C55E" "Green complete colour"

echo ""
echo "[5] Dependency safety"
if grep -q "expo-notifications" app/proof-2-hop.tsx 2>/dev/null; then
  echo "FAIL: expo-notifications still imported"
  PASS=false
else
  echo "OK: no expo-notifications dependency"
fi

echo ""
echo "[6] TypeScript"
if npx tsc --noEmit; then
  TS_RESULT="PASS"
  echo "OK: TypeScript passed"
else
  TS_RESULT="FAIL"
  PASS=false
  echo "FAIL: TypeScript failed"
fi

echo ""
echo "[7] Writing report"
cat > "$REPORT" <<MD
# MauriMesh APK Proof Readiness Report

Generated: $STAMP

## Status

Overall readiness: $([ "$PASS" = true ] && echo "PASS" || echo "FAIL")

## Checked

- Dashboard route to /proof-2-hop
- 2-hop proof screen exists
- A06 sender role exists
- S10 relay / ACK role exists
- Lit button stage colours exist
- NEXT STAGE READY banner exists
- Alert popup operator notification exists
- No expo-notifications dependency
- Required packet proof event names exist
- TypeScript result: $TS_RESULT

## Required Proof Events

Final hardware PASS requires same packetId across:

1. PACKET_ID_GENERATED
2. TX_A06_TO_S10
3. RX_S10_FROM_A06
4. ACK_RELAY_S10_TO_A06
5. ACK_BACK_TO_A06

## Truth Rule

This Replit check proves UI, routing, stage logic, and TypeScript readiness.

It does not prove real BLE.

Real BLE proof requires APK installed on physical A06 and S10 devices with matching packetId logs.

## Next Build Command

Use EAS preview APK build:

\`\`\`bash
npx eas-cli build --platform android --profile preview-apk --clear-cache
\`\`\`

MD

echo "Report written: $REPORT"

echo ""
echo "============================================================"
if [ "$PASS" = true ]; then
  echo "APK PROOF READINESS: PASS"
  echo "You can rebuild the APK now."
else
  echo "APK PROOF READINESS: FAIL"
  echo "Fix the failed item above before rebuilding APK."
  exit 1
fi
echo "============================================================"
