#!/usr/bin/env bash
set -euo pipefail

PACKET_ID="${1:-MMSF-RAW-LIVE-001}"
DURATION="${2:-180}"
PKG="${PKG:-com.maurimesh.messenger}"

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
RUN_ID="$(date -u +%Y%m%dT%H%M%SZ)_$PACKET_ID"
OUT="$ROOT/evidence/raw-device-runs/$RUN_ID"

mkdir -p "$OUT/logs/full" "$OUT/logs/filtered" "$OUT/videos" "$OUT/device-info" "$OUT/reports" "$OUT/manifests"

echo ""
echo "============================================================"
echo "MAURIMESH RAW-DEVICE EVIDENCE RUN"
echo "============================================================"
echo "Packet ID : $PACKET_ID"
echo "Duration  : $DURATION seconds"
echo "Package   : $PKG"
echo "Output    : $OUT"
echo "============================================================"
echo ""

if ! command -v adb >/dev/null 2>&1; then
  echo "ERROR: adb not found. Run this live capture on your Mac terminal where ADB can see the phones."
  exit 1
fi

adb start-server >/dev/null 2>&1 || true
adb devices -l > "$OUT/device-info/adb_devices_initial.txt" || true

DEVICES="$(adb devices | awk 'NR>1 && $2=="device"{print $1}')"
COUNT="$(printf "%s\n" "$DEVICES" | sed '/^$/d' | wc -l | tr -d ' ')"

if [ "$COUNT" -lt 1 ]; then
  echo "ERROR: No ADB devices connected."
  echo "Run: adb devices -l"
  exit 1
fi

SERIAL_A="${A06_SERIAL:-$(printf "%s\n" "$DEVICES" | sed -n '1p')}"
SERIAL_B="${S10_SERIAL:-$(printf "%s\n" "$DEVICES" | sed -n '2p')}"
SERIAL_C="${A16_SERIAL:-$(printf "%s\n" "$DEVICES" | sed -n '3p')}"

cat > "$OUT/run_metadata.txt" <<META
PROJECT=MauriMesh
RUN_TYPE=RAW_DEVICE_EVIDENCE_RUN
PACKET_ID=$PACKET_ID
DURATION_SECONDS=$DURATION
PACKAGE_NAME=$PKG
CREATED_AT=$(date -u +%Y-%m-%dT%H:%M:%SZ)
PHONE_A_A06_SERIAL=$SERIAL_A
PHONE_B_S10_SERIAL=$SERIAL_B
PHONE_C_A16_SERIAL=$SERIAL_C
META

save_info() {
  SERIAL="$1"
  ROLE="$2"
  [ -z "$SERIAL" ] && return 0
  {
    echo "ROLE=$ROLE"
    echo "SERIAL=$SERIAL"
    echo "MODEL=$(adb -s "$SERIAL" shell getprop ro.product.model 2>/dev/null || true)"
    echo "ANDROID=$(adb -s "$SERIAL" shell getprop ro.build.version.release 2>/dev/null || true)"
    echo "SDK=$(adb -s "$SERIAL" shell getprop ro.build.version.sdk 2>/dev/null || true)"
  } > "$OUT/device-info/${ROLE}_device_info.txt" || true
}

clear_logcat() {
  SERIAL="$1"
  ROLE="$2"
  [ -z "$SERIAL" ] && return 0
  echo "Clearing logcat: $ROLE / $SERIAL"
  adb -s "$SERIAL" logcat -c >/dev/null 2>&1 || true
}

launch_app() {
  SERIAL="$1"
  ROLE="$2"
  [ -z "$SERIAL" ] && return 0
  echo "Launching app: $ROLE / $SERIAL"
  adb -s "$SERIAL" shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1 || true
}

start_logcat() {
  SERIAL="$1"
  ROLE="$2"
  [ -z "$SERIAL" ] && { echo ""; return 0; }
  adb -s "$SERIAL" logcat -v time > "$OUT/logs/full/${ROLE}_full_logcat.log" 2>&1 &
  echo "$!"
}

filter_logs() {
  for f in "$OUT/logs/full/"*_full_logcat.log; do
    [ -f "$f" ] || continue
    base="$(basename "$f" _full_logcat.log)"
    grep -Ei "MAURIMESH|MMSF|STORE_FORWARD|packetId|PACKET_ID|TX_A06|S10_STORE|A16_OFFLINE|S10_HOLD|A16_RETURNS|FORWARD_STORED|RX_A16|ACK_A16|ACK_RELAY|ACK_RECEIVED" "$f" > "$OUT/logs/filtered/${base}_filtered_maurimesh.log" || true
  done
}

make_manifest() {
  MANIFEST="$OUT/manifests/raw_device_evidence_manifest_sha256.txt"
  : > "$MANIFEST"
  find "$OUT" -type f ! -path "$OUT/manifests/*" | sort | while IFS= read -r file; do
    hash="$(shasum -a 256 "$file" | awk '{print $1}')"
    size="$(wc -c < "$file" | tr -d ' ')"
    rel="${file#$OUT/}"
    echo "$hash  $size  $rel" >> "$MANIFEST"
  done
}

echo "Device assignment:"
echo "PHONE_A / A06 sender       : $SERIAL_A"
echo "PHONE_B / S10 relay        : $SERIAL_B"
echo "PHONE_C / A16 receiver ACK : $SERIAL_C"

save_info "$SERIAL_A" "PHONE_A_A06_SENDER"
save_info "$SERIAL_B" "PHONE_B_S10_RELAY"
save_info "$SERIAL_C" "PHONE_C_A16_RECEIVER_ACK"

clear_logcat "$SERIAL_A" "PHONE_A_A06_SENDER"
clear_logcat "$SERIAL_B" "PHONE_B_S10_RELAY"
clear_logcat "$SERIAL_C" "PHONE_C_A16_RECEIVER_ACK"

launch_app "$SERIAL_A" "PHONE_A_A06_SENDER"
launch_app "$SERIAL_B" "PHONE_B_S10_RELAY"
launch_app "$SERIAL_C" "PHONE_C_A16_RECEIVER_ACK"

PID_A="$(start_logcat "$SERIAL_A" "PHONE_A_A06_SENDER")"
PID_B="$(start_logcat "$SERIAL_B" "PHONE_B_S10_RELAY")"
PID_C="$(start_logcat "$SERIAL_C" "PHONE_C_A16_RECEIVER_ACK")"

echo ""
echo "============================================================"
echo "LIVE ACTION NOW"
echo "============================================================"
echo "Use packet ID: $PACKET_ID"
echo "Run the Store-Forward proof before timer ends."
echo "Timer: $DURATION seconds"
echo "============================================================"
echo ""

sleep "$DURATION"

for pid in "$PID_A" "$PID_B" "$PID_C"; do
  [ -n "${pid:-}" ] && kill "$pid" >/dev/null 2>&1 || true
done

adb devices -l > "$OUT/device-info/adb_devices_final.txt" || true

filter_logs
make_manifest

bash "$ROOT/tools/evidence-run/verify-raw-device-evidence-run.sh" "$OUT" || true

echo ""
echo "============================================================"
echo "RAW-DEVICE EVIDENCE RUN COMPLETE"
echo "============================================================"
echo "Output folder: $OUT"
echo "Filtered logs: $OUT/logs/filtered"
echo "Manifest: $OUT/manifests/raw_device_evidence_manifest_sha256.txt"
echo "============================================================"
