#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH API + PACKET DRIVER SEARCH"
echo "============================================================"
echo ""

echo "1. API env vars:"
grep -RIn \
  "EXPO_PUBLIC_API_BASE_URL\|EXPO_PUBLIC_BACKEND_BASE_URL\|VITE_API_BASE_URL\|VITE_BACKEND_BASE_URL\|API_BASE_URL\|BACKEND_BASE_URL" \
  . \
  --exclude-dir=node_modules \
  --exclude-dir=.git \
  --exclude-dir=android \
  --exclude-dir=ios \
  2>/dev/null || true

echo ""
echo "2. /api/activity references:"
grep -RIn "/api/activity\|api/activity" \
  . \
  --exclude-dir=node_modules \
  --exclude-dir=.git \
  --exclude-dir=android \
  --exclude-dir=ios \
  2>/dev/null || true

echo ""
echo "3. Packet / BLE / ACK driver references:"
grep -RIn \
  "TX_BLE\|RX_BLE\|WAITING_FOR_ACK\|ACK\|packetId\|MeshPacket\|routePacket\|sendPacket\|ble.*send\|BlePlx\|react-native-ble-plx" \
  src app server backend android \
  --exclude-dir=node_modules \
  --exclude-dir=.git \
  2>/dev/null | head -240 || true

echo ""
echo "4. Backend routes:"
grep -RIn "app.get\|app.post\|router.get\|router.post\|/api/" \
  server backend src api \
  --exclude-dir=node_modules \
  --exclude-dir=.git \
  2>/dev/null | head -240 || true

echo ""
echo "5. Done."
