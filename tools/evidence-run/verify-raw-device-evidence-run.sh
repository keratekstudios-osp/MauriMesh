#!/usr/bin/env bash
set -euo pipefail

RUN="${1:-}"

fail() {
  echo ""
  echo "============================================================"
  echo "MAURIMESH RAW-DEVICE EVIDENCE RUN VERIFY"
  echo "============================================================"
  echo "RAW DEVICE EVIDENCE VERDICT: FAIL"
  echo "Reason: $1"
  echo "============================================================"
  echo ""
  exit 1
}

[ -n "$RUN" ] || fail "Run folder missing."
[ -d "$RUN" ] || fail "Run folder not found: $RUN"
[ -f "$RUN/run_metadata.txt" ] || fail "run_metadata.txt missing."

PACKET_ID="$(grep '^PACKET_ID=' "$RUN/run_metadata.txt" | head -n1 | cut -d= -f2-)"
[ -n "$PACKET_ID" ] || fail "Packet ID missing from metadata."

FILTERED="$RUN/logs/filtered"
[ -d "$FILTERED" ] || fail "Filtered logs folder missing."

mkdir -p "$RUN/reports"
COMBINED="$RUN/reports/combined_filtered_logs.txt"
cat "$FILTERED"/*.log > "$COMBINED" 2>/dev/null || true

[ -s "$COMBINED" ] || fail "No filtered MauriMesh logs found."
grep -q "$PACKET_ID" "$COMBINED" || fail "Packet ID not found in filtered logs: $PACKET_ID"

MISSING=0
for stage in \
  PACKET_ID_CONFIRMED \
  TX_A06_TO_S10_STORE_REQUEST \
  S10_STORE_PACKET \
  A16_OFFLINE_CONFIRMED \
  S10_HOLD_DELAY \
  A16_RETURNS \
  S10_FORWARD_STORED_TO_A16 \
  RX_A16_STORED_PACKET \
  ACK_A16_TO_S10_STORED \
  ACK_RELAY_S10_TO_A06_STORED \
  ACK_RECEIVED_A06_STORED
do
  if ! grep -q "$stage" "$COMBINED"; then
    echo "Missing stage: $stage"
    MISSING=1
  fi
done

[ "$MISSING" -eq 0 ] || fail "One or more required Store-Forward stages missing."

echo ""
echo "============================================================"
echo "MAURIMESH RAW-DEVICE EVIDENCE RUN VERIFY"
echo "============================================================"
echo "RAW DEVICE EVIDENCE VERDICT: PASS"
echo "Packet : $PACKET_ID"
echo "Reason : Packet ID and all required Store-Forward stages found."
echo "============================================================"
echo ""
