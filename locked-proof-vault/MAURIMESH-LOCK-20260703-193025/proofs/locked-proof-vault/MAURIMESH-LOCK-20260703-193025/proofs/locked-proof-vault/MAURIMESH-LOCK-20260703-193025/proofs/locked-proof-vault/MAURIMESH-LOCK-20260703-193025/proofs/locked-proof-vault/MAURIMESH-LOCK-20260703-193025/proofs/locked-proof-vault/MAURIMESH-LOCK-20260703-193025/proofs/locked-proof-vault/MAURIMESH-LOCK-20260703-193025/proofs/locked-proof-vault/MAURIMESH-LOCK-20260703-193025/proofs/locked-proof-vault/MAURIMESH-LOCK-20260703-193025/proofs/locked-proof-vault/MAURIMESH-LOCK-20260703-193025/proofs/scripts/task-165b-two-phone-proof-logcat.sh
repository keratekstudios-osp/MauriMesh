#!/usr/bin/env bash
set -euo pipefail

PKG="${1:-com.maurimesh.messenger}"

echo "============================================================"
echo "#165B TWO-PHONE RAW PACKET PROOF LOGCAT"
echo "Package: $PKG"
echo "============================================================"

adb logcat -c || true

echo "Open Raw Packet Proof screen on both phones."
echo "Start receiver on both phones."
echo "Start BLE scan on both phones."
echo "Send proof packet from Phone A to Phone B."
echo "Watching logs for 120 seconds..."
echo ""

timeout 120 adb logcat | grep -E \
  "TASK_165B|TASK_165|RX_RAW_PACKET|RAW_PACKET_GATT_SERVER|sendRawPacket|broadcastRawPacket|ACK_SENT|MauriMeshBle" \
  || true

echo ""
echo "Done."
