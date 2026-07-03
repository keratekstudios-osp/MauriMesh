#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH NATIVE GATT JS RESOLVER v8b FIX"
echo "============================================================"
echo "Purpose:"
echo "- Remove bad v8 resolver inserted inside import block"
echo "- Reinsert resolver after all imports"
echo "- Patch old NativeModules[moduleName] lookup to use resolver"
echo "- Run TypeScript + Expo export gate"
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
SCREEN="app/native-ble-gatt-proof.tsx"
DOC_DIR="$ROOT/docs/native-ble-gatt"
ARCHIVE_DIR="$ROOT/archives/native-ble-gatt"
mkdir -p "$DOC_DIR" "$ARCHIVE_DIR"

REPORT="$DOC_DIR/NATIVE_GATT_JS_RESOLVER_V8B_FIX_${STAMP}.md"
LATEST="$DOC_DIR/NATIVE_GATT_JS_RESOLVER_V8B_FIX_LATEST.md"

if [ ! -f "$SCREEN" ]; then
  echo "FAIL: missing $SCREEN"
  exit 1
fi

cp "$SCREEN" "$ARCHIVE_DIR/native-ble-gatt-proof.tsx.before-v8b-fix-${STAMP}.bak"

echo "[1/7] Current file head before repair:"
sed -n '1,80p' "$SCREEN"

echo ""
echo "[2/7] Repairing resolver placement..."
python3 - <<'PY'
from pathlib import Path
import re
import sys

p = Path("app/native-ble-gatt-proof.tsx")
t = p.read_text(errors="ignore")

# Remove any previous v8 block wherever it landed.
t = re.sub(
    r'\n?// MM_GATT_JS_RESOLVER_V8_BEGIN[\s\S]*?// MM_GATT_JS_RESOLVER_V8_END\n?',
    '\n',
    t,
    flags=re.S,
)

# Also remove v8b block if rerun.
t = re.sub(
    r'\n?// MM_GATT_JS_RESOLVER_V8B_BEGIN[\s\S]*?// MM_GATT_JS_RESOLVER_V8B_END\n?',
    '\n',
    t,
    flags=re.S,
)

# Ensure react-native import contains NativeModules.
# Handles multi-line import { ... } from 'react-native';
def ensure_native_modules_import(src: str) -> str:
    m = re.search(r'import\s*\{([\s\S]*?)\}\s*from\s*[\'"]react-native[\'"]\s*;', src)
    if not m:
        return src

    body = m.group(1)
    if "NativeModules" in body:
        return src

    new_body = body.rstrip()
    if new_body.strip():
        new_body = new_body + ",\n  NativeModules,\n"
    else:
        new_body = "\n  NativeModules,\n"

    return src[:m.start(1)] + new_body + src[m.end(1):]

t = ensure_native_modules_import(t)

resolver = r'''
// MM_GATT_JS_RESOLVER_V8B_BEGIN
const getMauriMeshNativeGattModuleV8B = () => {
  const rn: any = require('react-native');
  const nativeModules: any = rn.NativeModules || NativeModules || {};

  let turboRegistry: any = rn.TurboModuleRegistry || null;
  try {
    turboRegistry = turboRegistry || require('react-native/Libraries/TurboModule/TurboModuleRegistry');
  } catch (err: any) {
    console.log(
      `MAURIMESH_NATIVE_BLE_GATT | GATT_JS_RESOLVER_V8B_TURBO_REGISTRY_REQUIRE_ERROR | error=${String(err?.message || err)} | finalPassClaimed=false`
    );
  }

  const nativeKeys = Object.keys(nativeModules || {});
  console.log(
    `MAURIMESH_NATIVE_BLE_GATT | GATT_JS_RESOLVER_V8B_KEYS | NativeModules=${nativeKeys.join(',')} | finalPassClaimed=false`
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
        `MAURIMESH_NATIVE_BLE_GATT | GATT_JS_RESOLVER_V8B_NATIVE_MODULE_FOUND | name=${name} | methods=${methodKeys.join(',')} | finalPassClaimed=false`
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
            `MAURIMESH_NATIVE_BLE_GATT | GATT_JS_RESOLVER_V8B_TURBO_MODULE_FOUND | name=${name} | methods=${methodKeys.join(',')} | finalPassClaimed=false`
          );
          return { name, mod, source: 'TurboModuleRegistry.get' };
        }
      } catch (err: any) {
        console.log(
          `MAURIMESH_NATIVE_BLE_GATT | GATT_JS_RESOLVER_V8B_TURBO_GET_ERROR | name=${name} | error=${String(err?.message || err)} | finalPassClaimed=false`
        );
      }
    }
  }

  const turboProxy = (globalThis as any).__turboModuleProxy;
  if (typeof turboProxy === 'function') {
    for (const name of candidateNames) {
      try {
        const mod = turboProxy(name);
        if (mod) {
          const methodKeys = Object.keys(mod || {});
          console.log(
            `MAURIMESH_NATIVE_BLE_GATT | GATT_JS_RESOLVER_V8B_GLOBAL_TURBO_PROXY_FOUND | name=${name} | methods=${methodKeys.join(',')} | finalPassClaimed=false`
          );
          return { name, mod, source: 'globalThis.__turboModuleProxy' };
        }
      } catch (err: any) {
        console.log(
          `MAURIMESH_NATIVE_BLE_GATT | GATT_JS_RESOLVER_V8B_GLOBAL_TURBO_PROXY_ERROR | name=${name} | error=${String(err?.message || err)} | finalPassClaimed=false`
        );
      }
    }
  }

  console.log(
    `MAURIMESH_NATIVE_BLE_GATT | GATT_JS_RESOLVER_V8B_MODULE_NOT_FOUND | candidates=${candidateNames.join(',')} | NativeModules=${nativeKeys.join(',')} | finalPassClaimed=false`
  );

  return null;
};

const callMauriMeshNativeGattTriggerV8B = async (packetId: string) => {
  const resolved = getMauriMeshNativeGattModuleV8B();

  if (!resolved?.mod) {
    throw new Error(
      'Native GATT trigger unavailable after v8b resolver. NativeModules=' +
        Object.keys((NativeModules as any) || {}).join(',')
    );
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
        `MAURIMESH_NATIVE_BLE_GATT | GATT_JS_RESOLVER_V8B_CALLING_METHOD | module=${resolved.name} | source=${resolved.source} | method=${methodName} | packetId=${packetId} | finalPassClaimed=false`
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
// MM_GATT_JS_RESOLVER_V8B_END
'''

# Find end of top import section safely.
lines = t.splitlines()
last_import_end = -1
in_import = False

for i, line in enumerate(lines):
    stripped = line.strip()

    if not in_import and stripped.startswith("import "):
        in_import = True

    if in_import and stripped.endswith(";"):
        last_import_end = i
        in_import = False
        continue

    # After import section begins, stop at first real non-import code after all imports.
    if last_import_end >= 0 and not in_import:
        if stripped and not stripped.startswith("//") and not stripped.startswith("/*") and not stripped.startswith("*") and not stripped.startswith("import "):
            break

if last_import_end < 0:
    print("FAIL: Could not find completed import block.")
    sys.exit(1)

lines.insert(last_import_end + 1, resolver)
t = "\n".join(lines)

# Patch old direct NativeModules lookup to fallback through v8b resolver.
t = t.replace(
    "NativeModules[moduleName]",
    "(getMauriMeshNativeGattModuleV8B()?.mod || (NativeModules as any)[moduleName])"
)

# Patch common direct calls if they exist.
direct_patterns = [
    r'NativeModules\.MauriMeshNativeBlePacket\.triggerGattPacketPayloadProof\s*\(\s*([^)]+?)\s*\)',
    r'MauriMeshNativeBlePacket\.triggerGattPacketPayloadProof\s*\(\s*([^)]+?)\s*\)',
    r'nativeModule\.triggerGattPacketPayloadProof\s*\(\s*([^)]+?)\s*\)',
]

for pat in direct_patterns:
    t = re.sub(pat, r'callMauriMeshNativeGattTriggerV8B(\1)', t, flags=re.S)

p.write_text(t)
print("PASS: v8b resolver placed after imports and lookup fallback patched.")
PY

echo ""
echo "[3/7] File head after repair:"
sed -n '1,130p' "$SCREEN"

echo ""
echo "[4/7] Verify v8b markers and old lookup patch..."
grep -n "MM_GATT_JS_RESOLVER_V8B_BEGIN\|GATT_JS_RESOLVER_V8B_KEYS\|GATT_JS_RESOLVER_V8B_NATIVE_MODULE_FOUND\|GATT_JS_RESOLVER_V8B_TURBO_MODULE_FOUND\|GATT_JS_RESOLVER_V8B_GLOBAL_TURBO_PROXY_FOUND\|GATT_JS_RESOLVER_V8B_CALLING_METHOD\|getMauriMeshNativeGattModuleV8B\|callMauriMeshNativeGattTriggerV8B" "$SCREEN" || true

echo ""
echo "[5/7] TypeScript gate..."
npx tsc --noEmit

echo ""
echo "[6/7] Expo Android export gate..."
npx expo export --platform android

echo ""
echo "[7/7] Write report..."
cat > "$REPORT" <<MD
# MauriMesh Native GATT JS Resolver v8b Fix

Timestamp: $STAMP

## Result

v8b fixed resolver placement and patched JS lookup fallback.

## Why

v8 failed because the resolver was inserted inside the multi-line import block:

\`\`\`
SyntaxError: Unexpected keyword 'const'
\`\`\`

## v8b markers

\`\`\`
GATT_JS_RESOLVER_V8B_KEYS
GATT_JS_RESOLVER_V8B_NATIVE_MODULE_FOUND
GATT_JS_RESOLVER_V8B_TURBO_MODULE_FOUND
GATT_JS_RESOLVER_V8B_GLOBAL_TURBO_PROXY_FOUND
GATT_JS_RESOLVER_V8B_CALLING_METHOD
GATT_JS_RESOLVER_V8B_MODULE_NOT_FOUND
\`\`\`

## Truth

Final Native BLE/GATT packet-bound PASS remains NOT CLAIMED.

Next runtime target:

\`\`\`
GATT_JS_RESOLVER_V8B_CALLING_METHOD
GATT_TRIGGER_NATIVE_METHOD_ENTERED
\`\`\`
MD

cp "$REPORT" "$LATEST"

echo ""
echo "============================================================"
echo "MAURIMESH NATIVE GATT JS RESOLVER v8b FIX COMPLETE"
echo "============================================================"
echo "Report: $REPORT"
echo "Latest: $LATEST"
echo "============================================================"
echo "FINAL VERDICT: READY_FOR_EAS_BUILD_V8B_JS_RESOLVER"
echo "Next:"
echo "1. EAS build."
echo "2. Install on A16."
echo "3. Run fail-fast runtime capture."
echo "4. Look for GATT_JS_RESOLVER_V8B_CALLING_METHOD and GATT_TRIGGER_NATIVE_METHOD_ENTERED."
echo "============================================================"
