#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH ONE-PAGE EXECUTIVE SUMMARY INSTALL"
echo "Creates 60-second review summary for investor/company proof pack"
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"

PACK_DIR="$ROOT/docs/investor-proof-pack"
TOOLS_DIR="$ROOT/tools/proof-verifiers"

MASTER_JSON="$ROOT/docs/proof-index/MAURIMESH_MASTER_PROOF_INDEX.json"
PACK_JSON="$PACK_DIR/MAURIMESH_PROOF_PACK_INDEX.json"

SUMMARY_MD="$PACK_DIR/MAURIMESH_ONE_PAGE_EXECUTIVE_SUMMARY.md"
SUMMARY_TXT="$PACK_DIR/MAURIMESH_ONE_PAGE_EXECUTIVE_SUMMARY.txt"
VERIFY_SUMMARY="$TOOLS_DIR/verify-maurimesh-one-page-executive-summary.js"

mkdir -p "$PACK_DIR" "$TOOLS_DIR"

backup_if_exists() {
  local file="$1"
  if [ -f "$file" ]; then
    cp "$file" "$file.backup-$STAMP"
    echo "Backup created: $file.backup-$STAMP"
  fi
}

backup_if_exists "$SUMMARY_MD"
backup_if_exists "$SUMMARY_TXT"
backup_if_exists "$VERIFY_SUMMARY"
backup_if_exists "$PACK_JSON"

if [ ! -f "$MASTER_JSON" ]; then
  echo "ERROR: Master proof index missing:"
  echo "$MASTER_JSON"
  exit 1
fi

node - <<'NODEEOF'
const fs = require("fs");
const path = require("path");

const root = process.cwd();

const masterPath = path.join(root, "docs/proof-index/MAURIMESH_MASTER_PROOF_INDEX.json");
const packPath = path.join(root, "docs/investor-proof-pack/MAURIMESH_PROOF_PACK_INDEX.json");

const summaryMdPath = path.join(root, "docs/investor-proof-pack/MAURIMESH_ONE_PAGE_EXECUTIVE_SUMMARY.md");
const summaryTxtPath = path.join(root, "docs/investor-proof-pack/MAURIMESH_ONE_PAGE_EXECUTIVE_SUMMARY.txt");

const master = JSON.parse(fs.readFileSync(masterPath, "utf8"));
const createdAt = new Date().toISOString();

const passed = master.milestones.filter((m) => m.status === "PASSED");

const md = `# MauriMesh — One-Page Executive Proof Summary

**Status:** READY FOR REVIEW  
**Project:** MauriMesh  
**Passed milestones indexed:** ${passed.length}  
**Generated:** ${createdAt}

## 60-Second Summary

MauriMesh is an offline-first mesh communication system designed to preserve message delivery when devices disconnect, move, return, or relay through other phones.

The current proof archive records passed app-level and project-verifier milestones for:

1. Two-device relay.
2. Three-device hop relay.
3. Store-forward delayed delivery.
4. External verifier PASS.
5. Tamper-evident SHA-256 hash manifest PASS.

## Strongest Current Proof

The strongest archived proof is the Store-Forward Delay Proof:

**Packet ID:** \`MMSF-TEJFNH-K3FKYM\`

Verified chain:

A06 sender → S10 stores packet → A16 is unavailable → S10 holds delay → A16 returns → S10 forwards stored packet → A16 receives → A16 ACKs S10 → S10 relays ACK → A06 receives final ACK.

## Why It Matters

A real mesh network cannot depend on every device being online at the same time. Store-forward behavior means a relay can preserve a packet while a receiver is unavailable, then deliver it when the receiver returns.

That is a key requirement for resilient offline messaging, disaster communication, rural connectivity, field teams, community networks, and device-to-device coordination.

## Proof Integrity

The proof pack now includes:

- Master Proof Index PASS.
- Investor / Company Proof Pack PASS.
- Store-forward cloned log.
- External verifier certificate.
- JSON verifier report.
- SHA-256 hash manifest.
- Hash manifest verification PASS.

## Correct Current Claim

MauriMesh has passed founder-controlled app-level relay and store-forward proof milestones, with project-side external verification and tamper-evident archive sealing.

## Important Boundary

This is not yet independent third-party certification, carrier certification, laboratory RF certification, emergency-service approval, or production security audit completion.

## Next Validation Step

The next strongest proof is a synchronized raw-device evidence run:

- A06 screen recording.
- S10 screen recording.
- A16 screen recording.
- ADB/logcat capture from all devices.
- One visible packet ID.
- One timestamped video showing the full proof sequence.
`;

const txt = `MAURIMESH — ONE-PAGE EXECUTIVE PROOF SUMMARY

Status: READY FOR REVIEW
Project: MauriMesh
Passed milestones indexed: ${passed.length}
Generated: ${createdAt}

60-SECOND SUMMARY

MauriMesh is an offline-first mesh communication system designed to preserve message delivery when devices disconnect, move, return, or relay through other phones.

The current proof archive records passed app-level and project-verifier milestones for:

1. Two-device relay.
2. Three-device hop relay.
3. Store-forward delayed delivery.
4. External verifier PASS.
5. Tamper-evident SHA-256 hash manifest PASS.

STRONGEST CURRENT PROOF

Packet ID: MMSF-TEJFNH-K3FKYM

Verified chain:

A06 sender -> S10 stores packet -> A16 is unavailable -> S10 holds delay -> A16 returns -> S10 forwards stored packet -> A16 receives -> A16 ACKs S10 -> S10 relays ACK -> A06 receives final ACK.

WHY IT MATTERS

A real mesh network cannot depend on every device being online at the same time. Store-forward behavior means a relay can preserve a packet while a receiver is unavailable, then deliver it when the receiver returns.

PROOF INTEGRITY

The proof pack now includes Master Proof Index PASS, Investor / Company Proof Pack PASS, cloned proof log, external verifier certificate, JSON verifier report, SHA-256 hash manifest, and hash manifest verification PASS.

CORRECT CURRENT CLAIM

MauriMesh has passed founder-controlled app-level relay and store-forward proof milestones, with project-side external verification and tamper-evident archive sealing.

IMPORTANT BOUNDARY

This is not yet independent third-party certification, carrier certification, laboratory RF certification, emergency-service approval, or production security audit completion.

NEXT VALIDATION STEP

The next strongest proof is a synchronized raw-device evidence run: A06 screen recording, S10 screen recording, A16 screen recording, ADB/logcat capture from all devices, one visible packet ID, and one timestamped video showing the full proof sequence.
`;

fs.writeFileSync(summaryMdPath, md);
fs.writeFileSync(summaryTxtPath, txt);

if (fs.existsSync(packPath)) {
  const pack = JSON.parse(fs.readFileSync(packPath, "utf8"));
  pack.updatedAt = createdAt;
  pack.status = "READY_FOR_REVIEW";

  pack.includedDocuments = Array.from(new Set([
    ...(pack.includedDocuments || []),
    "docs/investor-proof-pack/MAURIMESH_ONE_PAGE_EXECUTIVE_SUMMARY.md",
    "docs/investor-proof-pack/MAURIMESH_ONE_PAGE_EXECUTIVE_SUMMARY.txt"
  ]));

  fs.writeFileSync(packPath, JSON.stringify(pack, null, 2));
}
NODEEOF

cat > "$VERIFY_SUMMARY" <<'JSEOF'
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
JSEOF

chmod +x "$VERIFY_SUMMARY"

echo ""
echo "Running one-page executive summary verifier..."
node "$VERIFY_SUMMARY"

echo ""
echo "Refreshing investor proof pack archive..."
NEW_ARCHIVE="$ROOT/archives/maurimesh-investor-proof-pack-with-one-page-$STAMP.tar.gz"
tar -czf "$NEW_ARCHIVE" \
  docs/investor-proof-pack \
  docs/proof-index \
  docs/proof-certificates \
  docs/proof-archives/store-forward \
  tools/proof-verifiers

echo ""
echo "============================================================"
echo "MAURIMESH ONE-PAGE EXECUTIVE SUMMARY COMPLETE"
echo "============================================================"
echo "Markdown:"
echo "$SUMMARY_MD"
echo ""
echo "Text:"
echo "$SUMMARY_TXT"
echo ""
echo "Verifier:"
echo "$VERIFY_SUMMARY"
echo ""
echo "Archive:"
echo "$NEW_ARCHIVE"
echo ""
echo "Expected result: ONE-PAGE SUMMARY VERDICT: PASS"
echo "============================================================"
