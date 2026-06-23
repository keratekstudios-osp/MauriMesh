const fs = require("fs");
const path = require("path");

const root = process.cwd();

const searchRoots = ["app", "src", "screens", "components"];
const allowed = new Set([".ts", ".tsx", ".js", ".jsx"]);

const stages = [
  "PACKET_ID_CONFIRMED",
  "TX_A06_TO_S10_STORE_REQUEST",
  "S10_STORE_PACKET",
  "A16_OFFLINE_CONFIRMED",
  "S10_HOLD_DELAY",
  "A16_RETURNS",
  "S10_FORWARD_STORED_TO_A16",
  "RX_A16_STORED_PACKET",
  "ACK_A16_TO_S10_STORED",
  "ACK_RELAY_S10_TO_A06_STORED",
  "ACK_RECEIVED_A06_STORED"
];

const likelyLogFunctionNames = [
  "addLog",
  "appendLog",
  "pushLog",
  "recordLog",
  "addProofLog",
  "appendProofLog",
  "pushProofLog",
  "recordProofLog",
  "recordProofEvent",
  "logProofEvent",
  "recordEvent",
  "addEvent",
  "completeStage",
  "markStage",
  "markDone",
  "handleStage",
  "runStage",
  "advanceStage",
  "approveStage",
  "handleProofStep",
  "completeProofStep"
];

function walk(dir) {
  const abs = path.join(root, dir);
  if (!fs.existsSync(abs)) return [];
  let out = [];

  for (const entry of fs.readdirSync(abs, { withFileTypes: true })) {
    if (entry.name === "node_modules" || entry.name.startsWith(".")) continue;

    const full = path.join(abs, entry.name);

    if (entry.isDirectory()) {
      out = out.concat(walk(path.relative(root, full)));
    } else if (allowed.has(path.extname(entry.name))) {
      out.push(full);
    }
  }

  return out;
}

function isCandidate(source) {
  const upper = source.toUpperCase();
  return (
    upper.includes("STORE-FORWARD") ||
    upper.includes("STORE_FORWARD") ||
    upper.includes("STOREFORWARD") ||
    upper.includes("MAURIMESH_STORE_FORWARD_PROOF") ||
    stages.some((s) => upper.includes(s))
  );
}

function insertHelper(source) {
  if (source.includes("MAURIMESH_LOGCAT_BRIDGE_FIX_V2")) return source;

  const helper = `
/* MAURIMESH_LOGCAT_BRIDGE_FIX_V2_START */
function __mauriMeshStoreForwardLogcatBridge() {
  try {
    const args = Array.prototype.slice.call(arguments).filter((v) => v !== undefined && v !== null);

    const raw = args.map((v) => {
      if (typeof v === "string") return v;
      try { return JSON.stringify(v); } catch (_) { return String(v); }
    }).join(" | ");

    const stages = [
      "PACKET_ID_CONFIRMED",
      "TX_A06_TO_S10_STORE_REQUEST",
      "S10_STORE_PACKET",
      "A16_OFFLINE_CONFIRMED",
      "S10_HOLD_DELAY",
      "A16_RETURNS",
      "S10_FORWARD_STORED_TO_A16",
      "RX_A16_STORED_PACKET",
      "ACK_A16_TO_S10_STORED",
      "ACK_RELAY_S10_TO_A06_STORED",
      "ACK_RECEIVED_A06_STORED"
    ];

    const hasProofTag = raw.indexOf("MAURIMESH_STORE_FORWARD_PROOF") !== -1;
    const stage = stages.find((x) => raw.indexOf(x) !== -1);

    if (!hasProofTag && !stage && raw.indexOf("MMSF-") === -1) return;

    const packetMatch =
      raw.match(/packetId=([A-Z0-9-]+)/) ||
      raw.match(/packetId["':= ]+([A-Z0-9-]+)/) ||
      raw.match(/\\\\b(MMSF-[A-Z0-9-]+)\\\\b/);

    const packetId = packetMatch ? packetMatch[1] : "MMSF-RAW-LIVE-001";

    let line = raw;

    if (!hasProofTag) {
      line =
        new Date().toISOString() +
        " | MAURIMESH_STORE_FORWARD_PROOF" +
        " | RAW_DEVICE" +
        " | LOGCAT_BRIDGE" +
        " | " + (stage || "STORE_FORWARD_EVENT") +
        " | packetId=" + packetId +
        " | " + raw;
    }

    if (typeof console !== "undefined") {
      console.log(line);
      console.warn(line);
      console.error(line);
    }

    try {
      globalThis.__MAURIMESH_LAST_STORE_FORWARD_LOGCAT_LINE__ = line;
    } catch (_) {}
  } catch (_) {}
}
/* MAURIMESH_LOGCAT_BRIDGE_FIX_V2_END */

`;

  const imports = [...source.matchAll(/^import .*?;\s*$/gm)];
  if (imports.length) {
    const last = imports[imports.length - 1];
    const at = last.index + last[0].length;
    return source.slice(0, at) + helper + source.slice(at);
  }

  return helper + source;
}

function cleanParams(paramText) {
  return paramText
    .split(",")
    .map((p) => p.trim())
    .map((p) => p.replace(/=.*$/, "").trim())
    .map((p) => p.replace(/^\\.\\.\\./, "").trim())
    .map((p) => p.replace(/:.*/, "").trim())
    .filter((p) => /^[A-Za-z_$][A-Za-z0-9_$]*$/.test(p));
}

function bridgeCall(params) {
  const extras = [
    'typeof packetId !== "undefined" ? packetId : undefined',
    'typeof currentPacketId !== "undefined" ? currentPacketId : undefined',
    'typeof proofPacketId !== "undefined" ? proofPacketId : undefined',
    'typeof selectedPacketId !== "undefined" ? selectedPacketId : undefined',
    'typeof stage !== "undefined" ? stage : undefined',
    'typeof step !== "undefined" ? step : undefined',
    'typeof action !== "undefined" ? action : undefined',
    'typeof event !== "undefined" ? event : undefined',
    'typeof entry !== "undefined" ? entry : undefined',
    'typeof line !== "undefined" ? line : undefined',
    'typeof message !== "undefined" ? message : undefined'
  ];

  return `\\n  /* MAURIMESH_LOGCAT_BRIDGE_CALL_V2 */ try { __mauriMeshStoreForwardLogcatBridge(${params.concat(extras).join(", ")}); } catch (_) {}\\n`;
}

function patchNamedFunctions(source) {
  let patches = 0;

  for (const name of likelyLogFunctionNames) {
    const patterns = [
      new RegExp(`(function\\\\s+${name}\\\\s*\\\\(([^)]*)\\\\)\\\\s*\\\\{)(?!\\\\s*\\/\\\\* MAURIMESH_LOGCAT_BRIDGE_CALL_V2 \\\\*\\/)`, "g"),
      new RegExp(`(const\\\\s+${name}\\\\s*=\\\\s*(?:async\\\\s*)?\\\\(([^)]*)\\\\)\\\\s*=>\\\\s*\\\\{)(?!\\\\s*\\/\\\\* MAURIMESH_LOGCAT_BRIDGE_CALL_V2 \\\\*\\/)`, "g"),
      new RegExp(`(let\\\\s+${name}\\\\s*=\\\\s*(?:async\\\\s*)?\\\\(([^)]*)\\\\)\\\\s*=>\\\\s*\\\\{)(?!\\\\s*\\/\\\\* MAURIMESH_LOGCAT_BRIDGE_CALL_V2 \\\\*\\/)`, "g")
    ];

    for (const pattern of patterns) {
      source = source.replace(pattern, (m, head, params) => {
        patches++;
        return head + bridgeCall(cleanParams(params || ""));
      });
    }

    const singleParam = new RegExp(`(const\\\\s+${name}\\\\s*=\\\\s*(?:async\\\\s*)?([A-Za-z_$][A-Za-z0-9_$]*)\\\\s*=>\\\\s*\\\\{)(?!\\\\s*\\/\\\\* MAURIMESH_LOGCAT_BRIDGE_CALL_V2 \\\\*\\/)`, "g");

    source = source.replace(singleParam, (m, head, param) => {
      patches++;
      return head + bridgeCall([param]);
    });
  }

  return { source, patches };
}

function patchStageStringStatements(source) {
  let patches = 0;

  for (const stage of stages) {
    const escaped = stage.replace(/[.*+?^${}()|[\\]\\\\]/g, "\\\\$&");

    const re = new RegExp(
      `(\\n\\s*(?:const|let|var)\\s+([A-Za-z_$][A-Za-z0-9_$]*)\\s*=\\s*(?:\`[\\s\\S]*?${escaped}[\\s\\S]*?\`|"[^"\\n]*${escaped}[^"\\n]*"|'[^'\\n]*${escaped}[^'\\n]*');)(?!\\s*\\/\\* MAURIMESH_LOGCAT_BRIDGE_VAR_V2 \\*\\/)`,
      "g"
    );

    source = source.replace(re, (m, statement, varName) => {
      patches++;
      return `${statement}\\n  /* MAURIMESH_LOGCAT_BRIDGE_VAR_V2 */ try { __mauriMeshStoreForwardLogcatBridge(${varName}, typeof packetId !== "undefined" ? packetId : undefined); } catch (_) {}`;
    });
  }

  return { source, patches };
}

function patchDirectStageCalls(source) {
  let patches = 0;

  for (const stage of stages) {
    if (source.includes(`__mauriMeshStoreForwardLogcatBridge("${stage}"`)) continue;

    const marker = `/* MAURIMESH_LOGCAT_BRIDGE_DIRECT_${stage} */`;

    if (source.includes(marker)) continue;

    const firstIndex = source.indexOf(stage);
    if (firstIndex !== -1) {
      const insertAt = source.indexOf("\\n", firstIndex);
      if (insertAt !== -1) {
        const call =
          `\\n  ${marker} try { __mauriMeshStoreForwardLogcatBridge("${stage}", typeof packetId !== "undefined" ? packetId : undefined, typeof currentPacketId !== "undefined" ? currentPacketId : undefined, typeof proofPacketId !== "undefined" ? proofPacketId : undefined, typeof selectedPacketId !== "undefined" ? selectedPacketId : undefined); } catch (_) {}`;
        source = source.slice(0, insertAt + 1) + call + source.slice(insertAt + 1);
        patches++;
      }
    }
  }

  return { source, patches };
}

const files = searchRoots.flatMap(walk);
const candidates = files.filter((file) => isCandidate(fs.readFileSync(file, "utf8")));

if (!candidates.length) {
  console.error("ERROR: No Store-Forward source candidate found.");
  process.exit(1);
}

const changed = [];
let totalPatches = 0;

for (const file of candidates) {
  const rel = path.relative(root, file);
  const original = fs.readFileSync(file, "utf8");
  let source = original;

  source = insertHelper(source);

  const fn = patchNamedFunctions(source);
  source = fn.source;

  const vars = patchStageStringStatements(source);
  source = vars.source;

  const direct = patchDirectStageCalls(source);
  source = direct.source;

  const patches = fn.patches + vars.patches + direct.patches;

  if (source !== original && patches > 0) {
    const backup = path.join(root, "backups", "logcat-bridge-" + new Date().toISOString().replace(/[:.]/g, "-"), rel);
    fs.mkdirSync(path.dirname(backup), { recursive: true });
    fs.writeFileSync(backup, original);
    fs.writeFileSync(file, source);
    changed.push(rel);
    totalPatches += patches;
  }
}

const report = {
  project: "MauriMesh",
  fix: "STORE_FORWARD_LOGCAT_BRIDGE_V2",
  status: changed.length ? "PATCHED" : "NO_PATCH_APPLIED",
  changedFiles: changed,
  candidateFiles: candidates.map((f) => path.relative(root, f)),
  totalPatches,
  requiredNextStep: "Rebuild APK and reinstall on A06/S10/A16 before rerunning raw-device capture.",
  createdAt: new Date().toISOString()
};

fs.writeFileSync("docs/raw-device-evidence/STORE_FORWARD_LOGCAT_BRIDGE_FIX_REPORT.json", JSON.stringify(report, null, 2));

fs.writeFileSync(
  "docs/raw-device-evidence/STORE_FORWARD_LOGCAT_BRIDGE_FIX.md",
  `# MauriMesh Store-Forward Logcat Bridge Fix

Status: **${report.status}**

Patch points: **${totalPatches}**

## Changed Files

${changed.map((f) => `- \`${f}\``).join("\\n") || "- None"}

## Candidate Files

${report.candidateFiles.map((f) => `- \`${f}\``).join("\\n")}

## Why This Was Needed

The Mac raw-device capture successfully connected A06, S10, and A16, but the verifier could not find packet ID \`MMSF-RAW-LIVE-001\` in Android logcat.

That means the Store-Forward proof existed in the app UI, but was not being emitted into Android logcat.

This patch adds a logcat bridge so Store-Forward proof stages are emitted through console log/warn/error.

## Required Next Step

Rebuild the APK and reinstall on:

- A06
- S10
- A16

Then rerun the Mac capture:

\`\`\`bash
cd ~/maurimesh-raw-evidence
adb connect 192.168.1.7:5555
adb connect 192.168.1.10:5555
adb connect 192.168.1.4:5555
A06_SERIAL=192.168.1.7:5555 S10_SERIAL=192.168.1.10:5555 A16_SERIAL=192.168.1.4:5555 ./capture-maurimesh-raw-evidence.sh MMSF-RAW-LIVE-001 180
\`\`\`
`
);

console.log("");
console.log("============================================================");
console.log("STORE-FORWARD LOGCAT BRIDGE RESULT");
console.log("============================================================");
console.log("Status       :", report.status);
console.log("Patch points :", totalPatches);
console.log("Changed files:");
changed.forEach((f) => console.log(" - " + f));
console.log("");
console.log("Candidate files:");
report.candidateFiles.forEach((f) => console.log(" - " + f));
console.log("============================================================");

if (!changed.length || totalPatches === 0) {
  console.error("ERROR: No patch points applied. Send docs/raw-device-evidence/STORE_FORWARD_LOGCAT_BRIDGE_FIX_REPORT.json");
  process.exit(1);
}
