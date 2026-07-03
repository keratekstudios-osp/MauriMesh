#!/usr/bin/env bash
set -euo pipefail

PACKET_ID="${1:-}"
DURATION="${DURATION:-180}"
PKG="${PKG:-com.maurimesh.messenger}"
ROOT="$(pwd)"
RUN_ID="$(date +%Y%m%d-%H%M%S)"
OUT="$ROOT/evidence/raw-device-runs/run-$RUN_ID"

mkdir -p \
  "$OUT/logs" \
  "$OUT/filtered" \
  "$OUT/device-info" \
  "$OUT/screenshots-before" \
  "$OUT/screenshots-after" \
  "$OUT/screenrecords"

echo ""
echo "============================================================"
echo "MAURIMESH RAW-DEVICE EVIDENCE CAPTURE"
echo "============================================================"
echo "Run ID    : $RUN_ID"
echo "Packet ID : ${PACKET_ID:-NOT_SET_YET}"
echo "Duration  : ${DURATION}s"
echo "Package   : $PKG"
echo "Output    : $OUT"
echo "============================================================"
echo ""

if ! command -v adb >/dev/null 2>&1; then
  echo "ERROR: adb not found."
  echo "Install Android platform-tools first, then rerun."
  exit 1
fi

adb start-server >/dev/null

adb version | tee "$OUT/device-info/adb_version.txt"
adb devices -l | tee "$OUT/device-info/adb_devices_l.txt"

SERIALS="$(adb devices | awk 'NR>1 && $2=="device"{print $1}')"
DEVICE_COUNT="$(printf "%s\n" "$SERIALS" | sed '/^$/d' | wc -l | tr -d ' ')"

if [ "$DEVICE_COUNT" -lt 1 ]; then
  echo "ERROR: No ADB devices detected."
  echo "Connect A06, S10, and A16 by USB/Wi-Fi ADB, then rerun."
  exit 1
fi

if [ "$DEVICE_COUNT" -lt 3 ]; then
  echo "WARNING: Expected 3 devices for strongest proof, but detected $DEVICE_COUNT."
  echo "Continuing anyway so logs can still be captured."
fi

echo "role,expected_device,serial,model,android,product" > "$OUT/device-info/serial_map.csv"

safe_name() {
  echo "$1" | tr '/:.' '___'
}

guess_role() {
  local model="$1"
  case "$model" in
    *A065*|*A06*) echo "PHONE_A_EXPECTED_A06_SENDER" ;;
    *G973*|*S10*) echo "PHONE_B_EXPECTED_S10_RELAY" ;;
    *A166*|*A16*) echo "PHONE_C_EXPECTED_A16_RECEIVER" ;;
    *) echo "UNKNOWN_ROLE_CONFIRM_MANUALLY" ;;
  esac
}

echo ""
echo "[1/7] Capturing device properties and before screenshots..."
for SERIAL in $SERIALS; do
  SAFE="$(safe_name "$SERIAL")"
  MODEL="$(adb -s "$SERIAL" shell getprop ro.product.model 2>/dev/null | tr -d '\r' || true)"
  ANDROID="$(adb -s "$SERIAL" shell getprop ro.build.version.release 2>/dev/null | tr -d '\r' || true)"
  PRODUCT="$(adb -s "$SERIAL" shell getprop ro.product.name 2>/dev/null | tr -d '\r' || true)"
  ROLE="$(guess_role "$MODEL")"

  echo "$ROLE,CONFIRM_MANUALLY,$SERIAL,$MODEL,$ANDROID,$PRODUCT" >> "$OUT/device-info/serial_map.csv"

  adb -s "$SERIAL" shell getprop > "$OUT/device-info/getprop_$SAFE.txt" 2>/dev/null || true
  adb -s "$SERIAL" shell dumpsys battery > "$OUT/device-info/battery_$SAFE.txt" 2>/dev/null || true
  adb -s "$SERIAL" shell dumpsys wifi > "$OUT/device-info/wifi_$SAFE.txt" 2>/dev/null || true
  adb -s "$SERIAL" shell dumpsys bluetooth_manager > "$OUT/device-info/bluetooth_$SAFE.txt" 2>/dev/null || true

  adb -s "$SERIAL" shell screencap -p "/sdcard/${RUN_ID}_${SAFE}_before.png" >/dev/null 2>&1 || true
  adb -s "$SERIAL" pull "/sdcard/${RUN_ID}_${SAFE}_before.png" "$OUT/screenshots-before/${SAFE}_before.png" >/dev/null 2>&1 || true
done

cat > "$OUT/run_manifest.md" <<MANIFESTEOF
# MauriMesh Raw-Device Evidence Run

- Run ID: $RUN_ID
- Started at: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
- Packet ID: ${PACKET_ID:-NOT_SET_YET}
- Capture duration seconds: $DURATION
- Android package: $PKG
- Detected ADB devices: $DEVICE_COUNT

## Required target proof

A06 sender -> S10 relay/store-forward -> A16 receiver/ACK -> S10 ACK relay -> A06 final ACK.

## Evidence goal

Capture raw ADB/logcat, screenshots, screenrecordings, device properties, and filtered proof markers from the same run.
MANIFESTEOF

echo ""
echo "[2/7] Clearing logcat..."
for SERIAL in $SERIALS; do
  adb -s "$SERIAL" logcat -c >/dev/null 2>&1 || true
done

echo ""
echo "[3/7] Starting raw logcat capture..."
: > "$OUT/logcat_pids.txt"
for SERIAL in $SERIALS; do
  SAFE="$(safe_name "$SERIAL")"
  adb -s "$SERIAL" logcat -v threadtime > "$OUT/logs/${SAFE}_logcat_threadtime.txt" 2>&1 &
  echo "$!" >> "$OUT/logcat_pids.txt"
done

sleep 2

echo ""
echo "[4/7] Starting screenrecord on each device..."
: > "$OUT/screenrecord_serials.txt"
for SERIAL in $SERIALS; do
  SAFE="$(safe_name "$SERIAL")"
  echo "$SERIAL|$SAFE|/sdcard/${RUN_ID}_${SAFE}.mp4" >> "$OUT/screenrecord_serials.txt"
  adb -s "$SERIAL" shell screenrecord --time-limit "$DURATION" "/sdcard/${RUN_ID}_${SAFE}.mp4" >/dev/null 2>&1 &
done

sleep 2

echo ""
echo "[5/7] Launching MauriMesh on each device..."
for SERIAL in $SERIALS; do
  adb -s "$SERIAL" shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1 || true
done

echo ""
echo "============================================================"
echo "LIVE PROOF WINDOW OPEN"
echo "============================================================"
echo "Now run the MauriMesh proof on A06, S10, and A16."
echo ""
echo "Best evidence:"
echo "1. Start proof capture before pressing the proof buttons."
echo "2. Keep Packet ID visible."
echo "3. Complete the proof sequence."
echo "4. Wait for completion panel."
echo "5. Press Enter here when done, or wait for ${DURATION}s."
echo "============================================================"
echo ""

if read -r -t "$DURATION" _INPUT; then
  echo "Manual stop requested."
else
  echo "Capture duration ended."
fi

echo ""
echo "[6/7] Stopping captures and pulling evidence..."

for SERIAL in $SERIALS; do
  adb -s "$SERIAL" shell "pkill -INT screenrecord >/dev/null 2>&1 || killall -2 screenrecord >/dev/null 2>&1 || true" >/dev/null 2>&1 || true
done

sleep 4

if [ -f "$OUT/logcat_pids.txt" ]; then
  while IFS= read -r PID; do
    kill "$PID" >/dev/null 2>&1 || true
  done < "$OUT/logcat_pids.txt"
fi

for SERIAL in $SERIALS; do
  SAFE="$(safe_name "$SERIAL")"

  adb -s "$SERIAL" shell screencap -p "/sdcard/${RUN_ID}_${SAFE}_after.png" >/dev/null 2>&1 || true
  adb -s "$SERIAL" pull "/sdcard/${RUN_ID}_${SAFE}_after.png" "$OUT/screenshots-after/${SAFE}_after.png" >/dev/null 2>&1 || true

  adb -s "$SERIAL" pull "/sdcard/${RUN_ID}_${SAFE}.mp4" "$OUT/screenrecords/${SAFE}.mp4" >/dev/null 2>&1 || true
done

echo ""
echo "[7/7] Building filtered logs and hash manifest..."

cat "$OUT/logs/"*.txt > "$OUT/filtered/all_logcat_combined.txt" 2>/dev/null || true

grep -E "MAURIMESH|MMSF|MM3|packetId|PACKET_ID|ACK_|STORE|S10_|A16_|A06|PROOF" \
  "$OUT/filtered/all_logcat_combined.txt" \
  > "$OUT/filtered/maurimesh_filtered.txt" 2>/dev/null || true

if [ -n "$PACKET_ID" ]; then
  grep "$PACKET_ID" "$OUT/filtered/all_logcat_combined.txt" > "$OUT/filtered/packet_${PACKET_ID}.txt" 2>/dev/null || true
fi

find "$OUT" -type f ! -name "SHA256SUMS.txt" -print | sort | while IFS= read -r FILE; do
  shasum -a 256 "$FILE"
done > "$OUT/SHA256SUMS.txt"

cat >> "$OUT/run_manifest.md" <<MANIFESTEOF

## Finished

- Finished at: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
- Output folder: $OUT

## Verification

Run from project root:

\`\`\`bash
node tools/raw-evidence/verify-maurimesh-raw-evidence-run.js "$OUT" "${PACKET_ID:-}"
\`\`\`
MANIFESTEOF

echo ""
echo "============================================================"
echo "RAW-DEVICE EVIDENCE CAPTURE COMPLETE"
echo "============================================================"
echo "Evidence folder:"
echo "$OUT"
echo ""
echo "Filtered log:"
echo "$OUT/filtered/maurimesh_filtered.txt"
echo ""
echo "Hash list:"
echo "$OUT/SHA256SUMS.txt"
echo ""
echo "Next verifier command:"
echo "node tools/raw-evidence/verify-maurimesh-raw-evidence-run.js \"$OUT\" \"${PACKET_ID:-}\""
echo "============================================================"
echo ""
