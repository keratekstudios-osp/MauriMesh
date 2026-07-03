#!/usr/bin/env bash
set -euo pipefail

A16="192.168.1.2:5555"
A06="192.168.1.5:5555"
S10="192.168.1.6:5555"
PKG="com.maurimesh.messenger"
OUT="$HOME/Desktop/maurimesh-gatt-bridge-v5-test-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$OUT"

echo ""
echo "============================================================"
echo "MAURIMESH NATIVE GATT BRIDGE v5 PHONE TEST"
echo "============================================================"
echo "Run on Mac Terminal after installing the new APK."
echo "Then press Reset Packet and Trigger Native GATT Packet Payload."
echo "============================================================"
echo ""

adb connect "$A16" || true
adb connect "$A06" || true
adb connect "$S10" || true
adb devices -l | tee "$OUT/adb-devices.txt"

for D in "$A16" "$A06" "$S10"; do
  adb -s "$D" logcat -c || true
done

adb -s "$A16" logcat -v time | grep -E "ReactNativeJS|MAURIMESH_NATIVE_BLE_GATT|BUTTON_PRESS|GATT_TRIGGER|GATT_HELPER|GATT_PACKET_PAYLOAD|GATT_CLIENT_WRITE_ATTEMPT|GATT_SERVER_WRITE_RECEIVED|nativePacketBound|AndroidRuntime|FATAL|Exception" | tee "$OUT/a16.log" &
adb -s "$A06" logcat -v time | grep -E "ReactNativeJS|MAURIMESH_NATIVE_BLE_GATT|BUTTON_PRESS|GATT_TRIGGER|GATT_HELPER|GATT_PACKET_PAYLOAD|GATT_CLIENT_WRITE_ATTEMPT|GATT_SERVER_WRITE_RECEIVED|nativePacketBound|AndroidRuntime|FATAL|Exception" | tee "$OUT/a06.log" &
adb -s "$S10" logcat -v time | grep -E "ReactNativeJS|MAURIMESH_NATIVE_BLE_GATT|BUTTON_PRESS|GATT_TRIGGER|GATT_HELPER|GATT_PACKET_PAYLOAD|GATT_CLIENT_WRITE_ATTEMPT|GATT_SERVER_WRITE_RECEIVED|nativePacketBound|AndroidRuntime|FATAL|Exception" | tee "$OUT/s10.log" &

echo ""
echo "Output: $OUT"
echo ""
echo "Now on phone:"
echo "1. Open Native BLE/GATT Truth Gate"
echo "2. Press Reset Packet"
echo "3. Press Trigger Native GATT Packet Payload"
echo ""
echo "After pressing, inspect:"
echo "grep -R \"BUTTON_PRESS\\|GATT_TRIGGER\\|GATT_HELPER\\|GATT_PACKET_PAYLOAD\\|GATT_CLIENT_WRITE_ATTEMPT\\|GATT_SERVER_WRITE_RECEIVED\\|nativePacketBound\" \"$OUT\""
echo ""

sleep 2
jobs || true
