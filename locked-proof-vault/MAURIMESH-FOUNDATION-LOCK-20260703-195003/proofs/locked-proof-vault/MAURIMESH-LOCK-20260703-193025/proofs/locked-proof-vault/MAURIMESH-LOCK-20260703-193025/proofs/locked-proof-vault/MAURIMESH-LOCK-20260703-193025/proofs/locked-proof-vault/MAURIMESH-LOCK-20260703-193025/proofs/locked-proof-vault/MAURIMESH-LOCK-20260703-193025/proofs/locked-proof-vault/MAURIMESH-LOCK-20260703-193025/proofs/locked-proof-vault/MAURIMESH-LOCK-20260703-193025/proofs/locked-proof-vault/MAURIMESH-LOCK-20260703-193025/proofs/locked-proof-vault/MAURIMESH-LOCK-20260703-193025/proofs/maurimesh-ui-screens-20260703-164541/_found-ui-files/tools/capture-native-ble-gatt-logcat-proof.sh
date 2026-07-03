#!/usr/bin/env bash
set -euo pipefail

PKG="${1:-com.maurimesh.messenger}"
DURATION="${2:-90}"
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT="native-ble-gatt-logcat-proof-$STAMP"

mkdir -p "$OUT"

echo ""
echo "============================================================"
echo "MAURIMESH NATIVE BLE/GATT LOGCAT CAPTURE"
echo "============================================================"
echo "Package:  $PKG"
echo "Duration: ${DURATION}s"
echo "Output:   $OUT"
echo ""
echo "Truth:"
echo "- Captures ReactNativeJS + native BLE/GATT proof markers"
echo "- Does not claim native BLE/GATT PASS unless packet-bound markers exist"
echo "============================================================"
echo ""

if ! command -v adb >/dev/null 2>&1; then
  echo "FAIL: adb not found."
  exit 1
fi

adb devices -l | tee "$OUT/adb_devices.txt"

mapfile_cmd_available=1
if ! command -v bash >/dev/null 2>&1; then
  mapfile_cmd_available=0
fi

SERIALS="$(adb devices | awk 'NR>1 && $2=="device" {print $1}')"

if [ -z "$SERIALS" ]; then
  echo "FAIL: no adb devices connected."
  exit 1
fi

echo ""
echo "Connected serials:"
echo "$SERIALS"
echo ""

PIDS=""

cleanup() {
  for pid in $PIDS; do
    kill "$pid" >/dev/null 2>&1 || true
  done
}
trap cleanup EXIT

for serial in $SERIALS; do
  SAFE_SERIAL="$(echo "$serial" | tr ':./' '___')"
  LOG="$OUT/logcat_$SAFE_SERIAL.txt"
  echo "Starting logcat for $serial -> $LOG"

  {
    echo "===== DEVICE $serial ====="
    echo "===== START $(date -u +"%Y-%m-%dT%H:%M:%SZ") ====="
    adb -s "$serial" logcat -v time \
      ReactNativeJS:I \
      BluetoothGatt:D \
      BtGatt:D \
      BluetoothAdapter:D \
      BluetoothLeScanner:D \
      BLE:D \
      "$PKG":D \
      '*:S'
  } > "$LOG" 2>&1 &

  PIDS="$PIDS $!"
done

echo ""
echo "Now open APK route /native-ble-gatt-proof on the phones."
echo "Tap: Start BLE Callback Capture."
echo "Wait for scan callbacks."
echo "Then tap: Save Attempt Into Vault."
echo ""
echo "Capturing for ${DURATION}s..."
sleep "$DURATION"

cleanup
trap - EXIT

echo ""
echo "Extracting MauriMesh markers..."

COMBINED="$OUT/combined_markers.txt"
SUMMARY="$OUT/summary.md"
JSON="$OUT/summary.json"

grep -R \
  -E "MAURIMESH_NATIVE_BLE_GATT|MAURIMESH_3_DEVICE_PROOF|BluetoothGatt|BtGatt|BluetoothLeScanner" \
  "$OUT"/logcat_*.txt > "$COMBINED" 2>/dev/null || true

PACKET_IDS="$(grep -Eo 'packetId=[A-Z0-9-]+' "$COMBINED" | sed 's/packetId=//' | sort -u | tr '\n' ' ')"
NATIVE_MARKER_COUNT="$(grep -c "MAURIMESH_NATIVE_BLE_GATT" "$COMBINED" 2>/dev/null || echo 0)"
SCAN_CALLBACK_COUNT="$(grep -c "BLE_SCAN_CALLBACK_DEVICE" "$COMBINED" 2>/dev/null || echo 0)"
GATT_COUNT="$(grep -Ec "BluetoothGatt|BtGatt" "$COMBINED" 2>/dev/null || echo 0)"
PACKET_BOUND_PASS_COUNT="$(grep -Ec "PASS_NATIVE_PACKET_BOUND_BLE_GATT_PROOF|NATIVE_PACKET_BOUND_PASS=true|nativeBleGattPacketBoundPass=true" "$COMBINED" 2>/dev/null || echo 0)"

RESULT="PENDING"
REASON="Native BLE/GATT packet-bound PASS is not proven."

if [ "$PACKET_BOUND_PASS_COUNT" -gt 0 ]; then
  RESULT="PASS_NATIVE_PACKET_BOUND_BLE_GATT_PROOF_CANDIDATE_REVIEW_REQUIRED"
  REASON="Candidate pass markers found. Human review required to confirm same packetId across required native transport stages."
elif [ "$NATIVE_MARKER_COUNT" -gt 0 ] || [ "$SCAN_CALLBACK_COUNT" -gt 0 ] || [ "$GATT_COUNT" -gt 0 ]; then
  RESULT="NATIVE_CALLBACK_ACTIVITY_SEEN_PACKET_BOUND_PENDING"
  REASON="Native callback or BLE/GATT activity was seen, but packet-bound native transport PASS was not proven."
fi

cat > "$SUMMARY" <<MD
# MauriMesh Native BLE/GATT Logcat Proof Capture

Generated: $STAMP

## Result

$RESULT

## Reason

$REASON

## Counts

- MauriMesh native markers: $NATIVE_MARKER_COUNT
- BLE scan callback device markers: $SCAN_CALLBACK_COUNT
- Android BluetoothGatt/BtGatt lines: $GATT_COUNT
- Native packet-bound pass markers: $PACKET_BOUND_PASS_COUNT

## Packet IDs Found

$PACKET_IDS

## Truth Rule

Native BLE/GATT packet-bound PASS is not claimed unless the same packetId appears inside required native BLE/GATT transport logs.

## Files

- ADB devices: adb_devices.txt
- Combined markers: combined_markers.txt
- Raw logcat files: logcat_*.txt
MD

cat > "$JSON" <<JSON
{
  "type": "MAURIMESH_NATIVE_BLE_GATT_LOGCAT_CAPTURE",
  "generatedAt": "$STAMP",
  "result": "$RESULT",
  "reason": "$REASON",
  "packetIds": "$(echo "$PACKET_IDS" | sed 's/"/\\"/g')",
  "nativeMarkerCount": $NATIVE_MARKER_COUNT,
  "scanCallbackDeviceCount": $SCAN_CALLBACK_COUNT,
  "androidBluetoothGattLineCount": $GATT_COUNT,
  "nativePacketBoundPassMarkerCount": $PACKET_BOUND_PASS_COUNT,
  "truth": "Native BLE/GATT packet-bound PASS is not claimed unless same packetId appears inside native BLE/GATT transport logs."
}
JSON

tar -czf "$OUT.tar.gz" "$OUT" >/dev/null 2>&1 || true

echo ""
echo "============================================================"
echo "CAPTURE COMPLETE"
echo "============================================================"
cat "$SUMMARY"
echo ""
echo "Archive:"
echo "$OUT.tar.gz"
echo "============================================================"
