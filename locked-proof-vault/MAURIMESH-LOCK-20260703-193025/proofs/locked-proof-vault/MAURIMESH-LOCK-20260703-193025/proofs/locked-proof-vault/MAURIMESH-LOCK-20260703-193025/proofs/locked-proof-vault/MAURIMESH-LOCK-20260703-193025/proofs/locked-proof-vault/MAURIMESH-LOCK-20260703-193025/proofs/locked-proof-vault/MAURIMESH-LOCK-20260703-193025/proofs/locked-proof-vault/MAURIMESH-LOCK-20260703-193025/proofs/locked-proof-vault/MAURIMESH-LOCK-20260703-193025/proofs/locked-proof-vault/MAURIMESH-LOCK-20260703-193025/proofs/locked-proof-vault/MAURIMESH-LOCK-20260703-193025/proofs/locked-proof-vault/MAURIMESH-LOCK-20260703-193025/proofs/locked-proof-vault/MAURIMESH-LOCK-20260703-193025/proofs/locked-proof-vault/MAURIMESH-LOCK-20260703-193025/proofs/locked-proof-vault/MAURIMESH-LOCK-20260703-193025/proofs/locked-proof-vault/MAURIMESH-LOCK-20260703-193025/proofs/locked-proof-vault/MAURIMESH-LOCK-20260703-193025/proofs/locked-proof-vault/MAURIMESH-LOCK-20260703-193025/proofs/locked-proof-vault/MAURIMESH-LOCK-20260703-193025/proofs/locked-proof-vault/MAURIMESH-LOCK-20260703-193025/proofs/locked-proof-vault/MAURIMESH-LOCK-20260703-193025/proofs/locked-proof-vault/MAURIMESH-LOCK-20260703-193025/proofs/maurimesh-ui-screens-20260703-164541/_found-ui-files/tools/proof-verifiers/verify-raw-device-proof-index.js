const fs = require("fs");
const path = require("path");

const root = process.cwd();
const packetId = "MMSF-RAW-LIVE-001";
const sha256 = "6088e2bb906df9f7c4bd2c1246715b047e43b698db40b1026a7bfe981208afe8";

const requiredFiles = [
  `docs/proof-certificates/raw_device_${packetId}_certificate.md`,
  `docs/proof-certificates/raw_device_${packetId}_certificate.json`,
  "docs/proof-index/MAURIMESH_MASTER_PROOF_INDEX.md",
  "docs/proof-index/MAURIMESH_MASTER_PROOF_INDEX.json",
  "docs/investor-proof-pack/RAW_DEVICE_EVIDENCE_APPENDIX.md"
];

let failures = [];

for (const file of requiredFiles) {
  const full = path.join(root, file);
  if (!fs.existsSync(full)) {
    failures.push(`missing file: ${file}`);
  }
}

for (const file of requiredFiles.filter(f => fs.existsSync(path.join(root, f)))) {
  const text = fs.readFileSync(path.join(root, file), "utf8");
  if (!text.includes(packetId)) failures.push(`packet ID missing from ${file}`);
  if (file.includes("certificate") || file.includes("RAW_DEVICE") || file.includes("MASTER")) {
    if (!text.includes(sha256)) failures.push(`SHA-256 missing from ${file}`);
  }
  if (!text.includes("PASS")) failures.push(`PASS verdict missing from ${file}`);
}

const jsonPath = path.join(root, `docs/proof-certificates/raw_device_${packetId}_certificate.json`);
try {
  const cert = JSON.parse(fs.readFileSync(jsonPath, "utf8"));
  if (cert.packetId !== packetId) failures.push("certificate JSON packetId mismatch");
  if (cert.sha256 !== sha256) failures.push("certificate JSON sha256 mismatch");
  if (cert.verdict !== "PASS") failures.push("certificate JSON verdict mismatch");
} catch (err) {
  failures.push(`certificate JSON parse failed: ${err.message}`);
}

if (failures.length) {
  console.log("");
  console.log("============================================================");
  console.log("RAW DEVICE PROOF INDEX VERDICT: FAIL");
  console.log("============================================================");
  for (const failure of failures) console.log(`FAIL: ${failure}`);
  process.exit(1);
}

console.log("");
console.log("============================================================");
console.log("RAW DEVICE PROOF INDEX VERDICT: PASS");
console.log("============================================================");
console.log(`Packet ID: ${packetId}`);
console.log(`SHA-256: ${sha256}`);
console.log("Certificate: docs/proof-certificates/raw_device_MMSF-RAW-LIVE-001_certificate.md");
console.log("Master index: docs/proof-index/MAURIMESH_MASTER_PROOF_INDEX.md");
console.log("Investor appendix: docs/investor-proof-pack/RAW_DEVICE_EVIDENCE_APPENDIX.md");
console.log("============================================================");
