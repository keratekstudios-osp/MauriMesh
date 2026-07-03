#!/usr/bin/env bash
set -euo pipefail

TARGET="app/native-ble-gatt-proof.tsx"
BACKUP="$TARGET.backup-unified-guided-$(date +%Y%m%d-%H%M%S)"

if [ ! -f "$TARGET" ]; then
  echo "ERROR: $TARGET not found"
  exit 1
fi

cp "$TARGET" "$BACKUP"

python3 <<'PY'
from pathlib import Path

p = Path("app/native-ble-gatt-proof.tsx")
s = p.read_text()

insert = r'''
/**
 * Unified Guided Truth Gate additions:
 * - role-locked operator mode
 * - one active bright device
 * - inactive devices dim
 * - one valid next button
 * - 4-device-ready stage plan
 * - no final PASS claim from UI alone
 */
type GuidedRole = "PHONE_A" | "PHONE_B" | "PHONE_C" | "PHONE_D";

type GuidedStage = {
  id: number;
  role: GuidedRole;
  label: string;
  marker: string;
  color: string;
};

const GUIDED_4_DEVICE_STAGES: GuidedStage[] = [
  { id: 1, role: "PHONE_A", label: "Use Shared Packet ID", marker: "SHARED_PACKET_V9_APPLIED", color: "#00E676" },
  { id: 2, role: "PHONE_A", label: "Start BLE Callback Capture", marker: "BUTTON_PRESS_START_CAPTURE", color: "#00E676" },
  { id: 3, role: "PHONE_B", label: "Start Raw Packet Receiver", marker: "BUTTON_PRESS_START_REAL_GATT_RECEIVER", color: "#28A8FF" },
  { id: 4, role: "PHONE_A", label: "Send Real GATT Packet", marker: "GATT_CLIENT_WRITE_ATTEMPT", color: "#00E676" },
  { id: 5, role: "PHONE_A", label: "Trigger Native GATT Payload", marker: "GATT_PACKET_PAYLOAD", color: "#FFC107" },
  { id: 6, role: "PHONE_C", label: "Confirm RX / ACK Source", marker: "GATT_SERVER_WRITE_RECEIVED", color: "#B76CFF" },
  { id: 7, role: "PHONE_C", label: "Relay to PHONE_D Top Hop", marker: "NATIVE_RELAY_A16_TO_PHONE_D", color: "#B76CFF" },
  { id: 8, role: "PHONE_D", label: "PHONE_D Receive Top Hop", marker: "NATIVE_RX_PHONE_D_FROM_A16", color: "#FF7A18" },
  { id: 9, role: "PHONE_D", label: "PHONE_D ACK Back", marker: "NATIVE_ACK_PHONE_D_TO_A16", color: "#FF7A18" },
  { id: 10, role: "PHONE_C", label: "ACK Relay to PHONE_B", marker: "NATIVE_ACK_RELAY_A16_TO_S10", color: "#B76CFF" },
  { id: 11, role: "PHONE_B", label: "ACK Relay to PHONE_A", marker: "NATIVE_ACK_RELAY_S10_TO_A06", color: "#28A8FF" },
  { id: 12, role: "PHONE_A", label: "Save Attempt Into Vault", marker: "BUTTON_PRESS_SAVE_ATTEMPT", color: "#00E676" },
];

function guidedRoleText(role: GuidedRole) {
  if (role === "PHONE_A") return "PHONE_A / A06 SENDER";
  if (role === "PHONE_B") return "PHONE_B / S10 RELAY";
  if (role === "PHONE_C") return "PHONE_C / A16 RELAY + ACK";
  return "PHONE_D / TOP HOP";
}
'''

if "GUIDED_4_DEVICE_STAGES" not in s:
    # insert after imports
    idx = s.find("\n\n", s.find("import"))
    if idx != -1:
        s = s[:idx+2] + insert + "\n" + s[idx+2:]

# inject simple state after first useState block by adding near component body
if "guidedRole, setGuidedRole" not in s:
    marker = "export default function"
    pos = s.find(marker)
    brace = s.find("{", pos)
    s = s[:brace+1] + r'''

  const [guidedRole, setGuidedRole] = React.useState<GuidedRole>("PHONE_A");
  const [guidedStepIndex, setGuidedStepIndex] = React.useState(0);
  const guidedCurrent = GUIDED_4_DEVICE_STAGES[guidedStepIndex];
  const guidedComplete = guidedStepIndex >= GUIDED_4_DEVICE_STAGES.length;
  const guidedIsThisDeviceTurn =
    !!guidedCurrent && guidedCurrent.role === guidedRole;
  const guidedDimmed = !!guidedCurrent && !guidedIsThisDeviceTurn && !guidedComplete;

  function guidedAdvance(expectedMarker?: string) {
    if (!guidedCurrent || guidedComplete) return;

    if (!guidedIsThisDeviceTurn) {
      console.log(
        `MAURIMESH_GUIDED_TRUTH_GATE WRONG_DEVICE_BLOCKED required=${guidedCurrent.role} actual=${guidedRole} marker=${guidedCurrent.marker} finalPassClaimed=false`
      );
      return;
    }

    console.log(
      `MAURIMESH_GUIDED_TRUTH_GATE GUIDED_STEP_ACCEPTED step=${guidedCurrent.id} role=${guidedRole} marker=${expectedMarker || guidedCurrent.marker} finalPassClaimed=false`
    );

    setGuidedStepIndex((n) =>
      Math.min(n + 1, GUIDED_4_DEVICE_STAGES.length)
    );
  }

''' + s[brace+1:]

# add UI panel after first ScrollView opening if possible
panel = r'''
      <View style={[guidedStyles.card, guidedDimmed && guidedStyles.dimmed]}>
        <Text style={guidedStyles.kicker}>UNIFIED AUTO GUIDE</Text>
        <Text style={guidedStyles.title}>
          {guidedComplete
            ? "GUIDED SEQUENCE COMPLETE"
            : guidedIsThisDeviceTurn
              ? `${guidedRole} TURN — PRESS THE LIT BUTTON`
              : `STANDBY — WAIT FOR ${guidedCurrent?.role}`}
        </Text>

        <Text style={guidedStyles.body}>
          Only the active device is bright. Other phones stay dim and locked.
          UI completion does not claim native packet-bound PASS.
        </Text>

        <View style={guidedStyles.roleRow}>
          {(["PHONE_A", "PHONE_B", "PHONE_C", "PHONE_D"] as GuidedRole[]).map((r) => (
            <Pressable
              key={r}
              onPress={() => setGuidedRole(r)}
              style={[
                guidedStyles.roleButton,
                guidedRole === r && guidedStyles.roleButtonActive,
              ]}
            >
              <Text style={guidedStyles.roleText}>{r}</Text>
            </Pressable>
          ))}
        </View>

        <Text style={guidedStyles.currentRole}>{guidedRoleText(guidedRole)}</Text>

        {!guidedComplete && guidedCurrent ? (
          <Pressable
            onPress={() => guidedAdvance(guidedCurrent.marker)}
            style={[
              guidedStyles.litButton,
              {
                borderColor: guidedCurrent.color,
                backgroundColor: guidedIsThisDeviceTurn
                  ? guidedCurrent.color
                  : "rgba(255,255,255,0.05)",
              },
            ]}
          >
            <Text style={guidedStyles.litButtonText}>
              {guidedIsThisDeviceTurn
                ? `☀ ${guidedCurrent.label}`
                : `🔒 LOCKED — ${guidedCurrent.role} ONLY`}
            </Text>
            <Text style={guidedStyles.marker}>{guidedCurrent.marker}</Text>
          </Pressable>
        ) : (
          <Text style={guidedStyles.passReady}>READY FOR LOGCAT VERIFICATION</Text>
        )}

        <Text style={guidedStyles.progress}>
          Step {Math.min(guidedStepIndex + 1, GUIDED_4_DEVICE_STAGES.length)} / {GUIDED_4_DEVICE_STAGES.length}
        </Text>
      </View>
'''

if "UNIFIED AUTO GUIDE" not in s:
    open_scroll = s.find("<ScrollView")
    if open_scroll != -1:
        close_tag = s.find(">", open_scroll)
        s = s[:close_tag+1] + "\n" + panel + s[close_tag+1:]

styles = r'''
const guidedStyles = StyleSheet.create({
  card: {
    borderWidth: 2,
    borderColor: "rgba(0,230,118,0.55)",
    backgroundColor: "rgba(0,18,10,0.94)",
    borderRadius: 20,
    padding: 14,
    marginBottom: 14,
    gap: 10,
  },
  dimmed: {
    opacity: 0.22,
  },
  kicker: {
    color: "#00E676",
    fontWeight: "900",
    letterSpacing: 1.4,
    fontSize: 12,
  },
  title: {
    color: "#FFFFFF",
    fontWeight: "900",
    fontSize: 20,
    lineHeight: 26,
  },
  body: {
    color: "rgba(255,255,255,0.72)",
    lineHeight: 20,
  },
  roleRow: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 8,
  },
  roleButton: {
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.18)",
    backgroundColor: "rgba(255,255,255,0.06)",
    borderRadius: 12,
    paddingVertical: 9,
    paddingHorizontal: 10,
  },
  roleButtonActive: {
    borderColor: "#00E676",
    backgroundColor: "rgba(0,230,118,0.18)",
  },
  roleText: {
    color: "#FFFFFF",
    fontWeight: "900",
    fontSize: 12,
  },
  currentRole: {
    color: "#38BDF8",
    fontWeight: "900",
  },
  litButton: {
    borderWidth: 2,
    borderRadius: 16,
    padding: 14,
    alignItems: "center",
  },
  litButtonText: {
    color: "#FFFFFF",
    fontWeight: "900",
    fontSize: 16,
    textAlign: "center",
  },
  marker: {
    color: "rgba(255,255,255,0.75)",
    fontSize: 11,
    marginTop: 5,
    textAlign: "center",
  },
  progress: {
    color: "#FFFFFF",
    fontWeight: "900",
  },
  passReady: {
    color: "#00E676",
    fontWeight: "900",
    fontSize: 16,
  },
});
'''

if "const guidedStyles = StyleSheet.create" not in s:
    s += "\n\n" + styles

p.write_text(s)
print("PATCHED_UNIFIED_GUIDED_TRUTH_GATE_V1")
PY

npx tsc --noEmit
npx expo export --platform android

echo "READY_FOR_APK_BUILD_UNIFIED_GUIDED_TRUTH_GATE_V1"
