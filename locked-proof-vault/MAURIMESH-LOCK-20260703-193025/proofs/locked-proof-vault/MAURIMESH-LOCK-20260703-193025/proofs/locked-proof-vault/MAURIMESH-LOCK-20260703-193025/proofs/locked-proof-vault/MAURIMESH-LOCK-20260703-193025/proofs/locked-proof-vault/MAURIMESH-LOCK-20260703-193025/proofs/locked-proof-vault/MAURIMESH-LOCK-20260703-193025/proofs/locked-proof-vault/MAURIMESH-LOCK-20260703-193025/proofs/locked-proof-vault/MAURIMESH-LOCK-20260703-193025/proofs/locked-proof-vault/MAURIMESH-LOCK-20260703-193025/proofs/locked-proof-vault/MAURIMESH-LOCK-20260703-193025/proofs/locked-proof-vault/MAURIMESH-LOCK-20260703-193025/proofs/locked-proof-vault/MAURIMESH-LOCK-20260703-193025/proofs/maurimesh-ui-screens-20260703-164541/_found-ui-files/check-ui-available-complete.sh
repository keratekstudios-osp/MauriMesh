#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH UI AVAILABLE + COMPLETE CHECKLIST"
echo "Checks screens, components, dashboard buttons, labels, and TypeScript"
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
DOCS="$ROOT/docs"
mkdir -p "$DOCS"

REPORT="$DOCS/ui-available-complete-checklist-$STAMP.md"
LATEST="$DOCS/ui-available-complete-checklist-latest.md"
JSON="$DOCS/ui-available-complete-checklist-$STAMP.json"

PASS=0
FAIL=0
WARN=0

line() {
  echo "$1" | tee -a "$REPORT"
}

pass() {
  PASS=$((PASS+1))
  line "- [x] $1"
}

fail() {
  FAIL=$((FAIL+1))
  line "- [ ] MISSING: $1"
}

warn() {
  WARN=$((WARN+1))
  line "- [!] PARTIAL: $1"
}

has_file() {
  local file="$1"
  [ -f "$ROOT/$file" ]
}

has_text() {
  local file="$1"
  local text="$2"
  [ -f "$ROOT/$file" ] && grep -Fq "$text" "$ROOT/$file"
}

check_screen() {
  local file="$1"
  local title="$2"
  local route="$3"

  if has_file "$file"; then
    pass "$title screen exists: $file"
  else
    fail "$title screen file missing: $file"
    return
  fi

  if grep -Eq "export default function|export default" "$ROOT/$file"; then
    pass "$title has default export"
  else
    fail "$title missing default export"
  fi

  if has_text "$file" "$title"; then
    pass "$title screen title/text found"
  else
    warn "$title screen exists but title text not clearly found"
  fi

  if has_file "app/dashboard.tsx"; then
    if has_text "app/dashboard.tsx" "$route"; then
      pass "$title route is wired from Dashboard: $route"
    else
      warn "$title route not found in Dashboard: $route"
    fi
  else
    fail "Cannot check Dashboard wiring because app/dashboard.tsx missing"
  fi
}

check_component() {
  local file="$1"
  local name="$2"

  if has_file "$file"; then
    pass "$name component exists: $file"
  else
    fail "$name component missing: $file"
    return
  fi

  if has_text "$file" "export function $name" || has_text "$file" "export const $name"; then
    pass "$name component exports correctly"
  else
    warn "$name exists but export pattern not confirmed"
  fi
}

check_truth_label() {
  local file="$1"
  local label="$2"
  shift 2

  if ! has_file "$file"; then
    fail "$label cannot be checked because $file is missing"
    return
  fi

  for word in "$@"; do
    if has_text "$file" "$word"; then
      pass "$label truth label found: $word"
      return
    fi
  done

  warn "$label missing clear truth label"
}

: > "$REPORT"

line "# MauriMesh UI Available + Complete Checklist"
line ""
line "Generated: $STAMP"
line ""

line "## 1. Root Project"
if has_file "package.json"; then pass "package.json exists"; else fail "package.json missing"; fi
if [ -d "$ROOT/app" ]; then pass "app/ route folder exists"; else fail "app/ route folder missing"; fi
if [ -d "$ROOT/src" ]; then pass "src/ source folder exists"; else fail "src/ source folder missing"; fi
if [ -d "$ROOT/src/components" ]; then pass "src/components exists"; else fail "src/components missing"; fi
if [ -d "$ROOT/src/lib" ]; then pass "src/lib exists"; else fail "src/lib missing"; fi
if [ -d "$ROOT/src/theme" ]; then pass "src/theme exists"; else fail "src/theme missing"; fi

line ""
line "## 2. Core Required Screens"
check_screen "app/login.tsx" "MauriMesh" "/login"
check_screen "app/dashboard.tsx" "Dashboard" "/dashboard"
check_screen "app/chat.tsx" "Chat" "/chat"
check_screen "app/settings.tsx" "Settings" "/settings"
check_screen "app/add-friend.tsx" "Add Friend" "/add-friend"
check_screen "app/living-mesh.tsx" "Living Mesh" "/living-mesh"
check_screen "app/mesh-status.tsx" "Mesh Status" "/mesh-status"
check_screen "app/pixel-calling.tsx" "Pixel Calling" "/pixel-calling"

line ""
line "## 3. Final / Remaining UI Screens"
check_screen "app/ui-roadmap.tsx" "What Is Left To Create" "/ui-roadmap"
check_screen "app/proof-ledger.tsx" "Proof Ledger" "/proof-ledger"
check_screen "app/route-lab.tsx" "Route Lab" "/route-lab"
check_screen "app/tikanga-engine.tsx" "Tikanga Engine" "/tikanga-engine"
check_screen "app/self-healing.tsx" "Self-Healing" "/self-healing"
check_screen "app/device-proof.tsx" "Device Proof" "/device-proof"
check_screen "app/operator-console.tsx" "Operator Console" "/operator-console"
check_screen "app/mauricore-governance.tsx" "MauriCore Governance" "/mauricore-governance"
check_screen "app/mauricore-ble-runtime.tsx" "MauriCore BLE Runtime" "/mauricore-ble-runtime"

line ""
line "## 4. Core Components"
check_component "src/components/AppShell.tsx" "AppShell"
check_component "src/components/MauriButton.tsx" "MauriButton"
check_component "src/components/StatusPill.tsx" "StatusPill"
check_component "src/components/MeshSignalCard.tsx" "MeshSignalCard"
check_component "src/components/LivingMeshCanvas.tsx" "LivingMeshCanvas"
check_component "src/components/ChatBubble.tsx" "ChatBubble"

line ""
line "## 5. Final / Remaining Components"
check_component "src/components/UiRoadmapCard.tsx" "UiRoadmapCard"
check_component "src/components/ProofLedgerPanel.tsx" "ProofLedgerPanel"
check_component "src/components/RouteDecisionPanel.tsx" "RouteDecisionPanel"
check_component "src/components/TikangaDecisionCard.tsx" "TikangaDecisionCard"
check_component "src/components/SelfHealingPanel.tsx" "SelfHealingPanel"
check_component "src/components/DeviceProofCard.tsx" "DeviceProofCard"
check_component "src/components/MauriCoreStatusPanel.tsx" "MauriCoreStatusPanel"

line ""
line "## 6. Theme + Data + API"
if has_file "src/theme/mauriTheme.ts"; then pass "Mauri theme exists"; else fail "Mauri theme missing"; fi
if has_text "src/theme/mauriTheme.ts" "greenstone"; then pass "Theme includes greenstone"; else warn "Theme missing greenstone marker"; fi
if has_text "src/theme/mauriTheme.ts" "emerald"; then pass "Theme includes emerald"; else warn "Theme missing emerald marker"; fi

if has_file "src/lib/api.ts"; then pass "API client exists"; else fail "API client missing"; fi
if has_text "src/lib/api.ts" "EXPO_PUBLIC_MESH_API_URL"; then pass "API client supports EXPO_PUBLIC_MESH_API_URL"; else warn "API URL env marker missing"; fi

if has_file "src/lib/meshClient.ts"; then pass "Mesh client exists"; else fail "Mesh client missing"; fi
if has_text "src/lib/meshClient.ts" "SIMULATION"; then pass "Mesh client has simulation fallback"; else fail "Mesh client missing SIMULATION fallback"; fi

if has_file "src/lib/simulation.ts"; then pass "Simulation data exists"; else fail "Simulation data missing"; fi
if has_file "src/lib/uiRemainder.ts"; then pass "UI remainder data exists"; else warn "UI remainder data missing"; fi

line ""
line "## 7. Truth Labels / No Fake Live Claims"
check_truth_label "app/living-mesh.tsx" "Living Mesh" "SIMULATION" "simulation" "fallback"
check_truth_label "app/mesh-status.tsx" "Mesh Status" "SIMULATION" "UNAVAILABLE" "Checking"
check_truth_label "app/pixel-calling.tsx" "Pixel Calling" "UI SHELL" "SIMULATION" "requires native"
check_truth_label "app/add-friend.tsx" "Add Friend" "APK" "device" "Camera QR"
check_truth_label "app/device-proof.tsx" "Device Proof" "APK" "device" "logcat" "BLE"
check_truth_label "app/proof-ledger.tsx" "Proof Ledger" "SIMULATION" "DEVICE PROOF" "packet"

line ""
line "## 8. Dashboard Button Availability"

if has_file "app/dashboard.tsx"; then
  ROUTES=(
    "/chat"
    "/living-mesh"
    "/mesh-status"
    "/add-friend"
    "/pixel-calling"
    "/settings"
    "/ui-roadmap"
    "/proof-ledger"
    "/route-lab"
    "/tikanga-engine"
    "/self-healing"
    "/device-proof"
    "/operator-console"
    "/mauricore-governance"
    "/mauricore-ble-runtime"
  )

  for route in "${ROUTES[@]}"; do
    if has_text "app/dashboard.tsx" "$route"; then
      pass "Dashboard button/route found: $route"
    else
      warn "Dashboard route not found: $route"
    fi
  done
else
  fail "Dashboard missing, cannot check route buttons"
fi

line ""
line "## 9. Expo Router Essentials"
if has_file "app/_layout.tsx"; then pass "app/_layout.tsx exists"; else fail "app/_layout.tsx missing"; fi
if has_text "app/_layout.tsx" "Stack"; then pass "Expo Router Stack found"; else warn "Expo Router Stack not confirmed"; fi

if has_file "app/index.tsx"; then pass "app/index.tsx exists"; else fail "app/index.tsx missing"; fi
if has_text "app/index.tsx" "Redirect"; then pass "Index redirects to login"; else warn "Index redirect not confirmed"; fi

line ""
line "## 10. TypeScript Check"
TYPECHECK="not_run"

if command -v npx >/dev/null 2>&1 && has_file "package.json"; then
  line ""
  line "\`\`\`txt"
  if npx tsc --noEmit >> "$REPORT" 2>&1; then
    TYPECHECK="passed"
    line "\`\`\`"
    pass "TypeScript passed: npx tsc --noEmit"
  else
    TYPECHECK="failed"
    line "\`\`\`"
    fail "TypeScript failed. Read error output above."
  fi
else
  TYPECHECK="skipped"
  warn "TypeScript skipped because npx or package.json was unavailable"
fi

TOTAL=$((PASS + FAIL + WARN))
if [ "$TOTAL" -gt 0 ]; then
  SCORE=$((PASS * 100 / TOTAL))
else
  SCORE=0
fi

STATUS="INCOMPLETE"
if [ "$FAIL" -eq 0 ] && [ "$WARN" -eq 0 ]; then
  STATUS="COMPLETE"
elif [ "$FAIL" -eq 0 ]; then
  STATUS="AVAILABLE_WITH_PARTIALS"
else
  STATUS="MISSING_REQUIRED_UI"
fi

line ""
line "## Final Summary"
line ""
line "- Total checks: $TOTAL"
line "- Complete: $PASS"
line "- Partial: $WARN"
line "- Missing/failed: $FAIL"
line "- Score: $SCORE%"
line "- TypeScript: $TYPECHECK"
line "- Final UI status: **$STATUS**"
line ""

if [ "$STATUS" = "COMPLETE" ]; then
  line "✅ All checked UI screens are complete and available."
elif [ "$STATUS" = "AVAILABLE_WITH_PARTIALS" ]; then
  line "⚠️ UI is available, but some routes/components/truth labels are partial."
else
  line "❌ Required UI is not fully complete. Fix every MISSING line first."
fi

line ""
line "## Final Truth"
line ""
line "Replit can complete UI screens, routing shells, API fallback, and simulation views. Real BLE, native Bluetooth scanning, QR camera scanning, phone-to-phone ACK, and real calling transport still require APK/device proof."

cp "$REPORT" "$LATEST"

cat > "$JSON" <<JSON
{
  "project": "MauriMesh Messenger",
  "timestamp": "$STAMP",
  "total_checks": $TOTAL,
  "complete": $PASS,
  "partial": $WARN,
  "missing_or_failed": $FAIL,
  "score_percent": $SCORE,
  "typescript": "$TYPECHECK",
  "final_ui_status": "$STATUS",
  "report": "$REPORT",
  "latest_report": "$LATEST"
}
JSON

echo ""
echo "============================================================"
echo "UI CHECKLIST COMPLETE"
echo "============================================================"
echo "Status: $STATUS"
echo "Score:  $SCORE%"
echo ""
echo "Reports:"
echo "  $REPORT"
echo "  $LATEST"
echo "  $JSON"
echo ""
echo "Open latest report:"
echo "  cat $LATEST"
echo "============================================================"
echo ""

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
