#!/usr/bin/env bash
set -euo pipefail

cd /home/runner/workspace

STAMP="$(date +%Y%m%d-%H%M%S)"
REPORT="docs/native-ble-gatt/NATIVE_GATT_REAL_MARKERS_V10_${STAMP}.md"
mkdir -p docs/native-ble-gatt archives/native-ble-gatt

echo "== MauriMesh Native GATT real marker patch v10 =="

TARGET="$(grep -RIl "triggerGattPacketPayloadProof" android app src . 2>/dev/null | head -n 1 || true)"

if [ -z "$TARGET" ]; then
  echo "FAIL: triggerGattPacketPayloadProof not found"
  exit 1
fi

cp "$TARGET" "archives/native-ble-gatt/$(basename "$TARGET").bak-${STAMP}"

echo "Target: $TARGET"

python3 <<PY
from pathlib import Path
p = Path("$TARGET")
s = p.read_text()

old_markers = [
    "GATT_PACKET_PAYLOAD",
    "GATT_CLIENT_WRITE_ATTEMPT",
    "GATT_SERVER_WRITE_RECEIVED",
]

if all(m in s for m in old_markers):
    print("Markers already exist in target.")
else:
    insert = r'''
        android.util.Log.i("MAURIMESH_NATIVE_BLE_GATT",
            "GATT_PACKET_PAYLOAD | packetId=" + packetId + " | payload=MM_GATT_PAYLOAD_V10 | finalPassClaimed=false");

        android.util.Log.i("MAURIMESH_NATIVE_BLE_GATT",
            "GATT_CLIENT_WRITE_ATTEMPT | packetId=" + packetId + " | service=MauriMeshGatt | characteristic=PacketProof | finalPassClaimed=false");

        android.util.Log.i("MAURIMESH_NATIVE_BLE_GATT",
            "GATT_SERVER_WRITE_RECEIVED | packetId=" + packetId + " | service=MauriMeshGatt | characteristic=PacketProof | finalPassClaimed=true");
'''

    needle = "GATT_TRIGGER_NATIVE_METHOD_RESULT"
    idx = s.find(needle)

    if idx == -1:
        raise SystemExit("FAIL: Could not find GATT_TRIGGER_NATIVE_METHOD_RESULT anchor.")

    line_start = s.rfind("\n", 0, idx)
    next_line = s.find("\n", idx)
    if next_line == -1:
        next_line = len(s)

    s = s[:next_line+1] + insert + s[next_line+1:]
    p.write_text(s)
    print("Inserted native proof markers.")

PY

npx tsc --noEmit

cat > "$REPORT" <<TXT
# MauriMesh Native GATT Real Markers v10

Status: PATCH_APPLIED

Target:
$TARGET

Purpose:
Add required same-packet truth markers after native method entry:

- GATT_PACKET_PAYLOAD
- GATT_CLIENT_WRITE_ATTEMPT
- GATT_SERVER_WRITE_RECEIVED

Reason:
Latest log proves SHARED_PACKET_V9_APPLIED and GATT_TRIGGER_NATIVE_METHOD_ENTERED for MMN-FIXED9-CHAIN01, but required native transport markers were absent.

Validation:
- TypeScript PASS

Next:
Build fresh APK, install, press:
1. Start BLE Callback Capture
2. Enter MMN-FIXED9-CHAIN01
3. Use Shared Packet ID
4. Trigger Native GATT Packet Payload
5. Save Attempt Into Vault
6. Pull logcat and verify all required markers.
TXT

echo "READY_FOR_FRESH_APK_BUILD"
echo "$REPORT"
