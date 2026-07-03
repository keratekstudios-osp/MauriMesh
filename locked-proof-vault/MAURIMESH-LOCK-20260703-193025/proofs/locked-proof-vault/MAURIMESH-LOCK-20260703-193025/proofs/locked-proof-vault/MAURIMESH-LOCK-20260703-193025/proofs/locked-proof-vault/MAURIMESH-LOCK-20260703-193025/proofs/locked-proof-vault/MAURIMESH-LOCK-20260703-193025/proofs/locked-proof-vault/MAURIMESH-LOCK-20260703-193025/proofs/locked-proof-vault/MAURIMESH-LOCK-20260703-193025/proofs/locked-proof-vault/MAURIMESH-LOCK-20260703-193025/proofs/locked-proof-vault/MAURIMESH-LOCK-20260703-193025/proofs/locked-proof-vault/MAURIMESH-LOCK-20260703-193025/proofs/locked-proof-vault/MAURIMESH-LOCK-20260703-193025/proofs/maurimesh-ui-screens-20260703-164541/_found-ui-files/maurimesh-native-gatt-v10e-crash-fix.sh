#!/usr/bin/env bash
set -euo pipefail

SCREEN="app/native-ble-gatt-proof.tsx"
STAMP="$(date +%Y%m%d-%H%M%S)"
mkdir -p archives/native-ble-gatt docs/native-ble-gatt

cp "$SCREEN" "archives/native-ble-gatt/native-ble-gatt-proof.tsx.before-v10e-crash-fix-${STAMP}.bak"

python3 - <<'PY'
from pathlib import Path
import re, sys

p = Path("app/native-ble-gatt-proof.tsx")
t = p.read_text(errors="ignore")

# Replace Auto Guide handler with safe direct native call.
pattern = r"const autoGuideSharedPacketV10B = useCallback\(async \(\) => \{[\s\S]*?\n  \}, \[[^\]]*\]\);"
m = re.search(pattern, t)
if not m:
    print("FAIL: autoGuideSharedPacketV10B block not found")
    sys.exit(1)

safe = r'''const autoGuideSharedPacketV10B = useCallback(async () => {
    const typed = sharedPacketIdInput.trim().toUpperCase();
    const chosen = typed || packetId;
    const valid = /^MMN-[A-Z0-9]+-[A-Z0-9]+$/.test(chosen);

    if (!valid) {
      const msg = `${LOG_TAG} AUTO_GUIDE_V10E_INVALID packetId=${chosen} finalPassClaimed=false`;
      console.warn(msg);
      appendEvent(msg);
      return;
    }

    setPacketId(chosen);
    appendEvent(`${LOG_TAG} SHARED_PACKET_V9_APPLIED packetId=${chosen} source=AUTO_GUIDE_V10E finalPassClaimed=false`);
    console.warn(`${LOG_TAG} AUTO_GUIDE_V10E_START packetId=${chosen} finalPassClaimed=false`);

    try {
      const result = await callMauriMeshNativeGattTriggerV8(chosen);
      const done = `${LOG_TAG} AUTO_GUIDE_V10E_DONE packetId=${chosen} result=${JSON.stringify(result)} finalPassClaimed=false`;
      console.warn(done);
      appendEvent(done);
    } catch (err: any) {
      const fail = `${LOG_TAG} AUTO_GUIDE_V10E_ERROR packetId=${chosen} error=${String(err?.message || err)} finalPassClaimed=false`;
      console.warn(fail);
      appendEvent(fail);
    }
  }, [sharedPacketIdInput, packetId]);'''

t = t[:m.start()] + safe + t[m.end():]

t = t.replace("AUTO GUIDE v10c: Apply Shared Packet + Brown Trigger", "AUTO GUIDE v10e: Apply Shared Packet + Trigger")
t = t.replace("AUTO_GUIDE_V10C_START → BROWN_TRIGGER → AUTO_GUIDE_V10C_DONE", "AUTO_GUIDE_V10E_START → AUTO_GUIDE_V10E_DONE")

p.write_text(t)
print("PASS: v10e crash-safe Auto Guide patched.")
PY

grep -n "AUTO_GUIDE_V10E\|autoGuideSharedPacketV10B\|FIXED_SHARED_V10D" "$SCREEN" | head -n 120

npx tsc --noEmit
npx expo export --platform android

cat > "docs/native-ble-gatt/NATIVE_GATT_V10E_CRASH_FIX_${STAMP}.md" <<EOF2
# Native BLE/GATT v10e crash fix

Fixes Native BLE/GATT Proof crash by making Auto Guide call native trigger resolver directly, avoiding hook-order dependency on triggerNativeGattPacketPayload.

Verdict: READY_FOR_EAS_BUILD_V10E_CRASH_FIX
EOF2

echo "FINAL VERDICT: READY_FOR_EAS_BUILD_V10E_CRASH_FIX"
