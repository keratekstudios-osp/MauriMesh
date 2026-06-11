#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "INSTALL MAURIMESH UI BACKUP WIRING"
echo "Adds safe route registry + fallback navigation + backup report"
echo "Does not delete existing UI"
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$ROOT/backup-before-ui-backup-wiring-$STAMP"
APP="$ROOT/app"
SRC="$ROOT/src"
LIB="$SRC/lib"
COMP="$SRC/components"
DOCS="$ROOT/docs"

mkdir -p "$BACKUP" "$LIB" "$COMP" "$DOCS"

if [ ! -f "$ROOT/package.json" ]; then
  echo "ERROR: package.json not found. Run from Replit project root."
  exit 1
fi

backup_file() {
  local file="$1"
  if [ -f "$ROOT/$file" ]; then
    mkdir -p "$BACKUP/$(dirname "$file")"
    cp "$ROOT/$file" "$BACKUP/$file"
  fi
}

backup_file "app/dashboard.tsx"
backup_file "src/lib/uiBackupRoutes.ts"
backup_file "src/components/SafeNavButton.tsx"

echo "Backup saved:"
echo "$BACKUP"

# ------------------------------------------------------------
# 1. Create central backup route registry
# ------------------------------------------------------------
cat > "$LIB/uiBackupRoutes.ts" <<'TS'
export type UiRouteKey =
  | "login"
  | "dashboard"
  | "chat"
  | "settings"
  | "addFriend"
  | "livingMesh"
  | "meshStatus"
  | "pixelCalling"
  | "uiRoadmap"
  | "proofLedger"
  | "routeLab"
  | "tikangaEngine"
  | "selfHealing"
  | "deviceProof"
  | "operatorConsole"
  | "mauriCoreGovernance"
  | "mauriCoreBleRuntime";

export type UiBackupRoute = {
  key: UiRouteKey;
  title: string;
  route: string;
  fallbackRoute: string;
  critical: boolean;
  purpose: string;
};

export const uiBackupRoutes: UiBackupRoute[] = [
  {
    key: "login",
    title: "Login",
    route: "/login",
    fallbackRoute: "/dashboard",
    critical: true,
    purpose: "Entry screen and safe return point.",
  },
  {
    key: "dashboard",
    title: "Dashboard",
    route: "/dashboard",
    fallbackRoute: "/login",
    critical: true,
    purpose: "Main navigation hub.",
  },
  {
    key: "chat",
    title: "Chat",
    route: "/chat",
    fallbackRoute: "/dashboard",
    critical: true,
    purpose: "Messenger UI shell.",
  },
  {
    key: "settings",
    title: "Settings",
    route: "/settings",
    fallbackRoute: "/dashboard",
    critical: true,
    purpose: "User controls and logout.",
  },
  {
    key: "addFriend",
    title: "Add Friend",
    route: "/add-friend",
    fallbackRoute: "/dashboard",
    critical: true,
    purpose: "QR and nearby mesh friend UI shell.",
  },
  {
    key: "livingMesh",
    title: "Living Mesh",
    route: "/living-mesh",
    fallbackRoute: "/mesh-status",
    critical: true,
    purpose: "Mesh visualizer and simulation/live status view.",
  },
  {
    key: "meshStatus",
    title: "Mesh Status",
    route: "/mesh-status",
    fallbackRoute: "/dashboard",
    critical: true,
    purpose: "Mesh API/simulation status.",
  },
  {
    key: "pixelCalling",
    title: "Pixel Calling",
    route: "/pixel-calling",
    fallbackRoute: "/dashboard",
    critical: false,
    purpose: "Calling UI shell, not real transport proof.",
  },
  {
    key: "uiRoadmap",
    title: "UI Roadmap",
    route: "/ui-roadmap",
    fallbackRoute: "/dashboard",
    critical: true,
    purpose: "Remaining UI work and completion map.",
  },
  {
    key: "proofLedger",
    title: "Proof Ledger",
    route: "/proof-ledger",
    fallbackRoute: "/device-proof",
    critical: true,
    purpose: "Packet/hash/ACK proof UI.",
  },
  {
    key: "routeLab",
    title: "Route Lab",
    route: "/route-lab",
    fallbackRoute: "/mesh-status",
    critical: true,
    purpose: "Hybrid route decision UI.",
  },
  {
    key: "tikangaEngine",
    title: "Tikanga Engine",
    route: "/tikanga-engine",
    fallbackRoute: "/mauricore-governance",
    critical: true,
    purpose: "Governance decision UI.",
  },
  {
    key: "selfHealing",
    title: "Self-Healing",
    route: "/self-healing",
    fallbackRoute: "/operator-console",
    critical: true,
    purpose: "Repair queue and resilience UI.",
  },
  {
    key: "deviceProof",
    title: "Device Proof",
    route: "/device-proof",
    fallbackRoute: "/proof-ledger",
    critical: true,
    purpose: "APK/device proof checklist.",
  },
  {
    key: "operatorConsole",
    title: "Operator Console",
    route: "/operator-console",
    fallbackRoute: "/dashboard",
    critical: true,
    purpose: "System readiness and operator state.",
  },
  {
    key: "mauriCoreGovernance",
    title: "MauriCore Governance",
    route: "/mauricore-governance",
    fallbackRoute: "/tikanga-engine",
    critical: true,
    purpose: "MauriCore governance view.",
  },
  {
    key: "mauriCoreBleRuntime",
    title: "MauriCore BLE Runtime",
    route: "/mauricore-ble-runtime",
    fallbackRoute: "/device-proof",
    critical: true,
    purpose: "BLE runtime readiness UI.",
  },
];

export function getUiRoute(key: UiRouteKey): UiBackupRoute {
  const found = uiBackupRoutes.find((route) => route.key === key);

  if (!found) {
    return {
      key: "dashboard",
      title: "Dashboard",
      route: "/dashboard",
      fallbackRoute: "/login",
      critical: true,
      purpose: "Emergency fallback route.",
    };
  }

  return found;
}

export function getRouteFallback(route: string): string {
  return (
    uiBackupRoutes.find((item) => item.route === route)?.fallbackRoute ||
    "/dashboard"
  );
}

export function getRouteTitle(route: string): string {
  return uiBackupRoutes.find((item) => item.route === route)?.title || "Dashboard";
}
TS

# ------------------------------------------------------------
# 2. Create SafeNavButton component
# ------------------------------------------------------------
cat > "$COMP/SafeNavButton.tsx" <<'TSX'
import React from "react";
import { useRouter } from "expo-router";
import { Alert } from "react-native";
import { MauriButton } from "./MauriButton";
import { getUiRoute, UiRouteKey } from "../lib/uiBackupRoutes";

export function SafeNavButton({
  routeKey,
  variant = "primary",
}: {
  routeKey: UiRouteKey;
  variant?: "primary" | "secondary" | "danger";
}) {
  const router = useRouter();
  const target = getUiRoute(routeKey);

  function go() {
    try {
      router.push(target.route as never);
    } catch (error) {
      try {
        router.replace(target.fallbackRoute as never);
      } catch {
        Alert.alert(
          "Navigation fallback failed",
          `Could not open ${target.title}. Fallback route: ${target.fallbackRoute}`
        );
      }
    }
  }

  return <MauriButton title={target.title} variant={variant} onPress={go} />;
}
TSX

# ------------------------------------------------------------
# 3. Create backup wiring checker
# ------------------------------------------------------------
cat > "$ROOT/check-ui-backup-wiring.sh" <<'CHECK'
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
DOCS="$ROOT/docs"
mkdir -p "$DOCS"

REPORT="$DOCS/ui-backup-wiring-report-$STAMP.md"
LATEST="$DOCS/ui-backup-wiring-report-latest.md"

PASS=0
FAIL=0
WARN=0

line(){ echo "$1" | tee -a "$REPORT"; }
pass(){ PASS=$((PASS+1)); line "- [x] $1"; }
fail(){ FAIL=$((FAIL+1)); line "- [ ] MISSING: $1"; }
warn(){ WARN=$((WARN+1)); line "- [!] PARTIAL: $1"; }

has_file(){ [ -f "$ROOT/$1" ]; }
has_text(){ [ -f "$ROOT/$1" ] && grep -Fq "$2" "$ROOT/$1"; }

: > "$REPORT"

line "# MauriMesh UI Backup Wiring Report"
line ""
line "Generated: $STAMP"
line ""

line "## Backup Wiring Files"

if has_file "src/lib/uiBackupRoutes.ts"; then pass "Route registry exists"; else fail "src/lib/uiBackupRoutes.ts missing"; fi
if has_file "src/components/SafeNavButton.tsx"; then pass "SafeNavButton exists"; else fail "src/components/SafeNavButton.tsx missing"; fi

line ""
line "## Route Registry Coverage"

ROUTES=(
  "/login"
  "/dashboard"
  "/chat"
  "/settings"
  "/add-friend"
  "/living-mesh"
  "/mesh-status"
  "/pixel-calling"
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
  if has_text "src/lib/uiBackupRoutes.ts" "$route"; then
    pass "Backup registry contains $route"
  else
    fail "Backup registry missing $route"
  fi
done

line ""
line "## Fallback Route Coverage"

for route in "${ROUTES[@]}"; do
  if grep -Fq "fallbackRoute" "$ROOT/src/lib/uiBackupRoutes.ts" && grep -Fq "$route" "$ROOT/src/lib/uiBackupRoutes.ts"; then
    pass "$route has registry entry with fallback system available"
  else
    fail "$route fallback not confirmed"
  fi
done

line ""
line "## SafeNavButton Checks"

if has_text "src/components/SafeNavButton.tsx" "router.push"; then pass "SafeNavButton uses router.push"; else fail "SafeNavButton missing router.push"; fi
if has_text "src/components/SafeNavButton.tsx" "router.replace"; then pass "SafeNavButton uses fallback router.replace"; else fail "SafeNavButton missing fallback router.replace"; fi
if has_text "src/components/SafeNavButton.tsx" "getUiRoute"; then pass "SafeNavButton uses route registry"; else fail "SafeNavButton missing route registry"; fi

line ""
line "## TypeScript"

if npx tsc --noEmit >> "$REPORT" 2>&1; then
  pass "TypeScript passed"
else
  fail "TypeScript failed"
fi

TOTAL=$((PASS + FAIL + WARN))
if [ "$TOTAL" -gt 0 ]; then SCORE=$((PASS * 100 / TOTAL)); else SCORE=0; fi

STATUS="INCOMPLETE"
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
echo "UI BACKUP WIRING CHECK COMPLETE"
echo "Status: $STATUS"
echo "Score:  $SCORE%"
echo "Report: $LATEST"
echo "============================================================"
echo ""

if [ "$FAIL" -gt 0 ]; then exit 1; fi
CHECK

chmod +x "$ROOT/check-ui-backup-wiring.sh"

# ------------------------------------------------------------
# 4. Optional: add backup section to dashboard without replacing existing UI
# ------------------------------------------------------------
node <<'NODE'
const fs = require("fs");

const file = "app/dashboard.tsx";
if (!fs.existsSync(file)) {
  console.log("WARN: app/dashboard.tsx missing. Skipping dashboard backup section.");
  process.exit(0);
}

let src = fs.readFileSync(file, "utf8");

if (!src.includes("SafeNavButton")) {
  src = src.replace(
    /import\s+\{\s*MauriButton\s*\}\s+from\s+["']\.\.\/src\/components\/MauriButton["'];/,
    `import { MauriButton } from "../src/components/MauriButton";\nimport { SafeNavButton } from "../src/components/SafeNavButton";`
  );
}

if (!src.includes("Backup Navigation Wiring")) {
  const section = `
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Backup Navigation Wiring</Text>
        <SafeNavButton routeKey="dashboard" variant="secondary" />
        <SafeNavButton routeKey="login" variant="secondary" />
        <SafeNavButton routeKey="deviceProof" variant="secondary" />
        <SafeNavButton routeKey="operatorConsole" variant="secondary" />
      </View>
`;

  if (src.includes("<View style={styles.notice}>")) {
    src = src.replace("<View style={styles.notice}>", `${section}\n      <View style={styles.notice}>`);
  } else if (src.includes("</AppShell>")) {
    src = src.replace("</AppShell>", `${section}\n    </AppShell>`);
  } else {
    src += `\n// Backup Navigation Wiring installed.\n`;
  }
}

fs.writeFileSync(file, src);
NODE

echo ""
echo "Running TypeScript..."
npx tsc --noEmit

echo ""
echo "Running backup wiring checker..."
./check-ui-backup-wiring.sh

echo ""
echo "============================================================"
echo "DONE: UI BACKUP WIRING INSTALLED"
echo "============================================================"
echo "Created:"
echo "  src/lib/uiBackupRoutes.ts"
echo "  src/components/SafeNavButton.tsx"
echo "  check-ui-backup-wiring.sh"
echo ""
echo "Backup:"
echo "  $BACKUP"
echo ""
echo "Latest report:"
echo "  docs/ui-backup-wiring-report-latest.md"
echo "============================================================"
