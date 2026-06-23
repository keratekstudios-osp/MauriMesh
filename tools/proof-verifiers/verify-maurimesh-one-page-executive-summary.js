#!/usr/bin/env node
const fs = require("fs");
const path = require("path");

const root = process.cwd();

const requiredFiles = [
  "docs/proof-index/MAURIMESH_MASTER_PROOF_INDEX.json",
  "docs/investor-proof-pack/MAURIMESH_PROOF_PACK_INDEX.json",
  "docs/investor-proof-pack/MAURIMESH_ONE_PAGE_EXECUTIVE_SUMMARY.md",
  "docs/investor-proof-pack/MAURIMESH_ONE_PAGE_EXECUTIVE_SUMMARY.txt"
];

function fail(reason, details = {}) {
  console.log("");
  console.log("============================================================");
  console.log("MAURIMESH ONE-PAGE EXECUTIVE SUMMARY VERIFY");
  console.log("============================================================");
  console.log("ONE-PAGE SUMMARY VERDICT: FAIL");
  console.log(`Reason: ${reason}`);
  if (Object.keys(details).length) {
    console.log(JSON.stringify(details, null, 2));
  }
  console.log("============================================================");
  console.log("");
  process.exit(1);
}

const missing = requiredFiles.filter((rel) => !fs.existsSync(path.join(root, rel)));

if (missing.length > 0) {
  fail("Required summary files missing.", { missing });
}

const md = fs.readFileSync(
  path.join(root, "docs/investor-proof-pack/MAURIMESH_ONE_PAGE_EXECUTIVE_SUMMARY.md"),
  "utf8"
);

const requiredText = [
  "MMSF-TEJFNH-K3FKYM",
  "Store-Forward Delay Proof",
  "A06 sender",
  "S10 stores packet",
  "A16 is unavailable",
  "A16 returns",
  "A06 receives final ACK",
  "not yet independent third-party certification",
  "synchronized raw-device evidence run"
];

const missingText = requiredText.filter((text) => !md.includes(text));

if (missingText.length > 0) {
  fail("One-page summary is missing required proof language.", { missingText });
}

const master = JSON.parse(
  fs.readFileSync(path.join(root, "docs/proof-index/MAURIMESH_MASTER_PROOF_INDEX.json"), "utf8")
);

if (!Array.isArray(master.milestones) || master.milestones.length < 5) {
  fail("Master proof index does not contain at least 5 milestones.");
}

const notPassed = master.milestones.filter((m) => m.status !== "PASSED");

if (notPassed.length > 0) {
  fail("One or more master proof milestones are not PASSED.", { notPassed });
}

console.log("");
console.log("============================================================");
console.log("MAURIMESH ONE-PAGE EXECUTIVE SUMMARY VERIFY");
console.log("============================================================");
console.log("ONE-PAGE SUMMARY VERDICT: PASS");
console.log(`Project    : ${master.project}`);
console.log(`Milestones : ${master.milestones.length}`);
console.log("Status     : READY_FOR_REVIEW");
console.log("Reason     : One-page summary exists, includes required proof language, and matches the passed master proof index.");
console.log("============================================================");
console.log("");
