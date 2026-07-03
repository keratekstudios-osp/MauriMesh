#!/usr/bin/env bash
set -euo pipefail

SCREEN="app/native-ble-gatt-proof.tsx"
STAMP="$(date +%Y%m%d-%H%M%S)"
DOC_DIR="docs/native-ble-gatt"
ARCHIVE_DIR="archives/native-ble-gatt"
mkdir -p "$DOC_DIR" "$ARCHIVE_DIR"

cp "$SCREEN" "$ARCHIVE_DIR/native-ble-gatt-proof.tsx.before-v11-exam-${STAMP}.bak"

echo "============================================================"
echo "MAURIMESH NATIVE GATT EXAM MODE v11"
echo "============================================================"

python3 - <<'PY'
from pathlib import Path
import sys

p = Path("app/native-ble-gatt-proof.tsx")
t = p.read_text(errors="ignore")

if "MM_GATT_EXAM_MODE_V11" in t:
    print("SKIP: v11 already present.")
    sys.exit(0)

# Ensure Clipboard import fallback through expo-clipboard style require only, no top-level dependency risk.
helper = r'''
  // MM_GATT_EXAM_MODE_V11_HELPERS
  const copyPacketIdForOtherDevicesV11 = useCallback(async () => {
    const chosen = (sharedPacketIdInput.trim().toUpperCase() || packetId).trim();
    try {
      const Clipboard = require("expo-clipboard");
      if (Clipboard?.setStringAsync) {
        await Clipboard.setStringAsync(chosen);
      }
      const msg = `${LOG_TAG} EXAM_V11_PACKET_ID_COPIED packetId=${chosen} finalPassClaimed=false`;
      console.warn(msg);
      appendEvent(msg);
    } catch (err: any) {
      const msg = `${LOG_TAG} EXAM_V11_PACKET_ID_COPY_FALLBACK packetId=${chosen} error=${String(err?.message || err)} finalPassClaimed=false`;
      console.warn(msg);
      appendEvent(msg);
    }
  }, [sharedPacketIdInput, packetId]);

  const startNativeGattExamV11 = useCallback(() => {
    const chosen = (sharedPacketIdInput.trim().toUpperCase() || packetId).trim();
    setPacketId(chosen);
    setSharedPacketIdInput(chosen);

    const lines = [
      `${LOG_TAG} EXAM_V11_STARTED packetId=${chosen} role=UNKNOWN finalPassClaimed=false`,
      `${LOG_TAG} EXAM_V11_STAGE_1_APPLY_SHARED_PACKET packetId=${chosen}`,
      `${LOG_TAG} EXAM_V11_STAGE_2_COPY_PACKET_ID_TO_OTHER_DEVICES packetId=${chosen}`,
      `${LOG_TAG} EXAM_V11_STAGE_3_PRESS_AUTO_GUIDE_ON_A06 packetId=${chosen}`,
      `${LOG_TAG} EXAM_V11_STAGE_4_PRESS_AUTO_GUIDE_ON_S10 packetId=${chosen}`,
      `${LOG_TAG} EXAM_V11_STAGE_5_PRESS_AUTO_GUIDE_ON_A16 packetId=${chosen}`,
      `${LOG_TAG} EXAM_V11_STAGE_6_SAVE_VAULT_ALL_THREE packetId=${chosen}`,
      `${LOG_TAG} EXAM_V11_TRUTH_RULE samePacketRequires=A06,S10,A16 markers=GATT_TRIGGER_NATIVE_METHOD_ENTERED,GATT_PACKET_PAYLOAD,GATT_CLIENT_WRITE_ATTEMPT,GATT_SERVER_WRITE_RECEIVED finalPassClaimed=false`,
    ];

    for (const line of lines) {
      console.warn(line);
      appendEvent(line);
    }
  }, [sharedPacketIdInput, packetId]);

  const autoExamApplyCopyTriggerV11 = useCallback(async () => {
    const chosen = (sharedPacketIdInput.trim().toUpperCase() || packetId).trim();
    const valid = /^MMN-[A-Z0-9]+-[A-Z0-9]+$/.test(chosen);

    if (!valid) {
      const msg = `${LOG_TAG} EXAM_V11_INVALID_PACKET packetId=${chosen} finalPassClaimed=false`;
      console.warn(msg);
      appendEvent(msg);
      return;
    }

    setPacketId(chosen);
    setSharedPacketIdInput(chosen);

    const start = `${LOG_TAG} EXAM_V11_AUTO_GUIDE_STARTED packetId=${chosen} finalPassClaimed=false`;
    console.warn(start);
    appendEvent(start);

    await copyPacketIdForOtherDevicesV11();

    const applied = `${LOG_TAG} SHARED_PACKET_V9_APPLIED packetId=${chosen} source=EXAM_V11_AUTO_GUIDE finalPassClaimed=false`;
    console.warn(applied);
    appendEvent(applied);

    try {
      const result = await callMauriMeshNativeGattTriggerV8(chosen);
      const done = `${LOG_TAG} EXAM_V11_AUTO_GUIDE_TRIGGER_DONE packetId=${chosen} result=${JSON.stringify(result)} finalPassClaimed=false`;
      console.warn(done);
      appendEvent(done);
    } catch (err: any) {
      const fail = `${LOG_TAG} EXAM_V11_AUTO_GUIDE_TRIGGER_ERROR packetId=${chosen} error=${String(err?.message || err)} finalPassClaimed=false`;
      console.warn(fail);
      appendEvent(fail);
    }
  }, [sharedPacketIdInput, packetId, copyPacketIdForOtherDevicesV11]);
'''

anchor = "  const triggerNativeGattPacketPayload = useCallback"
if anchor not in t:
    print("FAIL: trigger anchor missing")
    sys.exit(1)

t = t.replace(anchor, helper + "\n" + anchor, 1)

ui = r'''
        {/* MM_GATT_EXAM_MODE_V11_UI */}
        <View style={styles.card}>
          <Text style={styles.h2}>Native GATT Exam Mode v11</Text>
          <Text style={styles.body}>
            Three-device exam flow: A06 generates or uses shared packetId, copy it to S10 and A16, then press Auto Exam on all three phones.
            PASS is only true when the same packetId appears in native GATT markers on A06, S10, and A16.
          </Text>

          <Pressable style={styles.button} onPress={startNativeGattExamV11}>
            <Text style={styles.buttonText}>Start Native GATT Exam</Text>
          </Pressable>

          <Pressable style={styles.button} onPress={copyPacketIdForOtherDevicesV11}>
            <Text style={styles.buttonText}>Copy Packet ID For Other Devices</Text>
          </Pressable>

          <Pressable style={styles.button} onPress={autoExamApplyCopyTriggerV11}>
            <Text style={styles.buttonText}>AUTO EXAM: Apply + Copy + Trigger</Text>
          </Pressable>

          <Text style={styles.mono}>EXAM_V11_STARTED → EXAM_V11_AUTO_GUIDE_TRIGGER_DONE</Text>
        </View>
'''

# Insert before existing auto guide UI or before trigger button
insert_anchor = "{/* MM_GATT_AUTO_GUIDE_V10B_UI */}"
if insert_anchor in t:
    t = t.replace(insert_anchor, ui + "\n" + insert_anchor, 1)
else:
    idx = t.find("Trigger Native GATT Packet Payload")
    if idx < 0:
        print("FAIL: UI anchor missing")
        sys.exit(1)
    insert_at = t.rfind("<", 0, idx)
    t = t[:insert_at] + ui + "\n" + t[insert_at:]

p.write_text(t)
print("PASS: v11 exam mode inserted.")
PY

echo ""
echo "[1] Wiring markers:"
grep -n "EXAM_V11\|Copy Packet ID For Other Devices\|AUTO EXAM\|Start Native GATT Exam" "$SCREEN" || true

echo ""
echo "[2] Button wiring audit:"
grep -n "onPress=.*copyPacketIdForOtherDevicesV11\|onPress=.*startNativeGattExamV11\|onPress=.*autoExamApplyCopyTriggerV11\|onPress=.*autoGuideSharedPacketV10B\|onPress=.*triggerNativeGattPacketPayload" "$SCREEN" || true

echo ""
echo "[3] Native trigger resolver audit:"
grep -n "callMauriMeshNativeGattTriggerV8\|triggerGattPacketPayloadProof\|GATT_TRIGGER_NATIVE_METHOD_ENTERED" "$SCREEN" || true

echo ""
echo "[4] TypeScript gate:"
npx tsc --noEmit

echo ""
echo "[5] Expo export gate:"
npx expo export --platform android

REPORT="$DOC_DIR/NATIVE_GATT_EXAM_MODE_V11_${STAMP}.md"
cat > "$REPORT" <<EOF2
# MauriMesh Native GATT Exam Mode v11

Timestamp: $STAMP

## Added

- Start Native GATT Exam
- Copy Packet ID For Other Devices
- AUTO EXAM: Apply + Copy + Trigger
- Exam markers:
  - EXAM_V11_STARTED
  - EXAM_V11_PACKET_ID_COPIED
  - EXAM_V11_AUTO_GUIDE_STARTED
  - EXAM_V11_AUTO_GUIDE_TRIGGER_DONE
  - EXAM_V11_TRUTH_RULE

## Button Wiring

Audited onPress wiring for:
- copyPacketIdForOtherDevicesV11
- startNativeGattExamV11
- autoExamApplyCopyTriggerV11
- autoGuideSharedPacketV10B
- triggerNativeGattPacketPayload

## Truth Rule

PASS only if the same packetId appears on A06, S10, and A16 with:

- GATT_TRIGGER_NATIVE_METHOD_ENTERED
- GATT_PACKET_PAYLOAD
- GATT_CLIENT_WRITE_ATTEMPT
- GATT_SERVER_WRITE_RECEIVED
- UNAVAILABLE=0

## Verdict

READY_FOR_EAS_BUILD_V11_NATIVE_GATT_EXAM_MODE
EOF2

cp "$REPORT" "$DOC_DIR/NATIVE_GATT_EXAM_MODE_V11_LATEST.md"

echo ""
echo "============================================================"
echo "FINAL VERDICT: READY_FOR_EAS_BUILD_V11_NATIVE_GATT_EXAM_MODE"
echo "Report: $REPORT"
echo "============================================================"
