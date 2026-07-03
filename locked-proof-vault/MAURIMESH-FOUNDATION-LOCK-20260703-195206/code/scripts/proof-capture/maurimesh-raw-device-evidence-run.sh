#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH RAW-DEVICE EVIDENCE RUN"
echo "A06 + S10 + A16 ADB/logcat synchronized capture"
echo "============================================================"
echo ""

ROOT="$(pwd)"
PKG="${PKG:-com.maurimesh.messenger}"
PROOF_TAG="${PROOF_TAG:-MAURIMESH}"
RUN_ID="${RUN_ID:-raw-device-$(date +%Y%m%d-%H%M%S)}"
OUT_DIR="$ROOT/evidence/raw-device/$RUN_ID"

mkdir -p "$OUT_DIR"

log() {
  echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $*"
}

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "ERROR: Required command missing: $1"
    exit 1
  fi
}

need_cmd adb
need_cmd node
need_cmd grep
need_cmd awk

echo "Output folder:"
echo "$OUT_DIR"
echo ""

adb start-server >/dev/null

echo "Connected devices:"
adb devices -l | tee "$OUT_DIR/adb_devices_before.txt"
echo ""

PHONE_A_SERIAL="${PHONE_A_SERIAL:-}"
PHONE_B_SERIAL="${PHONE_B_SERIAL:-}"
PHONE_C_SERIAL="${PHONE_C_SERIAL:-}"

if [ -z "$PHONE_A_SERIAL" ] || [ -z "$PHONE_B_SERIAL" ] || [ -z "$PHONE_C_SERIAL" ]; then
  echo "Set these first, then rerun:"
  echo ""
  echo "export PHONE_A_SERIAL=\"A06_ADB_SERIAL\""
  echo "export PHONE_B_SERIAL=\"S10_ADB_SERIAL\""
  echo "export PHONE_C_SERIAL=\"A16_ADB_SERIAL\""
  echo ""
  echo "Use this to see serials:"
  echo "adb devices -l"
  echo ""
  exit 1
fi

declare -A ROLES
ROLES["$PHONE_A_SERIAL"]="PHONE_A_A06_SENDER"
ROLES["$PHONE_B_SERIAL"]="PHONE_B_S10_STORE_FORWARD_RELAY"
ROLES["$PHONE_C_SERIAL"]="PHONE_C_A16_DELAYED_RECEIVER_ACK"

for SERIAL in "$PHONE_A_SERIAL" "$PHONE_B_SERIAL" "$PHONE_C_SERIAL"; do
  echo "Checking $SERIAL ..."
  adb -s "$SERIAL" get-state >/dev/null
  {
    echo "SERIAL=$SERIAL"
    echo "ROLE=${ROLES[$SERIAL]}"
    echo "UTC=$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    adb -s "$SERIAL" shell getprop ro.product.model 2>/dev/null | sed 's/^/model=/'
    adb -s "$SERIAL" shell getprop ro.product.manufacturer 2>/dev/null | sed 's/^/manufacturer=/'
    adb -s "$SERIAL" shell getprop ro.build.version.release 2>/dev/null | sed 's/^/android=/'
    adb -s "$SERIAL" shell getprop ro.build.version.sdk 2>/dev/null | sed 's/^/sdk=/'
  } > "$OUT_DIR/${ROLES[$SERIAL]}_device_identity.txt"
done

cat > "$OUT_DIR/run_metadata.json" <<METAEOF
{
  "project": "MauriMesh",
  "runId": "$RUN_ID",
  "createdAtUtc": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "package": "$PKG",
  "proofTag": "$PROOF_TAG",
  "phoneA": {
    "role": "PHONE_A",
    "device": "A06",
    "serial": "$PHONE_A_SERIAL"
  },
  "phoneB": {
    "role": "PHONE_B",
    "device": "S10",
    "serial": "$PHONE_B_SERIAL"
  },
  "phoneC": {
    "role": "PHONE_C",
    "device": "A16",
    "serial": "$PHONE_C_SERIAL"
  },
  "proofTarget": "Store-forward raw-device evidence capture"
}
METAEOF

echo ""
echo "Launching MauriMesh on all three devices..."
for SERIAL in "$PHONE_A_SERIAL" "$PHONE_B_SERIAL" "$PHONE_C_SERIAL"; do
  adb -s "$SERIAL" shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1 || true
done

echo ""
echo "Clearing old logcat buffers for clean proof capture..."
for SERIAL in "$PHONE_A_SERIAL" "$PHONE_B_SERIAL" "$PHONE_C_SERIAL"; do
  adb -s "$SERIAL" logcat -c || true
done

echo ""
echo "Starting raw logcat capture..."
PIDS=()

start_logcat() {
  local SERIAL="$1"
  local ROLE="$2"
  local RAW_FILE="$OUT_DIR/${ROLE}_raw_logcat.log"

  adb -s "$SERIAL" logcat -v threadtime > "$RAW_FILE" 2>&1 &
  local PID="$!"
  PIDS+=("$PID")
  echo "$PID" > "$OUT_DIR/${ROLE}_logcat.pid"
  echo "Started $ROLE logcat PID=$PID"
}

start_logcat "$PHONE_A_SERIAL" "PHONE_A_A06_SENDER"
start_logcat "$PHONE_B_SERIAL" "PHONE_B_S10_STORE_FORWARD_RELAY"
start_logcat "$PHONE_C_SERIAL" "PHONE_C_A16_DELAYED_RECEIVER_ACK"

cat > "$OUT_DIR/operator_instructions.txt" <<'INSTEOF'
MAURIMESH RAW-DEVICE EVIDENCE RUN INSTRUCTIONS

1. Keep this terminal recording logs.
2. Open the Store-Forward Delay Proof screen on A06, S10, and A16.
3. Use one visible packetId.
4. Complete the full proof:
   A06 -> S10 store request
   S10 stores packet
   A16 offline/unavailable confirmed
   S10 hold delay
   A16 returns
   S10 forwards stored packet to A16
   A16 receives stored packet
   A16 ACKs S10
   S10 relays ACK to A06
   A06 receives final ACK
5. When complete, return to this terminal and press ENTER.
INSTEOF

echo ""
echo "============================================================"
echo "CAPTURE IS RUNNING"
echo "============================================================"
echo "Now complete the Store-Forward proof on the phones."
echo "When the proof is complete, press ENTER here to stop capture."
echo "============================================================"
read -r _

echo ""
log "Stopping logcat capture..."

for PID in "${PIDS[@]}"; do
  kill "$PID" >/dev/null 2>&1 || true
done

sleep 2

adb devices -l | tee "$OUT_DIR/adb_devices_after.txt" >/dev/null

echo ""
echo "Creating filtered proof logs..."
for ROLE in PHONE_A_A06_SENDER PHONE_B_S10_STORE_FORWARD_RELAY PHONE_C_A16_DELAYED_RECEIVER_ACK; do
  RAW_FILE="$OUT_DIR/${ROLE}_raw_logcat.log"
  FILTERED_FILE="$OUT_DIR/${ROLE}_maurimesh_filtered.log"

  if [ -f "$RAW_FILE" ]; then
    grep -E "MAURIMESH|packetId=|PACKET_ID|TX_|RX_|ACK_|STORE|FORWARD|HOLD|OFFLINE|RETURNS" "$RAW_FILE" > "$FILTERED_FILE" || true
  else
    touch "$FILTERED_FILE"
  fi
done

echo ""
echo "Extracting possible packet IDs..."
cat "$OUT_DIR"/*_maurimesh_filtered.log 2>/dev/null \
  | grep -Eo 'MMSF-[A-Z0-9]+-[A-Z0-9]+|MM3-[A-Z0-9]+-[A-Z0-9]+|MM-[A-Z0-9]+-[A-Z0-9]+' \
  | sort \
  | uniq -c \
  | sort -nr \
  > "$OUT_DIR/packet_id_candidates.txt" || true

echo ""
echo "Packet ID candidates:"
cat "$OUT_DIR/packet_id_candidates.txt" || true
echo ""

PACKET_ID="${PACKET_ID:-}"

if [ -z "$PACKET_ID" ]; then
  echo "Enter the packetId used in the proof."
  echo "Example: MMSF-TEJFNH-K3FKYM"
  read -r PACKET_ID
fi

echo "$PACKET_ID" > "$OUT_DIR/selected_packet_id.txt"

echo ""
echo "Running raw evidence verifier..."
node "$ROOT/tools/proof-verifiers/verify-maurimesh-raw-evidence-run.js" "$OUT_DIR" "$PACKET_ID" || true

echo ""
echo "Creating SHA-256 manifest for raw evidence folder..."
(
  cd "$OUT_DIR"
  find . -type f -maxdepth 1 -print0 \
    | sort -z \
    | xargs -0 shasum -a 256 \
    > RAW_DEVICE_EVIDENCE_SHA256SUMS.txt
)

echo ""
echo "Creating compressed archive..."
(
  cd "$ROOT"
  mkdir -p archives
  tar -czf "archives/maurimesh-raw-device-evidence-$RUN_ID.tar.gz" "evidence/raw-device/$RUN_ID"
)

echo ""
echo "============================================================"
echo "RAW-DEVICE EVIDENCE RUN COMPLETE"
echo "============================================================"
echo "Folder:"
echo "$OUT_DIR"
echo ""
echo "Archive:"
echo "$ROOT/archives/maurimesh-raw-device-evidence-$RUN_ID.tar.gz"
echo ""
echo "Selected packetId:"
echo "$PACKET_ID"
echo ""
echo "Next:"
echo "Open the verifier report inside the evidence folder."
echo "============================================================"
