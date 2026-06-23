#!/usr/bin/env bash
set -euo pipefail

SCREEN="app/native-ble-gatt-proof.tsx"
STAMP="$(date +%Y%m%d-%H%M%S)"
DOC_DIR="docs/native-ble-gatt"
ARCHIVE_DIR="archives/native-ble-gatt"
mkdir -p "$DOC_DIR" "$ARCHIVE_DIR"

cp "$SCREEN" "$ARCHIVE_DIR/native-ble-gatt-proof.tsx.before-auto-guide-v10c-${STAMP}.bak"

python3 - <<'PY'
from pathlib import Path
import re, sys

p = Path("app/native-ble-gatt-proof.tsx")
t = p.read_text(errors="ignore")

old = re.search(
    r"const autoGuideSharedPacketV10B = useCallback\(async \(\) => \{[\s\S]*?\n  \}, \[sharedPacketIdInput, packetId, autoSharedPacketTriggerV10\]\);",
    t
)

if not old:
    print("FAIL: could not find old autoGuideSharedPacketV10B block")
    sys.exit(1)

new = r'''const autoGuideSharedPacketV10B = useCallback(async () => {
    const typed = sharedPacketIdInput.trim().toUpperCase();
    const chosen = typed || packetId;

    const valid = /^MMN-[A-Z0-9]+-[A-Z0-9]+$/.test(chosen);
    if (!valid) {
      const invalid = `${LOG_TAG} AUTO_GUIDE_V10C_INVALID packetId=${chosen} input=${sharedPacketIdInput} finalPassClaimed=false`;
      console.warn(invalid);
      appendEvent(invalid);
      return;
    }

    setPacketId(chosen);

    const start = `${LOG_TAG} AUTO_GUIDE_V10C_START packetId=${chosen} instruction="Apply shared packet then call same brown-button native trigger" finalPassClaimed=false`;
    console.warn(start);
    appendEvent(start);

    await new Promise((resolve) => setTimeout(resolve, 300));

    const apply = `${LOG_TAG} SHARED_PACKET_V9_APPLIED packetId=${chosen} source=AUTO_GUIDE_V10C finalPassClaimed=false`;
    console.warn(apply);
    appendEvent(apply);

    await new Promise((resolve) => setTimeout(resolve, 300));

    const trigger = `${LOG_TAG} AUTO_GUIDE_V10C_CALL_BROWN_TRIGGER packetId=${chosen} finalPassClaimed=false`;
    console.warn(trigger);
    appendEvent(trigger);

    await triggerNativeGattPacketPayload();

    const done = `${LOG_TAG} AUTO_GUIDE_V10C_DONE packetId=${chosen} next="Check Mac logcat for same packetId across all three devices" finalPassClaimed=false`;
    console.warn(done);
    appendEvent(done);
  }, [sharedPacketIdInput, packetId, triggerNativeGattPacketPayload]);'''

t = t[:old.start()] + new + t[old.end():]

# update visible label
t = t.replace(
    "AUTO GUIDE: Apply Shared Packet + Trigger",
    "AUTO GUIDE v10c: Apply Shared Packet + Brown Trigger"
)

t = t.replace(
    "AUTO_GUIDE_V10B_START → AUTO_GUIDE_V10B_DONE",
    "AUTO_GUIDE_V10C_START → BROWN_TRIGGER → AUTO_GUIDE_V10C_DONE"
)

p.write_text(t)
print("PASS: v10c auto guide now calls brown trigger function.")
PY

grep -n "AUTO_GUIDE_V10C\|autoGuideSharedPacketV10B\|triggerNativeGattPacketPayload" "$SCREEN" | head -n 80

npx tsc --noEmit
npx expo export --platform android

REPORT="$DOC_DIR/NATIVE_GATT_AUTO_GUIDE_V10C_${STAMP}.md"
cat > "$REPORT" <<EOF2
# MauriMesh Native GATT Auto Guide v10c

Auto Guide now calls the same triggerNativeGattPacketPayload function used by the brown manual button.

Markers:
- AUTO_GUIDE_V10C_START
- SHARED_PACKET_V9_APPLIED source=AUTO_GUIDE_V10C
- AUTO_GUIDE_V10C_CALL_BROWN_TRIGGER
- AUTO_GUIDE_V10C_DONE

Verdict: READY_FOR_EAS_BUILD_V10C_AUTO_GUIDE_BROWN_TRIGGER
EOF2

cp "$REPORT" "$DOC_DIR/NATIVE_GATT_AUTO_GUIDE_V10C_LATEST.md"

echo "FINAL VERDICT: READY_FOR_EAS_BUILD_V10C_AUTO_GUIDE_BROWN_TRIGGER"
