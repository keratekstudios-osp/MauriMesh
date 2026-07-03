#!/usr/bin/env bash
set -euo pipefail

PKG="com.maurimesh.messenger"
A16="${1:-RF8Y303XPFM}"
OUT="$HOME/Desktop/maurimesh-gatt-registration-v7-test-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$OUT"

echo ""
echo "============================================================"
echo "MAURIMESH GATT REGISTRATION v7 A16 TEST"
echo "============================================================"
echo "Device: $A16"
echo "Output: $OUT"
echo "============================================================"

adb devices -l | tee "$OUT/adb-devices.txt"

adb -s "$A16" shell am force-stop "$PKG" || true
adb -s "$A16" logcat -c || true
adb -s "$A16" shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 >/dev/null

sleep 3

LOG="$OUT/a16-registration-v7.log"

adb -s "$A16" logcat -v time | grep -E "ReactNativeJS|MAURIMESH_NATIVE_BLE_GATT|GATT_PACKAGE_REGISTRATION_V7|GATT_PACKAGE_CREATE_NATIVE_MODULES_V7|GATT_PACKAGE_MODULE_ADDED_V7|GATT_MODULE_CONSTRUCTOR_V7|GATT_MODULE_GET_NAME_V7|BUTTON_PRESS|GATT_TRIGGER|GATT_HELPER|NATIVE_GATT_TRIGGER_UNAVAILABLE|NativeModules|GATT_PACKET_PAYLOAD|GATT_CLIENT_WRITE_ATTEMPT|GATT_SERVER_WRITE_RECEIVED|nativePacketBound|AndroidRuntime|FATAL|Exception" | tee "$LOG" &
PID=$!

echo ""
echo "ACTION NOW:"
echo "1. Open Native BLE/GATT Truth Gate"
echo "2. Press Reset Packet"
echo "3. Press Trigger Native GATT Packet Payload"
echo "4. Wait 5 seconds"
echo "5. Press ENTER here"
read -r _

sleep 2
kill "$PID" 2>/dev/null || true

echo ""
echo "============================================================"
echo "REGISTRATION v7 RESULT"
echo "============================================================"
grep -E "GATT_PACKAGE_REGISTRATION_V7|GATT_PACKAGE_CREATE_NATIVE_MODULES_V7|GATT_PACKAGE_MODULE_ADDED_V7|GATT_MODULE_CONSTRUCTOR_V7|GATT_MODULE_GET_NAME_V7|BUTTON_PRESS|GATT_TRIGGER|GATT_HELPER|NATIVE_GATT_TRIGGER_UNAVAILABLE|NativeModules|GATT_PACKET_PAYLOAD|GATT_CLIENT_WRITE_ATTEMPT|GATT_SERVER_WRITE_RECEIVED|nativePacketBound" "$LOG" || true

echo ""
echo "Counts:"
echo "REGISTRATION: $(grep -c 'GATT_PACKAGE_REGISTRATION_V7' "$LOG" 2>/dev/null || echo 0)"
echo "CREATE_MODULES: $(grep -c 'GATT_PACKAGE_CREATE_NATIVE_MODULES_V7' "$LOG" 2>/dev/null || echo 0)"
echo "MODULE_CONSTRUCTOR: $(grep -c 'GATT_MODULE_CONSTRUCTOR_V7' "$LOG" 2>/dev/null || echo 0)"
echo "GET_NAME: $(grep -c 'GATT_MODULE_GET_NAME_V7' "$LOG" 2>/dev/null || echo 0)"
echo "TRIGGER_ENTERED: $(grep -c 'GATT_TRIGGER_NATIVE_METHOD_ENTERED' "$LOG" 2>/dev/null || echo 0)"
echo "UNAVAILABLE: $(grep -c 'NATIVE_GATT_TRIGGER_UNAVAILABLE\|Native GATT trigger unavailable' "$LOG" 2>/dev/null || echo 0)"

echo ""
if grep -q "GATT_TRIGGER_NATIVE_METHOD_ENTERED" "$LOG"; then
  echo "VERDICT: NATIVE_MODULE_REGISTERED_AND_TRIGGER_ENTERED"
elif grep -q "GATT_PACKAGE_CREATE_NATIVE_MODULES_V7" "$LOG"; then
  echo "VERDICT: PACKAGE_LOADED_BUT_JS_STILL_NOT_CALLING_MODULE"
elif grep -q "GATT_PACKAGE_REGISTRATION_V7" "$LOG"; then
  echo "VERDICT: MAINAPPLICATION_ADDED_PACKAGE_BUT_CREATE_MODULES_NOT_SEEN"
else
  echo "VERDICT: MAINAPPLICATION_REGISTRATION_NOT_RUNNING_OR_WRONG_APK"
fi

echo "Log: $LOG"
echo "Output: $OUT"
echo "============================================================"
