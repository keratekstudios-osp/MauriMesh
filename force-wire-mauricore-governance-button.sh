#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "FORCE WIRE MAURICORE GOVERNANCE BUTTON"
echo "Target: app/dashboard.tsx"
echo "Route:  /mauricore-governance"
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
DASH="$ROOT/app/dashboard.tsx"
BACKUP="$ROOT/backup-before-force-mauricore-button-$STAMP"

if [ ! -f "$ROOT/package.json" ]; then
  echo "ERROR: package.json not found. Run from /home/runner/workspace."
  exit 1
fi

if [ ! -f "$DASH" ]; then
  echo "ERROR: app/dashboard.tsx not found."
  exit 1
fi

if [ ! -f "$ROOT/app/mauricore-governance.tsx" ]; then
  echo "ERROR: app/mauricore-governance.tsx missing."
  exit 1
fi

if [ ! -f "$ROOT/src/mauricore/dashboard/MauriCoreGovernanceScreen.tsx" ]; then
  echo "ERROR: MauriCoreGovernanceScreen.tsx missing."
  exit 1
fi

mkdir -p "$BACKUP"
cp "$DASH" "$BACKUP/dashboard.tsx.before"

echo "Backup:"
echo "  $BACKUP/dashboard.tsx.before"

node <<'NODE'
const fs = require("fs");
const path = require("path");

const root = process.cwd();
const dash = path.join(root, "app/dashboard.tsx");
let s = fs.readFileSync(dash, "utf8");

const route = "/mauricore-governance";

if (s.includes(route) && s.includes("MauriCore Governance")) {
  console.log("Dashboard already contains MauriCore Governance route and label.");
  process.exit(0);
}

if (!s.includes("useRouter")) {
  s = s.replace(
    /import React[^;]*;/,
    (m) => `${m}\nimport { useRouter } from "expo-router";`
  );
}

if (!s.includes("router = useRouter")) {
  s = s.replace(
    /(export default function[^{]+{)/,
    `$1\n  const router = useRouter();`
  );
}

const button = `
      <Pressable
        onPress={() => router.push("/mauricore-governance")}
        style={{
          minHeight: 52,
          borderRadius: 14,
          backgroundColor: "rgba(0,208,132,0.18)",
          borderWidth: 1,
          borderColor: "rgba(0,208,132,0.45)",
          justifyContent: "center",
          paddingHorizontal: 16,
          marginTop: 10,
          marginBottom: 10
        }}
      >
        <Text style={{ color: "#FFFFFF", fontWeight: "900", fontSize: 15 }}>
          MauriCore Governance
        </Text>
      </Pressable>
`;

let inserted = false;

// Best position: before Back Home button
const backHome = s.indexOf("Back Home");
if (backHome !== -1) {
  const insertAt = s.lastIndexOf("<Pressable", backHome);
  if (insertAt !== -1) {
    s = s.slice(0, insertAt) + button + "\n" + s.slice(insertAt);
    inserted = true;
  }
}

// Fallback: before end of ScrollView
if (!inserted) {
  const scrollClose = s.lastIndexOf("</ScrollView>");
  if (scrollClose !== -1) {
    s = s.slice(0, scrollClose) + button + "\n" + s.slice(scrollClose);
    inserted = true;
  }
}

if (!inserted) {
  throw new Error("Could not find safe insertion point in app/dashboard.tsx");
}

fs.writeFileSync(dash, s);
console.log("Inserted MauriCore Governance button into app/dashboard.tsx");
NODE

echo ""
echo "1. Verify route files"
test -f "$ROOT/app/mauricore-governance.tsx" && echo "PASS: app/mauricore-governance.tsx"
test -f "$ROOT/src/mauricore/dashboard/MauriCoreGovernanceScreen.tsx" && echo "PASS: src/mauricore/dashboard/MauriCoreGovernanceScreen.tsx"
grep -n "MauriCore Governance" "$DASH" || true
grep -n "mauricore-governance" "$DASH" || true

echo ""
echo "2. Run TypeScript"
npm run mauricore:check

echo ""
echo "3. Run MauriCore smoke test"
npm run mauricore:test

echo ""
echo "4. Run Expo Android export"
npx expo export --platform android --output-dir dist-mauricore-button-check

echo ""
echo "============================================================"
echo "DONE"
echo "Now restart/open the app, go to Dashboard, and look for:"
echo "  MauriCore Governance"
echo "============================================================"
