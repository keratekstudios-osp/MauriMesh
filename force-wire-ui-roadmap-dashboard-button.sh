#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "FORCE WIRE UI ROADMAP BUTTON TO DASHBOARD"
echo "Target: app/dashboard.tsx"
echo "Route:  /ui-roadmap"
echo "Mode: safe backup + smart patch + fallback rebuild"
echo "============================================================"
echo ""

ROOT="$(pwd)"
DASH="$ROOT/app/dashboard.tsx"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$ROOT/backup-before-force-ui-roadmap-button-$STAMP"

if [ ! -f "$ROOT/package.json" ]; then
  echo "ERROR: package.json not found. Run this from the Replit project root."
  exit 1
fi

if [ ! -d "$ROOT/app" ]; then
  echo "ERROR: app folder not found."
  exit 1
fi

if [ ! -f "$ROOT/app/ui-roadmap.tsx" ]; then
  echo "ERROR: app/ui-roadmap.tsx not found."
  echo "Run this first:"
  echo "  ./design-maurimesh-ui-remainder.sh"
  exit 1
fi

mkdir -p "$BACKUP"

if [ -f "$DASH" ]; then
  cp "$DASH" "$BACKUP/dashboard.tsx"
  echo "Backup saved: $BACKUP/dashboard.tsx"
else
  echo "WARN: app/dashboard.tsx missing. Creating new dashboard."
fi

node <<'NODE'
const fs = require("fs");

const dashPath = "app/dashboard.tsx";

const button = `<MauriButton title="UI Roadmap" onPress={() => router.push("/ui-roadmap")} />`;

function writeFallbackDashboard(reason) {
  const fallback = `import { useRouter } from "expo-router";
import React, { useEffect, useState } from "react";
import { StyleSheet, Text, View } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { MauriButton } from "../src/components/MauriButton";
import { MeshSignalCard } from "../src/components/MeshSignalCard";
import { getMeshStatus, MeshStatus } from "../src/lib/meshClient";
import { mauriTheme } from "../src/theme/mauriTheme";

export default function DashboardScreen() {
  const router = useRouter();
  const [mesh, setMesh] = useState<MeshStatus | null>(null);

  useEffect(() => {
    getMeshStatus().then(setMesh).catch(() => {
      setMesh({
        mode: "SIMULATION",
        message: "Mesh status unavailable. Showing safe dashboard fallback.",
        nodes: [],
        routes: [],
      });
    });
  }, []);

  const mode = mesh?.mode || "UNAVAILABLE";

  return (
    <AppShell>
      <Text style={styles.title}>Dashboard</Text>
      <Text style={styles.subtitle}>
        MauriMesh command centre for messenger UI, mesh visibility, proof layers,
        governance, route design, and remaining UI completion.
      </Text>

      <MeshSignalCard
        title="Mesh Status"
        value={mesh?.message || "Checking mesh status..."}
        status={mode}
      />

      <View style={styles.grid}>
        <MauriButton title="Chat" onPress={() => router.push("/chat")} />
        <MauriButton title="Living Mesh" onPress={() => router.push("/living-mesh")} />
        <MauriButton title="Mesh Status" onPress={() => router.push("/mesh-status")} />
        <MauriButton title="Add Friend" onPress={() => router.push("/add-friend")} />
        <MauriButton title="Pixel Calling" onPress={() => router.push("/pixel-calling")} />
        <MauriButton title="Settings" onPress={() => router.push("/settings")} />

        <MauriButton title="UI Roadmap" onPress={() => router.push("/ui-roadmap")} />
      </View>

      <View style={styles.notice}>
        <Text style={styles.noticeTitle}>Final Truth</Text>
        <Text style={styles.noticeText}>
          Replit can complete UI, routing shells, API fallback, and simulation views.
          Real BLE, native Bluetooth scanning, QR camera proof, and phone-to-phone ACK
          still require APK/device proof.
        </Text>
      </View>
    </AppShell>
  );
}

const styles = StyleSheet.create({
  title: {
    color: mauriTheme.colors.white,
    fontSize: 36,
    fontWeight: "900",
  },
  subtitle: {
    color: mauriTheme.colors.mutedWhite,
    fontSize: 15,
    lineHeight: 22,
  },
  grid: {
    gap: mauriTheme.spacing.md,
  },
  notice: {
    borderWidth: 1,
    borderColor: mauriTheme.colors.panelBorder,
    backgroundColor: mauriTheme.colors.panel,
    borderRadius: mauriTheme.radius.xl,
    padding: mauriTheme.spacing.lg,
    gap: mauriTheme.spacing.sm,
  },
  noticeTitle: {
    color: mauriTheme.colors.greenstone,
    fontSize: 16,
    fontWeight: "900",
  },
  noticeText: {
    color: mauriTheme.colors.mutedWhite,
    fontSize: 13,
    lineHeight: 20,
  },
});
`;

  fs.writeFileSync(dashPath, fallback);
  console.log("Fallback dashboard written.");
  console.log("Reason:", reason);
}

if (!fs.existsSync(dashPath)) {
  writeFallbackDashboard("dashboard file was missing");
  process.exit(0);
}

let src = fs.readFileSync(dashPath, "utf8");

if (src.includes("/ui-roadmap")) {
  console.log("UI Roadmap route already exists in dashboard.");
  process.exit(0);
}

let patched = false;

// Make sure router exists.
if (!src.includes("useRouter")) {
  if (src.includes('from "expo-router"')) {
    src = src.replace(/import\s+\{([^}]+)\}\s+from\s+["']expo-router["'];/, (m, names) => {
      if (names.includes("useRouter")) return m;
      return `import {${names.trim()}, useRouter } from "expo-router";`;
    });
  } else {
    src = `import { useRouter } from "expo-router";\n${src}`;
  }
}

if (!src.includes("const router = useRouter()") && !src.includes("const router = useRouter();")) {
  src = src.replace(
    /export default function\s+[A-Za-z0-9_]*\s*\([^)]*\)\s*\{/,
    (m) => `${m}\n  const router = useRouter();`
  );
}

// Pattern 1: insert after Settings button.
const settingsRegex = /(\s*<MauriButton[^>]*title=["']Settings["'][\s\S]*?\/>)/;
if (!patched && settingsRegex.test(src)) {
  src = src.replace(settingsRegex, `$1\n        ${button}`);
  patched = true;
}

// Pattern 2: insert before closing grid view after last MauriButton.
if (!patched) {
  const lastButtonIndex = src.lastIndexOf("<MauriButton");
  if (lastButtonIndex !== -1) {
    const closeIndex = src.indexOf("/>", lastButtonIndex);
    if (closeIndex !== -1) {
      const insertAt = closeIndex + 2;
      src = src.slice(0, insertAt) + `\n        ${button}` + src.slice(insertAt);
      patched = true;
    }
  }
}

// Pattern 3: insert before AppShell close if screen has AppShell.
if (!patched && src.includes("</AppShell>")) {
  src = src.replace(
    "</AppShell>",
    `  <View style={{ gap: 12 }}>\n        ${button}\n      </View>\n    </AppShell>`
  );
  patched = true;
}

// Final fallback if structure is too custom.
if (!patched) {
  writeFallbackDashboard("dashboard structure was too custom to patch safely");
  process.exit(0);
}

fs.writeFileSync(dashPath, src);
console.log("Inserted UI Roadmap button into existing dashboard.");
NODE

echo ""
echo "Running TypeScript check..."
if command -v npx >/dev/null 2>&1; then
  if npx tsc --noEmit; then
    echo "TypeScript passed."
  else
    echo ""
    echo "TypeScript failed after patch."
    echo "Your original dashboard backup is here:"
    echo "$BACKUP/dashboard.tsx"
    exit 1
  fi
else
  echo "WARN: npx not found. Skipping TypeScript check."
fi

echo ""
echo "============================================================"
echo "DONE"
echo "Dashboard now has:"
echo "  UI Roadmap -> /ui-roadmap"
echo ""
echo "Backup:"
echo "  $BACKUP/dashboard.tsx"
echo ""
echo "Now open:"
echo "  Login -> Open Dashboard -> UI Roadmap"
echo "============================================================"
