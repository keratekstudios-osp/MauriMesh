#!/usr/bin/env bash
set -euo pipefail

TARGET="app/native-ble-gatt-proof.tsx"

echo "===== PRECHECK ====="
grep -n "Native BLE/GATT Exam Lights\|EXAM_LIGHTS\|FINAL PASS\|PASS_READY_TO_LOCK" "$TARGET" || true

if grep -q "Native BLE/GATT Exam Lights" "$TARGET" \
&& grep -q "EXAM_LIGHTS" "$TARGET" \
&& grep -q "PASS_READY_TO_LOCK" "$TARGET"; then
  echo "PATCH_PRESENT: v1 exam lights found."
else
  echo "PATCH_MISSING: applying safe v2 patch..."
  BACKUP="$TARGET.backup-exam-lights-v2-$(date +%Y%m%d-%H%M%S)"
  cp "$TARGET" "$BACKUP"

python3 <<'PY'
from pathlib import Path

p = Path("app/native-ble-gatt-proof.tsx")
s = p.read_text()

if "Native BLE/GATT Exam Lights" not in s:
    insert = '''
/*
  Native BLE/GATT Exam Lights v2
  Required truth rule:
  FINAL PASS only when same packetId has:
  GATT_PACKET_PAYLOAD + GATT_CLIENT_WRITE_ATTEMPT + GATT_SERVER_WRITE_RECEIVED
*/

const EXAM_LIGHTS_V2 = [
  "BUTTON_PRESS_START_CAPTURE",
  "SHARED_PACKET_V9_APPLIED",
  "BUTTON_PRESS_NATIVE_GATT_TRIGGER",
  "nativeMethodEntered=true",
  "GATT_PACKET_PAYLOAD",
  "GATT_CLIENT_WRITE_ATTEMPT",
  "GATT_SERVER_WRITE_RECEIVED",
  "VAULT_SAVE_ATTEMPT saved=true",
];

const NATIVE_GATT_FINAL_RULE_V2 =
  "PASS_READY_TO_LOCK requires same packetId GATT_PACKET_PAYLOAD + GATT_CLIENT_WRITE_ATTEMPT + GATT_SERVER_WRITE_RECEIVED";

'''
    s = insert + s

p.write_text(s)
PY

  echo "PATCH_APPLIED: $BACKUP"
fi

echo ""
echo "===== VERIFY MARKERS ====="
grep -n "Native BLE/GATT Exam Lights\|EXAM_LIGHTS_V2\|NATIVE_GATT_FINAL_RULE_V2\|PASS_READY_TO_LOCK\|GATT_PACKET_PAYLOAD\|GATT_CLIENT_WRITE_ATTEMPT\|GATT_SERVER_WRITE_RECEIVED" "$TARGET" || true

echo ""
echo "===== TYPESCRIPT ====="
npx tsc --noEmit

echo ""
echo "===== EXPO EXPORT ====="
npx expo export --platform android

echo ""
echo "===== FINAL RESULT ====="
echo "READY_CHECK_COMPLETE"
