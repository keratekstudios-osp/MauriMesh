#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "UPDATE MASTER READINESS WITH HYBRID WIFI BLE MESH"
echo "Adds /hybrid-wifi-ble-mesh and its checker to master gate."
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$ROOT/backup-before-master-hybrid-wifi-ble-$STAMP"

mkdir -p "$BACKUP"

MASTER="$ROOT/check-maurimesh-master-readiness.sh"

if [ ! -f "$MASTER" ]; then
  echo "ERROR: check-maurimesh-master-readiness.sh not found."
  exit 1
fi

cp "$MASTER" "$BACKUP/check-maurimesh-master-readiness.sh"

python3 <<'PY'
from pathlib import Path

path = Path("check-maurimesh-master-readiness.sh")
src = path.read_text()

# Add route file check
route_line = '  "/hybrid-wifi-ble-mesh:app/hybrid-wifi-ble-mesh.tsx"'
if route_line not in src:
    src = src.replace(
        '  "/ble-hardware-runtime:app/ble-hardware-runtime.tsx"\n)',
        '  "/ble-hardware-runtime:app/ble-hardware-runtime.tsx"\n'
        '  "/hybrid-wifi-ble-mesh:app/hybrid-wifi-ble-mesh.tsx"\n)'
    )

# Add layer files
layer_files = [
    '  "src/maurimesh/hybrid-wifi-ble-mesh/HybridWifiBleMeshTypes.ts"',
    '  "src/maurimesh/hybrid-wifi-ble-mesh/BackupHybridWifiBleMeshEngine.ts"',
    '  "src/maurimesh/hybrid-wifi-ble-mesh/index.ts"',
    '  "src/components/HybridWifiBleMeshPanel.tsx"',
]

for lf in layer_files:
    if lf not in src:
        src = src.replace(
            '  "src/components/BleHardwareRuntimePanel.tsx"\n)',
            '  "src/components/BleHardwareRuntimePanel.tsx"\n' + lf + '\n)'
        )

# Add critical markers
markers = [
    '  "src/maurimesh/hybrid-wifi-ble-mesh/BackupHybridWifiBleMeshEngine.ts:createHybridFallbackOrder"',
    '  "src/maurimesh/hybrid-wifi-ble-mesh/BackupHybridWifiBleMeshEngine.ts:decideBackupHybridWifiBleRoute"',
    '  "src/maurimesh/hybrid-wifi-ble-mesh/HybridWifiBleMeshTypes.ts:BLE_DIRECT"',
    '  "src/maurimesh/hybrid-wifi-ble-mesh/HybridWifiBleMeshTypes.ts:WIFI_LOCAL"',
    '  "src/maurimesh/hybrid-wifi-ble-mesh/HybridWifiBleMeshTypes.ts:INTERNET_GATEWAY"',
]

for marker in markers:
    if marker not in src:
        src = src.replace(
            '  "src/maurimesh/intelligence/BackupIntelligence.ts:forceBackupIntelligence"\n)',
            '  "src/maurimesh/intelligence/BackupIntelligence.ts:forceBackupIntelligence"\n' + marker + '\n)'
        )

# Add truth marker
truth = '  "src/maurimesh/hybrid-wifi-ble-mesh/BackupHybridWifiBleMeshEngine.ts:does not prove real radio delivery"'
if truth not in src:
    src = src.replace(
        '  "src/maurimesh/ble-runtime/BleHardwareBackupPolicy.ts:does not prove BLE delivery"\n)',
        '  "src/maurimesh/ble-runtime/BleHardwareBackupPolicy.ts:does not prove BLE delivery"\n' + truth + '\n)'
    )

# Add checker
checker_line = 'run_checker "check-maurimesh-hybrid-wifi-ble-mesh.sh" "Hybrid Wi-Fi BLE Mesh"'
if checker_line not in src:
    src = src.replace(
        'run_checker "check-maurimesh-ble-hardware-runtime-backup.sh" "BLE Hardware Runtime Backup"',
        'run_checker "check-maurimesh-ble-hardware-runtime-backup.sh" "BLE Hardware Runtime Backup"\n'
        'run_checker "check-maurimesh-hybrid-wifi-ble-mesh.sh" "Hybrid Wi-Fi BLE Mesh"'
    )

path.write_text(src)
PY

echo ""
echo "Running updated master checker..."
./check-maurimesh-master-readiness.sh

echo ""
echo "============================================================"
echo "DONE: MASTER READINESS UPDATED"
echo "============================================================"
echo "Backup:"
echo "  $BACKUP/check-maurimesh-master-readiness.sh"
echo ""
echo "Latest report:"
echo "  docs/maurimesh-master-readiness-report-latest.md"
echo ""
echo "Open report:"
echo "  cat docs/maurimesh-master-readiness-report-latest.md"
echo "============================================================"
