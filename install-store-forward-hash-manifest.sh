#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH STORE-FORWARD HASH MANIFEST INSTALL"
echo "Tamper-evident archive for packetId MMSF-TEJFNH-K3FKYM"
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
PACKET_ID="MMSF-TEJFNH-K3FKYM"

mkdir -p \
  "$ROOT/tools/proof-verifiers" \
  "$ROOT/docs/proof-certificates"

CREATE_MANIFEST="$ROOT/tools/proof-verifiers/create-store-forward-hash-manifest.js"
VERIFY_MANIFEST="$ROOT/tools/proof-verifiers/verify-store-forward-hash-manifest.js"
MANIFEST_JSON="$ROOT/docs/proof-certificates/store_forward_${PACKET_ID}_hash_manifest.json"
MANIFEST_MD="$ROOT/docs/proof-certificates/store_forward_${PACKET_ID}_hash_manifest.md"

backup_if_exists() {
  local file="$1"
  if [ -f "$file" ]; then
    cp "$file" "$file.backup-$STAMP"
    echo "Backup created: $file.backup-$STAMP"
  fi
}

backup_if_exists "$CREATE_MANIFEST"
backup_if_exists "$VERIFY_MANIFEST"
backup_if_exists "$MANIFEST_JSON"
backup_if_exists "$MANIFEST_MD"

cat > "$CREATE_MANIFEST" <<'JSEOF'
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
JSEOF

cat > "$VERIFY_MANIFEST" <<'JSEOF'
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
JSEOF

chmod +x "$CREATE_MANIFEST" "$VERIFY_MANIFEST"

echo ""
echo "Creating hash manifest..."
node "$CREATE_MANIFEST"

echo ""
echo "Verifying hash manifest..."
node "$VERIFY_MANIFEST"

echo ""
echo "============================================================"
echo "STORE-FORWARD HASH MANIFEST COMPLETE"
echo "============================================================"
echo "Manifest JSON:"
echo "$MANIFEST_JSON"
echo ""
echo "Manifest Markdown:"
echo "$MANIFEST_MD"
echo ""
echo "Expected result: HASH VERDICT: PASS"
echo "============================================================"
