#!/usr/bin/env node
const fs = require("fs");
const path = require("path");

const root = process.cwd();

const requiredFiles = [
  "scripts/proof-capture/maurimesh-raw-device-evidence-run.sh",
  "tools/proof-verifiers/verify-maurimesh-raw-evidence-run.js",
  "tools/proof-verifiers/verify-maurimesh-raw-device-evidence-kit.js",
  "docs/raw-device-evidence-kit/README.md",
  "docs/raw-device-evidence-kit/RAW_DEVICE_EVIDENCE_RUN_CHECKLIST.md",
  "docs/raw-device-evidence-kit/RAW_DEVICE_EVIDENCE_BOUNDARY.md"
];

function fail(reason, details = {}) {
  console.log("");
  console.log("============================================================");
  console.log("MAURIMESH RAW-DEVICE EVIDENCE KIT VERIFY");
  console.log("============================================================");
  console.log("RAW DEVICE KIT VERDICT: FAIL");
  console.log(`Reason: ${reason}`);
  if (Object.keys(details).length) console.log(JSON.stringify(details, null, 2));
  console.log("============================================================");
  console.log("");
  process.exit(1);
}

const missing = requiredFiles.filter((rel) => !fs.existsSync(path.join(root, rel)));

if (missing.length) {
  fail("Required kit files missing.", { missing });
}

console.log("");
console.log("============================================================");
console.log("MAURIMESH RAW-DEVICE EVIDENCE KIT VERIFY");
console.log("============================================================");
console.log("RAW DEVICE KIT VERDICT: PASS");
console.log("Status : READY_TO_CAPTURE");
console.log("Reason : Capture script, raw evidence verifier, checklist, and boundary document exist.");
console.log("============================================================");
console.log("");
