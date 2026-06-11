#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "UPDATE MASTER READINESS WITH MESSAGE ACK FALLBACK"
echo "Adds /message-fallback and checker to master gate."
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$ROOT/backup-before-master-message-ack-fallback-$STAMP"
MASTER="$ROOT/check-maurimesh-master-readiness.sh"

mkdir -p "$BACKUP"

if [ ! -f "$MASTER" ]; then
  echo "ERROR: check-maurimesh-master-readiness.sh not found."
  exit 1
fi

cp "$MASTER" "$BACKUP/check-maurimesh-master-readiness.sh"

python3 <<'PY'
from pathlib import Path

path = Path("check-maurimesh-master-readiness.sh")
src = path.read_text()

route_line = '  "/message-fallback:app/message-fallback.tsx"'
if route_line not in src:
    src = src.replace(
        '  "/hybrid-wifi-ble-mesh:app/hybrid-wifi-ble-mesh.tsx"\n)',
        '  "/hybrid-wifi-ble-mesh:app/hybrid-wifi-ble-mesh.tsx"\n'
        '  "/message-fallback:app/message-fallback.tsx"\n)'
    )

layer_files = [
    '  "src/maurimesh/message-fallback/MessageFallbackTypes.ts"',
    '  "src/maurimesh/message-fallback/MessageFallbackQueue.ts"',
    '  "src/maurimesh/message-fallback/AckFallbackEngine.ts"',
    '  "src/maurimesh/message-fallback/MessageAckFallbackEngine.ts"',
    '  "src/maurimesh/message-fallback/index.ts"',
    '  "src/components/MessageFallbackPanel.tsx"',
]

for lf in layer_files:
    if lf not in src:
        src = src.replace(
            '  "src/components/HybridWifiBleMeshPanel.tsx"\n)',
            '  "src/components/HybridWifiBleMeshPanel.tsx"\n' + lf + '\n)'
        )

markers = [
    '  "src/maurimesh/message-fallback/MessageFallbackQueue.ts:createRetryPlan"',
    '  "src/maurimesh/message-fallback/MessageFallbackQueue.ts:createMessageQueueRecord"',
    '  "src/maurimesh/message-fallback/AckFallbackEngine.ts:decideAckFallback"',
    '  "src/maurimesh/message-fallback/MessageAckFallbackEngine.ts:decideMessageAckFallback"',
    '  "src/maurimesh/message-fallback/MessageFallbackTypes.ts:STRICT_ACK"',
    '  "src/maurimesh/message-fallback/MessageFallbackTypes.ts:RELAY_ACK"',
    '  "src/maurimesh/message-fallback/MessageFallbackTypes.ts:DELIVERY_PENDING_PROOF"',
    '  "src/maurimesh/message-fallback/MessageFallbackTypes.ts:STORE_FORWARD_QUEUE"',
]

for marker in markers:
    if marker not in src:
        src = src.replace(
            '  "src/maurimesh/hybrid-wifi-ble-mesh/BackupHybridWifiBleMeshEngine.ts:createHybridFallbackOrder"\n)',
            '  "src/maurimesh/hybrid-wifi-ble-mesh/BackupHybridWifiBleMeshEngine.ts:createHybridFallbackOrder"\n' + marker + '\n)'
        )

truth = '  "src/maurimesh/message-fallback/MessageAckFallbackEngine.ts:does not claim real delivery until strict device ACK proof exists"'
if truth not in src:
    src = src.replace(
        '  "src/maurimesh/hybrid-wifi-ble-mesh/BackupHybridWifiBleMeshEngine.ts:does not prove real radio delivery"\n)',
        '  "src/maurimesh/hybrid-wifi-ble-mesh/BackupHybridWifiBleMeshEngine.ts:does not prove real radio delivery"\n' + truth + '\n)'
    )

checker_line = 'run_checker "check-maurimesh-message-ack-fallback.sh" "Message Queue + ACK Fallback"'
if checker_line not in src:
    src = src.replace(
        'run_checker "check-maurimesh-hybrid-wifi-ble-mesh.sh" "Hybrid Wi-Fi BLE Mesh"',
        'run_checker "check-maurimesh-hybrid-wifi-ble-mesh.sh" "Hybrid Wi-Fi BLE Mesh"\n'
        'run_checker "check-maurimesh-message-ack-fallback.sh" "Message Queue + ACK Fallback"'
    )

path.write_text(src)
PY

echo ""
echo "Running updated master checker..."
./check-maurimesh-master-readiness.sh

echo ""
echo "============================================================"
echo "DONE: MASTER READINESS UPDATED WITH MESSAGE ACK FALLBACK"
echo "============================================================"
echo "Backup:"
echo "  $BACKUP/check-maurimesh-master-readiness.sh"
echo ""
echo "Latest report:"
echo "  docs/maurimesh-master-readiness-report-latest.md"
echo "============================================================"
