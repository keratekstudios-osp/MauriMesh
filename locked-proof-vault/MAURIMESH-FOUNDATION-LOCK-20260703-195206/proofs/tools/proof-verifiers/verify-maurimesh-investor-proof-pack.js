#!/usr/bin/env node
const fs = require("fs");
const path = require("path");

const root = process.cwd();

const requiredFiles = [
  "docs/proof-index/MAURIMESH_MASTER_PROOF_INDEX.json",
  "docs/proof-index/MAURIMESH_MASTER_PROOF_INDEX.md",
  "docs/proof-archives/store-forward/store_forward_MMSF-TEJFNH-K3FKYM.log",
  "tools/proof-verifiers/verify-store-forward-proof.js",
  "tools/proof-verifiers/verify-store-forward-hash-manifest.js",
  "tools/proof-verifiers/verify-maurimesh-master-proof-index.js",
  "docs/proof-certificates/store_forward_MMSF-TEJFNH-K3FKYM_certificate.md",
  "docs/proof-certificates/store_forward_MMSF-TEJFNH-K3FKYM_verifier_report.json",
  "docs/proof-certificates/store_forward_MMSF-TEJFNH-K3FKYM_hash_manifest.json",
  "docs/proof-certificates/store_forward_MMSF-TEJFNH-K3FKYM_hash_manifest.md",
  "docs/investor-proof-pack/MAURIMESH_INVESTOR_PROOF_PACK.md",
  "docs/investor-proof-pack/MAURIMESH_DUE_DILIGENCE_SUMMARY.md",
  "docs/investor-proof-pack/MAURIMESH_TECHNICAL_PROOF_SUMMARY.md",
  "docs/investor-proof-pack/MAURIMESH_PROOF_LIMITS_AND_NEXT_STEPS.md",
  "docs/investor-proof-pack/MAURIMESH_PROOF_PACK_INDEX.json",
  "docs/investor-proof-pack/README.md"
];

function fail(reason, details = {}) {
  console.log("");
  console.log("============================================================");
  console.log("MAURIMESH INVESTOR PROOF PACK VERIFY");
  console.log("============================================================");
  console.log("PROOF PACK VERDICT: FAIL");
  console.log(`Reason: ${reason}`);
  if (Object.keys(details).length) {
    console.log(JSON.stringify(details, null, 2));
  }
  console.log("============================================================");
  console.log("");
  process.exit(1);
}

const missingFiles = requiredFiles.filter((rel) => !fs.existsSync(path.join(root, rel)));

if (missingFiles.length > 0) {
  fail("One or more required proof pack files are missing.", { missingFiles });
}

const master = JSON.parse(
  fs.readFileSync(path.join(root, "docs/proof-index/MAURIMESH_MASTER_PROOF_INDEX.json"), "utf8")
);

if (master.project !== "MauriMesh") {
  fail("Master proof index project mismatch.", { observed: master.project });
}

if (!Array.isArray(master.milestones) || master.milestones.length < 5) {
  fail("Master proof index does not contain at least 5 milestones.", {
    observed: Array.isArray(master.milestones) ? master.milestones.length : null
  });
}

const notPassed = master.milestones.filter((m) => m.status !== "PASSED");

if (notPassed.length > 0) {
  fail("One or more indexed milestones are not marked PASSED.", { notPassed });
}

const packIndex = JSON.parse(
  fs.readFileSync(path.join(root, "docs/investor-proof-pack/MAURIMESH_PROOF_PACK_INDEX.json"), "utf8")
);

if (packIndex.project !== "MauriMesh") {
  fail("Proof pack index project mismatch.", { observed: packIndex.project });
}

if (packIndex.status !== "READY_FOR_REVIEW") {
  fail("Proof pack status is not READY_FOR_REVIEW.", { observed: packIndex.status });
}

console.log("");
console.log("============================================================");
console.log("MAURIMESH INVESTOR PROOF PACK VERIFY");
console.log("============================================================");
console.log("PROOF PACK VERDICT: PASS");
console.log(`Project    : ${master.project}`);
console.log(`Milestones : ${master.milestones.length}`);
console.log("Status     : READY_FOR_REVIEW");
console.log("Reason     : Proof pack files exist, master proof index is valid, and all indexed milestones are PASSED.");
console.log("============================================================");
console.log("");
