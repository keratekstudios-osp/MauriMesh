#!/usr/bin/env bash
set -euo pipefail

TARGET="app/native-ble-gatt-proof.tsx"
BACKUP="$TARGET.backup-proof-conductor-visible-v1-$(date +%Y%m%d-%H%M%S)"
cp "$TARGET" "$BACKUP"

python3 <<'PY'
from pathlib import Path

p = Path("app/native-ble-gatt-proof.tsx")
s = p.read_text()

if "PROOF CONDUCTOR ACTIVE" not in s:
    panel = r'''
      <View style={guidedStyles.card}>
        <Text style={guidedStyles.kicker}>PROOF CONDUCTOR ACTIVE</Text>
        <Text style={guidedStyles.title}>
          {guidedComplete
            ? "GUIDED CHAIN COMPLETE — VERIFY LOGCAT"
            : guidedIsThisDeviceTurn
              ? `${guidedRole} BRIGHT — PRESS THIS DEVICE`
              : `${guidedRole} DIM — WAIT FOR ${guidedCurrent?.role}`}
        </Text>

        <Text style={guidedStyles.body}>
          Conductor rule: one packet ID, one active device, one unlocked button, ordered relay + ACK path.
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
              guidedIsThisDeviceTurn
                ? { backgroundColor: guidedCurrent.color, borderColor: guidedCurrent.color }
                : guidedStyles.lockedButton,
            ]}
          >
            <Text style={guidedStyles.litButtonText}>
              {guidedIsThisDeviceTurn
                ? `☀ PRESS NOW: ${guidedCurrent.label}`
                : `🔒 LOCKED — ${guidedCurrent.role} ONLY`}
            </Text>
            <Text style={guidedStyles.marker}>{guidedCurrent.marker}</Text>
          </Pressable>
        ) : (
          <Text style={guidedStyles.passReady}>READY FOR MAC LOGCAT VERIFICATION</Text>
        )}

        <Text style={guidedStyles.progress}>
          Guided Step {Math.min(guidedStepIndex + 1, GUIDED_4_DEVICE_STAGES.length)} / {GUIDED_4_DEVICE_STAGES.length}
        </Text>
      </View>
'''

    # Insert immediately after first content container starts.
    target = "<ScrollView"
    i = s.find(target)
    if i == -1:
        raise SystemExit("ScrollView not found")
    j = s.find(">", i)
    s = s[:j+1] + "\n" + panel + s[j+1:]

# Ensure lockedButton style exists.
if "lockedButton:" not in s and "const guidedStyles = StyleSheet.create" in s:
    s = s.replace(
        "passReady: {",
        'lockedButton: {\n    backgroundColor: "rgba(255,255,255,0.05)",\n    borderColor: "rgba(255,255,255,0.14)",\n    opacity: 0.45,\n  },\n  passReady: {'
    )

p.write_text(s)
print("PATCHED_PROOF_CONDUCTOR_VISIBLE_V1")
PY

npx tsc --noEmit
npx expo export --platform android

echo "READY_FOR_APK_BUILD_PROOF_CONDUCTOR_VISIBLE_V1"
