#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH GRADLE PRE-FAIL FIX + BUILD GUARD"
echo "Fixes known Kotlin compile blockers before EAS/Gradle:"
echo "1. Missing maurimesh.background package reference"
echo "2. Broken MainApplication package registration"
echo "3. NODE_ENV not set warning"
echo "4. Runs TypeScript + Android source sanity checks"
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$ROOT/backup-before-gradle-prefail-fix-$STAMP"
REPORT="$ROOT/docs/maurimesh-gradle-prefail-fix-report-$STAMP.md"
LATEST="$ROOT/docs/maurimesh-gradle-prefail-fix-report-latest.md"

mkdir -p "$BACKUP" "$ROOT/docs"

if [ ! -f "$ROOT/package.json" ]; then
  echo "ERROR: package.json not found. Run from /home/runner/workspace."
  exit 1
fi

APP_KT="$ROOT/android/app/src/main/java/com/maurimesh/messenger/MainApplication.kt"
BG_DIR="$ROOT/android/app/src/main/java/com/maurimesh/messenger/maurimesh/background"
BG_PACKAGE="$BG_DIR/MauriMeshBackgroundRuntimePackage.kt"
TELEMETRY_PACKAGE="$ROOT/android/app/src/main/java/com/maurimesh/messenger/maurimesh/telemetry/MauriMeshHardwareTelemetryPackage.kt"

line() {
  echo "$1" | tee -a "$REPORT"
}

: > "$REPORT"

line "# MauriMesh Gradle Pre-Fail Fix Report"
line ""
line "Generated: $STAMP"
line ""

backup_file() {
  local file="$1"
  if [ -f "$file" ]; then
    local rel="${file#$ROOT/}"
    mkdir -p "$BACKUP/$(dirname "$rel")"
    cp "$file" "$BACKUP/$rel"
    line "- Backed up: $rel"
  fi
}

line "## Backup"
backup_file "$APP_KT"
backup_file "$ROOT/package.json"
backup_file "$ROOT/eas.json"
line ""

# ============================================================
# 1. MainApplication sanity
# ============================================================

line "## MainApplication.kt Sanity"

if [ ! -f "$APP_KT" ]; then
  line "- [ ] MISSING: $APP_KT"
  line ""
  line "Cannot continue because MainApplication.kt is missing."
  cp "$REPORT" "$LATEST"
  exit 1
fi

line "- [x] MainApplication.kt found"

# Remove missing background package import/add unless actual package file exists.
if grep -q "maurimesh.background" "$APP_KT"; then
  if [ ! -f "$BG_PACKAGE" ]; then
    line "- [!] Found maurimesh.background reference but package file is missing"
    line "- [FIX] Removing broken background import/register lines from MainApplication.kt"

    python3 <<'PY'
from pathlib import Path
p = Path("android/app/src/main/java/com/maurimesh/messenger/MainApplication.kt")
src = p.read_text()

remove_tokens = [
    "import com.maurimesh.messenger.maurimesh.background.MauriMeshBackgroundRuntimePackage\n",
    "packages.add(MauriMeshBackgroundRuntimePackage())\n",
    "add(MauriMeshBackgroundRuntimePackage())\n",
]

for token in remove_tokens:
    src = src.replace(token, "")

# Remove any one-line malformed package apply containing background.
lines = []
for line in src.splitlines():
    if "MauriMeshBackgroundRuntimePackage" in line:
        continue
    lines.append(line)
src = "\n".join(lines) + "\n"

p.write_text(src)
PY

    line "- [x] Broken background package reference removed"
  else
    line "- [x] Background package file exists, keeping background reference"
  fi
else
  line "- [x] No broken maurimesh.background reference found"
fi

# ============================================================
# 2. Repair getPackages block if malformed
# ============================================================

line ""
line "## ReactPackage Registration Shape"

if grep -q "PackageList(this).packages.apply" "$APP_KT"; then
  line "- [!] Found fragile PackageList(this).packages.apply pattern"
  line "- [FIX] Rewriting getPackages() to safe mutableList form"

  python3 <<'PY'
from pathlib import Path
import re

p = Path("android/app/src/main/java/com/maurimesh/messenger/MainApplication.kt")
src = p.read_text()

telemetry_exists = Path("android/app/src/main/java/com/maurimesh/messenger/maurimesh/telemetry/MauriMeshHardwareTelemetryPackage.kt").exists()
background_exists = Path("android/app/src/main/java/com/maurimesh/messenger/maurimesh/background/MauriMeshBackgroundRuntimePackage.kt").exists()

# Ensure imports match real files only.
src = re.sub(r'import com\.maurimesh\.messenger\.maurimesh\.telemetry\.MauriMeshHardwareTelemetryPackage\n', '', src)
src = re.sub(r'import com\.maurimesh\.messenger\.maurimesh\.background\.MauriMeshBackgroundRuntimePackage\n', '', src)

insert_imports = ""
if telemetry_exists:
    insert_imports += "import com.maurimesh.messenger.maurimesh.telemetry.MauriMeshHardwareTelemetryPackage\n"
if background_exists:
    insert_imports += "import com.maurimesh.messenger.maurimesh.background.MauriMeshBackgroundRuntimePackage\n"

# Put imports after package line.
src = re.sub(r'(package com\.maurimesh\.messenger\n+)', r'\1' + insert_imports, src)

adds = ""
if telemetry_exists:
    adds += "            packages.add(MauriMeshHardwareTelemetryPackage())\n"
if background_exists:
    adds += "            packages.add(MauriMeshBackgroundRuntimePackage())\n"

safe_block = f'''override fun getPackages(): List<ReactPackage> {{
            val packages = PackageList(this).packages.toMutableList()
{adds}            return packages
        }}'''

# Replace common getPackages blocks.
src = re.sub(
    r'override fun getPackages\(\): List<ReactPackage> \{[\s\S]*?return PackageList\(this\)\.packages[\s\S]*?\n\s*\}',
    safe_block,
    src,
    count=1,
)

src = re.sub(
    r'override fun getPackages\(\): List<ReactPackage> \{[\s\S]*?PackageList\(this\)\.packages\.apply \{[\s\S]*?\n\s*\}',
    safe_block,
    src,
    count=1,
)

# If still no getPackages, insert inside ReactNativeHost object after getUseDeveloperSupport if possible.
if "override fun getPackages(): List<ReactPackage>" not in src:
    marker = "override fun getUseDeveloperSupport(): Boolean = BuildConfig.DEBUG"
    if marker in src:
        src = src.replace(marker, marker + "\n\n        " + safe_block)

p.write_text(src)
PY

  line "- [x] getPackages() rewritten safely"
else
  line "- [x] No fragile PackageList apply pattern found"
fi

# ============================================================
# 3. Ensure telemetry import/register is only present when file exists
# ============================================================

line ""
line "## Native Telemetry Package Check"

if [ -f "$TELEMETRY_PACKAGE" ]; then
  line "- [x] Telemetry package file exists"

  if ! grep -q "MauriMeshHardwareTelemetryPackage" "$APP_KT"; then
    line "- [FIX] Telemetry package exists but MainApplication does not reference it. Adding safely."

    python3 <<'PY'
from pathlib import Path
import re

p = Path("android/app/src/main/java/com/maurimesh/messenger/MainApplication.kt")
src = p.read_text()

if "import com.maurimesh.messenger.maurimesh.telemetry.MauriMeshHardwareTelemetryPackage" not in src:
    src = re.sub(
        r'(package com\.maurimesh\.messenger\n+)',
        r'\1import com.maurimesh.messenger.maurimesh.telemetry.MauriMeshHardwareTelemetryPackage\n',
        src,
        count=1,
    )

if "packages.add(MauriMeshHardwareTelemetryPackage())" not in src:
    src = src.replace(
        "val packages = PackageList(this).packages.toMutableList()",
        "val packages = PackageList(this).packages.toMutableList()\n            packages.add(MauriMeshHardwareTelemetryPackage())",
    )

p.write_text(src)
PY

    line "- [x] Telemetry package reference added"
  else
    line "- [x] MainApplication references telemetry package"
  fi
else
  line "- [!] Telemetry package file not found. Removing telemetry reference to avoid Kotlin failure."

  python3 <<'PY'
from pathlib import Path
p = Path("android/app/src/main/java/com/maurimesh/messenger/MainApplication.kt")
src = p.read_text()
src = src.replace("import com.maurimesh.messenger.maurimesh.telemetry.MauriMeshHardwareTelemetryPackage\n", "")
src = src.replace("packages.add(MauriMeshHardwareTelemetryPackage())\n", "")
src = src.replace("add(MauriMeshHardwareTelemetryPackage())\n", "")
p.write_text(src)
PY

  line "- [x] Missing telemetry reference removed"
fi

# ============================================================
# 4. Set NODE_ENV for local Gradle/EAS shell builds
# ============================================================

line ""
line "## Build Environment"

export NODE_ENV=production
line "- [x] NODE_ENV=production set for this shell"

if [ -f "$ROOT/eas.json" ]; then
  if ! grep -q '"NODE_ENV"' "$ROOT/eas.json"; then
    line "- [FIX] Adding NODE_ENV=production to eas.json build profiles where possible"

    python3 <<'PY'
import json
from pathlib import Path

p = Path("eas.json")
try:
    data = json.loads(p.read_text())
except Exception:
    raise SystemExit(0)

build = data.setdefault("build", {})
for name, profile in build.items():
    if isinstance(profile, dict):
        env = profile.setdefault("env", {})
        if isinstance(env, dict):
            env.setdefault("NODE_ENV", "production")

p.write_text(json.dumps(data, indent=2) + "\n")
PY

    line "- [x] eas.json NODE_ENV guard applied"
  else
    line "- [x] eas.json already has NODE_ENV"
  fi
else
  line "- [!] eas.json not found, skipping EAS env patch"
fi

# ============================================================
# 5. Print MainApplication key lines
# ============================================================

line ""
line "## MainApplication.kt Key Lines"
line '```kotlin'
grep -nE "package |import .*MauriMesh|override fun getPackages|PackageList|packages.add|MauriMesh.*Package|return packages|background" "$APP_KT" | tee -a "$REPORT" || true
line '```'

# ============================================================
# 6. TypeScript gate
# ============================================================

line ""
line "## TypeScript Gate"

if npx tsc --noEmit >> "$REPORT" 2>&1; then
  line "- [x] TypeScript passed"
else
  line "- [ ] TypeScript failed"
  cp "$REPORT" "$LATEST"
  echo ""
  echo "TypeScript failed. Open report:"
  echo "cat $LATEST"
  exit 1
fi

# ============================================================
# 7. Optional local Gradle source sanity
# ============================================================

line ""
line "## Kotlin Source Sanity"

if grep -q "maurimesh.background" "$APP_KT" && [ ! -f "$BG_PACKAGE" ]; then
  line "- [ ] FAIL: MainApplication still references missing maurimesh.background"
  cp "$REPORT" "$LATEST"
  exit 1
else
  line "- [x] No missing maurimesh.background reference remains"
fi

if grep -q "MauriMeshBackgroundRuntimePackage" "$APP_KT" && [ ! -f "$BG_PACKAGE" ]; then
  line "- [ ] FAIL: MainApplication still registers missing background package"
  cp "$REPORT" "$LATEST"
  exit 1
else
  line "- [x] No missing background package registration remains"
fi

if grep -q "MauriMeshHardwareTelemetryPackage" "$APP_KT" && [ ! -f "$TELEMETRY_PACKAGE" ]; then
  line "- [ ] FAIL: MainApplication references missing telemetry package"
  cp "$REPORT" "$LATEST"
  exit 1
else
  line "- [x] Telemetry package registration is source-safe"
fi

line ""
line "## Final Status"
line ""
line "- Status: **GRADLE_PREFLIGHT_READY**"
line "- Backup: $BACKUP"
line "- Next command: npx eas-cli build --platform android --profile preview-apk --clear-cache"

cp "$REPORT" "$LATEST"

echo ""
echo "============================================================"
echo "GRADLE PRE-FAIL FIX COMPLETE"
echo "Status: GRADLE_PREFLIGHT_READY"
echo "Report: $LATEST"
echo "============================================================"
echo ""
echo "Next build command:"
echo "npx eas-cli build --platform android --profile preview-apk --clear-cache"
echo ""
