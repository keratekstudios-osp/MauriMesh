#!/usr/bin/env bash
set -euo pipefail

PKG="com.maurimesh.messenger"
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT="$HOME/maurimesh-apk-proof-$STAMP"

mkdir -p "$OUT"

echo ""
echo "============================================================"
echo "MAURIMESH INSTALLED APK PROOF CAPTURE"
echo "Package: $PKG"
echo "Output:  $OUT"
echo "============================================================"
echo ""

echo "1. ADB devices"
adb devices -l | tee "$OUT/adb-devices.txt"

echo ""
echo "2. Phone/device info"
adb shell getprop ro.product.model | tee "$OUT/device-model.txt"
adb shell getprop ro.product.manufacturer | tee "$OUT/device-manufacturer.txt"
adb shell getprop ro.build.version.release | tee "$OUT/android-version.txt"
adb shell getprop ro.build.version.sdk | tee "$OUT/android-sdk.txt"

echo ""
echo "3. App install info"
adb shell pm list packages | grep "$PKG" | tee "$OUT/package-found.txt" || true
adb shell dumpsys package "$PKG" > "$OUT/package-dumpsys.txt" || true

echo ""
echo "4. Bluetooth state"
adb shell settings get global bluetooth_on | tee "$OUT/bluetooth-global.txt" || true
adb shell dumpsys bluetooth_manager > "$OUT/bluetooth-manager.txt" || true

echo ""
echo "5. Runtime permissions"
adb shell dumpsys package "$PKG" | grep -E "BLUETOOTH|ACCESS_FINE_LOCATION|ACCESS_COARSE_LOCATION|CAMERA|RECORD_AUDIO|POST_NOTIFICATIONS|granted=true|granted=false" \
  | tee "$OUT/permissions-summary.txt" || true

echo ""
echo "6. Clear logcat and launch APK"
adb logcat -c || true
adb shell am force-stop "$PKG" || true
adb shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 | tee "$OUT/launch-monkey.txt"

echo ""
echo "Wait 12 seconds while the app boots..."
sleep 12

echo ""
echo "7. Capture fatal/error log"
adb logcat -d \
  | grep -E "AndroidRuntime|FATAL EXCEPTION|ReactNativeJS|Exception|Error|MauriMesh|BLE|Bluetooth|ACK|NATIVE_ANDROID|JUMPCODE|TIKANGA|EVOLUTION|APK_PROOF" \
  | tail -500 \
  | tee "$OUT/logcat-filtered.txt" || true

echo ""
echo "8. Capture full logcat"
adb logcat -d > "$OUT/logcat-full.txt" || true

echo ""
echo "9. Proof summary"
{
  echo "# MauriMesh Installed APK Proof"
  echo ""
  echo "Generated: $STAMP"
  echo ""
  echo "## Proven"
  echo "- APK installed on Android phone"
  echo "- APK launch attempted through ADB"
  echo "- Device info captured"
  echo "- Bluetooth state captured"
  echo "- Permission state captured"
  echo "- Fatal crash log captured"
  echo ""
  echo "## Still requires manual confirmation"
  echo "- Open /test-layer inside APK"
  echo "- Open /native-telemetry"
  echo "- Open /mauricore-ble-runtime"
  echo "- Open /jumpcode-proof"
  echo "- Open /maori-protocols"
  echo "- Open /evolution-layer"
  echo "- Open /device-proof"
  echo "- Open /proof-ledger"
  echo ""
  echo "## Still requires second phone"
  echo "- Real BLE TX/RX"
  echo "- Receiver ACK"
  echo "- Relay ACK"
  echo "- 3-hop proof"
  echo "- Pixel Calling real audio proof"
  echo ""
  echo "## Truth"
  echo "This proves one installed APK launch/device state. It does not prove real mesh delivery until another phone receives and ACKs."
} | tee "$OUT/PROOF-SUMMARY.md"

echo ""
echo "============================================================"
echo "DONE"
echo "Proof folder:"
echo "$OUT"
echo "============================================================"
