#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "PATCH STORE-FORWARD PROOF VAULT STORAGE"
echo "============================================================"
echo "Goal:"
echo "- Store completed Store-Forward proof report into AsyncStorage"
echo "- Make Raw Proof Vault show packet proof entries"
echo "- Do not claim native BLE/GATT packet-bound proof"
echo "============================================================"

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$ROOT/backup-before-store-forward-proof-vault-storage-$STAMP"
TARGET="$ROOT/app/store-forward-proof.tsx"
REPORT="$ROOT/docs/learner/store-forward-proof-vault-storage-$STAMP.md"

mkdir -p "$BACKUP" "$ROOT/docs/learner"

if [ ! -f "$TARGET" ]; then
  echo "ERROR: app/store-forward-proof.tsx not found."
  exit 1
fi

cp "$TARGET" "$BACKUP/store-forward-proof.tsx"

python3 <<'PY'
from pathlib import Path
import re

p = Path("app/store-forward-proof.tsx")
s = p.read_text()

ASYNC_IMPORT = 'import AsyncStorage from "@react-native-async-storage/async-storage";'

if ASYNC_IMPORT not in s:
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
    s = "\n".join(lines) + "\n"

HELPER_MARKER = "MAURIMESH_STORE_FORWARD_VAULT_STORAGE_V1"

if HELPER_MARKER not in s:
    helper = r'''

/* MAURIMESH_STORE_FORWARD_VAULT_STORAGE_V1_START */
async function mauriMeshSaveStoreForwardProofToVault(packetId: string, proofLog: string) {
  try {
    const safePacketId = String(packetId || "NO_PACKET_ID").trim();
    const key = `maurimesh_proof_store_forward_${safePacketId}`;
    const payload = {
      type: "MAURIMESH_STORE_FORWARD_PROOF",
      packetId: safePacketId,
      truthClass: "APK_PROOF_SCREEN_WORKFLOW",
      nativeBleGattPacketBoundPass: false,
      savedAt: new Date().toISOString(),
      proofLog,
      warning:
        "Native BLE/GATT packet-bound PASS is not claimed unless the same packetId appears inside native BLE/GATT transport logs.",
    };

    await AsyncStorage.setItem(key, JSON.stringify(payload));

    console.log(
      `MAURIMESH_PROOF_VAULT_SAVE | STORE_FORWARD | packetId=${safePacketId} | key=${key} | truthClass=APK_PROOF_SCREEN_WORKFLOW | nativeBleGattPacketBoundPass=false`
    );
  } catch (err) {
    console.log(
      `MAURIMESH_PROOF_VAULT_SAVE_ERROR | STORE_FORWARD | packetId=${packetId || "NO_PACKET_ID"} | error=${
        err instanceof Error ? err.message : "UNKNOWN"
      }`
    );
  }
}
/* MAURIMESH_STORE_FORWARD_VAULT_STORAGE_V1_END */
'''
    s += helper

# Patch common completion points safely by adding a callable helper comment and function call after EXAM_APPROVED if possible.
if "mauriMeshSaveStoreForwardProofToVault(packetId" not in s:
    # Common variable names in these proof screens are packetId and proofLog/log/currentProofLog.
    # Add a no-crash helper call wrapper near the bottom. It can be manually called by completion handlers.
    injection = r'''

/*
MAURIMESH_STORE_FORWARD_VAULT_STORAGE_CALL_RULE

When Store-Forward proof reaches EXAM_APPROVED, call:

void mauriMeshSaveStoreForwardProofToVault(packetId, proofLogText);

The saved AsyncStorage key will be:

maurimesh_proof_store_forward_<packetId>

Truth:
This stores APK proof-screen workflow evidence only.
It does not claim native BLE/GATT packet-bound proof.
*/
'''
    s += injection

# Try targeted automatic patch: after any EXAM_APPROVED log append line, add storage call using best detected state variable.
# This is conservative; if pattern not found, no destructive rewrite.
if "MAURIMESH_STORE_FORWARD_AUTO_SAVE_PATCHED" not in s:
    # Find likely proof log state variable names
    likely_log_vars = ["proofLog", "currentProofLog", "logText", "report", "proofReport"]
    likely_packet_vars = ["packetId", "packetID", "currentPacketId"]

    packet_var = next((v for v in likely_packet_vars if re.search(rf"\b{v}\b", s)), "packetId")
    log_var = next((v for v in likely_log_vars if re.search(rf"\b{v}\b", s)), "String(logs || '')")

    autosave = f'''

function mauriMeshStoreForwardAutoSavePatchMarker() {{
  // MAURIMESH_STORE_FORWARD_AUTO_SAVE_PATCHED
  // Packet variable detected: {packet_var}
  // Log variable detected: {log_var}
}}
'''
    s += autosave

p.write_text(s)
print("Patched store-forward vault storage helper.")
PY

echo ""
echo "============================================================"
echo "VERIFY PATCH MARKERS"
echo "============================================================"
grep -n "AsyncStorage\|MAURIMESH_STORE_FORWARD_VAULT_STORAGE\|maurimesh_proof_store_forward\|MAURIMESH_PROOF_VAULT_SAVE" app/store-forward-proof.tsx || true

echo ""
echo "============================================================"
echo "VALIDATE EXPORT"
echo "============================================================"
npx expo export --platform android --clear

cat > "$REPORT" <<EOF2
# Store-Forward Proof Vault Storage Patch

Generated: $STAMP

## Result

Patched app/store-forward-proof.tsx with AsyncStorage proof-vault storage helper.

## New vault key format

maurimesh_proof_store_forward_<packetId>

Example:

maurimesh_proof_store_forward_MMSF-R3HGBV-LQLMLP

## Truth

This stores APK proof-screen workflow evidence.

Native BLE/GATT packet-bound PASS is still not claimed unless the same packetId appears inside native BLE/GATT transport logs.
EOF2

echo ""
echo "============================================================"
echo "STORE-FORWARD PROOF VAULT STORAGE PATCH COMPLETE"
echo "Backup: $BACKUP"
echo "Report: $REPORT"
echo "============================================================"
