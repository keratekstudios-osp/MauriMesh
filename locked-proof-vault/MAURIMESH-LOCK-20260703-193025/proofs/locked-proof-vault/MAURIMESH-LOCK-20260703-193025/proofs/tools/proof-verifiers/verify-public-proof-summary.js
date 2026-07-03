const fs = require("fs");
const path = require("path");

const root = process.cwd();

const requiredFiles = [
  "docs/public-proof-summary/README.txt",
  "docs/public-proof-summary/MAURIMESH_PUBLIC_PROOF_SUMMARY.md",
  "docs/public-proof-summary/MAURIMESH_PUBLIC_PROOF_SUMMARY.json"
];

const requiredText = [
  "Store-Forward Proof",
  "PASS",
  "proof-checkpoint/MMSF-RAW-LIVE-001",
  "proof/store-forward-raw-device-MMSF-RAW-LIVE-001",
  "6ce0f88cbb4d6572c221eafc2b540cb19bfa7a86",
  "NOT PUBLISHED",
  "main branch was intentionally left untouched"
];

const forbiddenPublicText = [
  "6088e2bb906df9f7c4bd2c1246715b047e43b698db40b1026a7bfe981208afe8",
  "/Users/maurimesh/maurimesh-raw-evidence",
  "maurimesh-raw-device-proof-MMSF-RAW-LIVE-001.tar.gz"
];

let failures = [];

for (const file of requiredFiles) {
  const full = path.join(root, file);
  if (!fs.existsSync(full)) {
    failures.push(`missing file: ${file}`);
    continue;
  }

  const text = fs.readFileSync(full, "utf8");

  for (const required of requiredText) {
    if (file.endsWith(".md") && !text.includes(required)) {
      failures.push(`missing required public text "${required}" in ${file}`);
    }
  }

  for (const forbidden of forbiddenPublicText) {
    if (text.includes(forbidden)) {
      failures.push(`forbidden sensitive text found in ${file}: ${forbidden}`);
    }
  }
}

try {
  const matrix = JSON.parse(fs.readFileSync(path.join(root, "docs/public-proof-summary/MAURIMESH_PUBLIC_PROOF_SUMMARY.json"), "utf8"));
  if (matrix.publicVerdict !== "PASS") failures.push("json publicVerdict is not PASS");
  if (matrix.remoteMainTouched !== false) failures.push("json remoteMainTouched must be false");
  if (matrix.publicReleasePublished !== false) failures.push("json publicReleasePublished must be false");
  if (matrix.publicBoundary.rawEvidenceArchive !== "withheld") failures.push("json rawEvidenceArchive boundary not withheld");
} catch (err) {
  failures.push(`json parse failed: ${err.message}`);
}

if (failures.length) {
  console.log("");
  console.log("============================================================");
  console.log("PUBLIC PROOF SUMMARY VERDICT: FAIL");
  console.log("============================================================");
  for (const failure of failures) console.log("FAIL:", failure);
  process.exit(1);
}

console.log("");
console.log("============================================================");
console.log("PUBLIC PROOF SUMMARY VERDICT: PASS");
console.log("============================================================");
console.log("Folder: docs/public-proof-summary");
console.log("Public release: NOT PUBLISHED");
console.log("Remote main: UNTOUCHED");
console.log("============================================================");
