const fs = require("fs");
const path = require("path");

const root = process.cwd();

const broadPatchedFiles = [
  "app/proof-2-hop.tsx",
  "app/store-forward-proof.tsx",
  "src/maurimesh/full-mesh-test/FullMeshTestEngine.ts",
  "src/maurimesh/proof/lockedProofVault.ts",
  "src/maurimesh/proofs/lockedProofRegistry.ts"
];

function exists(p) {
  return fs.existsSync(path.join(root, p));
}

function read(p) {
  return fs.readFileSync(path.join(root, p), "utf8");
}

function write(p, s) {
  fs.mkdirSync(path.dirname(path.join(root, p)), { recursive: true });
  fs.writeFileSync(path.join(root, p), s);
}

function allFiles(dir) {
  const abs = path.join(root, dir);
  if (!fs.existsSync(abs)) return [];
  let out = [];
  for (const entry of fs.readdirSync(abs, { withFileTypes: true })) {
    const full = path.join(abs, entry.name);
    if (entry.isDirectory()) out = out.concat(allFiles(path.relative(root, full)));
    else out.push(full);
  }
  return out;
}

function latestBackupFor(rel) {
  const backupRoot = path.join(root, "backups");
  if (!fs.existsSync(backupRoot)) return null;

  const candidates = allFiles("backups")
    .filter((abs) => abs.endsWith(rel))
    .map((abs) => {
      const stat = fs.statSync(abs);
      return { abs, mtime: stat.mtimeMs };
    })
    .sort((a, b) => b.mtime - a.mtime);

  return candidates.length ? candidates[0].abs : null;
}

function stripBadBridgeFragments(s) {
  // Remove helper blocks from broad patch.
  s = s.replace(/\/\* MAURIMESH_LOGCAT_BRIDGE_FIX_V2_START \*\/[\s\S]*?\/\* MAURIMESH_LOGCAT_BRIDGE_FIX_V2_END \*\/\n?/g, "");
  s = s.replace(/\/\* MAURIMESH_LOGCAT_BRIDGE_FIX_V1_START \*\/[\s\S]*?\/\* MAURIMESH_LOGCAT_BRIDGE_FIX_V1_END \*\/\n?/g, "");

  // Remove direct bridge fragments accidentally injected into string joins/templates.
  s = s.replace(/\\+n\s*\/\* MAURIMESH_LOGCAT_BRIDGE_DIRECT_[A-Z0-9_]+ \*\/ try \{ __mauriMeshStoreForwardLogcatBridge\([\s\S]*?\); \} catch \(_\) \{\}n?/g, "");
  s = s.replace(/\s*\/\* MAURIMESH_LOGCAT_BRIDGE_DIRECT_[A-Z0-9_]+ \*\/ try \{ __mauriMeshStoreForwardLogcatBridge\([\s\S]*?\); \} catch \(_\) \{\}n?/g, "");

  // Remove variable bridge calls from broad patch.
  s = s.replace(/\n?\s*\/\* MAURIMESH_LOGCAT_BRIDGE_VAR_V2 \*\/ try \{ __mauriMeshStoreForwardLogcatBridge\([\s\S]*?\); \} catch \(_\) \{\}/g, "");
  s = s.replace(/\n?\s*\/\* MAURIMESH_LOGCAT_BRIDGE_CALL_V2 \*\/ try \{ __mauriMeshStoreForwardLogcatBridge\([\s\S]*?\); \} catch \(_\) \{\}/g, "");

  return s;
}

const restored = [];
const fallbackCleaned = [];

for (const rel of broadPatchedFiles) {
  if (!exists(rel)) continue;

  const backup = latestBackupFor(rel);

  if (backup) {
    fs.copyFileSync(backup, path.join(root, rel));
    restored.push({ rel, backup: path.relative(root, backup) });
  } else {
    const before = read(rel);
    const after = stripBadBridgeFragments(before);
    if (after !== before) {
      write(rel, after);
      fallbackCleaned.push(rel);
    }
  }
}

const target = "app/store-forward-proof.tsx";

if (!exists(target)) {
  console.error("ERROR: app/store-forward-proof.tsx not found.");
  process.exit(1);
}

let s = read(target);

// Ensure any leftover broad-patch fragments are gone from the target.
s = stripBadBridgeFragments(s);

// Add one clean helper only.
if (!s.includes("MAURIMESH_SAFE_STORE_FORWARD_LOGCAT_BRIDGE_V1")) {
  const helper = `
/* MAURIMESH_SAFE_STORE_FORWARD_LOGCAT_BRIDGE_V1_START */
function mauriMeshEmitStoreForwardProofToLogcat(line: unknown) {
  try {
    const text = String(line ?? "");
    if (!text.includes("MAURIMESH_STORE_FORWARD_PROOF")) return;
    console.log(text);
    console.warn(text);
    console.error(text);
  } catch (_) {}
}
/* MAURIMESH_SAFE_STORE_FORWARD_LOGCAT_BRIDGE_V1_END */

`;

  const imports = [...s.matchAll(/^import .*?;\s*$/gm)];
  if (imports.length) {
    const last = imports[imports.length - 1];
    const at = last.index + last[0].length;
    s = s.slice(0, at) + helper + s.slice(at);
  } else {
    s = helper + s;
  }
}

// Insert emit calls after variable declarations that actually build MAURIMESH_STORE_FORWARD_PROOF lines.
// This is surgical: only app/store-forward-proof.tsx, only declarations containing the proof tag.
let patchCount = 0;
s = s.replace(
  /((?:const|let|var)\s+([A-Za-z_$][A-Za-z0-9_$]*)\s*=\s*(?:`[\s\S]*?MAURIMESH_STORE_FORWARD_PROOF[\s\S]*?`|"[^"\n]*MAURIMESH_STORE_FORWARD_PROOF[^"\n]*"|'[^'\n]*MAURIMESH_STORE_FORWARD_PROOF[^'\n]*')\s*;)(?!\s*\n\s*mauriMeshEmitStoreForwardProofToLogcat)/g,
  (m, statement, varName) => {
    patchCount++;
    return `${statement}\n  mauriMeshEmitStoreForwardProofToLogcat(${varName});`;
  }
);

// Also strengthen existing direct console.log proof lines by adding warn/error around the same text where safe.
s = s.replace(
  /console\.log\((`MAURIMESH_STORE_FORWARD_PROOF[\s\S]*?`)\);(?!\s*\n\s*console\.warn)/g,
  (m, arg) => {
    patchCount++;
    return `console.log(${arg});\n            console.warn(${arg});\n            console.error(${arg});`;
  }
);

s = s.replace(
  /console\.log\(("MAURIMESH_STORE_FORWARD_PROOF[^"]*")\);(?!\s*\n\s*console\.warn)/g,
  (m, arg) => {
    patchCount++;
    return `console.log(${arg});\n    console.warn(${arg});\n    console.error(${arg});`;
  }
);

write(target, s);

const filesToCheck = [
  "app/proof-2-hop.tsx",
  "app/store-forward-proof.tsx",
  "src/maurimesh/full-mesh-test/FullMeshTestEngine.ts",
  "src/maurimesh/proof/lockedProofVault.ts",
  "src/maurimesh/proofs/lockedProofRegistry.ts"
].filter(exists);

const badMarkers = [];
for (const rel of filesToCheck) {
  const text = read(rel);
  if (text.includes("MAURIMESH_LOGCAT_BRIDGE_DIRECT_")) badMarkers.push(rel);
}

const targetText = read(target);
const hasSafeBridge = targetText.includes("MAURIMESH_SAFE_STORE_FORWARD_LOGCAT_BRIDGE_V1");
const hasProofTag = targetText.includes("MAURIMESH_STORE_FORWARD_PROOF");

const report = {
  project: "MauriMesh",
  repair: "SAFE_STORE_FORWARD_LOGCAT_BRIDGE",
  status: badMarkers.length === 0 && hasSafeBridge && hasProofTag ? "PASS" : "FAIL",
  restored,
  fallbackCleaned,
  target,
  patchCount,
  badMarkers,
  hasSafeBridge,
  hasProofTag,
  next: "Run typecheck/build. If clean, rebuild APK and install on A06/S10/A16.",
  createdAt: new Date().toISOString()
};

write("docs/raw-device-evidence/SAFE_STORE_FORWARD_LOGCAT_BRIDGE_REPAIR_REPORT.json", JSON.stringify(report, null, 2));
write(
  "docs/raw-device-evidence/SAFE_STORE_FORWARD_LOGCAT_BRIDGE_REPAIR.md",
  `# Safe Store-Forward Logcat Bridge Repair

Status: **${report.status}**

Restored files:

${restored.map((x) => `- \`${x.rel}\` from \`${x.backup}\``).join("\n") || "- None"}

Fallback cleaned files:

${fallbackCleaned.map((x) => `- \`${x}\``).join("\n") || "- None"}

Target patched:

- \`${target}\`

Patch count: **${patchCount}**

Bad direct bridge markers remaining:

${badMarkers.map((x) => `- \`${x}\``).join("\n") || "- None"}

## Next

1. Run a build/type check.
2. Rebuild APK.
3. Install rebuilt APK on A06, S10, and A16.
4. Rerun Mac raw capture.
`
);

console.log("");
console.log("============================================================");
console.log("SAFE STORE-FORWARD LOGCAT BRIDGE REPAIR RESULT");
console.log("============================================================");
console.log("Status:", report.status);
console.log("Patch count:", patchCount);
console.log("Restored:", restored.length);
console.log("Fallback cleaned:", fallbackCleaned.length);
console.log("Bad direct markers remaining:", badMarkers.length);
if (badMarkers.length) {
  for (const f of badMarkers) console.log(" - " + f);
}
console.log("Report:");
console.log("docs/raw-device-evidence/SAFE_STORE_FORWARD_LOGCAT_BRIDGE_REPAIR.md");
console.log("============================================================");

if (report.status !== "PASS") {
  process.exit(1);
}
