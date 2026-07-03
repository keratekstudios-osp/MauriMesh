#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH NATIVE GATT SHARED PACKET ID MODE v9"
echo "============================================================"
echo "Purpose:"
echo "- Add shared packetId input to Native BLE/GATT Truth Gate"
echo "- Allow S10/A16 to use A06 packetId"
echo "- Preserve v8b resolver"
echo "- Keep truth boundary honest"
echo "============================================================"

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
SCREEN="app/native-ble-gatt-proof.tsx"
DOC_DIR="$ROOT/docs/native-ble-gatt"
ARCHIVE_DIR="$ROOT/archives/native-ble-gatt"
mkdir -p "$DOC_DIR" "$ARCHIVE_DIR"

REPORT="$DOC_DIR/NATIVE_GATT_SHARED_PACKET_V9_${STAMP}.md"
LATEST="$DOC_DIR/NATIVE_GATT_SHARED_PACKET_V9_LATEST.md"

if [ ! -f "$SCREEN" ]; then
  echo "FAIL: missing $SCREEN"
  exit 1
fi

cp "$SCREEN" "$ARCHIVE_DIR/native-ble-gatt-proof.tsx.before-shared-packet-v9-${STAMP}.bak"

echo "[1/5] Patch screen with shared packetId controls..."
python3 - <<'PY'
from pathlib import Path
import re
import sys

p = Path("app/native-ble-gatt-proof.tsx")
t = p.read_text(errors="ignore")

if "MM_GATT_SHARED_PACKET_V9" in t:
    print("SKIP: v9 already present.")
    sys.exit(0)

# Ensure TextInput imported
m = re.search(r'import\s*\{([\s\S]*?)\}\s*from\s*[\'"]react-native[\'"]\s*;', t)
if m and "TextInput" not in m.group(1):
    body = m.group(1).rstrip() + ",\n  TextInput,\n"
    t = t[:m.start(1)] + body + t[m.end(1):]

# Add state after packetId state if possible
state_inserted = False
patterns = [
    r'(const\s*\[\s*packetId\s*,\s*setPacketId\s*\]\s*=\s*useState[^\n]+;\s*)',
    r'(const\s*\[\s*packetId\s*,\s*setPacketId\s*\]\s*=\s*React\.useState[^\n]+;\s*)',
]
for pat in patterns:
    if re.search(pat, t):
        t = re.sub(
            pat,
            r'\1\n  // MM_GATT_SHARED_PACKET_V9_STATE\n  const [sharedPacketIdInput, setSharedPacketIdInput] = useState("");\n',
            t,
            count=1,
        )
        state_inserted = True
        break

if not state_inserted:
    print("FAIL: Could not find packetId useState line.")
    sys.exit(1)

helper = r'''
  // MM_GATT_SHARED_PACKET_V9_HELPER
  const applySharedPacketIdV9 = useCallback(() => {
    const clean = sharedPacketIdInput.trim().toUpperCase();
    const valid = /^MMN-[A-Z0-9]+-[A-Z0-9]+$/.test(clean);

    if (!valid) {
      const msg = `${LOG_TAG} SHARED_PACKET_V9_INVALID input=${sharedPacketIdInput}`;
      console.warn(msg);
      appendEvent(msg);
      return;
    }

    setPacketId(clean);
    const msg = `${LOG_TAG} SHARED_PACKET_V9_APPLIED packetId=${clean} finalPassClaimed=false`;
    console.warn(msg);
    appendEvent(msg);
  }, [sharedPacketIdInput]);
'''

# Insert helper before trigger function
if "const triggerNativeGattPacketPayload" in t:
    t = t.replace("  const triggerNativeGattPacketPayload", helper + "\n  const triggerNativeGattPacketPayload", 1)
else:
    print("FAIL: could not find triggerNativeGattPacketPayload function.")
    sys.exit(1)

ui = r'''
        {/* MM_GATT_SHARED_PACKET_V9_UI */}
        <View style={styles.card}>
          <Text style={styles.h2}>Shared Packet ID Chain Mode v9</Text>
          <Text style={styles.body}>
            Use this for A06 → S10 → A16 same-packet native GATT proof.
            Generate/reset packet on A06, then type the same packetId on S10 and A16.
          </Text>
          <TextInput
            style={styles.input}
            value={sharedPacketIdInput}
            onChangeText={setSharedPacketIdInput}
            placeholder="MMN-XXXXXX-XXXXXX"
            autoCapitalize="characters"
            autoCorrect={false}
          />
          <Pressable style={styles.button} onPress={applySharedPacketIdV9}>
            <Text style={styles.buttonText}>Use Shared Packet ID</Text>
          </Pressable>
          <Text style={styles.mono}>SHARED_PACKET_V9_APPLIED</Text>
        </View>
'''

# Insert UI before trigger button title if possible
if 'Trigger Native GATT Packet Payload' in t:
    # Put before first Pressable/card containing trigger title; safest insert before title text occurrence.
    idx = t.find('Trigger Native GATT Packet Payload')
    insert_at = t.rfind('<', 0, idx)
    if insert_at > 0:
        t = t[:insert_at] + ui + "\n" + t[insert_at:]
    else:
        t += "\n" + ui
else:
    t += "\n" + ui

# Ensure styles.input exists
if "input:" not in t:
    t = re.sub(
        r'(const\s+styles\s*=\s*StyleSheet\.create\s*\(\s*\{)',
        r'''\1
  input: {
    borderWidth: 1,
    borderColor: "#4b5563",
    borderRadius: 8,
    padding: 10,
    marginTop: 8,
    marginBottom: 8,
    color: "#ffffff",
  },''',
        t,
        count=1,
    )

p.write_text(t)
print("PASS: v9 shared packetId mode patched.")
PY

echo ""
echo "[2/5] Verify v9 markers..."
grep -n "MM_GATT_SHARED_PACKET_V9\|SHARED_PACKET_V9_APPLIED\|Shared Packet ID Chain Mode" "$SCREEN" || true

echo ""
echo "[3/5] TypeScript gate..."
npx tsc --noEmit

echo ""
echo "[4/5] Expo Android export gate..."
npx expo export --platform android

echo ""
echo "[5/5] Write report..."
cat > "$REPORT" <<MD
# MauriMesh Native GATT Shared Packet ID Mode v9

Timestamp: $STAMP

## Purpose

Adds Shared Packet ID Chain Mode to Native BLE/GATT Truth Gate.

## Use

1. A06 presses Reset Packet and generates packetId.
2. S10 enters the same packetId and presses Use Shared Packet ID.
3. A16 enters the same packetId and presses Use Shared Packet ID.
4. All three press Trigger Native GATT Packet Payload.
5. Capture logs across all three devices.

## Expected marker

\`\`\`
SHARED_PACKET_V9_APPLIED packetId=<same>
\`\`\`

## Truth Boundary

This does not itself prove relay. It enables same-packet native GATT marker capture across A06, S10, and A16.
MD

cp "$REPORT" "$LATEST"

echo ""
echo "============================================================"
echo "NATIVE GATT SHARED PACKET ID MODE v9 COMPLETE"
echo "============================================================"
echo "Report: $REPORT"
echo "Latest: $LATEST"
echo "FINAL VERDICT: READY_FOR_EAS_BUILD_V9_SHARED_PACKET_MODE"
echo "============================================================"
