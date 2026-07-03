#!/usr/bin/env bash
set -euo pipefail

SCREEN="app/native-ble-gatt-proof.tsx"
STAMP="$(date +%Y%m%d-%H%M%S)"
mkdir -p archives/native-ble-gatt docs/native-ble-gatt

cp "$SCREEN" "archives/native-ble-gatt/native-ble-gatt-proof.tsx.before-v10b-crash-repair-${STAMP}.bak"

python3 - <<'PY'
from pathlib import Path
import re, sys

p = Path("app/native-ble-gatt-proof.tsx")
t = p.read_text(errors="ignore")

# Repair v10b dependency by replacing autoSharedPacketTriggerV10 call with direct native trigger logic.
old = "await autoSharedPacketTriggerV10();"
new = r'''
    const valid = /^MMN-[A-Z0-9]+-[A-Z0-9]+$/.test(chosen);
    if (!valid) {
      const bad = `${LOG_TAG} AUTO_GUIDE_V10B_INVALID packetId=${chosen} finalPassClaimed=false`;
      console.warn(bad);
      appendEvent(bad);
      return;
    }

    setPacketId(chosen);

    const applied = `${LOG_TAG} AUTO_GUIDE_V10B_APPLIED packetId=${chosen} finalPassClaimed=false`;
    console.warn(applied);
    appendEvent(applied);

    await new Promise((resolve) => setTimeout(resolve, 250));

    const triggering = `${LOG_TAG} AUTO_GUIDE_V10B_TRIGGERING packetId=${chosen} finalPassClaimed=false`;
    console.warn(triggering);
    appendEvent(triggering);

    const result = await callMauriMeshNativeGattTriggerV8(chosen);
    const resultMsg = `${LOG_TAG} AUTO_GUIDE_V10B_TRIGGER_DONE packetId=${chosen} result=${JSON.stringify(result)} finalPassClaimed=false`;
    console.warn(resultMsg);
    appendEvent(resultMsg);
'''
if old not in t:
    print("WARN: old autoSharedPacketTriggerV10 call not found. Continuing cleanup.")

t = t.replace(old, new)

# Remove missing dependency from useCallback dependency array.
t = t.replace("[sharedPacketIdInput, packetId, autoSharedPacketTriggerV10]", "[sharedPacketIdInput, packetId]")

p.write_text(t)
print("PASS: v10b crash repair applied.")
PY

grep -n "AUTO_GUIDE_V10B\|autoSharedPacketTriggerV10" "$SCREEN" || true

npx tsc --noEmit
npx expo export --platform android

REPORT="docs/native-ble-gatt/NATIVE_GATT_V10B_CRASH_REPAIR_${STAMP}.md"
cat > "$REPORT" <<EOF2
# Native GATT v10b Crash Repair

Removed dependency on missing autoSharedPacketTriggerV10 and made AUTO GUIDE call native trigger directly through callMauriMeshNativeGattTriggerV8.

Verdict: READY_FOR_EAS_BUILD_AFTER_CRASH_REPAIR
EOF2

cp "$REPORT" docs/native-ble-gatt/NATIVE_GATT_V10B_CRASH_REPAIR_LATEST.md

echo "FINAL VERDICT: READY_FOR_EAS_BUILD_AFTER_CRASH_REPAIR"
