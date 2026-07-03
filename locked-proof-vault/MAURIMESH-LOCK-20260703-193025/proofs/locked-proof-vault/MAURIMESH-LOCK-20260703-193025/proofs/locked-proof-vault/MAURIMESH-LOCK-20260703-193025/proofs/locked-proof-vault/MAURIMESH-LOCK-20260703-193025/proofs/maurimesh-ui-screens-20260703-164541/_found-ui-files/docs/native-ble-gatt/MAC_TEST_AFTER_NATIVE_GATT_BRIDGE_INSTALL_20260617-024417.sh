#!/usr/bin/env bash
set -euo pipefail

A16="192.168.1.2:5555"
A06="192.168.1.5:5555"
S10="192.168.1.6:5555"
PKG="com.maurimesh.messenger"

echo ""
echo "============================================================"
echo "MAURIMESH MAC TEST AFTER NATIVE GATT BRIDGE INSTALL"
echo "============================================================"
echo "Run this in Mac Terminal after installing the new APK."
echo "Then press: Trigger Native GATT Packet Payload"
echo "============================================================"
echo ""

adb connect "$A16" || true
adb connect "$A06" || true
adb connect "$S10" || true
adb devices -l

mkdir -p "$HOME/Desktop/maurimesh-gatt-bridge-test"

for D in "$A16" "$A06" "$S10"; do
  adb -s "$D" logcat -c || true
done

adb -s "$A16" logcat -v time | grep -E "ReactNativeJS|MAURIMESH_NATIVE_BLE_GATT|BUTTON_PRESS|GATT_TRIGGER|GATT_HELPER|GATT_PACKET_PAYLOAD|GATT_CLIENT_WRITE_ATTEMPT|GATT_SERVER_WRITE_RECEIVED|nativePacketBound|AndroidRuntime|FATAL|Exception" | tee "$HOME/Desktop/maurimesh-gatt-bridge-test/a16.log" &
adb -s "$A06" logcat -v time | grep -E "ReactNativeJS|MAURIMESH_NATIVE_BLE_GATT|BUTTON_PRESS|GATT_TRIGGER|GATT_HELPER|GATT_PACKET_PAYLOAD|GATT_CLIENT_WRITE_ATTEMPT|GATT_SERVER_WRITE_RECEIVED|nativePacketBound|AndroidRuntime|FATAL|Exception" | tee "$HOME/Desktop/maurimesh-gatt-bridge-test/a06.log" &
adb -s "$S10" logcat -v time | grep -E "ReactNativeJS|MAURIMESH_NATIVE_BLE_GATT|BUTTON_PRESS|GATT_TRIGGER|GATT_HELPER|GATT_PACKET_PAYLOAD|GATT_CLIENT_WRITE_ATTEMPT|GATT_SERVER_WRITE_RECEIVED|nativePacketBound|AndroidRuntime|FATAL|Exception" | tee "$HOME/Desktop/maurimesh-gatt-bridge-test/s10.log" &

echo ""
echo "Now on phone:"
echo "1. Open Native BLE/GATT Truth Gate."
echo "2. Press Reset Packet once."
echo "3. Press Trigger Native GATT Packet Payload once."
echo ""
echo "Expected minimum:"
echo "- BUTTON_PRESS_NATIVE_GATT_TRIGGER"
echo "- GATT_TRIGGER_NATIVE_METHOD_ENTERED"
echo ""
echo "Final target:"
echo "- GATT_CLIENT_WRITE_ATTEMPT"
echo "- GATT_PACKET_PAYLOAD"
echo "- GATT_SERVER_WRITE_RECEIVED"
echo ""

sleep 2
jobs || true

echo ""
echo "To inspect:"
echo 'grep -R "GATT_TRIGGER\|GATT_HELPER\|GATT_PACKET_PAYLOAD\|GATT_CLIENT_WRITE_ATTEMPT\|GATT_SERVER_WRITE_RECEIVED\|BUTTON_PRESS\|nativePacketBound" "$HOME/Desktop/maurimesh-gatt-bridge-test"'
