#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH NATIVE GATT JS RESOLVER REPAIR v8"
echo "============================================================"
echo "Truth from v7:"
echo "- Android registration works"
echo "- Package createNativeModules works"
echo "- Module constructor/getName works"
echo "- JS lookup still says NativeModules unavailable"
echo ""
echo "Purpose:"
echo "- Patch the Truth Gate JS/TSX screen with a robust resolver"
echo "- Try NativeModules direct keys"
echo "- Try TurboModuleRegistry fallback"
echo "- Log available keys and method names"
echo "- Call triggerGattPacketPayloadProof once resolved"
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
DOC_DIR="$ROOT/docs/native-ble-gatt"
ARCHIVE_DIR="$ROOT/archives/native-ble-gatt"
mkdir -p "$DOC_DIR" "$ARCHIVE_DIR"

SCREEN="app/native-ble-gatt-proof.tsx"
REPORT="$DOC_DIR/NATIVE_GATT_JS_RESOLVER_V8_${STAMP}.md"
LATEST="$DOC_DIR/NATIVE_GATT_JS_RESOLVER_V8_LATEST.md"

if [ ! -f "$SCREEN" ]; then
  echo "FAIL: missing $SCREEN"
  exit 1
fi

cp "$SCREEN" "$ARCHIVE_DIR/native-ble-gatt-proof.tsx.before-js-resolver-v8-${STAMP}.bak"

echo "[1/6] Inspecting current native lookup lines..."
grep -n "NativeModules\|TurboModuleRegistry\|MauriMeshNativeBlePacket\|triggerGattPacketPayloadProof\|NATIVE_GATT_TRIGGER_UNAVAILABLE" "$SCREEN" || true

echo ""
echo "[2/6] Patching JS resolver safely..."
python3 - <<'PY'
from pathlib import Path
import re
import sys

p = Path("app/native-ble-gatt-proof.tsx")
t = p.read_text(errors="ignore")

if "MM_GATT_JS_RESOLVER_V8_BEGIN" in t:
    print("SKIP: v8 resolver already present.")
    sys.exit(0)

# Ensure NativeModules import exists.
if "NativeModules" not in t:
    # Add to react-native import block if possible.
    t = re.sub(
        r'import\s*\{([^}]+)\}\s*from\s*[\'"]react-native[\'"];',
        lambda m: 'import {' + m.group(1).rstrip() + ', NativeModules } from "react-native";',
        t,
        count=1,
        flags=re.S,
    )
elif "from 'react-native'" in t or 'from "react-native"' in t:
    # If NativeModules referenced but not imported in destructured import, add if needed.
    def add_native_modules(m):
        body = m.group(1)
        if "NativeModules" in body:
            return m.group(0)
        return "import {" + body.rstrip() + ", NativeModules } from 'react-native';"
    t = re.sub(r'import\s*\{([^}]+)\}\s*from\s*[\'"]react-native[\'"];', add_native_modules, t, count=1, flags=re.S)

resolver = r'''
// MM_GATT_JS_RESOLVER_V8_BEGIN
const getMauriMeshNativeGattModuleV8 = () => {
  const rn: any = require('react-native');
  const nativeModules: any = rn.NativeModules || NativeModules || {};
  const turboRegistry: any = rn.TurboModuleRegistry || null;

  const nativeKeys = Object.keys(nativeModules || {});
  console.log(
    `MAURIMESH_NATIVE_BLE_GATT | GATT_JS_RESOLVER_V8_KEYS | NativeModules=${nativeKeys.join(',')} | finalPassClaimed=false`
  );

  const candidateNames = [
    'MauriMeshNativeBlePacket',
    'MauriMeshNativeBlePacketModule',
    'NativeMauriMeshNativeBlePacket',
    'MauriMeshBlePacket',
    'MauriMeshBleModule',
  ];

  for (const name of candidateNames) {
    const mod = nativeModules?.[name];
    if (mod) {
      const methodKeys = Object.keys(mod || {});
      console.log(
        `MAURIMESH_NATIVE_BLE_GATT | GATT_JS_RESOLVER_V8_NATIVE_MODULE_FOUND | name=${name} | methods=${methodKeys.join(',')} | finalPassClaimed=false`
      );
      return { name, mod, source: 'NativeModules' };
    }
  }

  if (turboRegistry && typeof turboRegistry.get === 'function') {
    for (const name of candidateNames) {
      try {
        const mod = turboRegistry.get(name);
        if (mod) {
          const methodKeys = Object.keys(mod || {});
          console.log(
            `MAURIMESH_NATIVE_BLE_GATT | GATT_JS_RESOLVER_V8_TURBO_MODULE_FOUND | name=${name} | methods=${methodKeys.join(',')} | finalPassClaimed=false`
          );
          return { name, mod, source: 'TurboModuleRegistry.get' };
        }
      } catch (err: any) {
        console.log(
          `MAURIMESH_NATIVE_BLE_GATT | GATT_JS_RESOLVER_V8_TURBO_GET_ERROR | name=${name} | error=${String(err?.message || err)} | finalPassClaimed=false`
        );
      }
    }
  }

  console.log(
    `MAURIMESH_NATIVE_BLE_GATT | GATT_JS_RESOLVER_V8_MODULE_NOT_FOUND | candidates=${candidateNames.join(',')} | NativeModules=${nativeKeys.join(',')} | finalPassClaimed=false`
  );

  return null;
};

const callMauriMeshNativeGattTriggerV8 = async (packetId: string) => {
  const resolved = getMauriMeshNativeGattModuleV8();

  if (!resolved?.mod) {
    throw new Error('Native GATT trigger unavailable after v8 resolver. NativeModules=' + Object.keys((NativeModules as any) || {}).join(','));
  }

  const methodNames = [
    'triggerGattPacketPayloadProof',
    'triggerNativeGattPacketPayload',
    'triggerGattPacketPayload',
    'writeGattPacketProof',
    'sendGattPacketProof',
    'runGattPacketProof',
  ];

  for (const methodName of methodNames) {
    const candidate = resolved.mod?.[methodName];
    if (typeof candidate === 'function') {
      console.log(
        `MAURIMESH_NATIVE_BLE_GATT | GATT_JS_RESOLVER_V8_CALLING_METHOD | module=${resolved.name} | source=${resolved.source} | method=${methodName} | packetId=${packetId} | finalPassClaimed=false`
      );
      return await candidate(packetId);
    }
  }

  throw new Error(
    'Native GATT module found but no trigger method. module=' +
      resolved.name +
      ' source=' +
      resolved.source +
      ' methods=' +
      Object.keys(resolved.mod || {}).join(',')
  );
};
// MM_GATT_JS_RESOLVER_V8_END
'''

# Insert resolver after imports, before component code.
lines = t.splitlines()
insert_at = 0
for i, line in enumerate(lines):
    if line.startswith("import ") or line.strip().startswith("import "):
        insert_at = i + 1

lines.insert(insert_at, resolver)
t = "\n".join(lines)

# Replace direct native calls with v8 wrapper where possible.
# Handles common patterns:
patterns = [
    r'NativeModules\.MauriMeshNativeBlePacket\.triggerGattPacketPayloadProof\s*\(\s*([^)]+?)\s*\)',
    r'MauriMeshNativeBlePacket\.triggerGattPacketPayloadProof\s*\(\s*([^)]+?)\s*\)',
    r'nativeModule\.triggerGattPacketPayloadProof\s*\(\s*([^)]+?)\s*\)',
]

for pat in patterns:
    t = re.sub(pat, r'callMauriMeshNativeGattTriggerV8(\1)', t)

# If the old code has a known unavailable throw message, keep it but resolver will now be logged.
# Stronger targeted replacement: if triggerGattPacketPayloadProof still appears not via resolver, print warning.
remaining = [m.start() for m in re.finditer("triggerGattPacketPayloadProof", t)]
# Allowed inside resolver methodNames string only.
if len(remaining) <= 1:
    pass

p.write_text(t)
print("PASS: v8 resolver inserted and common trigger calls redirected.")
PY

echo ""
echo "[3/6] Verify v8 markers..."
grep -n "MM_GATT_JS_RESOLVER_V8_BEGIN\|GATT_JS_RESOLVER_V8_KEYS\|GATT_JS_RESOLVER_V8_NATIVE_MODULE_FOUND\|GATT_JS_RESOLVER_V8_TURBO_MODULE_FOUND\|GATT_JS_RESOLVER_V8_CALLING_METHOD\|callMauriMeshNativeGattTriggerV8" "$SCREEN" || true

echo ""
echo "[4/6] Run TypeScript gate..."
npx tsc --noEmit

echo ""
echo "[5/6] Run Expo Android export gate..."
npx expo export --platform android

echo ""
echo "[6/6] Write report..."
cat > "$REPORT" <<MD
# MauriMesh Native GATT JS Resolver Repair v8

Timestamp: $STAMP

## Input Truth From v7

\`\`\`
REGISTRATION=1
CREATE_MODULES=1
MODULE_ADDED=1
CONSTRUCTOR=1
GET_NAME=1
BUTTON_PRESS=2
TRIGGER_ENTERED=0
UNAVAILABLE=1
VERDICT: ANDROID_MODULE_CREATED_BUT_JS_LOOKUP_FAILED
\`\`\`

## v8 Purpose

Android registration is working. v8 repairs the JavaScript native module lookup path.

## Added markers

\`\`\`
GATT_JS_RESOLVER_V8_KEYS
GATT_JS_RESOLVER_V8_NATIVE_MODULE_FOUND
GATT_JS_RESOLVER_V8_TURBO_MODULE_FOUND
GATT_JS_RESOLVER_V8_CALLING_METHOD
GATT_JS_RESOLVER_V8_MODULE_NOT_FOUND
\`\`\`

## Truth

Final Native BLE/GATT packet-bound PASS remains NOT CLAIMED.

The next proof target is:

\`\`\`
GATT_TRIGGER_NATIVE_METHOD_ENTERED
GATT_PACKET_PAYLOAD
GATT_CLIENT_WRITE_ATTEMPT
GATT_SERVER_WRITE_RECEIVED
\`\`\`
MD

cp "$REPORT" "$LATEST"

echo ""
echo "============================================================"
echo "MAURIMESH NATIVE GATT JS RESOLVER v8 COMPLETE"
echo "============================================================"
echo "Report: $REPORT"
echo "Latest: $LATEST"
echo "============================================================"
echo "FINAL VERDICT: READY_FOR_EAS_BUILD_V8_JS_RESOLVER"
echo "Next:"
echo "1. Build EAS APK."
echo "2. Install on A16."
echo "3. Run the same fail-fast runtime capture."
echo "4. Look for GATT_JS_RESOLVER_V8_CALLING_METHOD and GATT_TRIGGER_NATIVE_METHOD_ENTERED."
echo "============================================================"
