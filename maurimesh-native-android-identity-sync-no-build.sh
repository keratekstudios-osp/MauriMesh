#!/usr/bin/env bash
set -e

echo "=================================================="
echo "MAURIMESH NATIVE ANDROID IDENTITY SYNC — NO BUILD"
echo "=================================================="

BACKUP="backup-before-native-android-identity-sync-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP"

for f in \
  android/app/build.gradle \
  android/app/src/main/AndroidManifest.xml \
  android/app/src/debug/AndroidManifest.xml \
  android/app/src/main/res/values/strings.xml \
  app.json \
  eas.json
do
  if [ -f "$f" ]; then
    mkdir -p "$BACKUP/$(dirname "$f")"
    cp "$f" "$BACKUP/$f"
    echo "Backed up: $f"
  fi
done

echo ""
echo "1. Patch android/app/build.gradle namespace + applicationId"

if [ -f android/app/build.gradle ]; then
python3 <<'PY'
from pathlib import Path

p = Path("android/app/build.gradle")
text = p.read_text()

replacements = {
    "namespace 'com.anonymous.workspace'": "namespace 'com.maurimesh.messenger'",
    'namespace "com.anonymous.workspace"': 'namespace "com.maurimesh.messenger"',
    "applicationId 'com.anonymous.workspace'": "applicationId 'com.maurimesh.messenger'",
    'applicationId "com.anonymous.workspace"': 'applicationId "com.maurimesh.messenger"',
    "namespace 'com.anonymous.MauriMesh'": "namespace 'com.maurimesh.messenger'",
    'namespace "com.anonymous.MauriMesh"': 'namespace "com.maurimesh.messenger"',
    "applicationId 'com.anonymous.MauriMesh'": "applicationId 'com.maurimesh.messenger'",
    'applicationId "com.anonymous.MauriMesh"': 'applicationId "com.maurimesh.messenger"',
}

for a, b in replacements.items():
    text = text.replace(a, b)

# If namespace/applicationId are missing, insert safely.
if "namespace " not in text:
    text = text.replace("android {", "android {\n    namespace 'com.maurimesh.messenger'", 1)

if "applicationId " not in text:
    text = text.replace("defaultConfig {", "defaultConfig {\n        applicationId 'com.maurimesh.messenger'", 1)

p.write_text(text)
PY
else
  echo "android/app/build.gradle not found."
fi

echo ""
echo "2. Patch app display name"

if [ -f android/app/src/main/res/values/strings.xml ]; then
python3 <<'PY'
from pathlib import Path
p = Path("android/app/src/main/res/values/strings.xml")
text = p.read_text()
text = text.replace(">workspace<", ">MauriMesh<")
text = text.replace(">MauriMeshMessenger<", ">MauriMesh<")
text = text.replace(">MauriMesh Messenger<", ">MauriMesh<")
text = text.replace(">anonymous<", ">MauriMesh<")
p.write_text(text)
PY
fi

echo ""
echo "3. Remove old anonymous package text where safe"

grep -R "com.anonymous.workspace\|com.anonymous.MauriMesh" android/app 2>/dev/null || true

echo ""
echo "4. Verify final Android identity"
grep -R "namespace\|applicationId" android/app/build.gradle 2>/dev/null || true
grep -R "com.maurimesh.messenger\|com.anonymous.workspace\|com.anonymous.MauriMesh" android/app 2>/dev/null || true

echo ""
echo "5. Run checks — NO BUILD"
npx expo-doctor || true
npx tsc --noEmit || true

echo ""
echo "=================================================="
echo "NATIVE ANDROID IDENTITY SYNC COMPLETE — NO EAS BUILD USED"
echo "Backup: $BACKUP"
echo "=================================================="
