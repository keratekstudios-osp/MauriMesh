#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "REPAIR MAINAPPLICATION GETPACKAGES CLEAN"
echo "Fixes malformed Kotlin package registration lines."
echo "Separates telemetry/background package adds correctly."
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$ROOT/backup-before-mainapplication-getpackages-clean-$STAMP"
DOCS="$ROOT/docs"

mkdir -p "$BACKUP" "$DOCS"

MAIN_KT="$(find "$ROOT/android/app/src/main" -name "MainApplication.kt" | head -1 || true)"

if [ -z "$MAIN_KT" ]; then
  echo "ERROR: MainApplication.kt not found."
  exit 1
fi

REL="${MAIN_KT#$ROOT/}"
mkdir -p "$BACKUP/$(dirname "$REL")"
cp "$MAIN_KT" "$BACKUP/$REL"

echo "MainApplication:"
echo "  $REL"
echo ""
echo "Backup:"
echo "  $BACKUP/$REL"
echo ""

python3 <<PY
from pathlib import Path
import re

path = Path("$MAIN_KT")
src = path.read_text()

pkg_match = re.search(r"^package\\s+([\\w.]+)", src, re.M)
if not pkg_match:
    raise SystemExit("Could not detect package line")

app_pkg = pkg_match.group(1)

imports = [
    "import com.facebook.react.ReactPackage",
    f"import {app_pkg}.maurimesh.telemetry.MauriMeshHardwareTelemetryPackage",
]

# Preserve background runtime import if already present or package class is referenced.
background_import = f"import {app_pkg}.maurimesh.background.MauriMeshBackgroundRuntimePackage"
has_background = "MauriMeshBackgroundRuntimePackage" in src
if has_background and background_import not in imports:
    imports.append(background_import)

# Add missing imports after existing import block.
lines = src.splitlines()
for imp in imports:
    if imp not in src:
        insert_at = 0
        for i, line in enumerate(lines):
            if line.startswith("import "):
                insert_at = i + 1
        lines.insert(insert_at, imp)
        src = "\\n".join(lines) + "\\n"
        lines = src.splitlines()

# Fix the specific bad joined line if present.
src = src.replace(
    "add(MauriMeshHardwareTelemetryPackage()) add(MauriMeshBackgroundRuntimePackage()) }.apply {",
    "add(MauriMeshHardwareTelemetryPackage())\\n                add(MauriMeshBackgroundRuntimePackage())\\n            }.apply {",
)

src = src.replace(
    "add(MauriMeshHardwareTelemetryPackage()) add(MauriMeshBackgroundRuntimePackage())",
    "add(MauriMeshHardwareTelemetryPackage())\\n                add(MauriMeshBackgroundRuntimePackage())",
)

# Rebuild getPackages body cleanly when it contains PackageList(this).packages.
pattern = re.compile(
    r"override\\s+fun\\s+getPackages\\s*\\(\\s*\\)\\s*:\\s*List<ReactPackage>\\s*=\\s*PackageList\\(this\\)\\.packages(?:\\.apply\\s*\\{[\\s\\S]*?\\})?(?:\\.apply\\s*\\{[\\s\\S]*?\\})?",
    re.M,
)

telemetry_add = "                add(MauriMeshHardwareTelemetryPackage())"
background_add = "                add(MauriMeshBackgroundRuntimePackage())"

adds = [telemetry_add]
if "MauriMeshBackgroundRuntimePackage" in src:
    adds.append(background_add)

new_getpackages = (
    "override fun getPackages(): List<ReactPackage> =\\n"
    "            PackageList(this).packages.apply {\\n"
    + "\\n".join(adds) +
    "\\n            }"
)

if pattern.search(src):
    src = pattern.sub(new_getpackages, src, count=1)
else:
    # Fallback: replace inside object reactNativeHost block if possible.
    marker = "override fun getJSMainModuleName()"
    if marker in src and "override fun getPackages()" not in src:
        src = src.replace(
            marker,
            new_getpackages + "\\n\\n        " + marker,
            1,
        )

# Remove accidental duplicate package adds inside getPackages.
src = re.sub(
    r"(add\\(MauriMeshHardwareTelemetryPackage\\(\\)\\)\\s*){2,}",
    "add(MauriMeshHardwareTelemetryPackage())\\n",
    src,
)

src = re.sub(
    r"(add\\(MauriMeshBackgroundRuntimePackage\\(\\)\\)\\s*){2,}",
    "add(MauriMeshBackgroundRuntimePackage())\\n",
    src,
)

path.write_text(src.rstrip() + "\\n")
PY

echo ""
echo "Patched getPackages section:"
echo "------------------------------------------------------------"
sed -n '1,70p' "$MAIN_KT"
echo "------------------------------------------------------------"

cat > "$ROOT/check-mainapplication-kotlin-syntax-shape.sh" <<'CHECK'
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
DOCS="$ROOT/docs"
mkdir -p "$DOCS"

REPORT="$DOCS/mainapplication-kotlin-syntax-shape-$STAMP.md"
LATEST="$DOCS/mainapplication-kotlin-syntax-shape-latest.md"

MAIN_KT="$(find "$ROOT/android/app/src/main" -name "MainApplication.kt" | head -1 || true)"

PASS=0
FAIL=0

line(){ echo "$1" | tee -a "$REPORT"; }
pass(){ PASS=$((PASS+1)); line "- [x] $1"; }
fail(){ FAIL=$((FAIL+1)); line "- [ ] FAILED: $1"; }

: > "$REPORT"

line "# MainApplication Kotlin Syntax Shape Check"
line ""
line "Generated: $STAMP"
line ""

if [ -n "$MAIN_KT" ]; then pass "MainApplication.kt found"; else fail "MainApplication.kt missing"; fi

if grep -Fq "add(MauriMeshHardwareTelemetryPackage()) add(" "$MAIN_KT"; then
  fail "Bad joined add(...) add(...) line still exists"
else
  pass "No joined add(...) add(...) line"
fi

if grep -Fq "add(MauriMeshHardwareTelemetryPackage())" "$MAIN_KT"; then
  pass "Telemetry package add exists"
else
  fail "Telemetry package add missing"
fi

if grep -Fq "PackageList(this).packages.apply" "$MAIN_KT"; then
  pass "PackageList apply block exists"
else
  fail "PackageList apply block missing"
fi

if grep -Fq ".maurimesh.telemetry.MauriMeshHardwareTelemetryPackage" "$MAIN_KT"; then
  pass "Telemetry import exists"
else
  fail "Telemetry import missing"
fi

line ""
line "## Summary"
line ""
TOTAL=$((PASS + FAIL))
SCORE=$((PASS * 100 / TOTAL))
if [ "$FAIL" -eq 0 ]; then STATUS="COMPLETE"; else STATUS="INCOMPLETE"; fi
line "- Total: $TOTAL"
line "- Complete: $PASS"
line "- Failed: $FAIL"
line "- Score: $SCORE%"
line "- Status: **$STATUS**"

cp "$REPORT" "$LATEST"

echo ""
echo "============================================================"
echo "MAINAPPLICATION KOTLIN SHAPE CHECK COMPLETE"
echo "Status: $STATUS"
echo "Score:  $SCORE%"
echo "Report: $LATEST"
echo "============================================================"

if [ "$FAIL" -gt 0 ]; then exit 1; fi
CHECK

chmod +x "$ROOT/check-mainapplication-kotlin-syntax-shape.sh"

echo ""
echo "Running syntax-shape checker..."
./check-mainapplication-kotlin-syntax-shape.sh

echo ""
echo "============================================================"
echo "DONE: MAINAPPLICATION GETPACKAGES CLEANED"
echo "============================================================"
echo "Backup:"
echo "  $BACKUP"
echo ""
echo "Next:"
echo "  ./check-mainapplication-kotlin-syntax-shape.sh"
echo "  ./check-maurimesh-master-readiness.sh"
echo "  npx eas-cli build --platform android --profile preview-apk --clear-cache"
echo "============================================================"
