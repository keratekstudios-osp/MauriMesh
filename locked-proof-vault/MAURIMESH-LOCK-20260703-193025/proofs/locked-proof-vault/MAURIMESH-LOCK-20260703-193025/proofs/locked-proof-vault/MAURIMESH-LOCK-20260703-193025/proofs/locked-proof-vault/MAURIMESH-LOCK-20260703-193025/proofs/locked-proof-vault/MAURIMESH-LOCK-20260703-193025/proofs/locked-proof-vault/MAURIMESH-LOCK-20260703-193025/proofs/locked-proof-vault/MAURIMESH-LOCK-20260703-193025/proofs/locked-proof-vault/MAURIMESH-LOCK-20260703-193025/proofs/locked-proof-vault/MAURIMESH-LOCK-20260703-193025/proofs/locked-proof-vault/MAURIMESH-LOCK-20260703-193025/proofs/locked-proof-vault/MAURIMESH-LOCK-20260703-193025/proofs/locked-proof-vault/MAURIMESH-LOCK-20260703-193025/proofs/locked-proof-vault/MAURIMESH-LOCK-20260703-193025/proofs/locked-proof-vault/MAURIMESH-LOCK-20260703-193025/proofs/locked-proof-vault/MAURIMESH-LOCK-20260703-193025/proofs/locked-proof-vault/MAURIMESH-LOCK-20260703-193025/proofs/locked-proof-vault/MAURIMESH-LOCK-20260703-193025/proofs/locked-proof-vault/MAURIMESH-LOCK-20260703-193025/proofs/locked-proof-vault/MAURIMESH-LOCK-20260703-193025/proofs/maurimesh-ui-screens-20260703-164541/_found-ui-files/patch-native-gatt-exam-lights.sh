#!/usr/bin/env bash
set -euo pipefail

TARGET="app/native-ble-gatt-proof.tsx"
BACKUP="$TARGET.backup-exam-lights-$(date +%Y%m%d-%H%M%S)"

cp "$TARGET" "$BACKUP"

python3 <<'PY'
from pathlib import Path

p = Path("app/native-ble-gatt-proof.tsx")
s = p.read_text()

insert = r'''
const EXAM_LIGHTS = [
  { key: "START_CAPTURE", label: "Start Capture", marker: "BUTTON_PRESS_START_CAPTURE", tone: "blue" },
  { key: "SHARED_PACKET", label: "Shared Packet", marker: "SHARED_PACKET_V9_APPLIED", tone: "green" },
  { key: "NATIVE_TRIGGER", label: "Native Trigger", marker: "BUTTON_PRESS_NATIVE_GATT_TRIGGER", tone: "blue" },
  { key: "NATIVE_METHOD_ENTERED", label: "Native Method Entered", marker: "nativeMethodEntered=true", tone: "green" },
  { key: "GATT_PAYLOAD", label: "GATT Payload", marker: "GATT_PACKET_PAYLOAD", tone: "green" },
  { key: "CLIENT_WRITE", label: "Client Write", marker: "GATT_CLIENT_WRITE_ATTEMPT", tone: "green" },
  { key: "SERVER_RECEIVED", label: "Server Received", marker: "GATT_SERVER_WRITE_RECEIVED", tone: "green" },
  { key: "VAULT_SAVED", label: "Vault Saved", marker: "VAULT_SAVE_ATTEMPT saved=true", tone: "green" },
];

function hasMarker(events: string[], marker: string) {
  return events.some((line) => line.includes(marker));
}

function hasSamePacketMarker(events: string[], packetId: string, marker: string) {
  return events.some((line) => line.includes(packetId) && line.includes(marker));
}

function examLightColor(passed: boolean, tone: string) {
  if (!passed) return "#2b2b2b";
  if (tone === "blue") return "#38BDF8";
  if (tone === "gold") return "#F59E0B";
  return "#22C55E";
}
'''

if "const EXAM_LIGHTS =" not in s:
    marker = "export default function"
    s = s.replace(marker, insert + "\n" + marker)

panel = r'''
      <View style={styles.examPanel}>
        <Text style={styles.examTitle}>Native BLE/GATT Exam Lights</Text>

        {EXAM_LIGHTS.map((light) => {
          const passed =
            light.key === "NATIVE_METHOD_ENTERED"
              ? liveEvents.some((e) => e.includes("nativeMethodEntered") && e.includes("true"))
              : light.key === "VAULT_SAVED"
                ? liveEvents.some((e) => e.includes("VAULT_SAVE_ATTEMPT") && e.includes("saved=true"))
                : hasSamePacketMarker(liveEvents, packetId, light.marker) || hasMarker(liveEvents, light.marker);

          return (
            <View key={light.key} style={styles.examLightRow}>
              <View
                style={[
                  styles.examLightDot,
                  { backgroundColor: examLightColor(passed, light.tone) },
                ]}
              />
              <View style={styles.examLightTextWrap}>
                <Text style={styles.examLightLabel}>{light.label}</Text>
                <Text style={styles.examLightMarker}>{light.marker}</Text>
                <Text style={passed ? styles.examPass : styles.examWaiting}>
                  {passed ? "PASS" : "WAITING"} · {packetId}
                </Text>
              </View>
            </View>
          );
        })}

        <View style={styles.examFinalBox}>
          <View
            style={[
              styles.examLightDot,
              {
                backgroundColor:
                  hasSamePacketMarker(liveEvents, packetId, "GATT_PACKET_PAYLOAD") &&
                  hasSamePacketMarker(liveEvents, packetId, "GATT_CLIENT_WRITE_ATTEMPT") &&
                  hasSamePacketMarker(liveEvents, packetId, "GATT_SERVER_WRITE_RECEIVED")
                    ? "#F59E0B"
                    : "#7F1D1D",
              },
            ]}
          />
          <View style={styles.examLightTextWrap}>
            <Text style={styles.examLightLabel}>FINAL PASS</Text>
            <Text style={styles.examLightMarker}>
              Requires same packetId GATT payload + client write + server received
            </Text>
            <Text style={styles.examWaiting}>
              {hasSamePacketMarker(liveEvents, packetId, "GATT_PACKET_PAYLOAD") &&
              hasSamePacketMarker(liveEvents, packetId, "GATT_CLIENT_WRITE_ATTEMPT") &&
              hasSamePacketMarker(liveEvents, packetId, "GATT_SERVER_WRITE_RECEIVED")
                ? "PASS_READY_TO_LOCK"
                : "NOT_READY: missing native GATT transport markers."}
            </Text>
          </View>
        </View>
      </View>
'''

if "Native BLE/GATT Exam Lights" not in s:
    anchor = "<Text style={styles.sectionTitle}>Expected logcat markers</Text>"
    s = s.replace(anchor, panel + "\n" + anchor)

style_insert = r'''
  examPanel: {
    borderWidth: 1,
    borderColor: "#14532D",
    backgroundColor: "rgba(0, 30, 18, 0.82)",
    borderRadius: 18,
    padding: 14,
    marginVertical: 12,
    gap: 10,
  },
  examTitle: {
    color: "#FFFFFF",
    fontSize: 18,
    fontWeight: "900",
    marginBottom: 4,
  },
  examLightRow: {
    flexDirection: "row",
    gap: 10,
    alignItems: "center",
    borderBottomWidth: 1,
    borderBottomColor: "rgba(255,255,255,0.08)",
    paddingBottom: 8,
  },
  examFinalBox: {
    flexDirection: "row",
    gap: 10,
    alignItems: "center",
    borderWidth: 1,
    borderColor: "#92400E",
    borderRadius: 14,
    padding: 10,
    backgroundColor: "rgba(120,53,15,0.18)",
  },
  examLightDot: {
    width: 22,
    height: 22,
    borderRadius: 11,
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.45)",
  },
  examLightTextWrap: {
    flex: 1,
  },
  examLightLabel: {
    color: "#FFFFFF",
    fontSize: 14,
    fontWeight: "900",
  },
  examLightMarker: {
    color: "#38BDF8",
    fontSize: 11,
    fontWeight: "700",
  },
  examPass: {
    color: "#22C55E",
    fontSize: 11,
    fontWeight: "900",
  },
  examWaiting: {
    color: "#F59E0B",
    fontSize: 11,
    fontWeight: "900",
  },
'''

if "examPanel:" not in s:
    s = s.replace("const styles = StyleSheet.create({", "const styles = StyleSheet.create({\n" + style_insert)

p.write_text(s)
PY

npx tsc --noEmit

echo "READY: Native BLE/GATT Exam Light Button System patched."
echo "Backup: $BACKUP"
