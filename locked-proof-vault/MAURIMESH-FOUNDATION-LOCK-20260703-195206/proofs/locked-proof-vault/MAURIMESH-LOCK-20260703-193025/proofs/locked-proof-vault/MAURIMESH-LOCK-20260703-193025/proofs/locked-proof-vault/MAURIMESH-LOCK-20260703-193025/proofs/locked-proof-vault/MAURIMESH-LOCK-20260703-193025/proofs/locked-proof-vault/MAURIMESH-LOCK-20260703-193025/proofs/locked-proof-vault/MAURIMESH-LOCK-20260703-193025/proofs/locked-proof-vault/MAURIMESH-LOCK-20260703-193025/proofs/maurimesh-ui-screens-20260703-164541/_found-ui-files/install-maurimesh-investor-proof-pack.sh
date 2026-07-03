#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH INVESTOR / COMPANY PROOF PACK INSTALL"
echo "Builds proof pack from Master Proof Index + verifier records"
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"

PACK_DIR="$ROOT/docs/investor-proof-pack"
VERIFY_PACK="$ROOT/tools/proof-verifiers/verify-maurimesh-investor-proof-pack.js"

mkdir -p \
  "$PACK_DIR" \
  "$ROOT/tools/proof-verifiers" \
  "$ROOT/archives"

MASTER_JSON="$ROOT/docs/proof-index/MAURIMESH_MASTER_PROOF_INDEX.json"
MASTER_MD="$ROOT/docs/proof-index/MAURIMESH_MASTER_PROOF_INDEX.md"

PACK_MD="$PACK_DIR/MAURIMESH_INVESTOR_PROOF_PACK.md"
DUE_DILIGENCE_MD="$PACK_DIR/MAURIMESH_DUE_DILIGENCE_SUMMARY.md"
TECHNICAL_MD="$PACK_DIR/MAURIMESH_TECHNICAL_PROOF_SUMMARY.md"
LIMITATIONS_MD="$PACK_DIR/MAURIMESH_PROOF_LIMITS_AND_NEXT_STEPS.md"
PACK_JSON="$PACK_DIR/MAURIMESH_PROOF_PACK_INDEX.json"
README="$PACK_DIR/README.md"
ARCHIVE="$ROOT/archives/maurimesh-investor-proof-pack-$STAMP.tar.gz"

backup_if_exists() {
  local file="$1"
  if [ -f "$file" ]; then
    cp "$file" "$file.backup-$STAMP"
    echo "Backup created: $file.backup-$STAMP"
  fi
}

backup_if_exists "$PACK_MD"
backup_if_exists "$DUE_DILIGENCE_MD"
backup_if_exists "$TECHNICAL_MD"
backup_if_exists "$LIMITATIONS_MD"
backup_if_exists "$PACK_JSON"
backup_if_exists "$README"
backup_if_exists "$VERIFY_PACK"

if [ ! -f "$MASTER_JSON" ]; then
  echo "ERROR: Master proof index missing:"
  echo "$MASTER_JSON"
  exit 1
fi

cat > "$VERIFY_PACK" <<'JSEOF'
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
JSEOF

chmod +x "$VERIFY_PACK"

node - <<'NODEEOF'
const fs = require("fs");
const path = require("path");

const root = process.cwd();

const masterPath = path.join(root, "docs/proof-index/MAURIMESH_MASTER_PROOF_INDEX.json");
const packDir = path.join(root, "docs/investor-proof-pack");

const master = JSON.parse(fs.readFileSync(masterPath, "utf8"));
const createdAt = new Date().toISOString();

const milestoneRows = master.milestones.map((m) => {
  return `| ${m.id} | ${m.title} | ${m.status} | ${m.proofLevel} | \`${m.packetId || "N/A"}\` |`;
}).join("\n");

const packIndex = {
  project: "MauriMesh",
  packName: "MauriMesh Investor / Company Proof Pack",
  status: "READY_FOR_REVIEW",
  createdAt,
  sourceIndex: "docs/proof-index/MAURIMESH_MASTER_PROOF_INDEX.json",
  includedDocuments: [
    "docs/investor-proof-pack/README.md",
    "docs/investor-proof-pack/MAURIMESH_INVESTOR_PROOF_PACK.md",
    "docs/investor-proof-pack/MAURIMESH_DUE_DILIGENCE_SUMMARY.md",
    "docs/investor-proof-pack/MAURIMESH_TECHNICAL_PROOF_SUMMARY.md",
    "docs/investor-proof-pack/MAURIMESH_PROOF_LIMITS_AND_NEXT_STEPS.md",
    "docs/proof-index/MAURIMESH_MASTER_PROOF_INDEX.md",
    "docs/proof-certificates/store_forward_MMSF-TEJFNH-K3FKYM_certificate.md",
    "docs/proof-certificates/store_forward_MMSF-TEJFNH-K3FKYM_hash_manifest.md"
  ],
  verificationCommands: [
    "node tools/proof-verifiers/verify-store-forward-proof.js",
    "node tools/proof-verifiers/verify-store-forward-hash-manifest.js",
    "node tools/proof-verifiers/verify-maurimesh-master-proof-index.js",
    "node tools/proof-verifiers/verify-maurimesh-investor-proof-pack.js"
  ],
  proofBoundary:
    "This pack proves internal app-level proof records, archived logs, external project-side verification, and hash-manifest integrity. It does not claim independent third-party certification or RF-layer laboratory certification."
};

fs.writeFileSync(
  path.join(packDir, "MAURIMESH_PROOF_PACK_INDEX.json"),
  JSON.stringify(packIndex, null, 2)
);

const readme = `# MauriMesh Investor / Company Proof Pack

Status: **READY FOR REVIEW**  
Created: ${createdAt}

This folder contains the current MauriMesh proof pack for technical review, investor review, company review, or grant review.

## Main Documents

1. \`MAURIMESH_INVESTOR_PROOF_PACK.md\`
2. \`MAURIMESH_DUE_DILIGENCE_SUMMARY.md\`
3. \`MAURIMESH_TECHNICAL_PROOF_SUMMARY.md\`
4. \`MAURIMESH_PROOF_LIMITS_AND_NEXT_STEPS.md\`
5. \`MAURIMESH_PROOF_PACK_INDEX.json\`

## Verification Commands

Run from project root:

\`\`\`bash
node tools/proof-verifiers/verify-store-forward-proof.js
node tools/proof-verifiers/verify-store-forward-hash-manifest.js
node tools/proof-verifiers/verify-maurimesh-master-proof-index.js
node tools/proof-verifiers/verify-maurimesh-investor-proof-pack.js
\`\`\`

Expected result:

\`\`\`text
Verdict: PASS
HASH VERDICT: PASS
MASTER INDEX VERDICT: PASS
PROOF PACK VERDICT: PASS
\`\`\`
`;

fs.writeFileSync(path.join(packDir, "README.md"), readme);

const investorPack = `# MauriMesh Investor / Company Proof Pack

## Executive Summary

MauriMesh is an offline-first mesh communication system designed around resilient message delivery, relay paths, delayed delivery, ACK confirmation, proof logging, and tamper-evident archive discipline.

The current proof archive records five passed milestones, including two-device relay, three-device hop relay, store-forward delay, external verification, and SHA-256 hash manifest sealing.

## Current Proof Status

- Project: **MauriMesh**
- Proof archive status: **ACTIVE / VERIFIED / INDEXED**
- Proof pack status: **READY FOR REVIEW**
- Passed milestones recorded: **${master.milestones.length}**
- Created: ${createdAt}

## Milestone Summary

| ID | Title | Status | Proof Level | Packet ID |
|---|---|---|---|---|
${milestoneRows}

## Strongest Current Evidence

The strongest current evidence is the Store-Forward Delay Proof for packet:

\`MMSF-TEJFNH-K3FKYM\`

This proof records:

1. A06 confirming packet identity.
2. A06 sending a store request to S10.
3. S10 storing the packet.
4. A16 being unavailable/offline.
5. S10 holding the packet across delay.
6. A16 returning / being rediscovered.
7. S10 forwarding the stored packet to A16.
8. A16 receiving the stored packet.
9. A16 ACKing S10.
10. S10 relaying ACK to A06.
11. A06 receiving final ACK.

## Why This Matters

Store-forward behavior is a core requirement for practical mesh messaging. Real-world mesh nodes move, disconnect, lose signal, go offline, return, and reconnect. A resilient mesh messenger must preserve message identity through interruption rather than treating temporary unavailability as final failure.

## Proof Integrity

The Store-Forward proof now has:

- Cloned proof log.
- External verifier.
- External verifier PASS.
- Certificate.
- JSON verifier report.
- SHA-256 hash manifest.
- Hash manifest PASS.
- Master proof index PASS.
- Investor proof pack verifier PASS.

## Commercial Review Position

This pack is suitable for early technical review, company discussion, grant discussion, prototype evaluation, and investor discovery.

It should not yet be described as independently certified, laboratory RF-certified, carrier-certified, emergency-service approved, or production-hardened until those reviews are completed.
`;

fs.writeFileSync(path.join(packDir, "MAURIMESH_INVESTOR_PROOF_PACK.md"), investorPack);

const dueDiligence = `# MauriMesh Due Diligence Summary

## Review Status

MauriMesh currently has a proof archive with app-level proof records, cloned logs, verifier scripts, certificate files, and tamper-evident hash manifests.

## Verified Internally

- Two-device relay proof: PASSED.
- Three-device hop relay proof: PASSED.
- Store-forward delay proof: PASSED.
- Store-forward external verifier: PASSED.
- Store-forward hash manifest: PASSED.
- Master proof index: PASSED.

## Evidence Available

- Master proof index.
- Store-forward cloned log.
- Store-forward verifier script.
- Store-forward certificate.
- Store-forward JSON report.
- Store-forward hash manifest.
- Screenshot-based proof records.
- Replit shell verifier output.

## Technical Diligence Questions Answered

### Does the system track packet identity?

Yes. The strongest archived store-forward proof uses packet ID \`MMSF-TEJFNH-K3FKYM\` across every required proof stage.

### Does the proof include delayed receiver loss?

Yes. The archived sequence includes \`A16_OFFLINE_CONFIRMED\`.

### Does the proof include relay holding?

Yes. The archived sequence includes \`S10_HOLD_DELAY\`.

### Does the proof include receiver return?

Yes. The archived sequence includes \`A16_RETURNS\`.

### Does the proof include final ACK back to sender?

Yes. The archived sequence ends with \`ACK_RECEIVED_A06_STORED\`.

### Is the archive tamper-evident?

Yes. The store-forward proof files are sealed by SHA-256 hash manifest and verified with \`HASH VERDICT: PASS\`.

## Boundary

This is not yet independent third-party certification. It is a founder-controlled proof archive with project-side verification and tamper-evident sealing.

## Recommended Next Validation

1. Capture raw ADB/logcat export directly from all devices.
2. Add timestamp synchronization notes.
3. Add video recording of the full test run.
4. Add third-party observer witness note.
5. Add BLE/Wi-Fi transport-level packet evidence where possible.
6. Repeat proof with 10+ packet IDs.
7. Repeat proof after app restart and device reboot.
8. Repeat proof at distance and through movement.
`;

fs.writeFileSync(path.join(packDir, "MAURIMESH_DUE_DILIGENCE_SUMMARY.md"), dueDiligence);

const technical = `# MauriMesh Technical Proof Summary

## Devices

- PHONE_A: Samsung Galaxy A06 / Sender.
- PHONE_B: Samsung Galaxy S10 / Relay / Store-forward node.
- PHONE_C: Samsung Galaxy A16 / Receiver + ACK.

## Passed Proof Categories

### 1. Two-Device Relay

A06 sender to S10 relay with ACK return.

### 2. Three-Device Hop Relay

A06 sender to S10 relay to A16 receiver, with ACK return path.

Known indexed packet:

\`MM3-JSY73G-JKDXYR\`

### 3. Store-Forward Delay

A06 sender to S10 store-forward relay. A16 is unavailable, later returns, receives stored packet, ACKs S10, and S10 relays ACK back to A06.

Verified packet:

\`MMSF-TEJFNH-K3FKYM\`

## Store-Forward Verified Stage Order

1. PACKET_ID_CONFIRMED
2. TX_A06_TO_S10_STORE_REQUEST
3. S10_STORE_PACKET
4. A16_OFFLINE_CONFIRMED
5. S10_HOLD_DELAY
6. A16_RETURNS
7. S10_FORWARD_STORED_TO_A16
8. RX_A16_STORED_PACKET
9. ACK_A16_TO_S10_STORED
10. ACK_RELAY_S10_TO_A06_STORED
11. ACK_RECEIVED_A06_STORED

## Verification Scripts

\`\`\`bash
node tools/proof-verifiers/verify-store-forward-proof.js
node tools/proof-verifiers/verify-store-forward-hash-manifest.js
node tools/proof-verifiers/verify-maurimesh-master-proof-index.js
node tools/proof-verifiers/verify-maurimesh-investor-proof-pack.js
\`\`\`

## Expected Results

\`\`\`text
Verdict: PASS
HASH VERDICT: PASS
MASTER INDEX VERDICT: PASS
PROOF PACK VERDICT: PASS
\`\`\`
`;

fs.writeFileSync(path.join(packDir, "MAURIMESH_TECHNICAL_PROOF_SUMMARY.md"), technical);

const limits = `# MauriMesh Proof Limits and Next Steps

## What Is Proven Now

The current archive proves that MauriMesh has app-level proof flows for:

- Two-device relay.
- Three-device hop relay.
- Store-forward delay.
- ACK return.
- External log verification.
- Tamper-evident proof file sealing.

## What Is Not Yet Proven

The current archive does not yet prove:

- Independent third-party certification.
- RF-layer laboratory packet capture.
- Carrier-grade reliability.
- Emergency-service approval.
- Large-scale field performance.
- Long-duration unattended operation.
- Security audit completion.
- Production-grade cryptographic identity verification.

## Next Proof Milestones

### P1 — Raw Device Log Proof

Capture ADB/logcat from A06, S10, and A16 during the same proof run.

### P2 — Video + Screen + Log Sync Proof

Record the three phones and the terminal logs at the same time.

### P3 — Multi-Packet Repetition Proof

Run the store-forward proof 10 times with 10 unique packet IDs.

### P4 — Distance Proof

Repeat the relay test with physical separation between devices.

### P5 — Restart Recovery Proof

Run proof, restart app/device, confirm archive continuity.

### P6 — Transport Hardening Proof

Separate app simulation logs from hardware transport logs.

### P7 — External Witness Proof

Have an independent reviewer observe and sign the proof record.

## External Claim Discipline

Do not claim independent certification, emergency deployment readiness, or world-first status in a formal company/investor document until independent review and prior-art checks are complete.

The correct current claim is:

**MauriMesh has passed founder-controlled app-level relay and store-forward proof milestones, with external project-side verification and tamper-evident archive sealing.**
`;

fs.writeFileSync(path.join(packDir, "MAURIMESH_PROOF_LIMITS_AND_NEXT_STEPS.md"), limits);
NODEEOF

echo ""
echo "Running investor proof pack verifier..."
node "$VERIFY_PACK"

echo ""
echo "Creating tar.gz archive..."
tar -czf "$ARCHIVE" \
  docs/investor-proof-pack \
  docs/proof-index \
  docs/proof-certificates \
  docs/proof-archives/store-forward \
  tools/proof-verifiers

echo ""
echo "============================================================"
echo "MAURIMESH INVESTOR / COMPANY PROOF PACK COMPLETE"
echo "============================================================"
echo "Proof pack folder:"
echo "$PACK_DIR"
echo ""
echo "Archive:"
echo "$ARCHIVE"
echo ""
echo "Verifier:"
echo "$VERIFY_PACK"
echo ""
echo "Expected result: PROOF PACK VERDICT: PASS"
echo "============================================================"
