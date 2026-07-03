#!/usr/bin/env bash
set -euo pipefail

TARGET="app/native-ble-gatt-proof.tsx"
BACKUP="$TARGET.backup-polish-v2-$(date +%Y%m%d-%H%M%S)"

cp "$TARGET" "$BACKUP"

python3 <<'PY'
from pathlib import Path
p = Path("app/native-ble-gatt-proof.tsx")
s = p.read_text()

# Add Vibration import if missing
if "Vibration" not in s:
    s = s.replace("Pressable,", "Pressable,\n  Vibration,")

# Add vibration when guided step accepted
old = """console.log(
      `MAURIMESH_GUIDED_TRUTH_GATE GUIDED_STEP_ACCEPTED step=${guidedCurrent.id} role=${guidedRole} marker=${expectedMarker || guidedCurrent.marker} finalPassClaimed=false`
    );"""

new = """console.log(
      `MAURIMESH_GUIDED_TRUTH_GATE GUIDED_STEP_ACCEPTED step=${guidedCurrent.id} role=${guidedRole} marker=${expectedMarker || guidedCurrent.marker} finalPassClaimed=false`
    );

    try {
      Vibration.vibrate(120);
    } catch (_) {}"""

if old in s and "Vibration.vibrate(120)" not in s:
    s = s.replace(old, new)

# Improve lit button glow / pulse-like visibility
s = s.replace(
"""litButton: {
    borderWidth: 2,
    borderRadius: 16,
    padding: 14,
    alignItems: "center",
  },""",
"""litButton: {
    borderWidth: 2,
    borderRadius: 16,
    padding: 14,
    alignItems: "center",
    shadowColor: "#00E676",
    shadowOffset: { width: 0, height: 0 },
    shadowOpacity: 0.95,
    shadowRadius: 18,
    elevation: 10,
  },"""
)

# Add clear truth line if not present
if "ACTIVE DEVICE BRIGHT" not in s:
    s = s.replace(
"""Only the active device is bright. Other phones stay dim and locked.
          UI completion does not claim native packet-bound PASS.""",
"""ACTIVE DEVICE BRIGHT: only this phone can press the lit button.
          Other phones stay dim and locked.
          UI completion does not claim native packet-bound PASS."""
    )

p.write_text(s)
print("PATCHED_GUIDED_TRUTH_GATE_POLISH_V2")
PY

npx tsc --noEmit
npx expo export --platform android

echo "READY_FOR_APK_BUILD_GUIDED_TRUTH_GATE_POLISH_V2"
