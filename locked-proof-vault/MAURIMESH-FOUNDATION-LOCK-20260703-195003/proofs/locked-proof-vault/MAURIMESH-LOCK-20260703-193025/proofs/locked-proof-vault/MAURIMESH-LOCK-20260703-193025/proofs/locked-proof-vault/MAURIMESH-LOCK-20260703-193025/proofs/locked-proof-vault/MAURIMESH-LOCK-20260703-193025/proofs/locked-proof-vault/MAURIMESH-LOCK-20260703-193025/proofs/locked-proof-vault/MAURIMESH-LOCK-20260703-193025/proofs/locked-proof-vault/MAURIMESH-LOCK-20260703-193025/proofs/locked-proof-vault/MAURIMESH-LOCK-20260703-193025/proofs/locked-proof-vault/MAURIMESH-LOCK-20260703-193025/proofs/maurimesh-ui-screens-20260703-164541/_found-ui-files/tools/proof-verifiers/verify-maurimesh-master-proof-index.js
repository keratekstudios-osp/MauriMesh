#!/usr/bin/env node
const fs = require("fs");
const path = require("path");

const root = process.cwd();

const masterJson = path.join(root, "docs/proof-index/MAURIMESH_MASTER_PROOF_INDEX.json");
const masterMd = path.join(root, "docs/proof-index/MAURIMESH_MASTER_PROOF_INDEX.md");

const requiredFiles = [
  "docs/proof-index/MAURIMESH_MASTER_PROOF_INDEX.json",
  "docs/proof-index/MAURIMESH_MASTER_PROOF_INDEX.md",
  "docs/proof-archives/store-forward/store_forward_MMSF-TEJFNH-K3FKYM.log",
  "tools/proof-verifiers/verify-store-forward-proof.js",
  "docs/proof-certificates/store_forward_MMSF-TEJFNH-K3FKYM_certificate.md",
  "docs/proof-certificates/store_forward_MMSF-TEJFNH-K3FKYM_verifier_report.json",
  "docs/proof-certificates/store_forward_MMSF-TEJFNH-K3FKYM_hash_manifest.json",
  "docs/proof-certificates/store_forward_MMSF-TEJFNH-K3FKYM_hash_manifest.md",
  "tools/proof-verifiers/verify-store-forward-hash-manifest.js"
];

function fail(reason, details = {}) {
  console.log("");
  console.log("============================================================");
  console.log("MAURIMESH MASTER PROOF INDEX VERIFY");
  console.log("============================================================");
  console.log("MASTER INDEX VERDICT: FAIL");
  console.log(`Reason: ${reason}`);
  if (Object.keys(details).length) {
    console.log(JSON.stringify(details, null, 2));
  }
  console.log("============================================================");
  console.log("");
  process.exit(1);
}

if (!fs.existsSync(masterJson)) {
  fail("Master JSON index missing.", { masterJson });
}

if (!fs.existsSync(masterMd)) {
  fail("Master Markdown index missing.", { masterMd });
}

const index = JSON.parse(fs.readFileSync(masterJson, "utf8"));

if (index.project !== "MauriMesh") {
  fail("Project name mismatch.", { observed: index.project });
}

if (!Array.isArray(index.milestones) || index.milestones.length < 5) {
  fail("Expected at least 5 proof milestones.", {
    observedCount: Array.isArray(index.milestones) ? index.milestones.length : null
  });
}

const failedMilestones = index.milestones.filter((m) => m.status !== "PASSED");

if (failedMilestones.length > 0) {
  fail("One or more milestones are not PASSED.", { failedMilestones });
}

const missingFiles = requiredFiles.filter((rel) => !fs.existsSync(path.join(root, rel)));

if (missingFiles.length > 0) {
  fail("One or more required index/proof files are missing.", { missingFiles });
}

console.log("");
console.log("============================================================");
console.log("MAURIMESH MASTER PROOF INDEX VERIFY");
console.log("============================================================");
console.log("MASTER INDEX VERDICT: PASS");
console.log(`Project    : ${index.project}`);
console.log(`Milestones : ${index.milestones.length}`);
console.log("Reason     : Master proof index exists, required proof files exist, and all indexed milestones are marked PASSED.");
console.log("============================================================");
console.log("");
