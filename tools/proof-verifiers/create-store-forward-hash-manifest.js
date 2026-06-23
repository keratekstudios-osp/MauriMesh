#!/usr/bin/env node
const fs = require("fs");
const path = require("path");
const crypto = require("crypto");

const root = process.cwd();
const packetId = "MMSF-TEJFNH-K3FKYM";

const filesToSeal = [
  "docs/proof-archives/store-forward/store_forward_MMSF-TEJFNH-K3FKYM.log",
  "tools/proof-verifiers/verify-store-forward-proof.js",
  "docs/proof-certificates/store_forward_MMSF-TEJFNH-K3FKYM_certificate.md",
  "docs/proof-certificates/store_forward_MMSF-TEJFNH-K3FKYM_verifier_report.json"
];

const manifestJson = path.join(
  root,
  "docs/proof-certificates/store_forward_MMSF-TEJFNH-K3FKYM_hash_manifest.json"
);

const manifestMd = path.join(
  root,
  "docs/proof-certificates/store_forward_MMSF-TEJFNH-K3FKYM_hash_manifest.md"
);

function sha256File(absPath) {
  const data = fs.readFileSync(absPath);
  return crypto.createHash("sha256").update(data).digest("hex");
}

function fileRecord(relativePath) {
  const absPath = path.join(root, relativePath);

  if (!fs.existsSync(absPath)) {
    throw new Error(`Missing required proof archive file: ${relativePath}`);
  }

  const stat = fs.statSync(absPath);

  return {
    relativePath,
    sizeBytes: stat.size,
    sha256: sha256File(absPath)
  };
}

const sealedFiles = filesToSeal.map(fileRecord);

const manifest = {
  proofName: "MauriMesh Store-Forward Delay Proof",
  archiveStatus: "TAMPER_EVIDENT_HASH_MANIFEST_CREATED",
  packetId,
  createdAt: new Date().toISOString(),
  hashAlgorithm: "SHA-256",
  sealedFileCount: sealedFiles.length,
  sealedFiles,
  verificationRule:
    "Any later change to sealed files must produce a different SHA-256 hash and fail verification."
};

fs.mkdirSync(path.dirname(manifestJson), { recursive: true });
fs.writeFileSync(manifestJson, JSON.stringify(manifest, null, 2));

const rows = sealedFiles
  .map((file, index) => {
    return `| ${index + 1} | \`${file.relativePath}\` | ${file.sizeBytes} | \`${file.sha256}\` |`;
  })
  .join("\n");

const md = `# MauriMesh Store-Forward Delay Proof — Hash Manifest

## Proof Identity

- Proof: MauriMesh Store-Forward Delay Proof
- Packet ID: \`${packetId}\`
- Archive status: **Tamper-evident hash manifest created**
- Hash algorithm: **SHA-256**
- Created at: ${manifest.createdAt}

## Purpose

This manifest seals the cloned proof archive, verifier, external verifier certificate, and JSON verifier report.

If any sealed file is edited, replaced, truncated, or corrupted, its SHA-256 hash will change and the manifest verification will fail.

## Sealed Files

| # | File | Size bytes | SHA-256 |
|---:|---|---:|---|
${rows}

## Verification Rule

Run:

\`\`\`bash
node tools/proof-verifiers/verify-store-forward-hash-manifest.js
\`\`\`

Expected result:

\`\`\`text
HASH VERDICT: PASS
\`\`\`
`;

fs.writeFileSync(manifestMd, md);

console.log("");
console.log("============================================================");
console.log("MAURIMESH HASH MANIFEST CREATED");
console.log("============================================================");
console.log(`Packet : ${packetId}`);
console.log(`Files  : ${sealedFiles.length}`);
console.log(`JSON   : ${manifestJson}`);
console.log(`MD     : ${manifestMd}`);
console.log("============================================================");
console.log("");
