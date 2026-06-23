#!/usr/bin/env node
const fs = require("fs");
const path = require("path");
const crypto = require("crypto");

const root = process.cwd();

const manifestJson = path.join(
  root,
  "docs/proof-certificates/store_forward_MMSF-TEJFNH-K3FKYM_hash_manifest.json"
);

function sha256File(absPath) {
  const data = fs.readFileSync(absPath);
  return crypto.createHash("sha256").update(data).digest("hex");
}

function fail(reason, details = {}) {
  console.log("");
  console.log("============================================================");
  console.log("MAURIMESH STORE-FORWARD HASH MANIFEST VERIFY");
  console.log("============================================================");
  console.log("HASH VERDICT: FAIL");
  console.log(`Reason: ${reason}`);
  if (Object.keys(details).length) {
    console.log(JSON.stringify(details, null, 2));
  }
  console.log("============================================================");
  console.log("");
  process.exit(1);
}

if (!fs.existsSync(manifestJson)) {
  fail("Hash manifest JSON not found.", { manifestJson });
}

const manifest = JSON.parse(fs.readFileSync(manifestJson, "utf8"));

if (manifest.packetId !== "MMSF-TEJFNH-K3FKYM") {
  fail("Packet ID mismatch inside manifest.", {
    expected: "MMSF-TEJFNH-K3FKYM",
    observed: manifest.packetId
  });
}

if (!Array.isArray(manifest.sealedFiles) || manifest.sealedFiles.length === 0) {
  fail("Manifest contains no sealed files.");
}

const checked = [];
const mismatches = [];

for (const record of manifest.sealedFiles) {
  const absPath = path.join(root, record.relativePath);

  if (!fs.existsSync(absPath)) {
    mismatches.push({
      relativePath: record.relativePath,
      reason: "File missing"
    });
    continue;
  }

  const stat = fs.statSync(absPath);
  const currentHash = sha256File(absPath);

  const result = {
    relativePath: record.relativePath,
    expectedSizeBytes: record.sizeBytes,
    currentSizeBytes: stat.size,
    expectedSha256: record.sha256,
    currentSha256: currentHash,
    pass: record.sizeBytes === stat.size && record.sha256 === currentHash
  };

  checked.push(result);

  if (!result.pass) {
    mismatches.push(result);
  }
}

if (mismatches.length > 0) {
  fail("One or more sealed proof files changed.", {
    packetId: manifest.packetId,
    mismatches
  });
}

console.log("");
console.log("============================================================");
console.log("MAURIMESH STORE-FORWARD HASH MANIFEST VERIFY");
console.log("============================================================");
console.log("HASH VERDICT: PASS");
console.log(`Packet : ${manifest.packetId}`);
console.log(`Files  : ${checked.length}`);
console.log("Reason : All sealed proof files match the original SHA-256 manifest.");
console.log("============================================================");
console.log("");
