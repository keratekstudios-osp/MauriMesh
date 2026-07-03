#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH GATT PACKET PAYLOAD PROOF INSTRUMENTATION v1"
echo "============================================================"
echo "Goal:"
echo "- Instrument native Android GATT write path"
echo "- Log packetId from actual GATT characteristic payload bytes"
echo "- Add capture script for physical 3-device proof"
echo "- Keep nativePacketBound final PASS locked"
echo "- No false native BLE/GATT PASS claim"
echo "============================================================"

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$ROOT/backup-before-gatt-packet-payload-proof-v1-$STAMP"
DOC_DIR="$ROOT/docs/native-ble-gatt"
ARCHIVE_DIR="$ROOT/archives"
REPORT="$DOC_DIR/GATT_PACKET_PAYLOAD_PROOF_INSTRUMENTATION_V1_$STAMP.md"

PKG_DIR="$ROOT/android/app/src/main/java/com/maurimesh/messenger"
LOGGER="$PKG_DIR/MauriMeshGattPacketProof.kt"
CLIENT="$PKG_DIR/MeshCentralClient.kt"
SERVER="$PKG_DIR/MeshRawPacketGattServer.kt"
CAPTURE="$ROOT/tools/capture-gatt-packet-payload-proof-v1.sh"

mkdir -p "$BACKUP" "$DOC_DIR" "$ARCHIVE_DIR" "$ROOT/tools"

echo ""
echo "Backing up target files..."
for f in "$LOGGER" "$CLIENT" "$SERVER"; do
  if [ -f "$f" ]; then
    mkdir -p "$BACKUP/$(dirname "${f#$ROOT/}")"
    cp "$f" "$BACKUP/${f#$ROOT/}"
    echo "Backup: ${f#$ROOT/}"
  else
    echo "WARN: missing target: ${f#$ROOT/}"
  fi
done

echo ""
echo "Writing native GATT packet payload proof logger..."

cat > "$LOGGER" <<'KT'
package com.maurimesh.messenger

import android.util.Log
import java.nio.charset.Charset
import java.util.Locale

/**
 * MauriMesh GATT packet payload proof logger.
 *
 * Truth:
 * - This logs packetId extracted from native GATT payload bytes.
 * - This does not claim final native BLE/GATT packet-bound PASS.
 * - Final PASS still requires same packetId across required physical-device GATT logs.
 */
object MauriMeshGattPacketProof {
  private const val TAG = "MAURIMESH_NATIVE_BLE_GATT"

  fun logGattPayload(stage: String, value: ByteArray?, context: String) {
    val text = decodePayload(value)
    val packetId = extractPacketId(text)
    val len = value?.size ?: 0
    val hex = toHex(value, 96)
    val packetSeen = packetId != "NONE"

    Log.i(
      TAG,
      "GATT_PACKET_PAYLOAD" +
        " | stage=${clean(stage)}" +
        " | packetId=$packetId" +
        " | nativePacketBoundCandidate=$packetSeen" +
        " | nativePacketBound=false" +
        " | len=$len" +
        " | hex=$hex" +
        " | text=${clean(text)}" +
        " | context=${clean(context)}"
    )
  }

  fun logGattEvent(stage: String, packetId: String?, context: String) {
    val safePacketId = packetId?.takeIf { it.isNotBlank() } ?: "NONE"

    Log.i(
      TAG,
      "GATT_PACKET_EVENT" +
        " | stage=${clean(stage)}" +
        " | packetId=${clean(safePacketId)}" +
        " | nativePacketBound=false" +
        " | context=${clean(context)}"
    )
  }

  fun extractPacketId(text: String): String {
    val regex = Regex("""MM[A-Z0-9]*-[A-Z0-9]{3,}-[A-Z0-9]{3,}""")
    return regex.find(text)?.value ?: "NONE"
  }

  private fun decodePayload(value: ByteArray?): String {
    if (value == null || value.isEmpty()) return ""

    return try {
      value.toString(Charsets.UTF_8)
    } catch (_: Throwable) {
      try {
        value.toString(Charset.forName("ISO-8859-1"))
      } catch (_: Throwable) {
        ""
      }
    }
  }

  private fun toHex(value: ByteArray?, maxBytes: Int): String {
    if (value == null || value.isEmpty()) return ""
    return value.take(maxBytes).joinToString("") {
      String.format(Locale.US, "%02X", it.toInt() and 0xff)
    }
  }

  private fun clean(value: String): String {
    return value
      .replace("\n", " ")
      .replace("\r", " ")
      .replace("|", "/")
      .take(220)
  }
}
KT

echo "PASS: wrote ${LOGGER#$ROOT/}"

echo ""
echo "Patching native GATT client/server call sites..."

python3 - <<'PY'
from pathlib import Path

root = Path.cwd()
client = root / "android/app/src/main/java/com/maurimesh/messenger/MeshCentralClient.kt"
server = root / "android/app/src/main/java/com/maurimesh/messenger/MeshRawPacketGattServer.kt"

# Patch client before writeCharacteristic.
if client.exists():
    s = client.read_text()
    marker = 'MauriMeshGattPacketProof.logGattPayload("GATT_CLIENT_WRITE_ATTEMPT"'
    if marker not in s:
        needle = 'MauriMeshNativeBlePacketLogger.gattWrite(characteristic.value, "before writeCharacteristic MeshCentralClient.kt")'
        if needle in s:
            s = s.replace(
                needle,
                needle + '\n          MauriMeshGattPacketProof.logGattPayload("GATT_CLIENT_WRITE_ATTEMPT", characteristic.value, "MeshCentralClient.kt before writeCharacteristic")'
            )
            client.write_text(s)
            print("PASS: patched MeshCentralClient.kt GATT_CLIENT_WRITE_ATTEMPT")
        else:
            print("WARN: MeshCentralClient.kt known gattWrite needle not found")
    else:
        print("PASS: MeshCentralClient.kt already has GATT_CLIENT_WRITE_ATTEMPT")
else:
    print("WARN: MeshCentralClient.kt missing")

# Patch server inside onCharacteristicWriteRequest.
if server.exists():
    lines = server.read_text().splitlines()
    joined = "\n".join(lines)
    marker = 'MauriMeshGattPacketProof.logGattPayload("GATT_SERVER_WRITE_RECEIVED"'
    if marker in joined:
        print("PASS: MeshRawPacketGattServer.kt already has GATT_SERVER_WRITE_RECEIVED")
    else:
        out = []
        in_method = False
        inserted = False
        for line in lines:
            out.append(line)
            if "override fun onCharacteristicWriteRequest" in line:
                in_method = True
            elif in_method and line.strip() == ") {" and not inserted:
                out.append('      MauriMeshGattPacketProof.logGattPayload("GATT_SERVER_WRITE_RECEIVED", value, "MeshRawPacketGattServer.kt onCharacteristicWriteRequest")')
                inserted = True
                in_method = False
        server.write_text("\n".join(out) + "\n")
        if inserted:
            print("PASS: patched MeshRawPacketGattServer.kt GATT_SERVER_WRITE_RECEIVED")
        else:
            print("WARN: could not locate onCharacteristicWriteRequest insert point")
else:
    print("WARN: MeshRawPacketGattServer.kt missing")
PY

echo ""
echo "Writing physical capture script..."

cat > "$CAPTURE" <<'SH'
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
SH

chmod +x "$CAPTURE"

echo ""
echo "Running TypeScript..."
if npx tsc --noEmit; then
  TSC_RESULT="PASS"
else
  TSC_RESULT="FAIL"
fi

echo ""
echo "Inspecting Kotlin markers..."
grep -RIn "GATT_PACKET_PAYLOAD\|GATT_CLIENT_WRITE_ATTEMPT\|GATT_SERVER_WRITE_RECEIVED" \
  android/app/src/main/java/com/maurimesh/messenger 2>/dev/null || true

cat > "$REPORT" <<MD
# MauriMesh GATT Packet Payload Proof Instrumentation v1

Generated: $STAMP

## Result

GATT_PACKET_PAYLOAD_INSTRUMENTATION_INSTALLED

## Files Added/Changed

- \`android/app/src/main/java/com/maurimesh/messenger/MauriMeshGattPacketProof.kt\`
- \`android/app/src/main/java/com/maurimesh/messenger/MeshCentralClient.kt\`
- \`android/app/src/main/java/com/maurimesh/messenger/MeshRawPacketGattServer.kt\`
- \`tools/capture-gatt-packet-payload-proof-v1.sh\`

## New Native Markers

- \`GATT_PACKET_PAYLOAD\`
- \`GATT_CLIENT_WRITE_ATTEMPT\`
- \`GATT_SERVER_WRITE_RECEIVED\`
- \`nativePacketBoundCandidate=true/false\`
- \`nativePacketBound=false\`

## TypeScript

$TSC_RESULT

## Truth

This patch does not claim final native BLE/GATT PASS.

It only adds instrumentation to prove whether a packetId appears inside native GATT payload bytes.

Final PASS remains pending until physical logcat evidence shows the same packetId across required GATT stages and device roles.

## Backup

$BACKUP
MD

tar -czf "$ARCHIVE_DIR/gatt-packet-payload-proof-instrumentation-v1-$STAMP.tar.gz" \
  "$REPORT" "$CAPTURE" "$LOGGER" "$CLIENT" "$SERVER" 2>/dev/null || true

echo ""
echo "============================================================"
echo "PATCH COMPLETE"
echo "============================================================"
echo "Result: GATT_PACKET_PAYLOAD_INSTRUMENTATION_INSTALLED"
echo "TypeScript: $TSC_RESULT"
echo "Report: $REPORT"
echo "Archive: $ARCHIVE_DIR/gatt-packet-payload-proof-instrumentation-v1-$STAMP.tar.gz"
echo ""
echo "Next:"
echo "1. Build fresh APK"
echo "2. Install on A06, S10, A16"
echo "3. Run tools/capture-gatt-packet-payload-proof-v1.sh from Mac-side equivalent or copy it to Mac"
echo "4. Trigger GATT/raw packet send in app"
echo "============================================================"

if [ "$TSC_RESULT" != "PASS" ]; then
  exit 1
fi
