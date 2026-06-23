#!/usr/bin/env node
const fs = require("fs");
const path = require("path");
const crypto = require("crypto");

const evidenceDir = process.argv[2];
const packetId = process.argv[3];

function out(msg = "") {
  console.log(msg);
}

function sha256File(file) {
  return crypto.createHash("sha256").update(fs.readFileSync(file)).digest("hex");
}

function fail(reason, details = {}) {
  const report = {
    verdict: "FAIL",
    packetId: packetId || null,
    reason,
    details,
    checkedAt: new Date().toISOString()
  };

  if (evidenceDir && fs.existsSync(evidenceDir)) {
    fs.writeFileSync(
      path.join(evidenceDir, "RAW_DEVICE_EVIDENCE_VERIFIER_REPORT.json"),
      JSON.stringify(report, null, 2)
    );
  }

  out("");
  out("============================================================");
  out("MAURIMESH RAW-DEVICE EVIDENCE VERIFY");
  out("============================================================");
  out("RAW EVIDENCE VERDICT: FAIL");
  out(`Reason: ${reason}`);
  if (Object.keys(details).length) out(JSON.stringify(details, null, 2));
  out("============================================================");
  out("");
  process.exitCode = 1;
}

function pass(report) {
  fs.writeFileSync(
    path.join(evidenceDir, "RAW_DEVICE_EVIDENCE_VERIFIER_REPORT.json"),
    JSON.stringify(report, null, 2)
  );

  const md = `# MauriMesh Raw-Device Evidence Report

## Verdict

**RAW EVIDENCE VERDICT: PASS**

## Packet ID

\`${report.packetId}\`

## Evidence Folder

\`${evidenceDir}\`

## Matched Required Stages

${report.matchedStages.map((x, i) => `${i + 1}. ${x}`).join("\n")}

## Device Log Files

${report.files.map((f) => `- \`${f.relativePath}\` — SHA-256: \`${f.sha256}\``).join("\n")}

## Boundary

This verifies raw captured log files in the evidence folder. It does not by itself prove independent third-party certification.
`;

  fs.writeFileSync(path.join(evidenceDir, "RAW_DEVICE_EVIDENCE_REPORT.md"), md);

  out("");
  out("============================================================");
  out("MAURIMESH RAW-DEVICE EVIDENCE VERIFY");
  out("============================================================");
  out("RAW EVIDENCE VERDICT: PASS");
  out(`Packet : ${report.packetId}`);
  out(`Stages : ${report.matchedStages.length}`);
  out(`Files  : ${report.files.length}`);
  out("Reason : Required store-forward stages were found in captured raw-device logs.");
  out("============================================================");
  out("");
}

if (!evidenceDir || !packetId) {
  fail("Usage: node verify-maurimesh-raw-evidence-run.js <evidence-folder> <packetId>");
}

if (!fs.existsSync(evidenceDir)) {
  fail("Evidence folder not found.", { evidenceDir });
}

const requiredFiles = [
  "PHONE_A_A06_SENDER_maurimesh_filtered.log",
  "PHONE_B_S10_STORE_FORWARD_RELAY_maurimesh_filtered.log",
  "PHONE_C_A16_DELAYED_RECEIVER_ACK_maurimesh_filtered.log",
  "PHONE_A_A06_SENDER_raw_logcat.log",
  "PHONE_B_S10_STORE_FORWARD_RELAY_raw_logcat.log",
  "PHONE_C_A16_DELAYED_RECEIVER_ACK_raw_logcat.log",
  "run_metadata.json"
];

const missing = requiredFiles.filter((file) => !fs.existsSync(path.join(evidenceDir, file)));

if (missing.length) {
  fail("Required raw evidence files missing.", { missing });
}

const allFiltered = requiredFiles
  .filter((file) => file.endsWith("_maurimesh_filtered.log"))
  .map((file) => fs.readFileSync(path.join(evidenceDir, file), "utf8"))
  .join("\n");

if (!allFiltered.includes(packetId)) {
  fail("Selected packetId was not found in filtered proof logs.", { packetId });
}

const requiredStages = [
  "PACKET_ID_CONFIRMED",
  "TX_A06_TO_S10_STORE_REQUEST",
  "S10_STORE_PACKET",
  "A16_OFFLINE_CONFIRMED",
  "S10_HOLD_DELAY",
  "A16_RETURNS",
  "S10_FORWARD_STORED_TO_A16",
  "RX_A16_STORED_PACKET",
  "ACK_A16_TO_S10_STORED",
  "ACK_RELAY_S10_TO_A06_STORED",
  "ACK_RECEIVED_A06_STORED"
];

const matchedStages = [];
const missingStages = [];

for (const stage of requiredStages) {
  const found = allFiltered.includes(stage) && allFiltered.includes(packetId);
  if (found) matchedStages.push(stage);
  else missingStages.push(stage);
}

if (missingStages.length) {
  fail("Missing one or more required store-forward stages in raw-device logs.", {
    packetId,
    missingStages,
    matchedStages
  });
}

const files = requiredFiles.map((relativePath) => {
  const abs = path.join(evidenceDir, relativePath);
  return {
    relativePath,
    sizeBytes: fs.statSync(abs).size,
    sha256: sha256File(abs)
  };
});

pass({
  verdict: "PASS",
  packetId,
  checkedAt: new Date().toISOString(),
  requiredStageCount: requiredStages.length,
  matchedStages,
  files
});
