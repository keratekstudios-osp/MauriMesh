#!/usr/bin/env bash
set -euo pipefail

STAMP="$(date +%Y%m%d-%H%M%S)"
OUT="$HOME/Desktop/maurimesh-total-proof-capture-$STAMP"
mkdir -p "$OUT"

echo ""
echo "============================================================"
echo "MAURIMESH TOTAL PROOF MAC LOGCAT CAPTURE"
echo "Captures 2-hop + 3-hop + button auto-test proof logs"
echo "============================================================"
echo ""

if ! command -v adb >/dev/null 2>&1; then
  echo "FAIL: adb not installed."
  echo "Install Android platform-tools first."
  exit 1
fi

adb kill-server >/dev/null 2>&1 || true
adb start-server >/dev/null 2>&1 || true

adb devices -l | tee "$OUT/adb-devices.txt"

SERIAL="$(adb devices | awk 'NR>1 && $2=="device" {print $1; exit}')"

if [ -z "$SERIAL" ]; then
  echo "FAIL: No authorized ADB device."
  echo "Unlock phone, accept RSA prompt, then rerun."
  exit 1
fi

MODEL="$(adb -s "$SERIAL" shell getprop ro.product.model | tr -d '\r')"
DEVICE="$(adb -s "$SERIAL" shell getprop ro.product.device | tr -d '\r')"
ANDROID="$(adb -s "$SERIAL" shell getprop ro.build.version.release | tr -d '\r')"
SDK="$(adb -s "$SERIAL" shell getprop ro.build.version.sdk | tr -d '\r')"

cat > "$OUT/device-proof.txt" <<TXT
serial=$SERIAL
model=$MODEL
device=$DEVICE
android=$ANDROID
sdk=$SDK
TXT

cat "$OUT/device-proof.txt"

echo ""
echo "Choose capture type:"
echo "1 = App auto-test proof"
echo "2 = PHONE_A two-hop hotspot/gateway"
echo "3 = PHONE_B two-hop client/sender"
echo "4 = PHONE_A 3-hop sender"
echo "5 = PHONE_B 3-hop relay"
echo "6 = PHONE_C 3-hop receiver"
read -r -p "Type 1-6: " CHOICE

case "$CHOICE" in
  1) ROLE="APP_AUTOTEST"; ROUTE="/two-three-hop-proof-lab" ;;
  2) ROLE="PHONE_A_GATEWAY"; ROUTE="/two-phone-hotspot-proof" ;;
  3) ROLE="PHONE_B_CLIENT"; ROUTE="/two-phone-hotspot-proof" ;;
  4) ROLE="PHONE_A_SENDER"; ROUTE="/three-hop-relay-proof" ;;
  5) ROLE="PHONE_B_RELAY"; ROUTE="/three-hop-relay-proof" ;;
  6) ROLE="PHONE_C_RECEIVER"; ROUTE="/three-hop-relay-proof" ;;
  *) echo "Invalid choice"; exit 1 ;;
esac

echo "$ROLE" > "$OUT/capture-role.txt"
echo "$ROUTE" > "$OUT/target-route.txt"

echo ""
echo "Open MauriMesh APK manually."
echo "Open route: $ROUTE"
echo "Role/action: $ROLE"
echo ""
echo "For auto-test, press:"
echo "RUN TOTAL APP PROOF AUTO TEST"
echo ""
echo "For role test, select role and press emit logs."
echo ""
read -r -p "Press ENTER when ready to start 120-second capture..."

adb -s "$SERIAL" logcat -c || true

for PKG in com.maurimesh.messenger com.anonymous.MauriMesh com.anonymous.maurimesh; do
  adb -s "$SERIAL" shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1 && {
    echo "Launched package: $PKG"
    echo "$PKG" > "$OUT/package.txt"
    break
  } || true
done

echo "Capturing logcat for 120 seconds..."
timeout 120 adb -s "$SERIAL" logcat > "$OUT/logcat-full.txt" 2>/dev/null || true

grep -Ei "MauriMeshHotspotProof|MauriMesh3HopProof|MauriMeshButtonAutoTest|MauriMeshRouteAutoTest|MauriMeshTotalProofStart|MauriMeshTotalProofComplete|PHONE_A_HOTSPOT_ON|PHONE_A_GATEWAY_READY|PHONE_B_CONNECTED_TO_PHONE_A_HOTSPOT|PHONE_B_TX_PACKET_START|PHONE_A_GATEWAY_RX_FROM_B|PHONE_A_GATEWAY_FORWARD_ATTEMPT|PHONE_A_GATEWAY_FORWARD_SUCCESS|PHONE_A_GATEWAY_ACK_TO_B|PHONE_B_ACK_RECEIVED|PHONE_A_TX_BLE_START|PHONE_B_RX_BLE_FROM_A|PHONE_B_RELAY_TX_TO_C|PHONE_C_RX_BLE_FROM_B|PHONE_C_STRICT_ACK_SENT|PHONE_B_RELAY_ACK_FROM_C|PHONE_A_STRICT_OR_RELAY_ACK_RECEIVED|AndroidRuntime|FATAL|ReactNativeJS" \
  "$OUT/logcat-full.txt" > "$OUT/logcat-proof-filtered.txt" 2>/dev/null || true

echo ""
echo "============================================================"
echo "PROOF RESULT: $ROLE"
echo "============================================================"

check() {
  local s="$1"
  if grep -q "$s" "$OUT/logcat-proof-filtered.txt"; then
    echo "PASS: $s"
  else
    echo "MISSING: $s"
  fi
}

if [ "$ROLE" = "APP_AUTOTEST" ]; then
  check "MauriMeshTotalProofStart"
  check "MauriMeshButtonAutoTest"
  check "MauriMeshRouteAutoTest"
  check "MauriMeshHotspotProof"
  check "MauriMesh3HopProof"
  check "MauriMeshTotalProofComplete"
fi

if [ "$ROLE" = "PHONE_A_GATEWAY" ]; then
  check "PHONE_A_HOTSPOT_ON"
  check "PHONE_A_GATEWAY_READY"
  check "PHONE_A_GATEWAY_RX_FROM_B"
  check "PHONE_A_GATEWAY_FORWARD_ATTEMPT"
  check "PHONE_A_GATEWAY_FORWARD_SUCCESS"
  check "PHONE_A_GATEWAY_ACK_TO_B"
fi

if [ "$ROLE" = "PHONE_B_CLIENT" ]; then
  check "PHONE_B_CONNECTED_TO_PHONE_A_HOTSPOT"
  check "PHONE_B_TX_PACKET_START"
  check "PHONE_B_ACK_RECEIVED"
fi

if [ "$ROLE" = "PHONE_A_SENDER" ]; then
  check "PHONE_A_TX_BLE_START"
  check "PHONE_A_STRICT_OR_RELAY_ACK_RECEIVED"
fi

if [ "$ROLE" = "PHONE_B_RELAY" ]; then
  check "PHONE_B_RX_BLE_FROM_A"
  check "PHONE_B_RELAY_TX_TO_C"
  check "PHONE_B_RELAY_ACK_FROM_C"
fi

if [ "$ROLE" = "PHONE_C_RECEIVER" ]; then
  check "PHONE_C_RX_BLE_FROM_B"
  check "PHONE_C_STRICT_ACK_SENT"
fi

echo ""
echo "Fatal check:"
if grep -Ei "AndroidRuntime|FATAL EXCEPTION|ReactNativeJS.*(Error|Exception|TypeError|ReferenceError)" "$OUT/logcat-full.txt" >/dev/null 2>&1; then
  echo "FAIL: fatal/runtime error found."
  grep -Ei "AndroidRuntime|FATAL EXCEPTION|ReactNativeJS.*(Error|Exception|TypeError|ReferenceError)" "$OUT/logcat-full.txt" | tail -80
else
  echo "PASS: no obvious AndroidRuntime/FATAL/ReactNativeJS fatal found."
fi

echo ""
echo "Filtered proof tail:"
tail -180 "$OUT/logcat-proof-filtered.txt" || true

echo ""
echo "============================================================"
echo "DONE"
echo "Saved folder:"
echo "$OUT"
echo "============================================================"
