#!/usr/bin/env bash
set -e

echo "=================================================="
echo "REPAIR CORRUPTED package.json"
echo "Restore from backup, preserve app source"
echo "=================================================="

echo ""
echo "1. Current package.json first lines"
head -20 package.json 2>/dev/null || echo "package.json missing"

echo ""
echo "2. Find valid backup package.json files"
node <<'NODE'
const fs = require("fs");
const cp = require("child_process");

let files = [];
try {
  files = cp.execSync(
    "find . -path '*/package.json' -not -path './node_modules/*' -not -path './.pnpm-store/*' -print",
    { encoding: "utf8" }
  ).trim().split("\n").filter(Boolean);
} catch {}

const valid = [];
for (const f of files) {
  try {
    const txt = fs.readFileSync(f, "utf8");
    const json = JSON.parse(txt);
    const score =
      (json.dependencies?.expo ? 10 : 0) +
      (json.dependencies?.["react-native"] ? 10 : 0) +
      (json.scripts ? 5 : 0) +
      (json.name ? 1 : 0);
    if (f !== "./package.json") valid.push({ f, score, name: json.name || "", scripts: Object.keys(json.scripts || {}) });
  } catch {}
}

valid.sort((a, b) => b.score - a.score || b.f.localeCompare(a.f));

if (!valid.length) {
  console.log("NO_VALID_BACKUP_PACKAGE_JSON_FOUND");
  process.exit(2);
}

console.log("Best backup:", valid[0].f);
console.log("Score:", valid[0].score);
console.log("Name:", valid[0].name);
console.log("Scripts:", valid[0].scripts.join(", "));

fs.copyFileSync(valid[0].f, "package.json");
console.log("RESTORED package.json from", valid[0].f);
NODE

echo ""
echo "3. Patch required scripts and packageManager safely"
node <<'NODE'
const fs = require("fs");
const p = JSON.parse(fs.readFileSync("package.json", "utf8"));

p.scripts = p.scripts || {};
p.scripts.dev = p.scripts.dev || "tsx server/index.ts";
p.scripts["expo:start"] = p.scripts["expo:start"] || "npx expo start --clear --port 8082";

if (p.packageManager && /^pnpm@10\./.test(p.packageManager)) {
  p.packageManager = "pnpm@9.15.4";
}
if (!p.packageManager) {
  p.packageManager = "pnpm@9.15.4";
}

fs.writeFileSync("package.json", JSON.stringify(p, null, 2) + "\n");
console.log("package.json repaired");
console.log("name:", p.name);
console.log("packageManager:", p.packageManager);
console.log("scripts:", p.scripts);
NODE

echo ""
echo "4. Validate core JSON"
node <<'NODE'
const fs = require("fs");
for (const f of ["package.json", "eas.json", "app.json", "tsconfig.json"]) {
  try {
    JSON.parse(fs.readFileSync(f, "utf8"));
    console.log(f + " OK");
  } catch (e) {
    console.log(f + " BAD: " + e.message);
    process.exitCode = 1;
  }
}
NODE

echo ""
echo "5. Confirm Native BLE repair still present"
grep -RniE "class MauriMeshBleModule|class MauriMeshBlePackage|MauriMeshBlePackage\\(\\)" android/app/src/main/java/com/maurimesh/messenger 2>/dev/null

echo ""
echo "6. TypeScript"
npx tsc --noEmit

echo ""
echo "7. Export"
rm -rf dist .expo
npx expo export --platform android --clear

echo ""
echo "=================================================="
echo "package.json REPAIRED — READY FOR EAS"
echo "=================================================="
