#!/usr/bin/env bash
set -u

PKG="${1:-com.maurimesh.messenger}"
DURATION="${2:-180}"
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT="$HOME/Desktop/maurimesh-gatt-packet-payload-proof-$STAMP"
STORE="$HOME/.maurimesh/adb-wifi-endpoints.txt"

mkdir -p "$OUT"

echo ""
echo "============================================================"
echo "MAURIMESH GATT PACKET PAYLOAD PHYSICAL CAPTURE v1"
echo "============================================================"
echo "Package:  $PKG"
echo "Duration: ${DURATION}s"
echo "Output:   $OUT"
echo ""
echo "Truth:"
echo "- Looks for packetId inside native GATT payload logs"
echo "- Does not claim final PASS automatically"
echo "- Final PASS requires same packetId across required physical-device stages"
echo "============================================================"
echo ""

adb start-server >/dev/null 2>&1 || true

if [ -s "$STORE" ]; then
  echo "Reconnecting saved Wi-Fi ADB endpoints..."
  awk -F'|' '{gsub(/^ +| +$/, "", $1); if ($1 != "") print $1}' "$STORE" | while read -r endpoint; do
    adb connect "$endpoint" >/dev/null 2>&1 || true
  done
  sleep 2
fi

adb devices -l | tee "$OUT/adb_devices.txt"

SERIALS="$(adb devices | awk 'NR>1 && $2=="device" && $1 ~ /:/ {print $1}' | sort -u)"
COUNT="$(echo "$SERIALS" | awk 'NF {c++} END {print c+0}')"

echo ""
echo "Wi-Fi device count: $COUNT"

if [ "$COUNT" -lt 3 ]; then
  echo "WARN: Full 3-device proof requires A06 + S10 + A16 over Wi-Fi ADB."
fi

if [ -z "$SERIALS" ]; then
  echo "FAIL: no Wi-Fi ADB devices connected."
  exit 1
fi

echo ""
echo "Selected devices:"
for serial in $SERIALS; do
  model="$(adb -s "$serial" shell getprop ro.product.model 2>/dev/null | tr -d '\r' | head -n 1)"
  device="$(adb -s "$serial" shell getprop ro.product.device 2>/dev/null | tr -d '\r' | head -n 1)"
  echo "- $serial | ${model:-unknown} | ${device:-unknown}"
done | tee "$OUT/selected_devices.txt"

PIDS=""

cleanup() {
  for pid in $PIDS; do
    kill "$pid" >/dev/null 2>&1 || true
  done
}
trap cleanup EXIT

echo ""
echo "Clearing logcat buffers..."
for serial in $SERIALS; do
  adb -s "$serial" logcat -c >/dev/null 2>&1 || true
done

echo ""
echo "Launching app..."
for serial in $SERIALS; do
  adb -s "$serial" shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1 || true
done

echo ""
echo "Starting broad logcat capture..."
for serial in $SERIALS; do
  safe="$(echo "$serial" | tr ':./' '___')"
  model="$(adb -s "$serial" shell getprop ro.product.model 2>/dev/null | tr -d '\r' | head -n 1)"
  log="$OUT/logcat_${safe}_${model:-unknown}.txt"

  {
    echo "===== DEVICE_SERIAL=$serial ====="
    echo "===== DEVICE_MODEL=${model:-unknown} ====="
    echo "===== START_UTC=$(date -u +"%Y-%m-%dT%H:%M:%SZ") ====="
    adb -s "$serial" logcat -v time
  } > "$log" 2>&1 &

  PIDS="$PIDS $!"
done

echo ""
echo "============================================================"
echo "PHONE ACTION NOW"
echo "============================================================"
echo "On all phones:"
echo "1. Open MauriMesh"
echo "2. Keep Bluetooth/Nearby permissions allowed"
echo "3. Open Native BLE/GATT Proof or the BLE/GATT runtime screen"
echo "4. Trigger any available GATT send / raw packet / relay proof action"
echo ""
echo "Roles:"
echo "- A06 = PHONE_A / Sender"
echo "- S10 = PHONE_B / Relay"
echo "- A16 = PHONE_C / Receiver"
echo "============================================================"
echo ""
echo "Capturing for ${DURATION}s..."
sleep "$DURATION"

cleanup
trap - EXIT

COMBINED="$OUT/combined_gatt_packet_payload_markers.txt"
SUMMARY="$OUT/summary.md"

grep -h -E \
  "MAURIMESH_NATIVE_BLE_GATT|GATT_PACKET_PAYLOAD|GATT_PACKET_EVENT|GATT_CLIENT_WRITE_ATTEMPT|GATT_SERVER_WRITE_RECEIVED|packetId=MM|nativePacketBound|writeCharacteristic|onCharacteristicWriteRequest|BluetoothGatt|BtGatt" \
  "$OUT"/logcat_*.txt > "$COMBINED" 2>/dev/null || true

count_pattern() {
  pattern="$1"
  grep -E "$pattern" "$COMBINED" 2>/dev/null | wc -l | tr -d ' '
}

PACKETS="$(grep -Eo 'packetId=MM[A-Z0-9]*-[A-Z0-9]{3,}-[A-Z0-9]{3,}' "$COMBINED" 2>/dev/null | sed 's/packetId=//' | sort -u | tr '\n' ' ')"
GATT_PAYLOAD_COUNT="$(count_pattern "GATT_PACKET_PAYLOAD")"
CLIENT_WRITE_COUNT="$(count_pattern "GATT_CLIENT_WRITE_ATTEMPT")"
SERVER_RECEIVE_COUNT="$(count_pattern "GATT_SERVER_WRITE_RECEIVED")"
BOUND_CANDIDATE_COUNT="$(count_pattern "nativePacketBoundCandidate=true")"
BOUND_TRUE_COUNT="$(count_pattern "nativePacketBound=true")"
BOUND_FALSE_COUNT="$(count_pattern "nativePacketBound=false")"

RESULT="PENDING"
REASON="No native GATT packet payload proof captured."

if [ "$BOUND_TRUE_COUNT" -gt 0 ]; then
  RESULT="NATIVE_PACKET_BOUND_TRUE_CANDIDATE_REVIEW_REQUIRED"
  REASON="nativePacketBound=true marker found. Human review required before any final claim."
elif [ "$CLIENT_WRITE_COUNT" -gt 0 ] && [ "$SERVER_RECEIVE_COUNT" -gt 0 ] && [ -n "$PACKETS" ]; then
  RESULT="GATT_PACKET_ID_NATIVE_PAYLOAD_CANDIDATE_REVIEW_REQUIRED"
  REASON="packetId appeared in native GATT payload write/receive markers. Human review must confirm same packetId and required device path."
elif [ "$GATT_PAYLOAD_COUNT" -gt 0 ] || [ "$BOUND_CANDIDATE_COUNT" -gt 0 ]; then
  RESULT="GATT_PAYLOAD_ACTIVITY_SEEN_PACKET_BOUND_PENDING"
  REASON="Native GATT payload activity was captured, but full packet-bound path was not proven."
fi

cat > "$SUMMARY" <<MD
# MauriMesh GATT Packet Payload Physical Capture v1

Generated: $STAMP

## Result

$RESULT

## Reason

$REASON

## Wi-Fi Device Count

$COUNT

## Counts

- GATT_PACKET_PAYLOAD markers: $GATT_PAYLOAD_COUNT
- GATT_CLIENT_WRITE_ATTEMPT markers: $CLIENT_WRITE_COUNT
- GATT_SERVER_WRITE_RECEIVED markers: $SERVER_RECEIVE_COUNT
- nativePacketBoundCandidate=true markers: $BOUND_CANDIDATE_COUNT
- nativePacketBound=true markers: $BOUND_TRUE_COUNT
- nativePacketBound=false markers: $BOUND_FALSE_COUNT

## Packet IDs Found

$PACKETS

## Selected Devices

\`\`\`
$(cat "$OUT/selected_devices.txt")
\`\`\`

## Truth

Final native BLE/GATT packet-bound PASS is not claimed by this capture.

Final PASS requires same packetId inside required native GATT payload/log evidence across the physical device path.
MD

tar -czf "$OUT.tar.gz" "$OUT" >/dev/null 2>&1 || true

echo ""
echo "============================================================"
echo "CAPTURE COMPLETE"
echo "============================================================"
cat "$SUMMARY"
echo ""
echo "Archive: $OUT.tar.gz"
echo "============================================================"
