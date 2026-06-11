#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH BUILD + RUST + JS BUNDLE DIAGNOSTIC"
echo "Finds why EAS Bundle JavaScript phase failed and confirms"
echo "whether Rust is only present or actually integrated."
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
REPORT="$ROOT/docs/maurimesh-build-rust-js-diagnostic-$STAMP.md"
LATEST="$ROOT/docs/maurimesh-build-rust-js-diagnostic-latest.md"
mkdir -p "$ROOT/docs"

: > "$REPORT"

log() {
  echo "$1" | tee -a "$REPORT"
}

log "# MauriMesh Build + Rust + JS Diagnostic"
log ""
log "Generated: $STAMP"
log ""

log "## 1. Project"
log ""
if [ -f package.json ]; then
  log "- [x] package.json found"
else
  log "- [ ] package.json missing"
  exit 1
fi

log ""
log "## 2. Rust File Presence"
log ""

RUST_FILES="$(find rust -type f \( -name 'Cargo.toml' -o -name '*.rs' \) 2>/dev/null || true)"

if [ -n "$RUST_FILES" ]; then
  log "- [x] Rust files found"
  echo "$RUST_FILES" | sed 's/^/  - /' | tee -a "$REPORT"
else
  log "- [ ] No Rust files found under ./rust"
fi

log ""
log "## 3. Cargo Check"
log ""

if command -v cargo >/dev/null 2>&1; then
  log "- [x] cargo found: $(cargo --version)"
  if [ -f rust/mauricore/Cargo.toml ]; then
    log ""
    log "### rust/mauricore cargo check"
    if (cd rust/mauricore && cargo check) >> "$REPORT" 2>&1; then
      log "- [x] rust/mauricore cargo check passed"
    else
      log "- [ ] rust/mauricore cargo check failed"
    fi
  else
    log "- [ ] rust/mauricore/Cargo.toml missing"
  fi

  if [ -f rust/maurimesh-core/Cargo.toml ]; then
    log ""
    log "### rust/maurimesh-core cargo check"
    if (cd rust/maurimesh-core && cargo check) >> "$REPORT" 2>&1; then
      log "- [x] rust/maurimesh-core cargo check passed"
    else
      log "- [ ] rust/maurimesh-core cargo check failed"
    fi
  else
    log "- [ ] rust/maurimesh-core/Cargo.toml missing"
  fi
else
  log "- [ ] cargo not found in Replit environment"
fi

log ""
log "## 4. Android Rust Integration Proof"
log ""

if grep -RIn "System.loadLibrary\|loadLibrary" android 2>/dev/null | grep -Ei "mauri|mesh|core|rust" >> "$REPORT"; then
  log "- [x] Kotlin/Java native library load reference found"
else
  log "- [ ] No MauriMesh Rust System.loadLibrary reference found"
fi

if find android/app/src/main -path '*jniLibs*' -type f -name '*.so' 2>/dev/null | grep -q .; then
  log "- [x] Native .so files found in android/app/src/main/jniLibs"
  find android/app/src/main -path '*jniLibs*' -type f -name '*.so' 2>/dev/null | sed 's/^/  - /' | tee -a "$REPORT"
else
  log "- [ ] No native .so files found in android/app/src/main/jniLibs"
fi

if grep -RIn "cargo\|rust\|uniffi\|jniLibs" android package.json 2>/dev/null >> "$REPORT"; then
  log "- [x] Rust/JNI references exist in android/package config"
else
  log "- [ ] No Rust/JNI build references found in android/package config"
fi

log ""
log "## 5. TypeScript Check"
log ""

if npx tsc --noEmit >> "$REPORT" 2>&1; then
  log "- [x] TypeScript passed"
else
  log "- [ ] TypeScript failed"
fi

log ""
log "## 6. Expo Export / JS Bundle Check"
log ""
log "This reproduces the EAS Bundle JavaScript phase locally."

EXPORT_DIR="$ROOT/.maurimesh-export-check-$STAMP"
rm -rf "$EXPORT_DIR"

if NODE_ENV=production npx expo export --platform android --output-dir "$EXPORT_DIR" >> "$REPORT" 2>&1; then
  log "- [x] Expo Android JS bundle export passed"
else
  log "- [ ] Expo Android JS bundle export failed"
  log ""
  log "### Last 120 lines from export failure"
  log ""
  NODE_ENV=production npx expo export --platform android --output-dir "$EXPORT_DIR" 2>&1 | tail -120 | tee -a "$REPORT" || true
fi

log ""
log "## 7. Metro Bundle Check"
log ""

if [ -f index.js ] || [ -f index.ts ] || [ -f index.tsx ]; then
  ENTRY="$(ls index.js index.ts index.tsx 2>/dev/null | head -1)"
else
  ENTRY="node_modules/expo/AppEntry.js"
fi

log "- Entry candidate: $ENTRY"

if [ -f "$ENTRY" ]; then
  if NODE_ENV=production npx react-native bundle \
    --platform android \
    --dev false \
    --entry-file "$ENTRY" \
    --bundle-output "$ROOT/tmp-maurimesh-index.android.bundle" \
    --assets-dest "$ROOT/tmp-maurimesh-assets" >> "$REPORT" 2>&1; then
    log "- [x] React Native bundle passed"
  else
    log "- [ ] React Native bundle failed"
  fi
else
  log "- [!] Entry file not found locally. Expo export result is more important."
fi

log ""
log "## 8. Final Status"
log ""

RUST_SO_COUNT="$(find android/app/src/main -path '*jniLibs*' -type f -name '*.so' 2>/dev/null | wc -l | tr -d ' ')"
LOAD_REF_COUNT="$(grep -RIn "System.loadLibrary\|loadLibrary" android 2>/dev/null | grep -Eic "mauri|mesh|core|rust" || true)"

if [ -n "$RUST_FILES" ]; then
  log "- Rust source status: PRESENT"
else
  log "- Rust source status: MISSING"
fi

if [ "${RUST_SO_COUNT:-0}" -gt 0 ] && [ "${LOAD_REF_COUNT:-0}" -gt 0 ]; then
  log "- Rust APK integration status: LIKELY INTEGRATED"
else
  log "- Rust APK integration status: NOT PROVEN"
fi

log ""
log "Truth:"
log "Rust source existing does not mean Rust is inside the APK."
log "APK proof requires compiled .so libraries, Gradle/JNI wiring, Kotlin loadLibrary, and runtime call proof."
log "Your current EAS error points to Bundle JavaScript build phase first."

cp "$REPORT" "$LATEST"

echo ""
echo "============================================================"
echo "DIAGNOSTIC COMPLETE"
echo "Report:"
echo "  $LATEST"
echo "============================================================"
