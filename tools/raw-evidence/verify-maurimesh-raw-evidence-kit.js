#!/usr/bin/env node
const fs = require("fs");
const path = require("path");

const root = process.cwd();

const required = [
  "docs/raw-device-evidence-kit/README.md",
  "docs/raw-device-evidence-kit/RAW_DEVICE_EVIDENCE_RUN_CHECKLIST.md",
  "docs/raw-device-evidence-kit/RAW_DEVICE_EVIDENCE_STANDARD.md",
  "tools/raw-evidence/capture-maurimesh-raw-device-evidence.sh",
  "tools/raw-evidence/verify-maurimesh-raw-evidence-run.js",
  "tools/raw-evidence/verify-maurimesh-raw-evidence-kit.js"
];

const missing = required.filter((rel) => !fs.existsSync(path.join(root, rel)));

console.log("");
console.log("============================================================");
console.log("MAURIMESH RAW-DEVICE EVIDENCE KIT VERIFY");
console.log("============================================================");

if (missing.length) {
  console.log("RAW DEVICE KIT VERDICT: FAIL");
  console.log("Missing:");
  console.log(JSON.stringify(missing, null, 2));
  console.log("============================================================");
  console.log("");
  process.exit(1);
}

console.log("RAW DEVICE KIT VERDICT: PASS");
console.log("Reason: Capture script, run verifier, and documentation exist.");
console.log("============================================================");
console.log("");
