#!/usr/bin/env bash
set -euo pipefail

SCREEN="app/native-ble-gatt-proof.tsx"
STAMP="$(date +%Y%m%d-%H%M%S)"
DOC_DIR="docs/native-ble-gatt"
ARCHIVE_DIR="archives/native-ble-gatt"
mkdir -p "$DOC_DIR" "$ARCHIVE_DIR"

cp "$SCREEN" "$ARCHIVE_DIR/native-ble-gatt-proof.tsx.before-v13-exam-controller-${STAMP}.bak"

python3 - <<'PY'
from pathlib import Path
import sys

p = Path("app/native-ble-gatt-proof.tsx")
t = p.read_text(errors="ignore")

if "MM_GATT_V13_EXAM_CONTROLLER" in t:
    print("SKIP: v13 already present.")
    sys.exit(0)

helper = r'''
  // MM_GATT_V13_EXAM_CONTROLLER_HELPER
  const runV13ThreeDeviceExamController = useCallback(async () => {
    const typed = sharedPacketIdInput.trim().toUpperCase();
    const examPacketId = typed || packetId;
    const valid = /^MMN-[A-Z0-9]+-[A-Z0-9]+$/.test(examPacketId);

    if (!valid) {
      const bad = `${LOG_TAG} V13_EXAM_INVALID_PACKET packetId=${examPacketId} finalPassClaimed=false`;
      console.warn(bad);
      appendEvent(bad);
      return;
    }

    setPacketId(examPacketId);

    const locked = `${LOG_TAG} V13_EXAM_PACKET_LOCKED packetId=${examPacketId} requiredDevices=A06,S10,A16 requiredSamePacket=true finalPassClaimed=false`;
    console.warn(locked);
    appendEvent(locked);

    const role = `${LOG_TAG} V13_EXAM_ROLE_CONFIRM_REQUIRED packetId=${examPacketId} roles=A06_SENDER,S10_RELAY,A16_RECEIVER finalPassClaimed=false`;
    console.warn(role);
    appendEvent(role);

    await new Promise((resolve) => setTimeout(resolve, 300));

    const trigger = `${LOG_TAG} V13_EXAM_NATIVE_TRIGGER_START packetId=${examPacketId} finalPassClaimed=false`;
    console.warn(trigger);
    appendEvent(trigger);

    const result = await callMauriMeshNativeGattTriggerV8(examPacketId);

    const triggered = `${LOG_TAG} V13_EXAM_NATIVE_TRIGGER_DONE packetId=${examPacketId} result=${JSON.stringify(result)} finalPassClaimed=false`;
    console.warn(triggered);
    appendEvent(triggered);

    const vault = `${LOG_TAG} V13_EXAM_READY_FOR_VAULT_SAVE packetId=${examPacketId} finalPassClaimed=false`;
    console.warn(vault);
    appendEvent(vault);

    const complete = `${LOG_TAG} V13_EXAM_READY_FOR_MAC_VERDICT packetId=${examPacketId} requiredMarkers=GATT_TRIGGER_NATIVE_METHOD_ENTERED,GATT_PACKET_PAYLOAD,GATT_CLIENT_WRITE_ATTEMPT,GATT_SERVER_WRITE_RECEIVED finalPassClaimed=false`;
    console.warn(complete);
    appendEvent(complete);
  }, [sharedPacketIdInput, packetId]);
'''

anchor = "  const triggerNativeGattPacketPayload"
if anchor not in t:
    print("FAIL: triggerNativeGattPacketPayload anchor missing.")
    sys.exit(1)

t = t.replace(anchor, helper + "\n" + anchor, 1)

ui = r'''
        {/* MM_GATT_V13_EXAM_CONTROLLER_UI */}
        <View style={styles.card}>
          <Text style={styles.h2}>v13 One-Tap 3-Device Native GATT Exam</Text>
          <Text style={styles.body}>
            Type the same packetId on A06, S10, and A16. Recommended: MMN-FIXED9-CHAIN01.
            Then press this button on each phone. The Mac verifier decides PASS only if the same packetId has native GATT markers on all three devices.
          </Text>
          <Pressable style={styles.button} onPress={runV13ThreeDeviceExamController}>
            <Text style={styles.buttonText}>START 3-DEVICE NATIVE GATT EXAM</Text>
          </Pressable>
          <Text style={styles.mono}>V13_EXAM_PACKET_LOCKED → V13_EXAM_READY_FOR_MAC_VERDICT</Text>
        </View>
'''

ui_anchor = "{/* MM_GATT_LIT_BUTTON_ORDER_V12_UI */}"
if ui_anchor in t:
    t = t.replace(ui_anchor, ui + "\n" + ui_anchor, 1)
else:
    idx = t.find("Shared Packet ID Chain Mode v9")
    if idx < 0:
        print("FAIL: UI anchor missing.")
        sys.exit(1)
    insert_at = t.rfind("<View", 0, idx)
    t = t[:insert_at] + ui + "\n" + t[insert_at:]

p.write_text(t)
print("PASS: v13 exam controller inserted.")
PY

grep -n "MM_GATT_V13_EXAM_CONTROLLER\|V13_EXAM_" "$SCREEN" || true

npx tsc --noEmit
npx expo export --platform android

REPORT="$DOC_DIR/NATIVE_GATT_V13_EXAM_CONTROLLER_${STAMP}.md"
cat > "$REPORT" <<EOF2
# Native GATT v13 One-Tap 3-Device Exam Controller

Adds:
- START 3-DEVICE NATIVE GATT EXAM

Markers:
- V13_EXAM_PACKET_LOCKED
- V13_EXAM_ROLE_CONFIRM_REQUIRED
- V13_EXAM_NATIVE_TRIGGER_START
- V13_EXAM_NATIVE_TRIGGER_DONE
- V13_EXAM_READY_FOR_VAULT_SAVE
- V13_EXAM_READY_FOR_MAC_VERDICT

Truth boundary:
PASS only if Mac logcat confirms the same packetId has native GATT markers on A06, S10, and A16.
EOF2

cp "$REPORT" "$DOC_DIR/NATIVE_GATT_V13_EXAM_CONTROLLER_LATEST.md"

echo "FINAL VERDICT: READY_FOR_EAS_BUILD_V13_EXAM_CONTROLLER"
