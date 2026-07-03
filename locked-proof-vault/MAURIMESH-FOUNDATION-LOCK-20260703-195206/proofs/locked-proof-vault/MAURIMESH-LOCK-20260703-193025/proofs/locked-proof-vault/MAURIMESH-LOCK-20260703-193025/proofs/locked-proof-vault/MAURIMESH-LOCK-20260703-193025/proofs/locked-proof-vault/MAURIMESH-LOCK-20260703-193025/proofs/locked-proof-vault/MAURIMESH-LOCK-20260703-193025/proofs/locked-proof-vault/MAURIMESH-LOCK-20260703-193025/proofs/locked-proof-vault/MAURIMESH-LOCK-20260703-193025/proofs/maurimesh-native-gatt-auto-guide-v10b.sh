#!/usr/bin/env bash
set -euo pipefail

SCREEN="app/native-ble-gatt-proof.tsx"
STAMP="$(date +%Y%m%d-%H%M%S)"
DOC_DIR="docs/native-ble-gatt"
ARCHIVE_DIR="archives/native-ble-gatt"
mkdir -p "$DOC_DIR" "$ARCHIVE_DIR"

cp "$SCREEN" "$ARCHIVE_DIR/native-ble-gatt-proof.tsx.before-auto-guide-v10b-${STAMP}.bak"

python3 - <<'PY'
from pathlib import Path
import sys

p = Path("app/native-ble-gatt-proof.tsx")
t = p.read_text(errors="ignore")

if "MM_GATT_AUTO_GUIDE_V10B" in t:
    print("SKIP: v10b already present.")
    sys.exit(0)

helper = r'''
  // MM_GATT_AUTO_GUIDE_V10B_HELPER
  const autoGuideSharedPacketV10B = useCallback(async () => {
    const typed = sharedPacketIdInput.trim().toUpperCase();
    const chosen = typed || packetId;

    const msg = `${LOG_TAG} AUTO_GUIDE_V10B_START packetId=${chosen} instruction="Use the exact same packetId on A06,S10,A16 then press AUTO button on each phone" finalPassClaimed=false`;
    console.warn(msg);
    appendEvent(msg);

    await autoSharedPacketTriggerV10();

    const done = `${LOG_TAG} AUTO_GUIDE_V10B_DONE packetId=${chosen} next="Check Mac logcat for same packetId across all three devices" finalPassClaimed=false`;
    console.warn(done);
    appendEvent(done);
  }, [sharedPacketIdInput, packetId, autoSharedPacketTriggerV10]);
'''

if "  const triggerNativeGattPacketPayload" not in t:
    print("FAIL: trigger function anchor missing.")
    sys.exit(1)

t = t.replace("  const triggerNativeGattPacketPayload", helper + "\n  const triggerNativeGattPacketPayload", 1)

ui = r'''
        {/* MM_GATT_AUTO_GUIDE_V10B_UI */}
        <View style={styles.card}>
          <Text style={styles.h2}>Auto Guide — 3 Device Same Packet</Text>
          <Text style={styles.body}>
            Type one shared packetId on A06, S10, and A16. Recommended: MMN-FIXED9-CHAIN01.
            Then press this guide button on each phone. It will apply the packetId and trigger native GATT.
          </Text>
          <Pressable style={styles.button} onPress={autoGuideSharedPacketV10B}>
            <Text style={styles.buttonText}>AUTO GUIDE: Apply Shared Packet + Trigger</Text>
          </Pressable>
          <Text style={styles.mono}>AUTO_GUIDE_V10B_START → AUTO_GUIDE_V10B_DONE</Text>
        </View>
'''

anchor = "{/* MM_GATT_AUTO_SHARED_BUTTON_V10_UI */}"
if anchor in t:
    t = t.replace(anchor, ui + "\n" + anchor, 1)
else:
    idx = t.find("Shared Packet ID Chain Mode v9")
    if idx < 0:
        print("FAIL: UI anchor missing.")
        sys.exit(1)
    insert_at = t.rfind("<View", 0, idx)
    t = t[:insert_at] + ui + "\n" + t[insert_at:]

p.write_text(t)
print("PASS: v10b auto guide button inserted.")
PY

grep -n "MM_GATT_AUTO_GUIDE_V10B\|AUTO_GUIDE_V10B" "$SCREEN" || true

npx tsc --noEmit
npx expo export --platform android

REPORT="$DOC_DIR/NATIVE_GATT_AUTO_GUIDE_V10B_${STAMP}.md"
cat > "$REPORT" <<EOF2
# MauriMesh Native GATT Auto Guide v10b

Adds guided auto button for same-packet 3-device Native GATT capture.

Markers:
- AUTO_GUIDE_V10B_START
- AUTO_GUIDE_V10B_DONE

Verdict: READY_FOR_EAS_BUILD_V10B_AUTO_GUIDE
EOF2

cp "$REPORT" "$DOC_DIR/NATIVE_GATT_AUTO_GUIDE_V10B_LATEST.md"

echo "FINAL VERDICT: READY_FOR_EAS_BUILD_V10B_AUTO_GUIDE"
