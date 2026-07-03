#!/usr/bin/env bash
set -euo pipefail

FILE="android/app/src/main/java/com/maurimesh/messenger/MauriMeshNativeBlePacketModule.java"

echo "TARGET=$FILE"

if [ ! -f "$FILE" ]; then
  echo "ERROR: file not found: $FILE"
  exit 1
fi

TS="$(date +%Y%m%d-%H%M%S)"
cp "$FILE" "$FILE.bak-$TS"
echo "BACKUP=$FILE.bak-$TS"

python3 <<'PY'
from pathlib import Path

p = Path("android/app/src/main/java/com/maurimesh/messenger/MauriMeshNativeBlePacketModule.java")
s = p.read_text()

broken = '''"GATT_TRIGGER_NATIVE_METHOD_RESULT | packetId=" + cleanPacketId + " | helperResult=" + helperResult + " | finalPassClaimed=false"'''

fixed = '''"GATT_TRIGGER_NATIVE_METHOD_RESULT | packetId=" + cleanPacketId + " | helperResult=" + helperResult + " | finalPassClaimed=false"
    );'''

if broken in s and fixed not in s:
    s = s.replace(broken, fixed)

# Remove accidental duplicate standalone close after the fixed log block.
s = s.replace('''    );
    );
''', '''    );
''')

p.write_text(s)
print("JAVA_SYNTAX_PATCH_APPLIED")
PY

echo "Showing repaired section:"
nl -ba "$FILE" | sed -n '85,112p'

echo "Running checks..."
npx tsc --noEmit
npx expo export --platform android

echo "READY_FOR_EAS_REBUILD"
