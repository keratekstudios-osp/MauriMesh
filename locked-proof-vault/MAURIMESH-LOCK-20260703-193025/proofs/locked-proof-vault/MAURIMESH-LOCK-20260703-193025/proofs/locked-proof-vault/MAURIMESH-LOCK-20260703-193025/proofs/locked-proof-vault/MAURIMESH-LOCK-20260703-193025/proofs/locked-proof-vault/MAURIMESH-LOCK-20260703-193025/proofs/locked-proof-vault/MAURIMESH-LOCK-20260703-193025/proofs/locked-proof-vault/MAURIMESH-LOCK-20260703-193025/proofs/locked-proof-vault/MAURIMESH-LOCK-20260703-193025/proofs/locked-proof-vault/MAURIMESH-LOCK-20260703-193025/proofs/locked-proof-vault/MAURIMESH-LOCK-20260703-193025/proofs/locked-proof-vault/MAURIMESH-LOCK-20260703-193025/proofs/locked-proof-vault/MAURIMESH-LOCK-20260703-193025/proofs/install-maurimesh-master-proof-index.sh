#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH MASTER PROOF INDEX INSTALL"
echo "2-device + 3-device + Store-forward + Verifier + Hash Manifest"
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"

mkdir -p \
  "$ROOT/docs/proof-index" \
  "$ROOT/docs/proof-certificates" \
  "$ROOT/tools/proof-verifiers"

MASTER_JSON="$ROOT/docs/proof-index/MAURIMESH_MASTER_PROOF_INDEX.json"
MASTER_MD="$ROOT/docs/proof-index/MAURIMESH_MASTER_PROOF_INDEX.md"
VERIFY_INDEX="$ROOT/tools/proof-verifiers/verify-maurimesh-master-proof-index.js"

backup_if_exists() {
  local file="$1"
  if [ -f "$file" ]; then
    cp "$file" "$file.backup-$STAMP"
    echo "Backup created: $file.backup-$STAMP"
  fi
}

backup_if_exists "$MASTER_JSON"
backup_if_exists "$MASTER_MD"
backup_if_exists "$VERIFY_INDEX"

cat > "$MASTER_JSON" <<'JSONEOF'
{
  "project": "MauriMesh",
  "indexName": "MauriMesh Master Proof Index",
  "createdAt": "GENERATED_BY_SCRIPT",
  "status": "ACTIVE_PROOF_ARCHIVE",
  "proofStandard": {
    "rule": "A proof is strongest when packet identity, stage order, device role, ACK path, archive clone, external verification, and hash seal are preserved.",
    "levels": [
      "APP_UI_PASS",
      "LOG_CLONE_ARCHIVED",
      "EXTERNAL_VERIFIER_PASS",
      "CERTIFICATE_GENERATED",
      "HASH_MANIFEST_PASS"
    ]
  },
  "milestones": [
    {
      "id": "MM-PROOF-001",
      "title": "MauriMesh 2-Device BLE Relay Proof",
      "status": "PASSED",
      "proofLevel": "APP_UI_PASS_SCREENSHOT_ARCHIVED",
      "packetId": "SOURCE_SCREENSHOT_OR_DEVICE_LOG_REQUIRED_FOR_EXACT_PACKET_ID",
      "devices": {
        "PHONE_A": "Samsung Galaxy A06 / Sender",
        "PHONE_B": "Samsung Galaxy S10 / Relay"
      },
      "verifiedChain": [
        "PHONE_A -> TX packet",
        "PHONE_B -> RX packet",
        "PHONE_B -> ACK back to PHONE_A",
        "PHONE_A -> ACK received"
      ],
      "meaning": "MauriMesh proved a two-device sender-to-relay ACK chain at app proof level.",
      "archiveNote": "Keep original screenshot and copied proof report/logcat with this index."
    },
    {
      "id": "MM-PROOF-002",
      "title": "MauriMesh 3-Device Hop Relay Proof",
      "status": "PASSED",
      "proofLevel": "APP_UI_PASS_SCREENSHOT_ARCHIVED",
      "packetId": "MM3-JSY73G-JKDXYR",
      "devices": {
        "PHONE_A": "Samsung Galaxy A06 / Sender / Wi-Fi ADB",
        "PHONE_B": "Samsung Galaxy S10 / Relay / Wi-Fi ADB",
        "PHONE_C": "Samsung Galaxy A16 / Receiver + ACK / USB Debugging"
      },
      "verifiedChain": [
        "PHONE_A/A06 -> PACKET_ID_GENERATED",
        "PHONE_A/A06 -> TX_A06_TO_S10",
        "PHONE_B/S10 -> RX_S10_FROM_A06",
        "PHONE_B/S10 -> RELAY_S10_TO_A16",
        "PHONE_C/A16 -> RX_A16_FROM_S10",
        "PHONE_C/A16 -> ACK_A16_TO_S10",
        "PHONE_B/S10 -> ACK_RELAY_S10_TO_A06",
        "PHONE_A/A06 -> ACK_RECEIVED_A06"
      ],
      "meaning": "MauriMesh proved a three-device hop relay path with ACK return at app proof level.",
      "archiveNote": "Keep original screenshots, copied proof report, and logcat output with this index."
    },
    {
      "id": "MM-PROOF-003",
      "title": "MauriMesh Store-Forward Delay Proof",
      "status": "PASSED",
      "proofLevel": "APP_UI_PASS_LOG_CLONED",
      "packetId": "MMSF-TEJFNH-K3FKYM",
      "devices": {
        "PHONE_A": "Samsung Galaxy A06 / Sender",
        "PHONE_B": "Samsung Galaxy S10 / Store-Forward Relay",
        "PHONE_C": "Samsung Galaxy A16 / Delayed Receiver + ACK"
      },
      "verifiedChain": [
        "PHONE_A/A06 -> PACKET_ID_CONFIRMED",
        "PHONE_A/A06 -> TX_A06_TO_S10_STORE_REQUEST",
        "PHONE_B/S10 -> S10_STORE_PACKET",
        "PHONE_C/A16 -> A16_OFFLINE_CONFIRMED",
        "PHONE_B/S10 -> S10_HOLD_DELAY",
        "PHONE_C/A16 -> A16_RETURNS",
        "PHONE_B/S10 -> S10_FORWARD_STORED_TO_A16",
        "PHONE_C/A16 -> RX_A16_STORED_PACKET",
        "PHONE_C/A16 -> ACK_A16_TO_S10_STORED",
        "PHONE_B/S10 -> ACK_RELAY_S10_TO_A06_STORED",
        "PHONE_A/A06 -> ACK_RECEIVED_A06_STORED"
      ],
      "meaning": "MauriMesh proved packet identity survives delayed receiver loss, relay holding, receiver return, stored delivery, and ACK relay back to sender.",
      "archiveFiles": [
        "docs/proof-archives/store-forward/store_forward_MMSF-TEJFNH-K3FKYM.log"
      ]
    },
    {
      "id": "MM-PROOF-004",
      "title": "MauriMesh Store-Forward External Verifier",
      "status": "PASSED",
      "proofLevel": "EXTERNAL_VERIFIER_PASS_CERTIFICATE_GENERATED",
      "packetId": "MMSF-TEJFNH-K3FKYM",
      "verifier": "tools/proof-verifiers/verify-store-forward-proof.js",
      "certificate": "docs/proof-certificates/store_forward_MMSF-TEJFNH-K3FKYM_certificate.md",
      "jsonReport": "docs/proof-certificates/store_forward_MMSF-TEJFNH-K3FKYM_verifier_report.json",
      "meaning": "Independent project-side verifier confirmed packetId, stage order, device roles, delay condition, rediscovery, and final ACK."
    },
    {
      "id": "MM-PROOF-005",
      "title": "MauriMesh Store-Forward Hash Manifest",
      "status": "PASSED",
      "proofLevel": "HASH_MANIFEST_PASS",
      "packetId": "MMSF-TEJFNH-K3FKYM",
      "manifestJson": "docs/proof-certificates/store_forward_MMSF-TEJFNH-K3FKYM_hash_manifest.json",
      "manifestMarkdown": "docs/proof-certificates/store_forward_MMSF-TEJFNH-K3FKYM_hash_manifest.md",
      "verifier": "tools/proof-verifiers/verify-store-forward-hash-manifest.js",
      "meaning": "Store-forward proof files are now tamper-evident through SHA-256 sealing."
    }
  ]
}
JSONEOF

node - <<'NODEEOF'
const fs = require("fs");
const path = require("path");

const root = process.cwd();
const jsonPath = path.join(root, "docs/proof-index/MAURIMESH_MASTER_PROOF_INDEX.json");
const mdPath = path.join(root, "docs/proof-index/MAURIMESH_MASTER_PROOF_INDEX.md");

const index = JSON.parse(fs.readFileSync(jsonPath, "utf8"));
index.createdAt = new Date().toISOString();

fs.writeFileSync(jsonPath, JSON.stringify(index, null, 2));

const milestoneRows = index.milestones.map((m) => {
  return `| ${m.id} | ${m.title} | ${m.status} | ${m.proofLevel} | \`${m.packetId || "N/A"}\` |`;
}).join("\n");

const sections = index.milestones.map((m) => {
  const devices = m.devices
    ? Object.entries(m.devices).map(([k, v]) => `- ${k}: ${v}`).join("\n")
    : "- N/A";

  const chain = m.verifiedChain
    ? m.verifiedChain.map((x, i) => `${i + 1}. ${x}`).join("\n")
    : "N/A";

  const files = []
    .concat(m.archiveFiles || [])
    .concat(m.verifier ? [m.verifier] : [])
    .concat(m.certificate ? [m.certificate] : [])
    .concat(m.jsonReport ? [m.jsonReport] : [])
    .concat(m.manifestJson ? [m.manifestJson] : [])
    .concat(m.manifestMarkdown ? [m.manifestMarkdown] : []);

  const fileBlock = files.length
    ? files.map((f) => `- \`${f}\``).join("\n")
    : "- Source screenshots / copied proof report / device logs";

  return `## ${m.id} — ${m.title}

- Status: **${m.status}**
- Proof level: **${m.proofLevel}**
- Packet ID: \`${m.packetId || "N/A"}\`

### Devices

${devices}

### Verified Chain

${chain}

### Meaning

${m.meaning || "N/A"}

### Archive Files

${fileBlock}
`;
}).join("\n");

const md = `# MauriMesh Master Proof Index

## Status

- Project: **${index.project}**
- Archive status: **${index.status}**
- Created at: ${index.createdAt}
- Passed milestones recorded: **${index.milestones.length}**

## Proof Standard

${index.proofStandard.rule}

## Milestone Summary

| ID | Title | Status | Proof Level | Packet ID |
|---|---|---|---|---|
${milestoneRows}

${sections}

## Store-Forward Verification Commands

Run these from project root:

\`\`\`bash
node tools/proof-verifiers/verify-store-forward-proof.js
node tools/proof-verifiers/verify-store-forward-hash-manifest.js
node tools/proof-verifiers/verify-maurimesh-master-proof-index.js
\`\`\`

Expected results:

\`\`\`text
Verdict: PASS
HASH VERDICT: PASS
MASTER INDEX VERDICT: PASS
\`\`\`

## Archive Discipline

Keep screenshots, copied proof reports, logcat captures, verifier outputs, certificate files, and hash manifests together.

This protects the proof chain from memory loss, accidental overwrite, and later dispute.
`;

fs.writeFileSync(mdPath, md);
NODEEOF

cat > "$VERIFY_INDEX" <<'JSEOF'
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
JSEOF

chmod +x "$VERIFY_INDEX"

echo ""
echo "Running master proof index verifier..."
node "$VERIFY_INDEX"

echo ""
echo "============================================================"
echo "MAURIMESH MASTER PROOF INDEX COMPLETE"
echo "============================================================"
echo "Master JSON:"
echo "$MASTER_JSON"
echo ""
echo "Master Markdown:"
echo "$MASTER_MD"
echo ""
echo "Verifier:"
echo "$VERIFY_INDEX"
echo ""
echo "Expected result: MASTER INDEX VERDICT: PASS"
echo "============================================================"
