#!/usr/bin/env bash
set -euo pipefail

echo "=== MauriMesh GATT instrumentation prep ==="

mkdir -p docs/native-ble-gatt scripts

echo "1) Finding native BLE/GATT files..."
grep -RIn \
  "triggerGattPacketPayloadProof\|triggerGattPacketPayload\|GATT_CLIENT_WRITE\|GATT_SERVER_WRITE\|BLE_SCAN_CALLBACK_DEVICE" \
  app src android 2>/dev/null | tee docs/native-ble-gatt/GATT_TARGET_FILE_SCAN.txt || true

echo ""
echo "2) Finding Kotlin/Java native files..."
find android -type f \( -name "*.kt" -o -name "*.java" \) | grep -Ei \
  "MauriMesh|Gatt|Ble|Bluetooth|MeshCentral|RawPacket" \
  | tee docs/native-ble-gatt/GATT_NATIVE_FILE_LIST.txt || true

echo ""
echo "3) Finding Truth Gate screen..."
find app src -type f \( -name "*.tsx" -o -name "*.ts" \) | grep -Ei \
  "native|ble|gatt|proof|truth" \
  | tee docs/native-ble-gatt/GATT_SCREEN_FILE_LIST.txt || true

echo ""
echo "4) Checking Android permissions..."
grep -RIn \
  "BLUETOOTH_SCAN\|BLUETOOTH_CONNECT\|BLUETOOTH_ADVERTISE\|ACCESS_FINE_LOCATION" \
  app.json app.config.* android 2>/dev/null \
  | tee docs/native-ble-gatt/GATT_PERMISSION_SCAN.txt || true

echo ""
echo "5) TypeScript check..."
npx tsc --noEmit | tee docs/native-ble-gatt/GATT_TSC_RESULT.txt

echo ""
echo "6) Expo Android export..."
npx expo export --platform android | tee docs/native-ble-gatt/GATT_EXPO_EXPORT_RESULT.txt

echo ""
echo "READY_FOR_MANUAL_PATCH_TARGET_REVIEW"
echo "Reports saved in docs/native-ble-gatt/"
