#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "FIX MAURIMESH MAINAPPLICATION TELEMETRY REGISTRATION"
echo "Repairs Kotlin package registration for native telemetry."
echo "Fixes EAS error: MainApplication.kt unresolved reference add"
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$ROOT/backup-before-mainapplication-telemetry-fix-$STAMP"
DOCS="$ROOT/docs"

mkdir -p "$BACKUP" "$DOCS"

if [ ! -f "$ROOT/package.json" ]; then
  echo "ERROR: package.json not found. Run from /home/runner/workspace."
  exit 1
fi

MAIN_KT="$(find "$ROOT/android/app/src/main" -name "MainApplication.kt" | head -1 || true)"

if [ -z "$MAIN_KT" ]; then
  echo "ERROR: MainApplication.kt not found."
  exit 1
fi

REL_MAIN="${MAIN_KT#$ROOT/}"
mkdir -p "$BACKUP/$(dirname "$REL_MAIN")"
cp "$MAIN_KT" "$BACKUP/$REL_MAIN"

echo "MainApplication:"
echo "  $REL_MAIN"
echo ""
echo "Backup:"
echo "  $BACKUP/$REL_MAIN"
echo ""

APP_PACKAGE="$(grep -E '^package ' "$MAIN_KT" | head -1 | sed 's/package //g' | tr -d ' ' | tr -d ';')"

if [ -z "$APP_PACKAGE" ]; then
  echo "ERROR: Could not detect package from MainApplication.kt"
  exit 1
fi

TELEMETRY_IMPORT="import ${APP_PACKAGE}.maurimesh.telemetry.MauriMeshHardwareTelemetryPackage"

python3 <<PY
from pathlib import Path
import re

path = Path("$MAIN_KT")
src = path.read_text()

telemetry_import = "$TELEMETRY_IMPORT"

# Add import once.
if telemetry_import not in src:
    lines = src.splitlines()
    insert_at = 0
    for i, line in enumerate(lines):
        if line.startswith("import "):
            insert_at = i + 1
    lines.insert(insert_at, telemetry_import)
    src = "\\n".join(lines) + "\\n"

# Remove bad direct immutable-list add patterns from earlier patch.
bad_patterns = [
    r"\\n\\s*PackageList\\(this\\)\\.packages\\.add\\(MauriMeshHardwareTelemetryPackage\\(\\)\\)",
    r"\\n\\s*getPackages\\(\\)\\.add\\(MauriMeshHardwareTelemetryPackage\\(\\)\\)",
    r"\\n\\s*super\\.getPackages\\(\\)\\.add\\(MauriMeshHardwareTelemetryPackage\\(\\)\\)",
]
for pattern in bad_patterns:
    src = re.sub(pattern, "", src)

# Remove duplicate raw package add lines if they exist in the wrong place.
src = re.sub(
    r"\\n\\s*packages\\.add\\(MauriMeshHardwareTelemetryPackage\\(\\)\\)\\s*\\n\\s*packages\\.add\\(MauriMeshHardwareTelemetryPackage\\(\\)\\)",
    "\\n          packages.add(MauriMeshHardwareTelemetryPackage())",
    src,
)

# Best case Expo/RN Kotlin template:
# override fun getPackages(): List<ReactPackage> =
#   PackageList(this).packages.apply {
#     ...
#   }
if "MauriMeshHardwareTelemetryPackage()" not in src:
    if "PackageList(this).packages.apply {" in src:
        src = src.replace(
            "PackageList(this).packages.apply {",
            "PackageList(this).packages.apply {\\n          add(MauriMeshHardwareTelemetryPackage())",
            1,
        )
    elif "val packages = PackageList(this).packages" in src:
        src = src.replace(
            "val packages = PackageList(this).packages",
            "val packages = PackageList(this).packages.toMutableList()",
            1,
        )

        # Add before first return packages.
        if "return packages" in src:
            src = src.replace(
                "return packages",
                "packages.add(MauriMeshHardwareTelemetryPackage())\\n          return packages",
                1,
            )
        else:
            src += "\\n// TODO: return packages after adding MauriMeshHardwareTelemetryPackage()\\n"
    elif "PackageList(this).packages" in src:
        # Expression-bodied getPackages without apply. Convert:
        # PackageList(this).packages
        # to:
        # PackageList(this).packages.apply { add(...) }
        src = src.replace(
            "PackageList(this).packages",
            "PackageList(this).packages.apply {\\n          add(MauriMeshHardwareTelemetryPackage())\\n        }",
            1,
        )
    else:
        src += "\\n// TODO: Add MauriMeshHardwareTelemetryPackage() to getPackages() manually.\\n"
else:
    # If telemetry exists but direct immutable add remains, convert val packages to mutable.
    src = src.replace(
        "val packages = PackageList(this).packages\\n          packages.add(MauriMeshHardwareTelemetryPackage())",
        "val packages = PackageList(this).packages.toMutableList()\\n          packages.add(MauriMeshHardwareTelemetryPackage())",
    )

# Clean duplicate imports.
lines = src.splitlines()
seen = set()
clean = []
for line in lines:
    if line == telemetry_import:
        if line in seen:
            continue
        seen.add(line)
    clean.append(line)

src = "\\n".join(clean).rstrip() + "\\n"
path.write_text(src)
PY

echo ""
echo "Patched MainApplication.kt package section:"
echo "------------------------------------------------------------"
grep -nE "package |MauriMeshHardwareTelemetryPackage|PackageList|packages|override fun getPackages|return packages" "$MAIN_KT" || true
echo "------------------------------------------------------------"

cat > "$ROOT/check-maurimesh-mainapplication-telemetry-fix.sh" <<'CHECK'
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
DOCS="$ROOT/docs"
mkdir -p "$DOCS"

REPORT="$DOCS/maurimesh-mainapplication-telemetry-fix-report-$STAMP.md"
LATEST="$DOCS/maurimesh-mainapplication-telemetry-fix-report-latest.md"

PASS=0
FAIL=0
WARN=0

line(){ echo "$1" | tee -a "$REPORT"; }
pass(){ PASS=$((PASS+1)); line "- [x] $1"; }
fail(){ FAIL=$((FAIL+1)); line "- [ ] MISSING: $1"; }
warn(){ WARN=$((WARN+1)); line "- [!] PARTIAL: $1"; }

MAIN_KT="$(find "$ROOT/android/app/src/main" -name "MainApplication.kt" | head -1 || true)"

: > "$REPORT"
line "# MauriMesh MainApplication Telemetry Fix Report"
line ""
line "Generated: $STAMP"
line ""

if [ -n "$MAIN_KT" ]; then
  pass "MainApplication.kt found: ${MAIN_KT#$ROOT/}"
else
  fail "MainApplication.kt missing"
fi

if [ -n "$MAIN_KT" ] && grep -Fq "MauriMeshHardwareTelemetryPackage" "$MAIN_KT"; then
  pass "Telemetry package reference exists"
else
  fail "Telemetry package reference missing"
fi

if [ -n "$MAIN_KT" ] && grep -Fq "import " "$MAIN_KT" && grep -Fq ".maurimesh.telemetry.MauriMeshHardwareTelemetryPackage" "$MAIN_KT"; then
  pass "Telemetry import exists"
else
  fail "Telemetry import missing"
fi

if [ -n "$MAIN_KT" ] && grep -Eq "apply \\{|toMutableList\\(\\)" "$MAIN_KT"; then
  pass "Mutable/apply package registration pattern exists"
else
  warn "Mutable/apply registration pattern not confirmed"
fi

if [ -n "$MAIN_KT" ] && grep -Fq "PackageList(this).packages.add" "$MAIN_KT"; then
  fail "Bad immutable PackageList(this).packages.add pattern still exists"
else
  pass "Bad immutable add pattern removed"
fi

line ""
line "## TypeScript"
if npx tsc --noEmit >> "$REPORT" 2>&1; then
  pass "TypeScript passed"
else
  fail "TypeScript failed"
fi

TOTAL=$((PASS + FAIL + WARN))
if [ "$TOTAL" -gt 0 ]; then SCORE=$((PASS * 100 / TOTAL)); else SCORE=0; fi

if [ "$FAIL" -eq 0 ] && [ "$WARN" -eq 0 ]; then
  STATUS="COMPLETE"
elif [ "$FAIL" -eq 0 ]; then
  STATUS="COMPLETE_WITH_WARNINGS"
else
  STATUS="INCOMPLETE"
fi

line ""
line "## Summary"
line ""
line "- Total: $TOTAL"
line "- Complete: $PASS"
line "- Partial: $WARN"
line "- Missing/failed: $FAIL"
line "- Score: $SCORE%"
line "- Status: **$STATUS**"

cp "$REPORT" "$LATEST"

echo ""
echo "============================================================"
echo "MAINAPPLICATION TELEMETRY FIX CHECK COMPLETE"
echo "Status: $STATUS"
echo "Score:  $SCORE%"
echo "Report: $LATEST"
echo "============================================================"
echo ""

if [ "$FAIL" -gt 0 ]; then exit 1; fi
CHECK

chmod +x "$ROOT/check-maurimesh-mainapplication-telemetry-fix.sh"

echo ""
echo "Running fix checker..."
./check-maurimesh-mainapplication-telemetry-fix.sh

echo ""
echo "============================================================"
echo "DONE: MAINAPPLICATION TELEMETRY REGISTRATION FIXED"
echo "============================================================"
echo "Backup:"
echo "  $BACKUP"
echo ""
echo "Latest report:"
echo "  docs/maurimesh-mainapplication-telemetry-fix-report-latest.md"
echo ""
echo "Next:"
echo "  npx tsc --noEmit"
echo "  ./check-maurimesh-master-readiness.sh"
echo "  npx eas-cli build --platform android --profile preview-apk --clear-cache"
echo "============================================================"
