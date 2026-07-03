#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "WIRE MAURICORE BLE RUNTIME DASHBOARD BUTTON"
echo "Target: app/dashboard.tsx"
echo "Route:  /mauricore-ble-runtime"
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
DASH="$ROOT/app/dashboard.tsx"
BACKUP="$ROOT/backup-before-mauricore-ble-runtime-button-$STAMP"

if [ ! -f "$ROOT/package.json" ]; then
  echo "ERROR: package.json not found. Run from /home/runner/workspace."
  exit 1
fi

if [ ! -f "$DASH" ]; then
  echo "ERROR: app/dashboard.tsx not found."
  exit 1
fi

if [ ! -f "$ROOT/app/mauricore-ble-runtime.tsx" ]; then
  echo "ERROR: app/mauricore-ble-runtime.tsx missing."
  exit 1
fi

mkdir -p "$BACKUP"
cp "$DASH" "$BACKUP/dashboard.tsx.before"

node <<'NODE'
const fs = require("fs");
const path = require("path");

const root = process.cwd();
const dash = path.join(root, "app/dashboard.tsx");
let s = fs.readFileSync(dash, "utf8");

const route = "/mauricore-ble-runtime";

if (s.includes(route) && s.includes("MauriCore Android BLE Runtime")) {
  console.log("Dashboard already contains MauriCore Android BLE Runtime route and label.");
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
        onPress={() => router.push("/mauricore-ble-runtime")}
        style={{
          minHeight: 52,
          borderRadius: 14,
          backgroundColor: "rgba(56,189,248,0.14)",
          borderWidth: 1,
          borderColor: "rgba(56,189,248,0.38)",
          justifyContent: "center",
          paddingHorizontal: 16,
          marginTop: 10,
          marginBottom: 10
        }}
      >
        <Text style={{ color: "#FFFFFF", fontWeight: "900", fontSize: 15 }}>
          MauriCore Android BLE Runtime
        </Text>
      </Pressable>
`;

let inserted = false;

const governance = s.indexOf("MauriCore Governance");
if (governance !== -1) {
  const afterGovernancePressable = s.indexOf("</Pressable>", governance);
  if (afterGovernancePressable !== -1) {
    const insertAt = afterGovernancePressable + "</Pressable>".length;
    s = s.slice(0, insertAt) + "\n" + button + s.slice(insertAt);
    inserted = true;
  }
}

if (!inserted) {
  const backHome = s.indexOf("Back Home");
  if (backHome !== -1) {
    const insertAt = s.lastIndexOf("<Pressable", backHome);
    if (insertAt !== -1) {
      s = s.slice(0, insertAt) + button + "\n" + s.slice(insertAt);
      inserted = true;
    }
  }
}

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
console.log("Inserted MauriCore Android BLE Runtime button into app/dashboard.tsx");
NODE

echo ""
echo "1. Verify button wiring"
grep -n "MauriCore Android BLE Runtime" "$DASH" || true
grep -n "mauricore-ble-runtime" "$DASH" || true

echo ""
echo "2. Run TypeScript"
npm run mauricore:check

echo ""
echo "3. Run MauriCore smoke test"
npm run mauricore:test

echo ""
echo "4. Run Expo Android export"
npx expo export --platform android --output-dir dist-mauricore-ble-runtime-button

echo ""
echo "============================================================"
echo "DONE"
echo "Dashboard should now show:"
echo "  MauriCore Android BLE Runtime"
echo "============================================================"
