#!/usr/bin/env bash
set -euo pipefail

PACKET_ID="${1:-MMN-TRANSPORT-0001}"
OUT_DIR="docs/native-ble-gatt/capture-${PACKET_ID}-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$OUT_DIR"

echo "=================================================="
echo " MAURIMESH NATIVE BLE/GATT PROOF CAPTURE"
echo "=================================================="
echo "Packet ID : $PACKET_ID"
echo "Output    : $OUT_DIR"
echo ""

echo "Connected devices:"
adb devices | tee "$OUT_DIR/adb-devices.txt"

DEVICES=($(adb devices | awk 'NR>1 && $2=="device"{print $1}'))

if [ "${#DEVICES[@]}" -lt 2 ]; then
    echo ""
    echo "ERROR: At least two ADB devices are required."
    exit 1
fi

SENDER="${DEVICES[0]}"
RECEIVER="${DEVICES[1]}"

echo ""
echo "Sender   : $SENDER"
echo "Receiver : $RECEIVER"

adb -s "$SENDER" logcat -c || true
adb -s "$RECEIVER" logcat -c || true

echo ""
echo "=================================================="
echo "PHONE STEPS"
echo "=================================================="
echo "Receiver:"
echo "  1. Open Native BLE/GATT Truth Gate"
echo "  2. Start BLE Callback Capture"
echo ""
echo "Sender:"
echo "  3. Open Native BLE/GATT Truth Gate"
echo "  4. Use Packet ID: $PACKET_ID"
echo "  5. Start BLE Callback Capture"
echo "  6. Trigger Native GATT Packet Payload"
echo "  7. Wait 10 seconds"
echo "  8. Save Attempt Into Vault"
echo ""
read -p "Press ENTER immediately after pressing Trigger Native GATT Packet Payload..."

echo ""
echo "Capturing logs..."

timeout 20s adb -s "$SENDER" logcat -v time > "$OUT_DIR/sender-full.log" &
P1=$!

timeout 20s adb -s "$RECEIVER" logcat -v time > "$OUT_DIR/receiver-full.log" &
P2=$!

wait "$P1" || true
wait "$P2" || true

grep -E "MAURIMESH_NATIVE_BLE_GATT|MauriMeshGattPacketProof|GATT_|BLE_SCAN_CALLBACK|${PACKET_ID}" \
"$OUT_DIR/sender-full.log" \
> "$OUT_DIR/sender-gatt-filtered.log" || true

grep -E "MAURIMESH_NATIVE_BLE_GATT|MauriMeshGattPacketProof|GATT_|BLE_SCAN_CALLBACK|${PACKET_ID}" \
"$OUT_DIR/receiver-full.log" \
> "$OUT_DIR/receiver-gatt-filtered.log" || true

cat \
"$OUT_DIR/sender-gatt-filtered.log" \
"$OUT_DIR/receiver-gatt-filtered.log" \
> "$OUT_DIR/combined-gatt-filtered.log"

echo ""
echo "=================================================="
echo " REQUIRED MARKER COUNTS"
echo "=================================================="

for M in \
GATT_PACKET_PAYLOAD \
GATT_CLIENT_WRITE_ATTEMPT \
GATT_SERVER_WRITE_RECEIVED
do
    COUNT=$(grep -c "$M.*$PACKET_ID\|$PACKET_ID.*$M" \
    "$OUT_DIR/combined-gatt-filtered.log" || true)
    echo "$M = $COUNT"
done | tee "$OUT_DIR/marker-counts.txt"

if \
grep -q "GATT_PACKET_PAYLOAD.*$PACKET_ID\|$PACKET_ID.*GATT_PACKET_PAYLOAD" "$OUT_DIR/combined-gatt-filtered.log" \
&& grep -q "GATT_CLIENT_WRITE_ATTEMPT.*$PACKET_ID\|$PACKET_ID.*GATT_CLIENT_WRITE_ATTEMPT" "$OUT_DIR/combined-gatt-filtered.log" \
&& grep -q "GATT_SERVER_WRITE_RECEIVED.*$PACKET_ID\|$PACKET_ID.*GATT_SERVER_WRITE_RECEIVED" "$OUT_DIR/combined-gatt-filtered.log"
then
    echo "PASS_READY_TO_LOCK: same packetId found in all required native GATT markers." \
    | tee "$OUT_DIR/verdict.txt"
else
    echo "NOT_READY: missing one or more required native GATT markers." \
    | tee "$OUT_DIR/verdict.txt"
fi

echo ""
echo "=================================================="
echo "FILES CREATED"
echo "=================================================="

ls -1 "$OUT_DIR"

echo ""
echo "=================================================="
echo "VERDICT"
echo "=================================================="

cat "$OUT_DIR/verdict.txt"

echo ""
echo "Combined filtered log:"
echo "$OUT_DIR/combined-gatt-filtered.log"

echo ""
echo "=================================================="
echo "DONE"
echo "=================================================="

