#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH PROOF VAULT STORAGE EXPANSION v1"
echo "============================================================"
echo "Goal:"
echo "- Add AsyncStorage proof-vault save helpers for:"
echo "  1. 3-device proof"
echo "  2. 2-hop proof"
echo "  3. native BLE/GATT attempt"
echo "  4. Learner Core reports"
echo "- Keep truth rules clean"
echo "- Do not claim native BLE/GATT PASS"
echo "============================================================"

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$ROOT/backup-before-proof-vault-storage-expansion-v1-$STAMP"
REPORT="$ROOT/docs/learner/proof-vault-storage-expansion-v1-$STAMP.md"

mkdir -p "$BACKUP" "$ROOT/docs/learner"

if [ ! -f "$ROOT/package.json" ]; then
  echo "ERROR: package.json not found. Run from project root."
  exit 1
fi

TARGETS=(
  "app/3-device-proof.tsx"
  "app/ble-3-device-proof.tsx"
  "app/ble-2-hop-proof.tsx"
  "app/learner-core.tsx"
)

for f in "${TARGETS[@]}"; do
  if [ -f "$ROOT/$f" ]; then
    mkdir -p "$BACKUP/$(dirname "$f")"
    cp "$ROOT/$f" "$BACKUP/$f"
    echo "Backed up: $f"
  else
    echo "Skipping missing: $f"
  fi
done

python3 <<'PY'
from pathlib import Path
import re

ASYNC_IMPORT = 'import AsyncStorage from "@react-native-async-storage/async-storage";'

def ensure_async_import(s: str) -> str:
    if ASYNC_IMPORT in s:
        return s

    lines = s.splitlines()
    insert_at = 0
    in_import = False

    for i, line in enumerate(lines):
        stripped = line.strip()
        if stripped.startswith("import "):
            in_import = True
        if in_import and stripped.endswith(";"):
            insert_at = i + 1
            in_import = False

    lines.insert(insert_at, ASYNC_IMPORT)
    return "\n".join(lines) + "\n"

def append_once(s: str, marker: str, block: str) -> str:
    if marker in s:
        return s
    return s + "\n" + block + "\n"

def patch_file(path: str, helper_name: str, proof_type: str, key_prefix: str, truth_class: str):
    p = Path(path)
    if not p.exists():
        print(f"Missing: {path}")
        return

    s = p.read_text()
    s = ensure_async_import(s)

    marker = f"MAURIMESH_{proof_type}_VAULT_STORAGE_V1"
    helper = f'''

/* {marker}_START */
async function {helper_name}(packetId: string, proofLog: string) {{
  try {{
    const safePacketId = String(packetId || "NO_PACKET_ID").trim();
    const key = `{key_prefix}_${{safePacketId}}`;
    const payload = {{
      type: "{proof_type}",
      packetId: safePacketId,
      truthClass: "{truth_class}",
      nativeBleGattPacketBoundPass: false,
      savedAt: new Date().toISOString(),
      proofLog,
      warning:
        "Native BLE/GATT packet-bound PASS is not claimed unless the same packetId appears inside native BLE/GATT transport logs.",
    }};

    await AsyncStorage.setItem(key, JSON.stringify(payload));

    console.log(
      `MAURIMESH_PROOF_VAULT_SAVE | {proof_type} | packetId=${{safePacketId}} | key=${{key}} | truthClass={truth_class} | nativeBleGattPacketBoundPass=false`
    );
  }} catch (err) {{
    console.log(
      `MAURIMESH_PROOF_VAULT_SAVE_ERROR | {proof_type} | packetId=${{packetId || "NO_PACKET_ID"}} | error=${{
        err instanceof Error ? err.message : "UNKNOWN"
      }}`
    );
  }}
}}
/* {marker}_END */
'''

    s = append_once(s, marker, helper)

    call_marker = f"MAURIMESH_{proof_type}_VAULT_SAVE_CALL_RULE"
    call_rule = f'''
/*
{call_marker}

When this proof reaches EXAM_APPROVED or final completion, call:

void {helper_name}(packetId, proofLogText);

Saved key format:

{key_prefix}_<packetId>

Truth:
This stores APK proof-screen workflow evidence only.
It does not claim native BLE/GATT packet-bound proof.
*/
'''
    s = append_once(s, call_marker, call_rule)

    p.write_text(s)
    print(f"Patched: {path}")

patch_file(
    "app/3-device-proof.tsx",
    "mauriMeshSaveThreeDeviceProofToVault",
    "THREE_DEVICE_RELAY_PROOF",
    "maurimesh_proof_3_device",
    "APK_PROOF_SCREEN_WORKFLOW"
)

patch_file(
    "app/ble-3-device-proof.tsx",
    "mauriMeshSaveBleThreeDeviceProofToVault",
    "BLE_THREE_DEVICE_RELAY_PROOF",
    "maurimesh_proof_ble_3_device",
    "APK_PROOF_SCREEN_WORKFLOW"
)

patch_file(
    "app/ble-2-hop-proof.tsx",
    "mauriMeshSaveBleTwoHopProofToVault",
    "BLE_TWO_HOP_PROOF",
    "maurimesh_proof_ble_2_hop",
    "APK_PROOF_SCREEN_WORKFLOW"
)

# Learner Core report storage
p = Path("app/learner-core.tsx")
if p.exists():
    s = p.read_text()
    s = ensure_async_import(s)

    marker = "MAURIMESH_LEARNER_CORE_REPORT_VAULT_STORAGE_V1"
    helper = r'''

/* MAURIMESH_LEARNER_CORE_REPORT_VAULT_STORAGE_V1_START */
async function mauriMeshSaveLearnerCoreReportToVault(packetId: string, report: unknown) {
  try {
    const safePacketId = String(packetId || "NO_PACKET_ID").trim();
    const key = `maurimesh_learner_report_${safePacketId}_${Date.now()}`;
    const payload = {
      type: "MAURIMESH_LEARNER_CORE_REPORT",
      packetId: safePacketId,
      truthClass: "LEARNER_CLASSIFICATION_REPORT",
      nativeBleGattPacketBoundPass: false,
      savedAt: new Date().toISOString(),
      report,
      warning:
        "Learner Core classifies evidence and recommends recovery. It does not prove native BLE/GATT transport by itself.",
    };

    await AsyncStorage.setItem(key, JSON.stringify(payload));

    console.log(
      `MAURIMESH_LEARNER_REPORT_SAVE | packetId=${safePacketId} | key=${key} | nativeBleGattPacketBoundPass=false`
    );
  } catch (err) {
    console.log(
      `MAURIMESH_LEARNER_REPORT_SAVE_ERROR | packetId=${packetId || "NO_PACKET_ID"} | error=${
        err instanceof Error ? err.message : "UNKNOWN"
      }`
    );
  }
}
/* MAURIMESH_LEARNER_CORE_REPORT_VAULT_STORAGE_V1_END */
'''
    s = append_once(s, marker, helper)

    rule = r'''
/*
MAURIMESH_LEARNER_CORE_REPORT_SAVE_RULE

When the user runs Learner Core against proof logs, call:

void mauriMeshSaveLearnerCoreReportToVault(report.packetId, report);

Saved key format:

maurimesh_learner_report_<packetId>_<timestamp>

Truth:
This stores learner classification output.
It does not claim native BLE/GATT packet-bound proof.
*/
'''
    s = append_once(s, "MAURIMESH_LEARNER_CORE_REPORT_SAVE_RULE", rule)
    p.write_text(s)
    print("Patched: app/learner-core.tsx")
PY

echo ""
echo "============================================================"
echo "VERIFY VAULT STORAGE MARKERS"
echo "============================================================"

for f in app/3-device-proof.tsx app/ble-3-device-proof.tsx app/ble-2-hop-proof.tsx app/learner-core.tsx app/store-forward-proof.tsx; do
  if [ -f "$f" ]; then
    echo ""
    echo "--- $f ---"
    grep -n "AsyncStorage\|MAURIMESH_PROOF_VAULT_SAVE\|maurimesh_proof_\|maurimesh_learner_report\|VAULT_STORAGE" "$f" | head -60 || true
  fi
done

echo ""
echo "============================================================"
echo "VALIDATE EXPORT"
echo "============================================================"

npx expo export --platform android --clear

cat > "$REPORT" <<MD
# MauriMesh Proof Vault Storage Expansion v1

Generated: $STAMP

## Added vault storage helpers for

- 3-device relay proof
- BLE 3-device relay proof
- BLE 2-hop proof
- Learner Core reports

## Existing

- Store-Forward proof vault helper and save call already wired.

## New key formats

\`\`\`txt
maurimesh_proof_3_device_<packetId>
maurimesh_proof_ble_3_device_<packetId>
maurimesh_proof_ble_2_hop_<packetId>
maurimesh_learner_report_<packetId>_<timestamp>
maurimesh_proof_store_forward_<packetId>
\`\`\`

## Truth

These vault entries store app proof workflow and learner-classification evidence.

They do not claim native BLE/GATT packet-bound proof.

Native BLE/GATT PASS requires the same packetId inside native BLE/GATT transport logs.
MD

echo ""
echo "============================================================"
echo "PROOF VAULT STORAGE EXPANSION v1 COMPLETE"
echo "============================================================"
echo "Backup: $BACKUP"
echo "Report: $REPORT"
echo ""
echo "Next:"
echo "Current EAS build will not include this if already uploaded."
echo "Next APK build will include these vault storage helpers."
echo "============================================================"
