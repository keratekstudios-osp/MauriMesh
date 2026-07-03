#!/usr/bin/env bash
set -euo pipefail

PACKET="${1:-}"
LABEL="${2:-proof}"

if [ -z "$PACKET" ]; then
  echo "Usage:"
  echo "./scripts/capture-maurimesh-proof-logs.sh <PACKET_ID> <label>"
  echo ""
  echo "Example:"
  echo "./scripts/capture-maurimesh-proof-logs.sh MM3-JSY73G-JKDXYR 3device"
  exit 1
fi

STAMP="$(date -u +%Y%m%d-%H%M%S)"
OUT="archives/maurimesh-locked-proof-vault/raw-evidence/${LABEL}_${PACKET}_${STAMP}"

mkdir -p "$OUT"

echo ""
echo "============================================================"
echo "CAPTURING MAURIMESH PROOF LOGS"
echo "Packet: $PACKET"
echo "Output: $OUT"
echo "============================================================"
echo ""

adb -s 192.168.1.8:5555 logcat -d | grep -iE "MAURIMESH|$PACKET|packetId|PHONE_A|AndroidRuntime|FATAL|ReactNativeJS" > "$OUT/A06_PHONE_A.log" || true
adb -s 192.168.1.10:5555 logcat -d | grep -iE "MAURIMESH|$PACKET|packetId|PHONE_B|AndroidRuntime|FATAL|ReactNativeJS" > "$OUT/S10_PHONE_B.log" || true
adb -s RF8Y303XPFM logcat -d | grep -iE "MAURIMESH|$PACKET|packetId|PHONE_C|AndroidRuntime|FATAL|ReactNativeJS" > "$OUT/A16_PHONE_C.log" || true

cat > "$OUT/README.md" <<REPORT
# MauriMesh Proof Log Capture

Captured UTC: $(date -u +%Y-%m-%dT%H:%M:%SZ)

Packet:

\`\`\`txt
$PACKET
\`\`\`

Label:

\`\`\`txt
$LABEL
\`\`\`

Files:

\`\`\`txt
A06_PHONE_A.log
S10_PHONE_B.log
A16_PHONE_C.log
\`\`\`
REPORT

echo "Capture complete:"
echo "$OUT"
