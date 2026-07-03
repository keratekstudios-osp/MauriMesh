#!/usr/bin/env bash
set -euo pipefail

APP_ID="com.maurimesh.messenger"
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT="$HOME/Desktop/maurimesh-real-device-proof-$STAMP"
mkdir -p "$OUT"

echo ""
echo "============================================================"
echo "MAURIMESH REAL DEVICE PROOF LOGGER"
echo "Use for APK/logcat phase after ADB sees phone as device."
echo "============================================================"
echo ""

adb devices -l | tee "$OUT/adb-devices.txt"

SERIAL="$(adb devices | awk 'NR>1 && $2=="device"{print $1; exit}')"
if [ -z "${SERIAL:-}" ]; then
  echo "No authorized ADB device found."
  echo "Fix USB/cable/debugging first."
  exit 1
fi

echo "$SERIAL" > "$OUT/phone-a-serial.txt"

adb -s "$SERIAL" logcat -c
adb -s "$SERIAL" shell am force-stop "$APP_ID" || true
adb -s "$SERIAL" shell monkey -p "$APP_ID" -c android.intent.category.LAUNCHER 1

echo ""
echo "Live log started. Run /test-layer in the app, then run messaging/BLE test."
echo "Press CTRL+C to stop."
echo ""

adb -s "$SERIAL" logcat \
  | grep -E "MauriMesh|maurimesh|AndroidRuntime|FATAL EXCEPTION|ReactNativeJS|NATIVE_ANDROID|JS_FALLBACK|BLE|Bluetooth|TX_BLE|RX_BLE|SCAN|ADVERTISE|PHONE_A|PHONE_B|PHONE_C|STRICT_ACK|RELAY_ACK|NO_ACK_YET|DELIVERY_PENDING_PROOF|STORE_FORWARD|PROOF_LEDGER|CALL_|PIXEL|RECONSTRUCTED_PIXEL_ACK|AI_PIXELS_CORRECTED|RAW_32K_LIVE_FALSE" \
  | tee "$OUT/live-maurimesh-proof-log.txt"
