#!/usr/bin/env bash
set -euo pipefail

PKG="${1:-com.maurimesh}"
DEVICE="${2:-}"

if [ -z "$DEVICE" ]; then
  DEVICE="$(adb devices | awk 'NR==2 {print $1}')"
fi

if [ -z "$DEVICE" ]; then
  echo "No Android device found."
  exit 1
fi

echo "MauriMesh BLE Runtime Proof"
echo "Device: $DEVICE"
echo "Package: $PKG"

echo ""
echo "1. Clear logs"
adb -s "$DEVICE" logcat -c

echo ""
echo "2. Force stop app"
adb -s "$DEVICE" shell am force-stop "$PKG" || true

echo ""
echo "3. Launch app"
adb -s "$DEVICE" shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1

sleep 8

PID="$(adb -s "$DEVICE" shell pidof "$PKG" | tr -d '\r' || true)"

if [ -z "$PID" ]; then
  echo "App is not running."
  adb -s "$DEVICE" logcat -d -b crash
  exit 1
fi

echo "PID: $PID"

echo ""
echo "4. Capturing MauriMesh BLE logs for 90 seconds..."
timeout 90 adb -s "$DEVICE" logcat \
  | grep -E "MauriMesh|BluetoothSuper|BLE|peer|advertise|scan|GATT|ACK|JumpCode|sqrt2|runtime" \
  || true

echo ""
echo "5. Crash buffer"
adb -s "$DEVICE" logcat -d -b crash || true

echo ""
echo "BLE runtime proof capture complete."
