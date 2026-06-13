const fs = require("fs");
const path = require("path");

const root = process.cwd();
const packetId = "MMSF-RAW-LIVE-001";
const rawSha = "6088e2bb906df9f7c4bd2c1246715b047e43b698db40b1026a7bfe981208afe8";

const files = [
  "docs/company-review-pack/MAURIMESH_FINAL_COMPANY_REVIEW_PACK.md",
  "docs/company-review-pack/MAURIMESH_PROOF_STATUS_LOCK.md",
  "docs/company-review-pack/MAURIMESH_PROOF_MATRIX.json",
  "docs/proof-certificates/raw_device_MMSF-RAW-LIVE-001_certificate.md",
  "docs/proof-index/MAURIMESH_MASTER_PROOF_INDEX.md",
  "docs/investor-proof-pack/RAW_DEVICE_EVIDENCE_APPENDIX.md"
];

let failures = [];

for (const file of files) {
  const full = path.join(root, file);
  if (!fs.existsSync(full)) {
    failures.push("missing: " + file);
    continue;
  }
  const text = fs.readFileSync(full, "utf8");
  if (!text.includes(packetId)) failures.push("packet ID missing: " + file);
  if (!text.includes("PASS")) failures.push("PASS missing: " + file);
  if (!text.includes(rawSha)) failures.push("SHA missing: " + file);
}

try {
  const matrix = JSON.parse(fs.readFileSync(path.join(root, "docs/company-review-pack/MAURIMESH_PROOF_MATRIX.json"), "utf8"));
  if (matrix.status !== "PASS") failures.push("matrix status not PASS");
  if (matrix.protected !== true) failures.push("matrix protected flag not true");
} catch (err) {
  failures.push("matrix JSON parse failed: " + err.message);
}

if (failures.length) {
  console.log("FINAL COMPANY REVIEW PACK VERDICT: FAIL");
  failures.forEach(f => console.log("FAIL:", f));
  process.exit(1);
}

console.log("");
console.log("============================================================");
console.log("FINAL COMPANY REVIEW PACK VERDICT: PASS");
console.log("============================================================");
console.log("Packet ID:", packetId);
console.log("SHA-256:", rawSha);
console.log("Folder: docs/company-review-pack");
console.log("============================================================");
