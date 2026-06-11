#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "FIND MAURIMESH RUST"
echo "Searches Rust source, Cargo projects, Android JNI/.so wiring,"
echo "Gradle links, package scripts, and runtime bridge references."
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
REPORT="$ROOT/docs/maurimesh-rust-find-report-$STAMP.md"
LATEST="$ROOT/docs/maurimesh-rust-find-report-latest.md"

mkdir -p "$ROOT/docs"

if [ ! -f "$ROOT/package.json" ]; then
  echo "ERROR: package.json not found. Run from /home/runner/workspace."
  exit 1
fi

: > "$REPORT"

log() {
  echo "$1" | tee -a "$REPORT"
}

log "# MauriMesh Rust Find Report"
log ""
log "Generated: $STAMP"
log ""

log "## 1. Rust Cargo Projects"
log ""

CARGO_FILES="$(find "$ROOT" \
  -path "$ROOT/node_modules" -prune -o \
  -path "$ROOT/.git" -prune -o \
  -path "$ROOT/mesh-messenger/node_modules" -prune -o \
  -name "Cargo.toml" -print 2>/dev/null || true)"

if [ -n "$CARGO_FILES" ]; then
  log "- [x] Cargo.toml files found"
  echo "$CARGO_FILES" | sed "s|$ROOT/||" | sed 's/^/  - /' | tee -a "$REPORT"
else
  log "- [ ] No Cargo.toml files found"
fi

log ""
log "## 2. Rust Source Files"
log ""

RUST_FILES="$(find "$ROOT" \
  -path "$ROOT/node_modules" -prune -o \
  -path "$ROOT/.git" -prune -o \
  -path "$ROOT/mesh-messenger/node_modules" -prune -o \
  -name "*.rs" -print 2>/dev/null || true)"

if [ -n "$RUST_FILES" ]; then
  log "- [x] Rust .rs files found"
  echo "$RUST_FILES" | sed "s|$ROOT/||" | sed 's/^/  - /' | tee -a "$REPORT"
else
  log "- [ ] No Rust .rs files found"
fi

log ""
log "## 3. Rust Directory Summary"
log ""

find "$ROOT" \
  -path "$ROOT/node_modules" -prune -o \
  -path "$ROOT/.git" -prune -o \
  -path "$ROOT/mesh-messenger/node_modules" -prune -o \
  -type d \( -name "rust" -o -name "*rust*" -o -name "*mauricore*" -o -name "*maurimesh-core*" \) -print 2>/dev/null \
  | sed "s|$ROOT/||" \
  | sed 's/^/  - /' \
  | tee -a "$REPORT" || true

log ""
log "## 4. Package.json Rust Scripts"
log ""

if grep -nEi '"[^"]*(rust|cargo|mauricore)[^"]*"\s*:' "$ROOT/package.json" >> "$REPORT" 2>/dev/null; then
  log "- [x] Rust/Cargo scripts found in package.json"
else
  log "- [ ] No Rust/Cargo scripts found in package.json"
fi

log ""
log "## 5. Cargo Check"
log ""

if command -v cargo >/dev/null 2>&1; then
  log "- [x] cargo found: $(cargo --version)"
  while IFS= read -r cargo_file; do
    [ -z "$cargo_file" ] && continue
    dir="$(dirname "$cargo_file")"
    rel="${dir#$ROOT/}"
    log ""
    log "### cargo check: $rel"
    if (cd "$dir" && cargo check) >> "$REPORT" 2>&1; then
      log "- [x] $rel cargo check passed"
    else
      log "- [ ] $rel cargo check failed"
    fi
  done <<< "$CARGO_FILES"
else
  log "- [ ] cargo not found in this environment"
fi

log ""
log "## 6. Android JNI / Native Library Wiring"
log ""

log "### Android .so files"
SO_FILES="$(find "$ROOT/android" "$ROOT/src" "$ROOT/app" \
  -type f -name "*.so" 2>/dev/null || true)"

if [ -n "$SO_FILES" ]; then
  log "- [x] Native .so files found"
  echo "$SO_FILES" | sed "s|$ROOT/||" | sed 's/^/  - /' | tee -a "$REPORT"
else
  log "- [ ] No .so files found under android/src/app"
fi

log ""
log "### jniLibs references"
if grep -RIn "jniLibs" "$ROOT/android" "$ROOT/package.json" 2>/dev/null | tee -a "$REPORT"; then
  log "- [x] jniLibs reference found"
else
  log "- [ ] No jniLibs reference found"
fi

log ""
log "### System.loadLibrary / loadLibrary references"
if grep -RIn "System.loadLibrary\|loadLibrary" "$ROOT/android" "$ROOT/src" "$ROOT/app" 2>/dev/null | tee -a "$REPORT"; then
  log "- [x] loadLibrary reference found"
else
  log "- [ ] No loadLibrary reference found"
fi

log ""
log "### JNI / UniFFI / FFI references"
if grep -RIn "jni\|JNI\|uniffi\|UniFFI\|ffi\|FFI\|cdylib\|staticlib" \
  "$ROOT/rust" "$ROOT/android" "$ROOT/src" "$ROOT/app" "$ROOT/package.json" 2>/dev/null | tee -a "$REPORT"; then
  log "- [x] JNI/FFI style reference found"
else
  log "- [ ] No JNI/FFI style reference found"
fi

log ""
log "## 7. Android Gradle Rust/Cargo Hooks"
log ""

if grep -RIn "cargo\|rust\|uniffi\|exec.*cargo\|jniLibs" "$ROOT/android" 2>/dev/null | tee -a "$REPORT"; then
  log "- [x] Android Gradle/native Rust-related reference found"
else
  log "- [ ] No Android Gradle Rust build hook found"
fi

log ""
log "## 8. Runtime Bridge Search"
log ""

if grep -RIn "MauriCore\|mauricore\|MauriMeshCore\|maurimesh-core\|Rust\|rust" \
  "$ROOT/src" "$ROOT/app" "$ROOT/android" 2>/dev/null | tee -a "$REPORT"; then
  log "- [x] Runtime bridge/reference strings found"
else
  log "- [ ] No runtime bridge/reference strings found"
fi

log ""
log "## 9. Final Rust Status"
log ""

CARGO_COUNT="$(echo "$CARGO_FILES" | grep -c "Cargo.toml" || true)"
RS_COUNT="$(echo "$RUST_FILES" | grep -c "\.rs$" || true)"
SO_COUNT="$(echo "$SO_FILES" | grep -c "\.so$" || true)"
LOAD_COUNT="$(grep -RIn "System.loadLibrary\|loadLibrary" "$ROOT/android" "$ROOT/src" "$ROOT/app" 2>/dev/null | grep -Eic "mauri|mesh|core|rust" || true)"
GRADLE_CARGO_COUNT="$(grep -RIn "cargo\|rust\|uniffi" "$ROOT/android" 2>/dev/null | grep -vc "node_modules" || true)"

log "- Cargo.toml count: $CARGO_COUNT"
log "- Rust .rs count: $RS_COUNT"
log "- Android/native .so count: $SO_COUNT"
log "- Mauri-related loadLibrary count: $LOAD_COUNT"
log "- Android Gradle Cargo/Rust hook count: $GRADLE_CARGO_COUNT"
log ""

if [ "$CARGO_COUNT" -gt 0 ] && [ "$RS_COUNT" -gt 0 ]; then
  log "- Rust source status: PRESENT"
else
  log "- Rust source status: NOT FOUND"
fi

if [ "$SO_COUNT" -gt 0 ] && [ "$LOAD_COUNT" -gt 0 ]; then
  log "- Rust APK integration status: LIKELY WIRED"
elif [ "$CARGO_COUNT" -gt 0 ] && [ "$RS_COUNT" -gt 0 ]; then
  log "- Rust APK integration status: SOURCE PRESENT, APK INTEGRATION NOT PROVEN"
else
  log "- Rust APK integration status: NOT INTEGRATED"
fi

log ""
log "## Truth Boundary"
log ""
log "Rust source files prove Rust exists in the repo."
log "They do not prove Rust is inside the APK."
log "APK Rust proof requires compiled .so files, Gradle wiring, Kotlin loadLibrary/JNI or UniFFI bridge, and runtime call proof."

cp "$REPORT" "$LATEST"

echo ""
echo "============================================================"
echo "RUST FIND COMPLETE"
echo "Latest report:"
echo "  $LATEST"
echo ""
echo "Show report:"
echo "  cat docs/maurimesh-rust-find-report-latest.md"
echo "============================================================"
