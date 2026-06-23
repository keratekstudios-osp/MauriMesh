#!/usr/bin/env node
const fs = require("fs");
const path = require("path");

const root = process.cwd();
const runDirArg = process.argv[2];
const packetIdArg = process.argv[3] || "";

function newestRunDir() {
  const base = path.join(root, "evidence/raw-device-runs");
  if (!fs.existsSync(base)) return null;
  const dirs = fs.readdirSync(base)
    .filter((name) => name.startsWith("run-"))
    .map((name) => path.join(base, name))
    .filter((p) => fs.statSync(p).isDirectory())
    .sort();
  return dirs.length ? dirs[dirs.length - 1] : null;
}

const runDir = runDirArg || newestRunDir();

function fail(verdict, reason, details = {}) {
  console.log("");
  console.log("============================================================");
  console.log("MAURIMESH RAW-DEVICE EVIDENCE RUN VERIFY");
  console.log("============================================================");
  console.log(`RAW EVIDENCE VERDICT: ${verdict}`);
  console.log(`Reason: ${reason}`);
  if (Object.keys(details).length) {
    console.log(JSON.stringify(details, null, 2));
  }
  console.log("============================================================");
  console.log("");
  process.exit(verdict === "FAIL" ? 1 : 2);
}

if (!runDir || !fs.existsSync(runDir)) {
  fail("FAIL", "Evidence run directory not found.", { runDir });
}

const requiredPaths = [
  "run_manifest.md",
  "device-info/adb_devices_l.txt",
  "device-info/serial_map.csv",
  "filtered/all_logcat_combined.txt",
  "filtered/maurimesh_filtered.txt",
  "SHA256SUMS.txt"
];

const missing = requiredPaths.filter((rel) => !fs.existsSync(path.join(runDir, rel)));

if (missing.length > 0) {
  fail("FAIL", "Required evidence files missing.", { runDir, missing });
}

const logsDir = path.join(runDir, "logs");
const screenDir = path.join(runDir, "screenrecords");

const logFiles = fs.existsSync(logsDir)
  ? fs.readdirSync(logsDir).filter((f) => f.endsWith(".txt"))
  : [];

const screenFiles = fs.existsSync(screenDir)
  ? fs.readdirSync(screenDir).filter((f) => f.endsWith(".mp4"))
  : [];

if (logFiles.length < 1) {
  fail("FAIL", "No raw logcat files found.", { logsDir });
}

const manifest = fs.readFileSync(path.join(runDir, "run_manifest.md"), "utf8");
const filtered = fs.readFileSync(path.join(runDir, "filtered/maurimesh_filtered.txt"), "utf8");
const combined = fs.readFileSync(path.join(runDir, "filtered/all_logcat_combined.txt"), "utf8");
const searchText = `${manifest}\n${filtered}\n${combined}`;

let packetId = packetIdArg.trim();

if (!packetId) {
  const match = manifest.match(/Packet ID:\s*([A-Z0-9-]+)/);
  if (match && match[1] !== "NOT") packetId = match[1];
}

const expectedStoreForwardStages = [
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

const expectedThreeDeviceStages = [
  "PACKET_ID_GENERATED",
  "TX_A06_TO_S10",
  "RX_S10_FROM_A06",
  "RELAY_S10_TO_A16",
  "RX_A16_FROM_S10",
  "ACK_A16_TO_S10",
  "ACK_RELAY_S10_TO_A06",
  "ACK_RECEIVED_A06"
];

function foundStages(stages) {
  return stages.filter((stage) => searchText.includes(stage));
}

const sfFound = foundStages(expectedStoreForwardStages);
const threeFound = foundStages(expectedThreeDeviceStages);

const packetFound = packetId ? searchText.includes(packetId) : false;

const result = {
  runDir,
  packetId: packetId || "NOT_SET",
  packetFound,
  rawLogFiles: logFiles.length,
  screenRecordFiles: screenFiles.length,
  storeForwardFound: sfFound.length,
  storeForwardRequired: expectedStoreForwardStages.length,
  threeDeviceFound: threeFound.length,
  threeDeviceRequired: expectedThreeDeviceStages.length,
  missingStoreForwardStages: expectedStoreForwardStages.filter((s) => !sfFound.includes(s)),
  missingThreeDeviceStages: expectedThreeDeviceStages.filter((s) => !threeFound.includes(s))
};

const reportPath = path.join(runDir, "raw_evidence_verifier_report.json");
fs.writeFileSync(reportPath, JSON.stringify(result, null, 2));

const sfPass = sfFound.length === expectedStoreForwardStages.length && (!packetId || packetFound);
const threePass = threeFound.length === expectedThreeDeviceStages.length && (!packetId || packetFound);

console.log("");
console.log("============================================================");
console.log("MAURIMESH RAW-DEVICE EVIDENCE RUN VERIFY");
console.log("============================================================");

if (sfPass) {
  console.log("RAW EVIDENCE VERDICT: PASS");
  console.log("Proof type : STORE_FORWARD_DELAY");
  console.log(`Packet     : ${packetId || "NOT_SET"}`);
  console.log(`Logs       : ${logFiles.length}`);
  console.log(`Videos     : ${screenFiles.length}`);
  console.log("Reason     : Raw evidence folder contains required store-forward stages and packet evidence.");
  console.log(`Report     : ${reportPath}`);
  console.log("============================================================");
  console.log("");
  process.exit(0);
}

if (threePass) {
  console.log("RAW EVIDENCE VERDICT: PASS");
  console.log("Proof type : THREE_DEVICE_HOP");
  console.log(`Packet     : ${packetId || "NOT_SET"}`);
  console.log(`Logs       : ${logFiles.length}`);
  console.log(`Videos     : ${screenFiles.length}`);
  console.log("Reason     : Raw evidence folder contains required three-device hop stages and packet evidence.");
  console.log(`Report     : ${reportPath}`);
  console.log("============================================================");
  console.log("");
  process.exit(0);
}

console.log("RAW EVIDENCE VERDICT: INCOMPLETE");
console.log(`Packet     : ${packetId || "NOT_SET"}`);
console.log(`Packet hit : ${packetFound}`);
console.log(`Logs       : ${logFiles.length}`);
console.log(`Videos     : ${screenFiles.length}`);
console.log(`SF stages  : ${sfFound.length}/${expectedStoreForwardStages.length}`);
console.log(`3D stages  : ${threeFound.length}/${expectedThreeDeviceStages.length}`);
console.log(`Report     : ${reportPath}`);
console.log("Reason     : Evidence folder exists, but full required proof stage chain was not found in raw logs.");
console.log("============================================================");
console.log("");
process.exit(2);
