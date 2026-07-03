#!/usr/bin/env bash
set -euo pipefail

FILE="android/app/src/main/java/com/maurimesh/messenger/MauriMeshBleModule.kt"

echo "============================================================"
echo "#192B Duplicate Native Event Detector"
echo "============================================================"

if [ ! -f "$FILE" ]; then
  echo "WARN: $FILE not found"
  exit 0
fi

RX_COUNT=$(grep -n '"rx_packet"' "$FILE" | wc -l | tr -d ' ')
ACK_COUNT=$(grep -n '"ack_sent"' "$FILE" | wc -l | tr -d ' ')

echo "rx_packet marker count: $RX_COUNT"
echo "ack_sent marker count: $ACK_COUNT"

if [ "$RX_COUNT" -gt 1 ] || [ "$ACK_COUNT" -gt 1 ]; then
  echo "WARN: Duplicate native proof event blocks may exist from rerunning #192."
  echo "This will not break export, but it may double-count metrics until cleaned."
  grep -nE 'emitRawPacketProofEvent|\"rx_packet\"|\"ack_sent\"|MauriMeshRawPacketProofEvent' "$FILE" || true
else
  echo "✅ No duplicate rx_packet/ack_sent markers detected"
fi
