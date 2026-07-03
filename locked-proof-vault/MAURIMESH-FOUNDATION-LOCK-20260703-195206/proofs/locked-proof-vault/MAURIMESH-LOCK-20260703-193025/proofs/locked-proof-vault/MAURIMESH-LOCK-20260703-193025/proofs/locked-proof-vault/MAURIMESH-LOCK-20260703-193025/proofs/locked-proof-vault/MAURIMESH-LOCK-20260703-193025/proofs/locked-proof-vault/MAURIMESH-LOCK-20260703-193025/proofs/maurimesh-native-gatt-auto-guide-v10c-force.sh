#!/usr/bin/env bash
set -euo pipefail

SCREEN="app/native-ble-gatt-proof.tsx"
STAMP="$(date +%Y%m%d-%H%M%S)"
DOC_DIR="docs/native-ble-gatt"
ARCHIVE_DIR="archives/native-ble-gatt"
mkdir -p "$DOC_DIR" "$ARCHIVE_DIR"

cp "$SCREEN" "$ARCHIVE_DIR/native-ble-gatt-proof.tsx.before-v10c-force-${STAMP}.bak"

python3 - <<'PY'
from pathlib import Path
import sys

p = Path("app/native-ble-gatt-proof.tsx")
t = p.read_text(errors="ignore")

start = t.find("const autoGuideSharedPacketV10B = useCallback")
end = t.find("const triggerNativeGattPacketPayload = useCallback")

if start < 0 or end < 0 or end <= start:
    print("FAIL: could not find safe function anchors")
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

    const startMsg = `${LOG_TAG} AUTO_GUIDE_V10C_START packetId=${chosen} instruction="Apply shared packet then call same brown-button native trigger" finalPassClaimed=false`;
    console.warn(startMsg);
    appendEvent(startMsg);

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
  }, [sharedPacketIdInput, packetId, triggerNativeGattPacketPayload]);

  '''

t = t[:start] + new + t[end:]

t = t.replace(
    "AUTO GUIDE: Apply Shared Packet + Trigger",
    "AUTO GUIDE v10c: Apply Shared Packet + Brown Trigger"
).replace(
    "AUTO_GUIDE_V10B_START → AUTO_GUIDE_V10B_DONE",
    "AUTO_GUIDE_V10C_START → BROWN_TRIGGER → AUTO_GUIDE_V10C_DONE"
)

p.write_text(t)
print("PASS: v10c force patch applied.")
PY

grep -n "AUTO_GUIDE_V10C\|autoGuideSharedPacketV10B\|triggerNativeGattPacketPayload" "$SCREEN" | head -n 100

npx tsc --noEmit
npx expo export --platform android

echo "FINAL VERDICT: READY_FOR_EAS_BUILD_V10C_AUTO_GUIDE_BROWN_TRIGGER"
