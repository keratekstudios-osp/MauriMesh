#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH JUMPCODE APK READINESS CHECK"
echo "Checks source, imports, route wiring, JS bundle inclusion,"
echo "and APK proof requirements."
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
REPORT="$ROOT/docs/maurimesh-jumpcode-apk-readiness-$STAMP.md"
LATEST="$ROOT/docs/maurimesh-jumpcode-apk-readiness-latest.md"
EXPORT_DIR="$ROOT/.maurimesh-jumpcode-export-$STAMP"

mkdir -p "$ROOT/docs"

: > "$REPORT"

log() {
  echo "$1" | tee -a "$REPORT"
}

check_file() {
  local label="$1"
  local file="$2"
  if [ -f "$ROOT/$file" ]; then
    log "- [x] $label exists: $file"
  else
    log "- [ ] MISSING: $label: $file"
  fi
}

check_grep() {
  local label="$1"
  local pattern="$2"
  local paths="$3"
  if grep -RIn "$pattern" $paths 2>/dev/null >> "$REPORT"; then
    log "- [x] $label"
  else
    log "- [ ] MISSING: $label"
  fi
}

log "# MauriMesh JumpCode APK Readiness Report"
log ""
log "Generated: $STAMP"
log ""

log "## 1. Source Files"
check_file "JumpCode engine" "src/routing/jumpCodeEngine.ts"

log ""
log "## 2. JumpCode Source Markers"
check_grep "JumpCode references found" "jumpCode\\|JumpCode\\|JUMPCODE" "$ROOT/src $ROOT/app"
check_grep "ACK rate routing logic found" "ackRate" "$ROOT/src $ROOT/app"
check_grep "Trust score routing logic found" "trustScore" "$ROOT/src $ROOT/app"

log ""
log "## 3. Import / Runtime Wiring"
check_grep "JumpCode imported somewhere in app/src" "jumpCodeEngine\\|from .*routing/jumpCode\\|from .*jumpCode" "$ROOT/src $ROOT/app"
check_grep "Route lab or dashboard references JumpCode" "JumpCode\\|jumpCode" "$ROOT/app $ROOT/src/components $ROOT/src/lib"

log ""
log "## 4. TypeScript"
if npx tsc --noEmit >> "$REPORT" 2>&1; then
  log "- [x] TypeScript passed"
else
  log "- [ ] TypeScript failed"
fi

log ""
log "## 5. Expo Android JS Bundle Export"
rm -rf "$EXPORT_DIR"

if NODE_ENV=production npx expo export --platform android --output-dir "$EXPORT_DIR" >> "$REPORT" 2>&1; then
  log "- [x] Expo Android export passed"
else
  log "- [ ] Expo Android export failed"
fi

log ""
log "## 6. Bundle String Search"
BUNDLE_FILE="$(find "$EXPORT_DIR" -type f \( -name '*.hbc' -o -name '*.js' \) | head -1 || true)"

if [ -n "$BUNDLE_FILE" ]; then
  log "- [x] Bundle found: ${BUNDLE_FILE#$ROOT/}"

  if strings "$BUNDLE_FILE" | grep -Ei "jumpCode|JumpCode|ackRate|avgRelayTrustAck" >> "$REPORT" 2>&1; then
    log "- [x] JumpCode-like strings found inside exported Android bundle"
    BUNDLE_STATUS="LIKELY_IN_BUNDLE"
  else
    log "- [ ] JumpCode strings not found in exported bundle"
    BUNDLE_STATUS="NOT_CONFIRMED_IN_BUNDLE"
  fi
else
  log "- [ ] No exported Android bundle found"
  BUNDLE_STATUS="NO_BUNDLE"
fi

log ""
log "## 7. APK Truth Boundary"
log ""
log "To prove JumpCode is inside the APK:"
log "1. Build APK with EAS."
log "2. Download APK."
log "3. Unzip APK."
log "4. Search assets/index.android.bundle or Hermes .hbc for JumpCode markers."
log "5. Install APK."
log "6. Open route/test screen that calls JumpCode."
log "7. Capture logcat or UI proof."

log ""
log "## Status"
if [ "$BUNDLE_STATUS" = "LIKELY_IN_BUNDLE" ]; then
  log "JUMPCODE_STATUS=LIKELY_INCLUDED_IN_ANDROID_JS_BUNDLE"
else
  log "JUMPCODE_STATUS=SOURCE_PRESENT_BUNDLE_NOT_PROVEN"
fi

cp "$REPORT" "$LATEST"

echo ""
echo "============================================================"
echo "JUMPCODE READINESS CHECK COMPLETE"
echo "Report:"
echo "  $LATEST"
echo ""
echo "Show report:"
echo "  cat docs/maurimesh-jumpcode-apk-readiness-latest.md"
echo "============================================================"
