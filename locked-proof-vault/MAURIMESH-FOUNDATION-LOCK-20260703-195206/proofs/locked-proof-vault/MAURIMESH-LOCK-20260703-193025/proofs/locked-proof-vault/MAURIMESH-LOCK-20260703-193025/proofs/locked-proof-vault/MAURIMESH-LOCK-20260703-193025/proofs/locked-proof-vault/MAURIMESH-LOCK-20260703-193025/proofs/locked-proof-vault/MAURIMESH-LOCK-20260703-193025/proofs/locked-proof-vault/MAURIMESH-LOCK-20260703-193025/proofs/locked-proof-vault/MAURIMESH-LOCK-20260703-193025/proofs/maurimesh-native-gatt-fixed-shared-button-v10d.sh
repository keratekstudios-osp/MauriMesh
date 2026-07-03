#!/usr/bin/env bash
set -euo pipefail

SCREEN="app/native-ble-gatt-proof.tsx"
STAMP="$(date +%Y%m%d-%H%M%S)"
cp "$SCREEN" "archives/native-ble-gatt/native-ble-gatt-proof.tsx.before-v10d-${STAMP}.bak"

python3 - <<'PY'
from pathlib import Path

p = Path("app/native-ble-gatt-proof.tsx")
t = p.read_text(errors="ignore")

if "MM_GATT_FIXED_SHARED_BUTTON_V10D" in t:
    print("SKIP: v10d already present.")
    raise SystemExit

helper = r'''
  // MM_GATT_FIXED_SHARED_BUTTON_V10D_HELPER
  const useFixedSharedPacketV10D = useCallback(() => {
    const fixed = "MMN-FIXED9-CHAIN01";
    setSharedPacketIdInput(fixed);
    setPacketId(fixed);

    const msg = `${LOG_TAG} FIXED_SHARED_V10D_APPLIED packetId=${fixed} finalPassClaimed=false`;
    console.warn(msg);
    appendEvent(msg);
  }, []);
'''

t = t.replace("  const autoGuideSharedPacketV10B", helper + "\n  const autoGuideSharedPacketV10B", 1)

ui = r'''
          {/* MM_GATT_FIXED_SHARED_BUTTON_V10D_UI */}
          <Pressable style={styles.button} onPress={useFixedSharedPacketV10D}>
            <Text style={styles.buttonText}>Use Fixed Shared Packet ID</Text>
          </Pressable>
          <Text style={styles.mono}>MMN-FIXED9-CHAIN01</Text>
'''

anchor = "AUTO GUIDE v10c: Apply Shared Packet + Brown Trigger"
idx = t.find(anchor)
if idx > 0:
    insert_at = t.rfind("<Pressable", 0, idx)
    t = t[:insert_at] + ui + "\n" + t[insert_at:]
else:
    t = t.replace("{/* MM_GATT_AUTO_GUIDE_V10B_UI */}", ui + "\n{/* MM_GATT_AUTO_GUIDE_V10B_UI */}", 1)

p.write_text(t)
print("PASS: v10d fixed shared packet button inserted.")
PY

grep -n "FIXED_SHARED_V10D\|Use Fixed Shared Packet ID" "$SCREEN" || true

npx tsc --noEmit
npx expo export --platform android

echo "FINAL VERDICT: READY_FOR_EAS_BUILD_V10D_FIXED_SHARED_PACKET_BUTTON"
