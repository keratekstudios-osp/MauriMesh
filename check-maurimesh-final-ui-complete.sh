#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH FINAL UI COMPLETION CHECKER"
echo "Checks all required Replit-safe UI screens, routing, components,"
echo "API fallback files, TypeScript, Expo Router structure, and dashboard wiring."
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
REPORT="$ROOT/maurimesh-final-ui-completion-report-$STAMP.txt"
JSON="$ROOT/maurimesh-final-ui-completion-report-$STAMP.json"

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

touch "$REPORT"

log() {
  echo "$1" | tee -a "$REPORT"
}

pass() {
  PASS_COUNT=$((PASS_COUNT + 1))
  log "PASS: $1"
}

fail() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  log "FAIL: $1"
}

warn() {
  WARN_COUNT=$((WARN_COUNT + 1))
  log "WARN: $1"
}

section() {
  log ""
  log "------------------------------------------------------------"
  log "$1"
  log "------------------------------------------------------------"
}

contains() {
  local file="$1"
  local needle="$2"
  if [ -f "$file" ] && grep -Fq "$needle" "$file"; then
    return 0
  fi
  return 1
}

contains_any() {
  local file="$1"
  shift
  if [ ! -f "$file" ]; then
    return 1
  fi
  for needle in "$@"; do
    if grep -Fq "$needle" "$file"; then
      return 0
    fi
  done
  return 1
}

file_required() {
  local file="$1"
  local label="$2"
  if [ -f "$ROOT/$file" ]; then
    pass "$label exists: $file"
  else
    fail "$label missing: $file"
  fi
}

dir_required() {
  local dir="$1"
  local label="$2"
  if [ -d "$ROOT/$dir" ]; then
    pass "$label exists: $dir"
  else
    fail "$label missing: $dir"
  fi
}

check_import_path() {
  local file="$1"
  local import_text="$2"
  local label="$3"
  if contains "$ROOT/$file" "$import_text"; then
    pass "$label import found in $file"
  else
    fail "$label import missing in $file"
  fi
}

check_route_push() {
  local route="$1"
  if contains "$ROOT/app/dashboard.tsx" "$route"; then
    pass "Dashboard links to $route"
  else
    fail "Dashboard does not link to $route"
  fi
}

check_text_marker() {
  local file="$1"
  local marker="$2"
  local label="$3"
  if contains "$ROOT/$file" "$marker"; then
    pass "$label marker found in $file"
  else
    fail "$label marker missing in $file"
  fi
}

check_file_not_empty() {
  local file="$1"
  local label="$2"
  if [ -s "$ROOT/$file" ]; then
    pass "$label is not empty: $file"
  else
    fail "$label is empty or missing: $file"
  fi
}

section "1. PROJECT ROOT CHECKS"

if [ -f "$ROOT/package.json" ]; then
  pass "package.json found"
else
  fail "package.json not found. Run this from the Replit project root."
fi

if [ -d "$ROOT/app" ]; then
  pass "Expo Router app/ folder found"
else
  fail "app/ folder missing"
fi

if [ -d "$ROOT/src" ]; then
  pass "src/ folder found"
else
  fail "src/ folder missing"
fi

section "2. REQUIRED DIRECTORIES"

dir_required "app" "Routes directory"
dir_required "src" "Source directory"
dir_required "src/components" "Components directory"
dir_required "src/lib" "Library directory"
dir_required "src/theme" "Theme directory"

if [ -d "$ROOT/server" ]; then
  pass "Server directory exists"
else
  warn "server/ directory missing. UI can still run, but Replit API shell is incomplete."
fi

section "3. REQUIRED UI ROUTE FILES"

file_required "app/_layout.tsx" "Root layout"
file_required "app/index.tsx" "Index redirect"
file_required "app/login.tsx" "Login screen"
file_required "app/dashboard.tsx" "Dashboard screen"
file_required "app/chat.tsx" "Chat screen"
file_required "app/settings.tsx" "Settings screen"
file_required "app/add-friend.tsx" "Add Friend screen"
file_required "app/living-mesh.tsx" "Living Mesh screen"
file_required "app/mesh-status.tsx" "Mesh Status screen"
file_required "app/pixel-calling.tsx" "Pixel Calling screen"

section "4. REQUIRED COMPONENT FILES"

file_required "src/components/AppShell.tsx" "App shell component"
file_required "src/components/MauriButton.tsx" "Mauri button component"
file_required "src/components/StatusPill.tsx" "Status pill component"
file_required "src/components/MeshSignalCard.tsx" "Mesh signal card component"
file_required "src/components/LivingMeshCanvas.tsx" "Living mesh canvas component"
file_required "src/components/ChatBubble.tsx" "Chat bubble component"

section "5. REQUIRED LIBRARY AND THEME FILES"

file_required "src/theme/mauriTheme.ts" "Mauri theme"
file_required "src/lib/api.ts" "API client"
file_required "src/lib/meshClient.ts" "Mesh client"
file_required "src/lib/simulation.ts" "Simulation data"

if [ -f "$ROOT/server/index.ts" ]; then
  pass "Replit API server exists: server/index.ts"
else
  warn "server/index.ts missing. API fallback UI can still work if meshClient falls back to simulation."
fi

if [ -f "$ROOT/.env.example" ]; then
  pass ".env.example exists"
else
  warn ".env.example missing"
fi

section "6. ROUTE FILE CONTENT CHECKS"

check_file_not_empty "app/_layout.tsx" "Root layout"
check_file_not_empty "app/index.tsx" "Index route"
check_file_not_empty "app/login.tsx" "Login screen"
check_file_not_empty "app/dashboard.tsx" "Dashboard screen"
check_file_not_empty "app/chat.tsx" "Chat screen"
check_file_not_empty "app/settings.tsx" "Settings screen"
check_file_not_empty "app/add-friend.tsx" "Add Friend screen"
check_file_not_empty "app/living-mesh.tsx" "Living Mesh screen"
check_file_not_empty "app/mesh-status.tsx" "Mesh Status screen"
check_file_not_empty "app/pixel-calling.tsx" "Pixel Calling screen"

section "7. EXPO ROUTER CHECKS"

check_text_marker "app/_layout.tsx" "Stack" "Expo Router Stack"
check_text_marker "app/index.tsx" "Redirect" "Index redirect"
check_text_marker "app/login.tsx" "router.replace" "Login navigation"
check_text_marker "app/login.tsx" "/dashboard" "Login to dashboard route"
check_text_marker "app/settings.tsx" "/login" "Settings logout route"

section "8. DASHBOARD FINAL NAVIGATION CHECKS"

if [ -f "$ROOT/app/dashboard.tsx" ]; then
  check_route_push "/chat"
  check_route_push "/living-mesh"
  check_route_push "/add-friend"
  check_route_push "/pixel-calling"
  check_route_push "/mesh-status"
  check_route_push "/settings"

  if contains_any "$ROOT/app/dashboard.tsx" "router.push" "router.replace"; then
    pass "Dashboard uses Expo Router navigation"
  else
    fail "Dashboard has no router.push/router.replace navigation"
  fi
else
  fail "Cannot check dashboard routes because app/dashboard.tsx is missing"
fi

section "9. SCREEN IDENTITY MARKER CHECKS"

check_text_marker "app/login.tsx" "MauriMesh" "Login brand"
check_text_marker "app/login.tsx" "Open Dashboard" "Login button"
check_text_marker "app/dashboard.tsx" "Dashboard" "Dashboard title"
check_text_marker "app/chat.tsx" "Chat" "Chat title"
check_text_marker "app/settings.tsx" "Settings" "Settings title"
check_text_marker "app/add-friend.tsx" "Add Friend" "Add Friend title"
check_text_marker "app/living-mesh.tsx" "Living Mesh" "Living Mesh title"
check_text_marker "app/mesh-status.tsx" "Mesh Status" "Mesh Status title"
check_text_marker "app/pixel-calling.tsx" "Pixel Calling" "Pixel Calling title"

section "10. TRUTHFUL SIMULATION / NO FAKE LIVE CLAIM CHECKS"

if contains_any "$ROOT/app/chat.tsx" "SIMULATION" "simulation"; then
  pass "Chat labels simulation/dev state"
else
  warn "Chat does not clearly label simulation/dev state"
fi

if contains_any "$ROOT/app/living-mesh.tsx" "simulation" "SIMULATION" "Replit fallback"; then
  pass "Living Mesh labels simulation/fallback state"
else
  warn "Living Mesh does not clearly label simulation/fallback state"
fi

if contains_any "$ROOT/app/pixel-calling.tsx" "UI SHELL ONLY" "SIMULATION" "requires native" "Real media transport"; then
  pass "Pixel Calling is clearly labelled as UI shell / not real transport"
else
  fail "Pixel Calling screen may be falsely implying real calling"
fi

if [ -f "$ROOT/src/lib/meshClient.ts" ]; then
  if contains "$ROOT/src/lib/meshClient.ts" "SIMULATION"; then
    pass "meshClient includes SIMULATION fallback"
  else
    fail "meshClient missing SIMULATION fallback"
  fi

  if contains_any "$ROOT/src/lib/meshClient.ts" "apiGet" "/api/mesh/status"; then
    pass "meshClient checks API before fallback"
  else
    warn "meshClient may not check /api/mesh/status"
  fi
fi

section "11. API FALLBACK CHECKS"

if [ -f "$ROOT/src/lib/api.ts" ]; then
  check_text_marker "src/lib/api.ts" "EXPO_PUBLIC_MESH_API_URL" "Expo public API URL support"
  check_text_marker "src/lib/api.ts" "AbortController" "API timeout support"
  check_text_marker "src/lib/api.ts" "unavailable" "Unavailable state"
else
  fail "Cannot check API client because src/lib/api.ts is missing"
fi

if [ -f "$ROOT/server/index.ts" ]; then
  check_text_marker "server/index.ts" "/api/health" "Health endpoint"
  check_text_marker "server/index.ts" "/api/mesh/status" "Mesh status endpoint"
  if contains_any "$ROOT/server/index.ts" "simulation" "SIMULATION" "Not live BLE" "development only"; then
    pass "Server labels API as simulation/development"
  else
    warn "Server does not clearly label simulation/development truth"
  fi
fi

section "12. COMPONENT EXPORT / STRUCTURE CHECKS"

check_text_marker "src/components/AppShell.tsx" "export function AppShell" "AppShell export"
check_text_marker "src/components/MauriButton.tsx" "export function MauriButton" "MauriButton export"
check_text_marker "src/components/StatusPill.tsx" "export function StatusPill" "StatusPill export"
check_text_marker "src/components/MeshSignalCard.tsx" "export function MeshSignalCard" "MeshSignalCard export"
check_text_marker "src/components/LivingMeshCanvas.tsx" "export function LivingMeshCanvas" "LivingMeshCanvas export"
check_text_marker "src/components/ChatBubble.tsx" "export function ChatBubble" "ChatBubble export"

section "13. THEME CHECKS"

if [ -f "$ROOT/src/theme/mauriTheme.ts" ]; then
  check_text_marker "src/theme/mauriTheme.ts" "greenstone" "Greenstone color"
  check_text_marker "src/theme/mauriTheme.ts" "emerald" "Emerald color"
  check_text_marker "src/theme/mauriTheme.ts" "panelBorder" "Panel border color"
  check_text_marker "src/theme/mauriTheme.ts" "radius" "Radius tokens"
  check_text_marker "src/theme/mauriTheme.ts" "spacing" "Spacing tokens"
else
  fail "Cannot check theme because src/theme/mauriTheme.ts missing"
fi

section "14. IMPORT WIRING CHECKS"

check_import_path "app/login.tsx" "../src/components/AppShell" "Login AppShell"
check_import_path "app/dashboard.tsx" "../src/components/AppShell" "Dashboard AppShell"
check_import_path "app/chat.tsx" "../src/components/AppShell" "Chat AppShell"
check_import_path "app/settings.tsx" "../src/components/AppShell" "Settings AppShell"
check_import_path "app/add-friend.tsx" "../src/components/AppShell" "Add Friend AppShell"
check_import_path "app/living-mesh.tsx" "../src/components/AppShell" "Living Mesh AppShell"
check_import_path "app/mesh-status.tsx" "../src/components/AppShell" "Mesh Status AppShell"
check_import_path "app/pixel-calling.tsx" "../src/components/AppShell" "Pixel Calling AppShell"

check_import_path "app/dashboard.tsx" "../src/lib/meshClient" "Dashboard mesh client"
check_import_path "app/living-mesh.tsx" "../src/lib/meshClient" "Living Mesh mesh client"
check_import_path "app/mesh-status.tsx" "../src/lib/meshClient" "Mesh Status mesh client"

section "15. PACKAGE SCRIPT CHECKS"

if [ -f "$ROOT/package.json" ]; then
  node -e '
const fs = require("fs");
const p = JSON.parse(fs.readFileSync("package.json", "utf8"));
const scripts = p.scripts || {};
const deps = {...(p.dependencies || {}), ...(p.devDependencies || {})};

function out(kind, msg){ console.log(kind + ": " + msg); }

if (scripts.start) out("PASS", "package.json has start script: " + scripts.start);
else out("FAIL", "package.json missing start script");

if (scripts.typecheck || scripts.check) out("PASS", "package.json has typecheck/check script");
else out("WARN", "package.json missing typecheck/check script");

if (deps["expo-router"]) out("PASS", "expo-router dependency found");
else out("WARN", "expo-router dependency not found in package.json");

if (deps["expo"]) out("PASS", "expo dependency found");
else out("WARN", "expo dependency not found in package.json");

if (deps["react-native"]) out("PASS", "react-native dependency found");
else out("WARN", "react-native dependency not found in package.json");

if (deps["express"]) out("PASS", "express dependency found");
else out("WARN", "express dependency missing; server/index.ts needs express if API server is used");

if (deps["tsx"]) out("PASS", "tsx dependency found");
else out("WARN", "tsx dependency missing; server/index.ts needs tsx for local run");
' | while IFS= read -r line; do
    case "$line" in
      PASS:*) pass "${line#PASS: }" ;;
      FAIL:*) fail "${line#FAIL: }" ;;
      WARN:*) warn "${line#WARN: }" ;;
      *) log "$line" ;;
    esac
  done
fi

section "16. TYPESCRIPT CONFIG CHECK"

if [ -f "$ROOT/tsconfig.json" ]; then
  pass "tsconfig.json found"
else
  warn "tsconfig.json missing. Expo can generate defaults, but final checking is stronger with tsconfig.json."
fi

section "17. STATIC ROUTE COMPILE SANITY"

ROUTE_FILES=(
  "app/_layout.tsx"
  "app/index.tsx"
  "app/login.tsx"
  "app/dashboard.tsx"
  "app/chat.tsx"
  "app/settings.tsx"
  "app/add-friend.tsx"
  "app/living-mesh.tsx"
  "app/mesh-status.tsx"
  "app/pixel-calling.tsx"
)

for f in "${ROUTE_FILES[@]}"; do
  if [ -f "$ROOT/$f" ]; then
    if grep -Eq "export default function|export default" "$ROOT/$f"; then
      pass "$f has default export"
    else
      fail "$f missing default export"
    fi
  fi
done

section "18. TYPESCRIPT CHECK"

TYPECHECK_RAN="no"
TYPECHECK_OK="unknown"

if command -v npx >/dev/null 2>&1; then
  if [ -f "$ROOT/package.json" ]; then
    TYPECHECK_RAN="yes"
    log "Running: npx tsc --noEmit"
    if npx tsc --noEmit >> "$REPORT" 2>&1; then
      TYPECHECK_OK="yes"
      pass "TypeScript passed: npx tsc --noEmit"
    else
      TYPECHECK_OK="no"
      fail "TypeScript failed. See report: $REPORT"
    fi
  else
    warn "Skipping TypeScript because package.json missing"
  fi
else
  warn "npx not found; skipping TypeScript check"
fi

section "19. EXPO DOCTOR / CONFIG CHECK"

EXPO_CHECK_RAN="no"
EXPO_CHECK_OK="unknown"

if command -v npx >/dev/null 2>&1 && [ -f "$ROOT/package.json" ]; then
  EXPO_CHECK_RAN="yes"

  log "Running: npx expo config --type public"
  if npx expo config --type public >> "$REPORT" 2>&1; then
    EXPO_CHECK_OK="yes"
    pass "Expo config resolved"
  else
    EXPO_CHECK_OK="no"
    warn "Expo config check failed or Expo CLI unavailable. See report."
  fi
else
  warn "Skipping Expo config check"
fi

section "20. OPTIONAL API SERVER STATIC CHECK"

if [ -f "$ROOT/server/index.ts" ]; then
  if contains "$ROOT/server/index.ts" "app.listen"; then
    pass "server/index.ts starts Express listener"
  else
    warn "server/index.ts exists but app.listen not found"
  fi

  if contains "$ROOT/server/index.ts" "0.0.0.0"; then
    pass "server/index.ts binds to 0.0.0.0 for Replit"
  else
    warn "server/index.ts may not bind to 0.0.0.0"
  fi
fi

section "21. FINAL UI COMPLETION SCORE"

TOTAL_CHECKS=$((PASS_COUNT + FAIL_COUNT + WARN_COUNT))

if [ "$TOTAL_CHECKS" -gt 0 ]; then
  SCORE=$((PASS_COUNT * 100 / TOTAL_CHECKS))
else
  SCORE=0
fi

log "Total checks: $TOTAL_CHECKS"
log "Passed: $PASS_COUNT"
log "Warnings: $WARN_COUNT"
log "Failed: $FAIL_COUNT"
log "Completion score: $SCORE%"

FINAL_STATUS="INCOMPLETE"

if [ "$FAIL_COUNT" -eq 0 ] && [ "$WARN_COUNT" -eq 0 ]; then
  FINAL_STATUS="COMPLETE"
elif [ "$FAIL_COUNT" -eq 0 ]; then
  FINAL_STATUS="COMPLETE_WITH_WARNINGS"
else
  FINAL_STATUS="INCOMPLETE"
fi

log "Final status: $FINAL_STATUS"

section "22. FINAL DECISION"

if [ "$FINAL_STATUS" = "COMPLETE" ]; then
  log "RESULT: FINAL UI SCREENS ARE COMPLETE."
  log "All required route screens, core components, routing, API fallback, and TypeScript checks passed."
elif [ "$FINAL_STATUS" = "COMPLETE_WITH_WARNINGS" ]; then
  log "RESULT: FINAL UI SCREENS ARE BASICALLY COMPLETE, BUT WARNINGS REMAIN."
  log "Warnings usually mean optional API/server/config hardening is missing, not necessarily a broken UI."
else
  log "RESULT: FINAL UI SCREENS ARE NOT COMPLETE."
  log "Fix all FAIL lines in this report, then run this checker again."
fi

cat > "$JSON" <<JSON
{
  "project": "MauriMesh Messenger",
  "checker": "final-ui-completion",
  "timestamp": "$STAMP",
  "total_checks": $TOTAL_CHECKS,
  "passed": $PASS_COUNT,
  "warnings": $WARN_COUNT,
  "failed": $FAIL_COUNT,
  "completion_score_percent": $SCORE,
  "typecheck_ran": "$TYPECHECK_RAN",
  "typecheck_ok": "$TYPECHECK_OK",
  "expo_check_ran": "$EXPO_CHECK_RAN",
  "expo_check_ok": "$EXPO_CHECK_OK",
  "final_status": "$FINAL_STATUS",
  "report_file": "$REPORT"
}
JSON

section "23. REPORT FILES CREATED"

log "Text report: $REPORT"
log "JSON report: $JSON"

echo ""
echo "============================================================"
echo "MAURIMESH FINAL UI CHECK COMPLETE"
echo "Status: $FINAL_STATUS"
echo "Score:  $SCORE%"
echo "Report: $REPORT"
echo "JSON:   $JSON"
echo "============================================================"
echo ""

if [ "$FAIL_COUNT" -gt 0 ]; then
  exit 1
else
  exit 0
fi
