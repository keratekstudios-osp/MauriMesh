#!/usr/bin/env bash
set -euo pipefail

PACKET_ID="${1:-${PACKET_ID:-}}"
APP_PKG="${APP_PKG:-com.maurimesh.messenger}"
STAMP="$(date +"%Y%m%d-%H%M%S")"
OUT_DIR="$(pwd)/docs/native-proof"
mkdir -p "$OUT_DIR"

if [ -z "$PACKET_ID" ]; then
  echo "ERROR: packetId required."
  echo ""
  echo "Usage:"
  echo "  PACKET_ID=MM3-XXXXXX-XXXXXX ./scripts/validate-native-ble-gatt-packet-bound-proof.sh"
  echo "or:"
  echo "  ./scripts/validate-native-ble-gatt-packet-bound-proof.sh MM3-XXXXXX-XXXXXX"
  exit 1
fi

LOG_FILE="$OUT_DIR/native-ble-gatt-packet-bound-log-$PACKET_ID-$STAMP.txt"
REPORT="$OUT_DIR/native-ble-gatt-packet-bound-report-$PACKET_ID-$STAMP.md"

echo ""
echo "============================================================"
echo "MAURIMESH NATIVE BLE/GATT PACKET-BOUND VALIDATOR"
echo "============================================================"
echo "Packet ID: $PACKET_ID"
echo "App package: $APP_PKG"
echo ""
echo "Instructions:"
echo "1. This will clear logcat."
echo "2. Run the proof on phones."
echo "3. Press ENTER here after the proof flow finishes."
echo "============================================================"
echo ""

adb logcat -c || true

read -r -p "Run the proof now, then press ENTER to capture native logs..."

adb logcat -d > "$LOG_FILE" || true

MATCH_FILE="$OUT_DIR/native-ble-gatt-packet-bound-matches-$PACKET_ID-$STAMP.txt"
grep "MAURIMESH_NATIVE_BLE_GATT" "$LOG_FILE" | grep "$PACKET_ID" > "$MATCH_FILE" || true

required=(
  "advertise_start_packetId"
  "scan_result_packetId"
  "gatt_write_packetId"
  "gatt_read_packetId"
  "characteristic_changed_packetId"
  "relay_packetId"
  "ack_packetId"
)

PASS="yes"

{
  echo "# MauriMesh Native BLE/GATT Packet-Bound Proof Report"
  echo ""
  echo "Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  echo ""
  echo "Packet ID: \`$PACKET_ID\`"
  echo ""
  echo "## Required Native Stages"
  echo ""
  echo "| Stage | Status |"
  echo "|---|---|"

  for stage in "${required[@]}"; do
    if grep "$stage" "$MATCH_FILE" >/dev/null 2>&1; then
      echo "| $stage | FOUND |"
    else
      echo "| $stage | MISSING |"
      PASS="no"
    fi
  done

  echo ""
  echo "## Result"
  echo ""

  if [ "$PASS" = "yes" ]; then
    echo "NATIVE BLE/GATT PACKET-BOUND PASS"
  else
    echo "NATIVE BLE/GATT PACKET-BOUND PASS NOT CLAIMED"
  fi

  echo ""
  echo "## Files"
  echo ""
  echo "- Full log: $LOG_FILE"
  echo "- Matching packet logs: $MATCH_FILE"
  echo "- Report: $REPORT"
  echo ""
  echo "## Matching Logs"
  echo ""
  echo '```txt'
  cat "$MATCH_FILE"
  echo '```'
} > "$REPORT"

echo ""
echo "============================================================"
if [ "$PASS" = "yes" ]; then
  echo "NATIVE BLE/GATT PACKET-BOUND PASS"
else
  echo "NATIVE BLE/GATT PACKET-BOUND PASS NOT CLAIMED"
fi
echo "============================================================"
echo "Report:"
echo "$REPORT"
echo ""
echo "Matches:"
echo "$MATCH_FILE"
echo ""
echo "Full log:"
echo "$LOG_FILE"
echo "============================================================"
