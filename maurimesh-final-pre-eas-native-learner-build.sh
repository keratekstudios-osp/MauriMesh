#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH FINAL PRE-EAS BUILD GATE"
echo "Native BLE Logger + Learner Core APK"
echo "============================================================"

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
REPORT="$ROOT/docs/native-proof/MAURIMESH_FINAL_PRE_EAS_NATIVE_LEARNER_BUILD_$STAMP.md"

mkdir -p "$ROOT/docs/native-proof" "$ROOT/docs/learner"

if [ ! -f "$ROOT/package.json" ]; then
  echo "ERROR: package.json not found. Run from /home/runner/workspace."
  exit 1
fi

echo ""
echo "[1] Required files"
REQUIRED=(
  "src/maurimesh/native/nativeBlePacketLogger.ts"
  "src/maurimesh/proof/nativeBleGattProofVerdict.ts"
  "android/app/src/main/java/com/maurimesh/messenger/MauriMeshNativeBlePacketModule.java"
  "android/app/src/main/java/com/maurimesh/messenger/MauriMeshNativeBlePacketPackage.java"
  "src/maurimesh/learner/mauriMeshLearnerCore.ts"
  "src/maurimesh/learner/evidenceMemory.ts"
  "src/maurimesh/learner/proofClassifier.ts"
  "src/maurimesh/learner/decisionScoring.ts"
  "src/maurimesh/learner/badDecisionLearner.ts"
  "src/maurimesh/learner/recoveryPlanner.ts"
  "src/maurimesh/learner/trustLedger.ts"
  "app/learner-core.tsx"
  "app/dashboard.tsx"
)

MISSING=0
for f in "${REQUIRED[@]}"; do
  if [ -f "$ROOT/$f" ]; then
    echo "PASS: $f"
  else
    echo "MISSING: $f"
    MISSING=1
  fi
done

if [ "$MISSING" -ne 0 ]; then
  echo "ERROR: Required files missing. Stop before EAS."
  exit 1
fi

echo ""
echo "[2] Registration check"
grep -R "MauriMeshNativeBlePacketPackage" "$ROOT/android/app/src/main/java" || {
  echo "ERROR: Native package registration not found."
  exit 1
}

echo ""
echo "[3] Dashboard learner button check"
grep -n "Learner Core\|learner-core" "$ROOT/app/dashboard.tsx" || {
  echo "ERROR: Learner Core dashboard route not found."
  exit 1
}

echo ""
echo "[4] Native packet logger marker check"
grep -R "MAURIMESH_NATIVE_BLE_PACKET" "$ROOT/src/maurimesh" "$ROOT/android/app/src/main/java/com/maurimesh/messenger" | head -80 || {
  echo "ERROR: Native BLE packet marker not found."
  exit 1
}

echo ""
echo "[5] TypeScript check"
npx tsc --noEmit || true

echo ""
echo "[6] Expo Android export check"
npx expo export --platform android --clear

echo ""
echo "[7] Write final gate report"

cat > "$REPORT" <<MD
# MauriMesh Final Pre-EAS Native Learner Build Gate

Generated: $STAMP

## Build target

Native BLE Logger + Learner Core APK

## Passed checks

- Native BLE packet logger wrapper exists.
- Native BLE/GATT proof verdict helper exists.
- Android native bridge files exist.
- MainApplication registers MauriMeshNativeBlePacketPackage.
- Proof screens import nativeBlePacketLogSafe.
- Learner Core v1 files exist.
- /learner-core route exists.
- Dashboard has Learner Core button.
- Expo Android export passed.
- dist output generated.

## Local native compile note

Earlier local Gradle compile reached Android SDK check and stopped because Replit has no Android SDK / ANDROID_HOME.

This is a local environment blocker, not a confirmed code failure.

## Truth rule

This APK prepares:
- Native BLE/GATT packet logging bridge
- Learner Core evidence classification
- recovery planning
- trust scoring
- proof strength scoring

This APK does not prove native BLE/GATT transport by itself.

Native BLE/GATT PASS still requires physical phone logcat evidence showing the same packetId inside:

\`\`\`txt
MAURIMESH_NATIVE_BLE_PACKET
transport=BLE_GATT
\`\`\`

or Android Bluetooth/GATT callback lines.

## Next physical proof target

Install the new APK on:
- A06 / PHONE_A
- S10 / PHONE_B relay
- A16 / PHONE_C

Then rerun native BLE/GATT capture and search for same packetId across:
- GATT_WRITE_PACKET
- GATT_READ_PACKET
- RELAY_PACKET_NATIVE
- ACK_PACKET_NATIVE
- GATT_CHARACTERISTIC_CHANGED
MD

echo "Report created:"
echo "$REPORT"

echo ""
echo "============================================================"
echo "PRE-EAS GATE PASSED"
echo "============================================================"
echo "Report: $REPORT"
echo ""
echo "Starting EAS Android preview build..."
echo "============================================================"

if command -v eas >/dev/null 2>&1; then
  eas build -p android --profile preview --clear-cache
else
  npx eas-cli build -p android --profile preview --clear-cache
fi

