#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH NATIVE BLE/GATT PACKET-ID LOGGING PATCH GATE"
echo "============================================================"
echo "Goal:"
echo "- Add native Android packetId logging helper"
echo "- Create validation scripts"
echo "- Create proof contract"
echo "- Inspect BLE/GATT bridge files"
echo "- Do NOT claim native BLE/GATT pass yet"
echo ""
echo "Safety:"
echo "- Backup first"
echo "- No delete"
echo "- No git push"
echo "- No firmware"
echo "- No live routing mutation"
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +"%Y%m%d-%H%M%S")"
PATCH_ID="MM-NATIVE-BLE-GATT-LOGGING-$STAMP"

if [ ! -f "$ROOT/package.json" ]; then
  echo "ERROR: package.json not found."
  echo "Run this from your MauriMesh project root."
  exit 1
fi

mkdir -p \
  "$ROOT/docs/native-proof" \
  "$ROOT/scripts" \
  "$ROOT/archives" \
  "$ROOT/backups"

BACKUP_DIR="$ROOT/backups/before-native-ble-gatt-packetid-logging-$STAMP"
mkdir -p "$BACKUP_DIR"

echo "[1/9] Backing up key project files..."

for p in android app src package.json app.json eas.json; do
  if [ -e "$ROOT/$p" ]; then
    cp -R "$ROOT/$p" "$BACKUP_DIR/" 2>/dev/null || true
  fi
done

BACKUP_ARCHIVE="$ROOT/archives/before-native-ble-gatt-packetid-logging-$STAMP.tar.gz"
tar -czf "$BACKUP_ARCHIVE" -C "$BACKUP_DIR" . >/dev/null 2>&1 || true

echo "Backup:"
echo "$BACKUP_ARCHIVE"

echo ""
echo "[2/9] Checking Android native tree..."

if [ ! -d "$ROOT/android/app/src/main" ]; then
  echo "WARNING: android/app/src/main not found."
  echo "This repo may not have native Android files generated yet."
  echo "Creating docs + scripts only."
  HAS_ANDROID="no"
else
  HAS_ANDROID="yes"
fi

APP_GRADLE="$ROOT/android/app/build.gradle"
MAIN_SRC="$ROOT/android/app/src/main"
NAMESPACE=""

if [ "$HAS_ANDROID" = "yes" ] && [ -f "$APP_GRADLE" ]; then
  NAMESPACE="$(grep -E 'namespace[[:space:]]+["'\'']' "$APP_GRADLE" | head -1 | sed -E 's/.*namespace[[:space:]]+["'\'']([^"'\'']+)["'\''].*/\1/' || true)"
fi

if [ -z "$NAMESPACE" ] && [ "$HAS_ANDROID" = "yes" ]; then
  NAMESPACE="$(find "$MAIN_SRC" -type f \( -name "MainActivity.kt" -o -name "MainActivity.java" \) -print -quit | xargs grep -h '^package ' 2>/dev/null | head -1 | sed 's/package //; s/;//' || true)"
fi

if [ -z "$NAMESPACE" ]; then
  NAMESPACE="com.maurimesh.messenger"
fi

PKG_PATH="$(echo "$NAMESPACE" | tr '.' '/')"
NATIVE_DIR="$ROOT/android/app/src/main/java/$PKG_PATH"

echo "Detected Android namespace:"
echo "$NAMESPACE"

if [ "$HAS_ANDROID" = "yes" ]; then
  mkdir -p "$NATIVE_DIR"
fi

echo ""
echo "[3/9] Creating native packetId logger helper..."

LOGGER_FILE="$NATIVE_DIR/MauriMeshNativeBlePacketLogger.kt"

if [ "$HAS_ANDROID" = "yes" ]; then
cat > "$LOGGER_FILE" <<KOTLIN
package $NAMESPACE

import android.util.Log
import java.nio.charset.Charset

/**
 * MauriMesh native BLE/GATT packet-bound proof logger.
 *
 * Truth rule:
 * Native BLE/GATT packet-bound PASS is not claimed unless the same packetId appears
 * directly inside native Android BLE/GATT logs across advertise, scan, GATT write/read,
 * characteristic changed, relay, and ACK events.
 */
object MauriMeshNativeBlePacketLogger {
    private const val TAG = "MAURIMESH_NATIVE_BLE_GATT"

    private val packetRegex = Regex(
        pattern = "(MM[A-Z0-9-]*-[A-Z0-9]{4,}-[A-Z0-9]{4,})",
        options = setOf(RegexOption.IGNORE_CASE)
    )

    @JvmStatic
    fun extractPacketId(text: String?): String {
        if (text.isNullOrBlank()) return "UNKNOWN_PACKET_ID"
        return packetRegex.find(text)?.value ?: "UNKNOWN_PACKET_ID"
    }

    @JvmStatic
    fun extractPacketId(bytes: ByteArray?): String {
        if (bytes == null || bytes.isEmpty()) return "UNKNOWN_PACKET_ID"

        val utf8 = try {
            bytes.toString(Charsets.UTF_8)
        } catch (_: Throwable) {
            ""
        }

        val direct = extractPacketId(utf8)
        if (direct != "UNKNOWN_PACKET_ID") return direct

        val hex = bytes.joinToString("") { "%02X".format(it) }
        return extractPacketId(hex)
    }

    @JvmStatic
    fun event(stage: String, packetId: String?, detail: String? = null) {
        val safePacketId = if (packetId.isNullOrBlank()) "UNKNOWN_PACKET_ID" else packetId
        val safeStage = if (stage.isBlank()) "unknown_stage" else stage
        val safeDetail = detail ?: ""
        Log.i(TAG, "stage=\$safeStage packetId=\$safePacketId detail=\$safeDetail")
    }

    @JvmStatic
    fun eventFromText(stage: String, text: String?, detail: String? = null) {
        event(stage, extractPacketId(text), detail)
    }

    @JvmStatic
    fun eventFromBytes(stage: String, bytes: ByteArray?, detail: String? = null) {
        event(stage, extractPacketId(bytes), detail)
    }

    @JvmStatic
    fun advertiseStart(packetId: String?, detail: String? = null) {
        event("advertise_start_packetId", packetId, detail)
    }

    @JvmStatic
    fun scanResult(packetId: String?, detail: String? = null) {
        event("scan_result_packetId", packetId, detail)
    }

    @JvmStatic
    fun gattWrite(bytes: ByteArray?, detail: String? = null) {
        eventFromBytes("gatt_write_packetId", bytes, detail)
    }

    @JvmStatic
    fun gattRead(bytes: ByteArray?, detail: String? = null) {
        eventFromBytes("gatt_read_packetId", bytes, detail)
    }

    @JvmStatic
    fun characteristicChanged(bytes: ByteArray?, detail: String? = null) {
        eventFromBytes("characteristic_changed_packetId", bytes, detail)
    }

    @JvmStatic
    fun relay(packetId: String?, detail: String? = null) {
        event("relay_packetId", packetId, detail)
    }

    @JvmStatic
    fun ack(packetId: String?, detail: String? = null) {
        event("ack_packetId", packetId, detail)
    }
}
KOTLIN
  echo "Created:"
  echo "$LOGGER_FILE"
else
  echo "Skipped native helper because Android tree does not exist."
fi

echo ""
echo "[4/9] Inspecting native BLE/GATT candidate files..."

CANDIDATE_REPORT="$ROOT/docs/native-proof/native-ble-gatt-candidate-files-$PATCH_ID.txt"
: > "$CANDIDATE_REPORT"

if [ "$HAS_ANDROID" = "yes" ]; then
  {
    echo "MauriMesh Native BLE/GATT Candidate Files"
    echo "Patch ID: $PATCH_ID"
    echo "Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    echo ""
    echo "Search patterns:"
    echo "BluetoothGatt, BluetoothGattCallback, BluetoothLeAdvertiser, BluetoothLeScanner,"
    echo "ScanCallback, startAdvertising, onScanResult, writeCharacteristic,"
    echo "readCharacteristic, onCharacteristicChanged"
    echo ""
    echo "============================================================"
  } >> "$CANDIDATE_REPORT"

  find "$ROOT/android/app/src/main" -type f \( -name "*.kt" -o -name "*.java" \) | while read -r f; do
    if grep -E "BluetoothGatt|BluetoothGattCallback|BluetoothLeAdvertiser|BluetoothLeScanner|ScanCallback|startAdvertising|onScanResult|writeCharacteristic|readCharacteristic|onCharacteristicChanged|setValue|getValue" "$f" >/dev/null 2>&1; then
      echo "$f" >> "$CANDIDATE_REPORT"
      grep -nE "BluetoothGatt|BluetoothGattCallback|BluetoothLeAdvertiser|BluetoothLeScanner|ScanCallback|startAdvertising|onScanResult|writeCharacteristic|readCharacteristic|onCharacteristicChanged|setValue|getValue" "$f" >> "$CANDIDATE_REPORT" || true
      echo "------------------------------------------------------------" >> "$CANDIDATE_REPORT"
    fi
  done
fi

echo "Candidate report:"
echo "$CANDIDATE_REPORT"

echo ""
echo "[5/9] Creating patch snippets for native bridge wiring..."

SNIPPETS="$ROOT/docs/native-proof/native-ble-gatt-packetid-logging-snippets-$PATCH_ID.md"

cat > "$SNIPPETS" <<MD
# MauriMesh Native BLE/GATT PacketId Logging Snippets

Patch ID: $PATCH_ID

## Truth Rule

Do not claim native BLE/GATT packet-bound PASS unless the same packetId appears directly inside native Android BLE/GATT logs.

Required stages:

\`\`\`txt
advertise_start_packetId
scan_result_packetId
gatt_write_packetId
gatt_read_packetId
characteristic_changed_packetId
relay_packetId
ack_packetId
\`\`\`

## Logger

Created helper:

\`\`\`txt
$LOGGER_FILE
\`\`\`

Android log tag:

\`\`\`txt
MAURIMESH_NATIVE_BLE_GATT
\`\`\`

## Kotlin call examples

### Advertise start

Place where BLE advertising begins and packetId is known:

\`\`\`kt
MauriMeshNativeBlePacketLogger.advertiseStart(
    packetId,
    "advertise start serviceUuid=\$serviceUuid"
)
\`\`\`

### Scan result

Place inside ScanCallback / onScanResult:

\`\`\`kt
MauriMeshNativeBlePacketLogger.scanResult(
    packetId,
    "scan result device=\${result.device?.address}"
)
\`\`\`

If packetId is inside manufacturer/service data as bytes:

\`\`\`kt
MauriMeshNativeBlePacketLogger.eventFromBytes(
    "scan_result_packetId",
    serviceDataBytes,
    "scan service data"
)
\`\`\`

### GATT write

Place before/after characteristic write:

\`\`\`kt
MauriMeshNativeBlePacketLogger.gattWrite(
    characteristic.value,
    "write uuid=\${characteristic.uuid}"
)
\`\`\`

### GATT read

Place inside onCharacteristicRead:

\`\`\`kt
MauriMeshNativeBlePacketLogger.gattRead(
    characteristic.value,
    "read uuid=\${characteristic.uuid} status=\$status"
)
\`\`\`

### Characteristic changed

Place inside onCharacteristicChanged:

\`\`\`kt
MauriMeshNativeBlePacketLogger.characteristicChanged(
    characteristic.value,
    "changed uuid=\${characteristic.uuid}"
)
\`\`\`

### Relay

Place when relay forwards packetId:

\`\`\`kt
MauriMeshNativeBlePacketLogger.relay(
    packetId,
    "relay native bridge forward"
)
\`\`\`

### ACK

Place when ACK is created, sent, received, or relayed:

\`\`\`kt
MauriMeshNativeBlePacketLogger.ack(
    packetId,
    "ack native bridge"
)
\`\`\`

## Required ADB proof query

\`\`\`bash
adb logcat -d | grep "MAURIMESH_NATIVE_BLE_GATT" | grep "MM3-"
\`\`\`

## PASS rule

Same packetId must appear with all required native stages:

\`\`\`txt
advertise_start_packetId
scan_result_packetId
gatt_write_packetId
gatt_read_packetId
characteristic_changed_packetId
relay_packetId
ack_packetId
\`\`\`

If any stage is missing, status remains:

\`\`\`txt
NATIVE BLE/GATT PACKET-BOUND PASS NOT CLAIMED
\`\`\`
MD

echo "Snippets:"
echo "$SNIPPETS"

echo ""
echo "[6/9] Creating source usage inspection script..."

INSPECT_SCRIPT="$ROOT/scripts/inspect-native-ble-gatt-packetid-logging.sh"

cat > "$INSPECT_SCRIPT" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo ""
echo "============================================================"
echo "MAURIMESH NATIVE BLE/GATT PACKET-ID LOGGING INSPECTION"
echo "============================================================"

echo ""
echo "[1] Logger helper:"
find "$ROOT/android/app/src/main" -type f -name "MauriMeshNativeBlePacketLogger.kt" -print 2>/dev/null || true

echo ""
echo "[2] Native logger usages:"
grep -RIn "MauriMeshNativeBlePacketLogger" "$ROOT/android/app/src/main" 2>/dev/null || true

echo ""
echo "[3] Required stage source references:"
for stage in \
  advertise_start_packetId \
  scan_result_packetId \
  gatt_write_packetId \
  gatt_read_packetId \
  characteristic_changed_packetId \
  relay_packetId \
  ack_packetId
do
  echo ""
  echo "Stage: $stage"
  grep -RIn "$stage" "$ROOT/android/app/src/main" "$ROOT/src" "$ROOT/app" 2>/dev/null || true
done

echo ""
echo "[4] BLE/GATT candidate files:"
find "$ROOT/android/app/src/main" -type f \( -name "*.kt" -o -name "*.java" \) 2>/dev/null | while read -r f; do
  if grep -E "BluetoothGatt|BluetoothLeAdvertiser|BluetoothLeScanner|ScanCallback|startAdvertising|onScanResult|writeCharacteristic|readCharacteristic|onCharacteristicChanged" "$f" >/dev/null 2>&1; then
    echo "$f"
  fi
done

echo ""
echo "============================================================"
echo "Inspection complete."
echo "============================================================"
SCRIPT

chmod +x "$INSPECT_SCRIPT"

echo "Inspection script:"
echo "$INSPECT_SCRIPT"

echo ""
echo "[7/9] Creating ADB native packet-bound proof validator..."

VALIDATOR="$ROOT/scripts/validate-native-ble-gatt-packet-bound-proof.sh"

cat > "$VALIDATOR" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail

PACKET_ID="${1:-${PACKET_ID:-}}"
APP_PKG="${APP_PKG:-com.maurimesh.messenger}"
STAMP="$(date +"%Y%m%d-%H%M%S")"
OUT_DIR="$(pwd)/docs/native-proof"
mkdir -p "$OUT_DIR"

if [ -z "$PACKET_ID" ]; then
  echo "ERROR: packetId required."
  echo ""
  echo "Usage:"
  echo "  PACKET_ID=MM3-XXXXXX-XXXXXX ./scripts/validate-native-ble-gatt-packet-bound-proof.sh"
  echo "or:"
  echo "  ./scripts/validate-native-ble-gatt-packet-bound-proof.sh MM3-XXXXXX-XXXXXX"
  exit 1
fi

LOG_FILE="$OUT_DIR/native-ble-gatt-packet-bound-log-$PACKET_ID-$STAMP.txt"
REPORT="$OUT_DIR/native-ble-gatt-packet-bound-report-$PACKET_ID-$STAMP.md"

echo ""
echo "============================================================"
echo "MAURIMESH NATIVE BLE/GATT PACKET-BOUND VALIDATOR"
echo "============================================================"
echo "Packet ID: $PACKET_ID"
echo "App package: $APP_PKG"
echo ""
echo "Instructions:"
echo "1. This will clear logcat."
echo "2. Run the proof on phones."
echo "3. Press ENTER here after the proof flow finishes."
echo "============================================================"
echo ""

adb logcat -c || true

read -r -p "Run the proof now, then press ENTER to capture native logs..."

adb logcat -d > "$LOG_FILE" || true

MATCH_FILE="$OUT_DIR/native-ble-gatt-packet-bound-matches-$PACKET_ID-$STAMP.txt"
grep "MAURIMESH_NATIVE_BLE_GATT" "$LOG_FILE" | grep "$PACKET_ID" > "$MATCH_FILE" || true

required=(
  "advertise_start_packetId"
  "scan_result_packetId"
  "gatt_write_packetId"
  "gatt_read_packetId"
  "characteristic_changed_packetId"
  "relay_packetId"
  "ack_packetId"
)

PASS="yes"

{
  echo "# MauriMesh Native BLE/GATT Packet-Bound Proof Report"
  echo ""
  echo "Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  echo ""
  echo "Packet ID: \`$PACKET_ID\`"
  echo ""
  echo "## Required Native Stages"
  echo ""
  echo "| Stage | Status |"
  echo "|---|---|"

  for stage in "${required[@]}"; do
    if grep "$stage" "$MATCH_FILE" >/dev/null 2>&1; then
      echo "| $stage | FOUND |"
    else
      echo "| $stage | MISSING |"
      PASS="no"
    fi
  done

  echo ""
  echo "## Result"
  echo ""

  if [ "$PASS" = "yes" ]; then
    echo "NATIVE BLE/GATT PACKET-BOUND PASS"
  else
    echo "NATIVE BLE/GATT PACKET-BOUND PASS NOT CLAIMED"
  fi

  echo ""
  echo "## Files"
  echo ""
  echo "- Full log: $LOG_FILE"
  echo "- Matching packet logs: $MATCH_FILE"
  echo "- Report: $REPORT"
  echo ""
  echo "## Matching Logs"
  echo ""
  echo '```txt'
  cat "$MATCH_FILE"
  echo '```'
} > "$REPORT"

echo ""
echo "============================================================"
if [ "$PASS" = "yes" ]; then
  echo "NATIVE BLE/GATT PACKET-BOUND PASS"
else
  echo "NATIVE BLE/GATT PACKET-BOUND PASS NOT CLAIMED"
fi
echo "============================================================"
echo "Report:"
echo "$REPORT"
echo ""
echo "Matches:"
echo "$MATCH_FILE"
echo ""
echo "Full log:"
echo "$LOG_FILE"
echo "============================================================"
SCRIPT

chmod +x "$VALIDATOR"

echo "Validator:"
echo "$VALIDATOR"

echo ""
echo "[8/9] Creating proof contract report..."

CONTRACT="$ROOT/docs/native-proof/MAURIMESH_NATIVE_BLE_GATT_PACKET_BOUND_LOGGING_GATE_$STAMP.md"

cat > "$CONTRACT" <<MD
# MauriMesh Native BLE/GATT Packet-Bound Logging Gate

Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")

## Patch ID

$PATCH_ID

## Status

Native packetId logger helper and validation scripts created.

## Truth

This patch gate does **not** claim native BLE/GATT packet-bound PASS.

Current valid status remains:

\`\`\`txt
NATIVE BLE/GATT PACKET-BOUND PASS NOT CLAIMED
\`\`\`

until the same packetId appears directly inside native BLE/GATT logs.

## Created Files

- Logger helper: \`$LOGGER_FILE\`
- Candidate report: \`$CANDIDATE_REPORT\`
- Snippets: \`$SNIPPETS\`
- Inspector: \`$INSPECT_SCRIPT\`
- Validator: \`$VALIDATOR\`
- Backup archive: \`$BACKUP_ARCHIVE\`

## Required Native Stages

\`\`\`txt
advertise_start_packetId
scan_result_packetId
gatt_write_packetId
gatt_read_packetId
characteristic_changed_packetId
relay_packetId
ack_packetId
\`\`\`

## PASS Rule

Same packetId must appear in native Android logs for all required stages.

## Validation Command

After building/installing APK and running the proof:

\`\`\`bash
PACKET_ID=MM3-YOURID-HERE ./scripts/validate-native-ble-gatt-packet-bound-proof.sh
\`\`\`

## Engineering Next Step

Open the candidate file report:

\`\`\`txt
$CANDIDATE_REPORT
\`\`\`

Then wire the logger snippets into the actual native Android BLE/GATT bridge functions.

## Protection

This gate does not mutate live routing.
This gate does not modify proven ACK/store-forward proof rules.
This gate does not auto-promote evolution.
This gate does not claim native BLE/GATT proof.
MD

echo "Contract:"
echo "$CONTRACT"

echo ""
echo "[9/9] Running inspection..."

"$INSPECT_SCRIPT" | tee "$ROOT/docs/native-proof/native-ble-gatt-packetid-logging-inspection-$STAMP.txt" || true

FINAL_ARCHIVE="$ROOT/archives/maurimesh-native-ble-gatt-packetid-logging-gate-$STAMP.tar.gz"
tar -czf "$FINAL_ARCHIVE" \
  -C "$ROOT" \
  "docs/native-proof" \
  "scripts/inspect-native-ble-gatt-packetid-logging.sh" \
  "scripts/validate-native-ble-gatt-packet-bound-proof.sh" \
  >/dev/null 2>&1 || true

echo ""
echo "============================================================"
echo "MAURIMESH NATIVE BLE/GATT PACKET-ID LOGGING GATE COMPLETE"
echo "============================================================"
echo "Patch ID:"
echo "$PATCH_ID"
echo ""
echo "Namespace:"
echo "$NAMESPACE"
echo ""
echo "Logger helper:"
echo "$LOGGER_FILE"
echo ""
echo "Candidate report:"
echo "$CANDIDATE_REPORT"
echo ""
echo "Snippets:"
echo "$SNIPPETS"
echo ""
echo "Inspector:"
echo "$INSPECT_SCRIPT"
echo ""
echo "Validator:"
echo "$VALIDATOR"
echo ""
echo "Contract:"
echo "$CONTRACT"
echo ""
echo "Backup archive:"
echo "$BACKUP_ARCHIVE"
echo ""
echo "Final archive:"
echo "$FINAL_ARCHIVE"
echo ""
echo "FINAL TRUTH:"
echo "Native packetId logging helper is installed/prepared."
echo "Native BLE/GATT packet-bound PASS is NOT claimed yet."
echo "Next: wire logger calls into actual BLE/GATT bridge functions, build APK, run validator."
echo "============================================================"
