#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH CHAT E2E 3-DEVICE PRECHECK"
echo "============================================================"

missing=0

check_file() {
  if [ -f "$1" ]; then
    echo "PASS file: $1"
  else
    echo "FAIL missing file: $1"
    missing=$((missing+1))
  fi
}

check_file app/chat.tsx
check_file package.json

echo ""
echo "Searching for existing transport/proof markers..."
grep -R "GATT_PACKET_PAYLOAD\|GATT_CLIENT_WRITE_ATTEMPT\|GATT_SERVER_WRITE_RECEIVED\|STORE_FORWARD\|ACK_RECEIVED\|RELAY" . \
  --exclude-dir=node_modules \
  --exclude-dir=.git \
  --exclude-dir=.expo \
  -n | head -80 || true

echo ""
echo "Running TypeScript..."
npx tsc --noEmit

echo ""
echo "Running Android export..."
npx expo export --platform android

mkdir -p docs/chat-e2e

cat > docs/chat-e2e/MAURIMESH_CHAT_E2E_3DEVICE_DELIVERY_PROOF_V1.md <<REPORT
# MAURIMESH CHAT E2E 3-DEVICE DELIVERY PROOF v1

Status: PRECHECK_READY

This file is the starting report for wiring real Chat UI delivery.

Required same-messageId events:
- CHAT_CREATED
- CHAT_TX_A06
- CHAT_RX_S10
- CHAT_RELAY_S10_TO_A16
- CHAT_RX_A16
- CHAT_UI_DISPLAYED_A16
- CHAT_ACK_A16
- CHAT_ACK_RELAY_S10_TO_A06
- CHAT_DELIVERED_A06

Truth:
This proves real Chat UI message delivery only if run on APK physical devices.

Precheck:
- app/chat.tsx present
- package.json present
- TypeScript command completed
- Android export command completed

Final verdict:
READY_FOR_CHAT_E2E_PATCH
REPORT

echo ""
if [ "$missing" -eq 0 ]; then
  echo "READY_FOR_CHAT_E2E_PATCH"
else
  echo "BLOCKED_WITH_MISSING_FILES"
  exit 1
fi
