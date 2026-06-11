#!/usr/bin/env bash
set -euo pipefail

APP_ID="com.maurimesh.messenger"
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT="$HOME/Desktop/maurimesh-one-real-device-apk-test-$STAMP"
mkdir -p "$OUT"

echo ""
echo "============================================================"
echo "MAURIMESH ONE REAL DEVICE APK TEST"
echo "Tests installed APK on one Android device through ADB/logcat."
echo "============================================================"
echo ""

if ! command -v adb >/dev/null 2>&1; then
  echo "ADB not found. Install Android platform-tools first."
  exit 1
fi

adb kill-server || true
adb start-server || true
adb devices -l | tee "$OUT/adb-devices.txt"

SERIAL="$(adb devices | awk 'NR>1 && $2=="device"{print $1; exit}')"

if [ -z "${SERIAL:-}" ]; then
  echo ""
  echo "FAIL: No authorised ADB device found."
  echo "Fix USB cable/debugging first."
  exit 1
fi

echo "$SERIAL" > "$OUT/device-serial.txt"

echo ""
echo "Device info..."
{
  echo "SERIAL=$SERIAL"
  echo "MANUFACTURER=$(adb -s "$SERIAL" shell getprop ro.product.manufacturer | tr -d '\r')"
  echo "MODEL=$(adb -s "$SERIAL" shell getprop ro.product.model | tr -d '\r')"
  echo "ANDROID=$(adb -s "$SERIAL" shell getprop ro.build.version.release | tr -d '\r')"
  echo "SDK=$(adb -s "$SERIAL" shell getprop ro.build.version.sdk | tr -d '\r')"
} | tee "$OUT/device-info.txt"

echo ""
echo "Checking APK package..."
if adb -s "$SERIAL" shell pm list packages | grep -q "$APP_ID"; then
  echo "PASS: $APP_ID installed" | tee "$OUT/package-check.txt"
else
  echo "FAIL: $APP_ID not installed" | tee "$OUT/package-check.txt"
  echo "Install APK first:"
  echo "adb -s $SERIAL install -r /path/to/maurimesh.apk"
  exit 1
fi

echo ""
echo "Granting/checking common permissions..."
adb -s "$SERIAL" shell pm grant "$APP_ID" android.permission.BLUETOOTH_SCAN 2>/dev/null || true
adb -s "$SERIAL" shell pm grant "$APP_ID" android.permission.BLUETOOTH_CONNECT 2>/dev/null || true
adb -s "$SERIAL" shell pm grant "$APP_ID" android.permission.BLUETOOTH_ADVERTISE 2>/dev/null || true
adb -s "$SERIAL" shell pm grant "$APP_ID" android.permission.ACCESS_FINE_LOCATION 2>/dev/null || true
adb -s "$SERIAL" shell pm grant "$APP_ID" android.permission.ACCESS_COARSE_LOCATION 2>/dev/null || true
adb -s "$SERIAL" shell pm grant "$APP_ID" android.permission.CAMERA 2>/dev/null || true
adb -s "$SERIAL" shell pm grant "$APP_ID" android.permission.RECORD_AUDIO 2>/dev/null || true
adb -s "$SERIAL" shell pm grant "$APP_ID" android.permission.POST_NOTIFICATIONS 2>/dev/null || true

adb -s "$SERIAL" shell dumpsys package "$APP_ID" > "$OUT/package-dumpsys.txt" || true

echo ""
echo "Bluetooth state..."
adb -s "$SERIAL" shell settings get global bluetooth_on | tee "$OUT/bluetooth-on.txt" || true
adb -s "$SERIAL" shell dumpsys bluetooth_manager > "$OUT/bluetooth-manager.txt" || true

echo ""
echo "Battery state..."
adb -s "$SERIAL" shell dumpsys battery > "$OUT/battery.txt" || true

echo ""
echo "Launching APK..."
adb -s "$SERIAL" logcat -c
adb -s "$SERIAL" shell am force-stop "$APP_ID" || true
adb -s "$SERIAL" shell monkey -p "$APP_ID" -c android.intent.category.LAUNCHER 1 | tee "$OUT/launch.txt"

sleep 7

echo ""
echo "Capturing crash and MauriMesh logs..."
adb -s "$SERIAL" logcat -d > "$OUT/full-startup-logcat.txt"

adb -s "$SERIAL" logcat -d \
  | grep -E "AndroidRuntime|FATAL EXCEPTION|ReactNativeJS|MauriMesh|maurimesh|NATIVE_ANDROID|JS_FALLBACK|Bluetooth|BLE|TX_BLE|RX_BLE|ACK|STRICT_ACK|RELAY_ACK|DELIVERY_PENDING_PROOF|STORE_FORWARD|CALL_|PIXEL|RECONSTRUCTED|AI_PIXEL|RAW_32K_LIVE_FALSE" \
  | tail -600 \
  | tee "$OUT/filtered-startup-logcat.txt" || true

echo ""
echo "Checking process..."
if adb -s "$SERIAL" shell pidof "$APP_ID" >/dev/null 2>&1; then
  echo "APP_RUNNING=YES" | tee "$OUT/app-running.txt"
else
  echo "APP_RUNNING=NO" | tee "$OUT/app-running.txt"
fi

echo ""
echo "Creating manual screen checklist..."
cat > "$OUT/manual-one-device-screen-checklist.txt" <<TXT
MAURIMESH ONE REAL DEVICE APK TEST

Open these screens manually on the phone:

1. /login
   - Press Open Dashboard.

2. /dashboard
   - Confirm no crash.

3. /test-layer
   - Press RUN FULL MAURIMESH TEST.
   - Press RUN ONE REAL DEVICE APK TEST.
   - Expected: PASSED_WITH_WARNINGS unless all native/device proof is complete.

4. /native-telemetry
   - PASS if NATIVE_ANDROID appears.
   - WARNING if JS_FALLBACK appears.

5. /hardware-runtime
   - Confirm screen loads.

6. /ble-hardware-runtime
   - Confirm Bluetooth/BLE runtime screen loads.

7. /hybrid-wifi-ble-mesh
   - Confirm fallback route chain loads.

8. /message-fallback
   - Confirm STRICT_ACK, RELAY_ACK, DELIVERY_PENDING_PROOF, STORE_FORWARD labels.

9. /pixel-calling
   - Confirm screen loads without crash.

10. /pixel-calling-backup
   - Confirm backup fallback loads.

11. /pixel-reconstruction-ack
   - Confirm reconstructed ACK proof rule loads.

12. /ai-pixel-reconstruction
   - Confirm RAW_32K_LIVE_FALSE.
   - Confirm AI_32K_RECONSTRUCTION_TARGET.
   - Confirm RECONSTRUCTED_PIXEL_ACK_REQUIRED.

13. /device-proof and /proof-ledger
   - Confirm proof panels load.

ONE DEVICE PASS:
- APK installed.
- App launches.
- No AndroidRuntime fatal crash.
- No ReactNativeJS fatal crash.
- Routes load.
- Permissions/Bluetooth state visible.
- Native telemetry shows NATIVE_ANDROID or JS_FALLBACK.
- Truth labels are visible.

ONE DEVICE CANNOT PROVE:
- Real BLE phone-to-phone delivery.
- Receiver ACK from another phone.
- 3-hop BLE relay.
TXT

echo ""
echo "Writing final one-device report..."
CRASH_COUNT="$(grep -Ec "FATAL EXCEPTION|AndroidRuntime|ReactNativeJS.*Error" "$OUT/filtered-startup-logcat.txt" || true)"
RUNNING="$(cat "$OUT/app-running.txt" || true)"
BT="$(cat "$OUT/bluetooth-on.txt" || true)"

{
  echo "# MauriMesh One Real Device APK Test Report"
  echo ""
  echo "Generated: $STAMP"
  echo ""
  echo "## Device"
  cat "$OUT/device-info.txt"
  echo ""
  echo "## Package"
  cat "$OUT/package-check.txt"
  echo ""
  echo "## Bluetooth"
  echo "bluetooth_on=$BT"
  echo ""
  echo "## Runtime"
  echo "$RUNNING"
  echo ""
  echo "## Crash Check"
  echo "crash_marker_count=$CRASH_COUNT"
  echo ""
  if [ "$CRASH_COUNT" = "0" ] && grep -q "APP_RUNNING=YES" "$OUT/app-running.txt"; then
    echo "Status: PASSED_ONE_DEVICE_STARTUP"
  elif [ "$CRASH_COUNT" = "0" ]; then
    echo "Status: WARNING_APP_NOT_RUNNING_AFTER_LAUNCH"
  else
    echo "Status: FAILED_CRASH_MARKERS_FOUND"
  fi
  echo ""
  echo "## Truth"
  echo "This confirms one real device APK startup/readiness only."
  echo "It does not prove real BLE delivery, receiver ACK, or 3-hop relay."
} | tee "$OUT/one-device-apk-test-report.md"

echo ""
echo "============================================================"
echo "ONE REAL DEVICE APK TEST COMPLETE"
echo "Proof folder:"
echo "  $OUT"
echo ""
echo "Report:"
echo "  $OUT/one-device-apk-test-report.md"
echo ""
echo "Checklist:"
echo "  $OUT/manual-one-device-screen-checklist.txt"
echo "============================================================"
