#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH GUARDED NATIVE BLE/GATT PACKET-ID WIRING"
echo "============================================================"
echo "Goal:"
echo "- Wire MauriMeshNativeBlePacketLogger into safe native call sites"
echo "- Patch only Kotlin files where safe patterns are found"
echo "- Backup first"
echo "- Avoid claiming native BLE/GATT pass"
echo "- Produce report + archive"
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +"%Y%m%d-%H%M%S")"
PATCH_ID="MM-NATIVE-BLE-GATT-WIRE-$STAMP"

if [ ! -f "$ROOT/package.json" ]; then
  echo "ERROR: package.json not found. Run from /home/runner/workspace."
  exit 1
fi

LOGGER="$ROOT/android/app/src/main/java/com/maurimesh/messenger/MauriMeshNativeBlePacketLogger.kt"

if [ ! -f "$LOGGER" ]; then
  echo "ERROR: Logger helper not found:"
  echo "$LOGGER"
  echo "Run patch-native-ble-gatt-packetid-logging-gate.sh first."
  exit 1
fi

mkdir -p \
  "$ROOT/backups" \
  "$ROOT/archives" \
  "$ROOT/docs/native-proof" \
  "$ROOT/scripts"

BACKUP_DIR="$ROOT/backups/before-native-ble-gatt-wiring-$STAMP"
mkdir -p "$BACKUP_DIR"

echo "[1/8] Backing up Android native files..."

if [ -d "$ROOT/android/app/src/main/java" ]; then
  cp -R "$ROOT/android/app/src/main/java" "$BACKUP_DIR/java"
fi

BACKUP_ARCHIVE="$ROOT/archives/before-native-ble-gatt-wiring-$STAMP.tar.gz"
tar -czf "$BACKUP_ARCHIVE" -C "$BACKUP_DIR" . >/dev/null 2>&1 || true

echo "Backup archive:"
echo "$BACKUP_ARCHIVE"

PATCHER="$ROOT/scripts/guarded-native-ble-gatt-packetid-patcher.py"
REPORT="$ROOT/docs/native-proof/MAURIMESH_NATIVE_BLE_GATT_PACKETID_WIRING_REPORT_$STAMP.md"

echo ""
echo "[2/8] Creating guarded patcher..."

cat > "$PATCHER" <<'PY'
#!/usr/bin/env python3
from __future__ import annotations

import re
from pathlib import Path
from datetime import datetime, timezone

ROOT = Path.cwd()
JAVA_ROOT = ROOT / "android/app/src/main/java"
REPORT_PATH = ROOT / "docs/native-proof" / f"MAURIMESH_NATIVE_BLE_GATT_PACKETID_WIRING_REPORT_PLACEHOLDER.md"

LOGGER_FQN = "com.maurimesh.messenger.MauriMeshNativeBlePacketLogger"
LOGGER_NAME = "MauriMeshNativeBlePacketLogger"

CANDIDATES = [
    ROOT / "android/app/src/main/java/com/maurimesh/mesh/MeshEngine.kt",
    ROOT / "android/app/src/main/java/com/maurimesh/messenger/MauriMeshBleModule.kt",
    ROOT / "android/app/src/main/java/com/maurimesh/messenger/MeshCentralClient.kt",
    ROOT / "android/app/src/main/java/com/maurimesh/messenger/MeshRawPacketGattServer.kt",
    ROOT / "android/app/src/main/java/com/maurimesh/messenger/maurimesh/blehardware/MauriMeshHardwareBleScanService.kt",
]

required_stages = [
    "advertise_start_packetId",
    "scan_result_packetId",
    "gatt_write_packetId",
    "gatt_read_packetId",
    "characteristic_changed_packetId",
    "relay_packetId",
    "ack_packetId",
]

changes: list[str] = []
warnings: list[str] = []


def has_logger_import(text: str) -> bool:
    return LOGGER_FQN in text or "package com.maurimesh.messenger" in text


def add_import_if_needed(text: str, path: Path) -> str:
    if has_logger_import(text):
        return text
    if LOGGER_NAME not in text:
        return text

    lines = text.splitlines()
    out = []
    inserted = False

    for i, line in enumerate(lines):
        out.append(line)
        if not inserted and line.startswith("package "):
            out.append("")
            out.append(f"import {LOGGER_FQN}")
            inserted = True

    if inserted:
        changes.append(f"{path}: added logger import")

    return "\n".join(out) + ("\n" if text.endswith("\n") else "")


def indent_of(line: str) -> str:
    return line[: len(line) - len(line.lstrip())]


def packet_var_from_signature(sig: str) -> str | None:
    candidates = [
        "packetId",
        "packetID",
        "id",
    ]
    for c in candidates:
        if re.search(rf"\b{c}\s*:\s*String\b", sig):
            return c
    return None


def patch_function_entries(text: str, path: Path) -> str:
    """
    Adds entry logs for functions with an explicit packetId:String style parameter.
    Stage is selected by function name.
    """
    lines = text.splitlines()
    out = []
    i = 0

    while i < len(lines):
        line = lines[i]
        out.append(line)

        if "fun " in line and "(" in line and ")" in line and "packetId" in line and "{" in line:
            sig = line
            pkt = packet_var_from_signature(sig)
            if pkt:
                lname = sig.lower()
                stage_call = None

                if "advertis" in lname:
                    stage_call = f'{LOGGER_NAME}.advertiseStart({pkt}, "native function entry {path.name}")'
                elif "scan" in lname:
                    stage_call = f'{LOGGER_NAME}.scanResult({pkt}, "native function entry {path.name}")'
                elif "ack" in lname:
                    stage_call = f'{LOGGER_NAME}.ack({pkt}, "native function entry {path.name}")'
                elif "relay" in lname or "forward" in lname:
                    stage_call = f'{LOGGER_NAME}.relay({pkt}, "native function entry {path.name}")'
                elif "write" in lname or "send" in lname or "transmit" in lname:
                    stage_call = f'{LOGGER_NAME}.event("gatt_write_packetId", {pkt}, "native function entry {path.name}")'
                elif "read" in lname or "receive" in lname:
                    stage_call = f'{LOGGER_NAME}.event("gatt_read_packetId", {pkt}, "native function entry {path.name}")'

                if stage_call and LOGGER_NAME not in lines[i + 1 : i + 4]:
                    ind = indent_of(line) + "    "
                    out.append(f"{ind}{stage_call}")
                    changes.append(f"{path}: inserted function-entry packetId log after: {line.strip()}")

        i += 1

    return "\n".join(out) + ("\n" if text.endswith("\n") else "")


def patch_gatt_callbacks(text: str, path: Path) -> str:
    lines = text.splitlines()
    out = []

    for idx, line in enumerate(lines):
        out.append(line)
        stripped = line.strip()

        already_next = "\n".join(lines[idx + 1 : idx + 5])

        # Kotlin callback: override fun onCharacteristicChanged(..., characteristic: BluetoothGattCharacteristic) {
        if (
            "onCharacteristicChanged" in stripped
            and "BluetoothGattCharacteristic" in stripped
            and "{" in stripped
            and LOGGER_NAME not in already_next
        ):
            ind = indent_of(line) + "    "
            if re.search(r"\bvalue\s*:\s*ByteArray\b", stripped):
                out.append(f'{ind}{LOGGER_NAME}.characteristicChanged(value, "onCharacteristicChanged {path.name}")')
            else:
                out.append(f'{ind}{LOGGER_NAME}.characteristicChanged(characteristic.value, "onCharacteristicChanged {path.name}")')
            changes.append(f"{path}: inserted characteristic_changed_packetId log")

        # Kotlin callback: onCharacteristicRead(... characteristic: BluetoothGattCharacteristic ...)
        if (
            "onCharacteristicRead" in stripped
            and "BluetoothGattCharacteristic" in stripped
            and "{" in stripped
            and LOGGER_NAME not in already_next
        ):
            ind = indent_of(line) + "    "
            out.append(f'{ind}{LOGGER_NAME}.gattRead(characteristic.value, "onCharacteristicRead {path.name}")')
            changes.append(f"{path}: inserted gatt_read_packetId log")

        # Kotlin callback: onCharacteristicWrite(... characteristic: BluetoothGattCharacteristic ...)
        if (
            "onCharacteristicWrite" in stripped
            and "BluetoothGattCharacteristic" in stripped
            and "{" in stripped
            and LOGGER_NAME not in already_next
        ):
            ind = indent_of(line) + "    "
            out.append(f'{ind}{LOGGER_NAME}.gattWrite(characteristic.value, "onCharacteristicWrite {path.name}")')
            changes.append(f"{path}: inserted gatt_write_packetId log")

    return "\n".join(out) + ("\n" if text.endswith("\n") else "")


def patch_safe_write_calls(text: str, path: Path) -> str:
    lines = text.splitlines()
    out = []

    for idx, line in enumerate(lines):
        stripped = line.strip()
        ind = indent_of(line)

        # Only insert when the literal variable "characteristic" is clearly being written.
        if (
            "writeCharacteristic(characteristic" in stripped
            and LOGGER_NAME not in "\n".join(lines[max(0, idx - 3) : idx + 1])
        ):
            out.append(f'{ind}{LOGGER_NAME}.gattWrite(characteristic.value, "before writeCharacteristic {path.name}")')
            changes.append(f"{path}: inserted before writeCharacteristic(characteristic...)")

        out.append(line)

    return "\n".join(out) + ("\n" if text.endswith("\n") else "")


def patch_ack_relay_from_packetid_vars(text: str, path: Path) -> str:
    """
    Conservative pass:
    If a line contains packetId and also ACK/relay/forward, insert a log before it.
    Avoid duplicate if logger already nearby.
    """
    lines = text.splitlines()
    out = []

    for idx, line in enumerate(lines):
        stripped = line.strip()
        lower = stripped.lower()
        nearby = "\n".join(lines[max(0, idx - 3) : idx + 4])

        if "packetId" in stripped and LOGGER_NAME not in nearby:
            ind = indent_of(line)
            if "ack" in lower:
                out.append(f'{ind}{LOGGER_NAME}.ack(packetId, "ack packetId nearby {path.name}")')
                changes.append(f"{path}: inserted ack_packetId near packetId/ack line")
            elif "relay" in lower or "forward" in lower:
                out.append(f'{ind}{LOGGER_NAME}.relay(packetId, "relay packetId nearby {path.name}")')
                changes.append(f"{path}: inserted relay_packetId near packetId/relay line")

        out.append(line)

    return "\n".join(out) + ("\n" if text.endswith("\n") else "")


def patch_scan_and_advertise_from_packetid_vars(text: str, path: Path) -> str:
    lines = text.splitlines()
    out = []

    for idx, line in enumerate(lines):
        stripped = line.strip()
        lower = stripped.lower()
        nearby = "\n".join(lines[max(0, idx - 3) : idx + 4])
        ind = indent_of(line)

        # Only if packetId variable is visibly in nearby text.
        if "packetId" in nearby and LOGGER_NAME not in nearby:
            if "startadvertising" in lower or "advertis" in lower:
                out.append(f'{ind}{LOGGER_NAME}.advertiseStart(packetId, "advertise packetId nearby {path.name}")')
                changes.append(f"{path}: inserted advertise_start_packetId near packetId/advertise")
            elif "onscanresult" in lower or "scan" in lower:
                out.append(f'{ind}{LOGGER_NAME}.scanResult(packetId, "scan packetId nearby {path.name}")')
                changes.append(f"{path}: inserted scan_result_packetId near packetId/scan")

        out.append(line)

    return "\n".join(out) + ("\n" if text.endswith("\n") else "")


def patch_file(path: Path) -> None:
    if not path.exists():
        warnings.append(f"Missing candidate file: {path}")
        return

    if path.suffix != ".kt":
        warnings.append(f"Skipped non-Kotlin candidate: {path}")
        return

    original = path.read_text(errors="replace")
    text = original

    if LOGGER_NAME not in text:
        # We add import only after actual logger use is inserted later.
        pass

    text = patch_gatt_callbacks(text, path)
    text = patch_safe_write_calls(text, path)
    text = patch_function_entries(text, path)
    text = patch_ack_relay_from_packetid_vars(text, path)
    text = patch_scan_and_advertise_from_packetid_vars(text, path)

    if LOGGER_NAME in text:
        text = add_import_if_needed(text, path)

    if text != original:
        path.write_text(text)
    else:
        warnings.append(f"No safe patch inserted for: {path}")


def main() -> None:
    for p in CANDIDATES:
        patch_file(p)

    report = []
    report.append("# MauriMesh Guarded Native BLE/GATT PacketId Wiring Report")
    report.append("")
    report.append(f"Generated: {datetime.now(timezone.utc).isoformat()}")
    report.append("")
    report.append("## Truth")
    report.append("")
    report.append("This patch wires native packetId logging only where safe Kotlin patterns were detected.")
    report.append("")
    report.append("Native BLE/GATT packet-bound PASS is still **NOT CLAIMED**.")
    report.append("")
    report.append("## Changes")
    report.append("")
    if changes:
        for c in changes:
            report.append(f"- {c}")
    else:
        report.append("- No safe code insertions were made.")
    report.append("")
    report.append("## Warnings / Skipped")
    report.append("")
    if warnings:
        for w in warnings:
            report.append(f"- {w}")
    else:
        report.append("- None")
    report.append("")
    report.append("## Required Stages")
    report.append("")
    for s in required_stages:
        report.append(f"- {s}")
    report.append("")
    report.append("## Next Validation")
    report.append("")
    report.append("Run:")
    report.append("")
    report.append("```bash")
    report.append("./scripts/inspect-native-ble-gatt-packetid-logging.sh")
    report.append("```")
    report.append("")
    report.append("Then build APK and run:")
    report.append("")
    report.append("```bash")
    report.append("PACKET_ID=MM3-YOURID-HERE ./scripts/validate-native-ble-gatt-packet-bound-proof.sh")
    report.append("```")
    report.append("")

    out = ROOT / "docs/native-proof/GUARDED_NATIVE_BLE_GATT_PACKETID_WIRING_REPORT.md"
    out.write_text("\n".join(report) + "\n")

    print("Guarded patcher complete.")
    print(f"Changes: {len(changes)}")
    print(f"Warnings: {len(warnings)}")
    print(f"Report: {out}")


if __name__ == "__main__":
    main()
PY

# Replace placeholder name with stamped report copy after run.
chmod +x "$PATCHER"

echo "Patcher:"
echo "$PATCHER"

echo ""
echo "[3/8] Running guarded patcher..."

python3 "$PATCHER"

STAMPED_REPORT="$ROOT/docs/native-proof/MAURIMESH_NATIVE_BLE_GATT_PACKETID_WIRING_REPORT_$STAMP.md"
cp "$ROOT/docs/native-proof/GUARDED_NATIVE_BLE_GATT_PACKETID_WIRING_REPORT.md" "$STAMPED_REPORT"

echo "Stamped report:"
echo "$STAMPED_REPORT"

echo ""
echo "[4/8] Running logger inspection..."

INSPECTION_OUT="$ROOT/docs/native-proof/native-ble-gatt-packetid-wiring-inspection-$STAMP.txt"

if [ -x "$ROOT/scripts/inspect-native-ble-gatt-packetid-logging.sh" ]; then
  "$ROOT/scripts/inspect-native-ble-gatt-packetid-logging.sh" | tee "$INSPECTION_OUT"
else
  echo "WARNING: inspection script missing." | tee "$INSPECTION_OUT"
fi

echo ""
echo "[5/8] Checking required stage references..."

STAGE_REPORT="$ROOT/docs/native-proof/native-ble-gatt-required-stage-reference-check-$STAMP.txt"
: > "$STAGE_REPORT"

for stage in \
  advertise_start_packetId \
  scan_result_packetId \
  gatt_write_packetId \
  gatt_read_packetId \
  characteristic_changed_packetId \
  relay_packetId \
  ack_packetId
do
  echo "" >> "$STAGE_REPORT"
  echo "Stage: $stage" >> "$STAGE_REPORT"
  grep -RIn "$stage" "$ROOT/android/app/src/main/java" "$ROOT/src" "$ROOT/app" 2>/dev/null >> "$STAGE_REPORT" || true
done

cat "$STAGE_REPORT"

echo ""
echo "[6/8] Running TypeScript check if available..."

TSC_OUT="$ROOT/docs/native-proof/typecheck-after-native-ble-gatt-wiring-$STAMP.txt"

if [ -f "$ROOT/tsconfig.json" ]; then
  if npx tsc --noEmit > "$TSC_OUT" 2>&1; then
    echo "TypeScript: PASS"
  else
    echo "TypeScript: CHECK FAILED OR WARNINGS"
    tail -80 "$TSC_OUT" || true
  fi
else
  echo "No tsconfig.json found; skipped TypeScript check." | tee "$TSC_OUT"
fi

echo ""
echo "[7/8] Running Gradle compile check if Android wrapper exists..."

GRADLE_OUT="$ROOT/docs/native-proof/gradle-check-after-native-ble-gatt-wiring-$STAMP.txt"

if [ -x "$ROOT/android/gradlew" ]; then
  (
    cd "$ROOT/android"
    ./gradlew :app:compileDebugKotlin --no-daemon
  ) > "$GRADLE_OUT" 2>&1 && echo "Gradle Kotlin compile: PASS" || {
    echo "Gradle Kotlin compile: CHECK FAILED"
    echo "Showing last 120 lines:"
    tail -120 "$GRADLE_OUT" || true
  }
else
  echo "No android/gradlew executable found; skipped Gradle compile." | tee "$GRADLE_OUT"
fi

echo ""
echo "[8/8] Creating archive..."

FINAL_ARCHIVE="$ROOT/archives/maurimesh-native-ble-gatt-packetid-wiring-$STAMP.tar.gz"

tar -czf "$FINAL_ARCHIVE" \
  -C "$ROOT" \
  "docs/native-proof" \
  "scripts/guarded-native-ble-gatt-packetid-patcher.py" \
  "scripts/inspect-native-ble-gatt-packetid-logging.sh" \
  "scripts/validate-native-ble-gatt-packet-bound-proof.sh" \
  >/dev/null 2>&1 || true

echo ""
echo "============================================================"
echo "MAURIMESH GUARDED NATIVE BLE/GATT PACKET-ID WIRING COMPLETE"
echo "============================================================"
echo "Patch ID:"
echo "$PATCH_ID"
echo ""
echo "Backup archive:"
echo "$BACKUP_ARCHIVE"
echo ""
echo "Wiring report:"
echo "$STAMPED_REPORT"
echo ""
echo "Inspection:"
echo "$INSPECTION_OUT"
echo ""
echo "Stage reference check:"
echo "$STAGE_REPORT"
echo ""
echo "TypeScript output:"
echo "$TSC_OUT"
echo ""
echo "Gradle output:"
echo "$GRADLE_OUT"
echo ""
echo "Final archive:"
echo "$FINAL_ARCHIVE"
echo ""
echo "FINAL TRUTH:"
echo "Guarded native BLE/GATT packetId wiring attempted."
echo "Native BLE/GATT packet-bound PASS is NOT claimed yet."
echo "Next: if Gradle passed, build APK and run validator on real devices."
echo "If Gradle failed, send the last error lines and we patch safely."
echo "============================================================"
