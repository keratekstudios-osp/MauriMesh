#!/usr/bin/env bash
set -euo pipefail

TS="$(date +%Y%m%d-%H%M%S)"
REPORT="docs/native-ble-gatt/REAL_GATT_PROOF_MARKERS_V1_${TS}.md"

mkdir -p docs/native-ble-gatt

echo "=== MauriMesh Real GATT Proof Markers v1 ==="

JAVA="android/app/src/main/java/com/maurimesh/messenger/MauriMeshNativeBlePacketModule.java"

cp "$JAVA" "${JAVA}.bak-real-gatt-proof-markers-${TS}"

python3 - <<'PY'
from pathlib import Path
p = Path("android/app/src/main/java/com/maurimesh/messenger/MauriMeshNativeBlePacketModule.java")
s = p.read_text()

old = '''
      Log.i(
        "MAURIMESH_NATIVE_BLE_GATT",
        "GATT_PACKET_PAYLOAD | packetId=" + cleanPacketId + " | payload=MM_GATT_PAYLOAD_V10 | finalPassClaimed=false"
      );

      Log.i(
        "MAURIMESH_NATIVE_BLE_GATT",
        "GATT_CLIENT_WRITE_ATTEMPT | packetId=" + cleanPacketId + " | service=MauriMeshGatt | characteristic=PacketProof | finalPassClaimed=false"
      );

      Log.i(
        "MAURIMESH_NATIVE_BLE_GATT",
        "GATT_SERVER_WRITE_RECEIVED | packetId=" + cleanPacketId + " | service=MauriMeshGatt | characteristic=PacketProof | finalPassClaimed=true"
      );
'''

replacement = '''
      Log.i(
        "MAURIMESH_NATIVE_BLE_GATT",
        "GATT_WRITE_PATH_NOT_REACHED | packetId=" + cleanPacketId + " | reason=bridge_method_entered_only_real_gatt_markers_must_come_from_transport | finalPassClaimed=false"
      );
'''

if old not in s:
    raise SystemExit("Target simulated bridge GATT marker block not found. Stop: inspect file before patching.")

s = s.replace(old, replacement)
s = s.replace('result.putBoolean("finalPassClaimed", true);', 'result.putBoolean("finalPassClaimed", false);')
p.write_text(s)
PY

echo "Checking bridge no longer emits fake final markers..."
if grep -n "GATT_PACKET_PAYLOAD | packetId=.*MM_GATT_PAYLOAD_V10\|GATT_CLIENT_WRITE_ATTEMPT | packetId=.*service=MauriMeshGatt\|GATT_SERVER_WRITE_RECEIVED | packetId=.*finalPassClaimed=true" "$JAVA"; then
  echo "FAIL: simulated bridge final marker remains"
  exit 1
fi

echo "Checking real transport markers still exist..."
grep -RIn "GATT_CLIENT_WRITE_ATTEMPT" android/app/src/main/java/com/maurimesh/messenger/MeshCentralClient.kt
grep -RIn "GATT_SERVER_WRITE_RECEIVED" android/app/src/main/java/com/maurimesh/messenger/MeshRawPacketGattServer.kt

echo "Running TypeScript..."
npx tsc --noEmit

echo "Running Expo Android export..."
npx expo export --platform android

cat > "$REPORT" <<EOF
# MauriMesh Real GATT Proof Markers v1

Timestamp: $TS

## Changed
- Removed simulated final GATT proof marker emissions from:
  - $JAVA

## Preserved
- Bridge still logs:
  - GATT_TRIGGER_NATIVE_METHOD_ENTERED
  - GATT_TRIGGER_NATIVE_METHOD_RESULT
  - GATT_WRITE_PATH_NOT_REACHED

## Truth Rule
Final PASS must only come from real transport markers:
- GATT_PACKET_PAYLOAD
- GATT_CLIENT_WRITE_ATTEMPT from MeshCentralClient.kt
- GATT_SERVER_WRITE_RECEIVED from MeshRawPacketGattServer.kt

## Validation
- TypeScript PASS
- Expo Android export PASS
EOF

echo "READY_FOR_FRESH_APK_BUILD"
echo "$REPORT"
