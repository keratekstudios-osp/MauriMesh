#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH RAW-DEVICE EVIDENCE RUN KIT INSTALL"
echo "Creates A06 + S10 + A16 synchronized capture kit"
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"

KIT_DIR="$ROOT/docs/raw-device-evidence-kit"
CAPTURE_DIR="$ROOT/scripts/proof-capture"
TOOLS_DIR="$ROOT/tools/proof-verifiers"
ARCHIVE_DIR="$ROOT/archives"

mkdir -p "$KIT_DIR" "$CAPTURE_DIR" "$TOOLS_DIR" "$ARCHIVE_DIR"

CAPTURE_SCRIPT="$CAPTURE_DIR/maurimesh-raw-device-evidence-run.sh"
RAW_VERIFY="$TOOLS_DIR/verify-maurimesh-raw-evidence-run.js"
KIT_VERIFY="$TOOLS_DIR/verify-maurimesh-raw-device-evidence-kit.js"
README="$KIT_DIR/README.md"
CHECKLIST="$KIT_DIR/RAW_DEVICE_EVIDENCE_RUN_CHECKLIST.md"
BOUNDARY="$KIT_DIR/RAW_DEVICE_EVIDENCE_BOUNDARY.md"
ARCHIVE="$ARCHIVE_DIR/maurimesh-raw-device-evidence-kit-$STAMP.tar.gz"

backup_if_exists() {
  local file="$1"
  if [ -f "$file" ]; then
    cp "$file" "$file.backup-$STAMP"
    echo "Backup created: $file.backup-$STAMP"
  fi
}

backup_if_exists "$CAPTURE_SCRIPT"
backup_if_exists "$RAW_VERIFY"
backup_if_exists "$KIT_VERIFY"
backup_if_exists "$README"
backup_if_exists "$CHECKLIST"
backup_if_exists "$BOUNDARY"

cat > "$CAPTURE_SCRIPT" <<'CAPEOF'
#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH RAW-DEVICE EVIDENCE RUN"
echo "A06 + S10 + A16 ADB/logcat synchronized capture"
echo "============================================================"
echo ""

ROOT="$(pwd)"
PKG="${PKG:-com.maurimesh.messenger}"
PROOF_TAG="${PROOF_TAG:-MAURIMESH}"
RUN_ID="${RUN_ID:-raw-device-$(date +%Y%m%d-%H%M%S)}"
OUT_DIR="$ROOT/evidence/raw-device/$RUN_ID"

mkdir -p "$OUT_DIR"

log() {
  echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $*"
}

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "ERROR: Required command missing: $1"
    exit 1
  fi
}

need_cmd adb
need_cmd node
need_cmd grep
need_cmd awk

echo "Output folder:"
echo "$OUT_DIR"
echo ""

adb start-server >/dev/null

echo "Connected devices:"
adb devices -l | tee "$OUT_DIR/adb_devices_before.txt"
echo ""

PHONE_A_SERIAL="${PHONE_A_SERIAL:-}"
PHONE_B_SERIAL="${PHONE_B_SERIAL:-}"
PHONE_C_SERIAL="${PHONE_C_SERIAL:-}"

if [ -z "$PHONE_A_SERIAL" ] || [ -z "$PHONE_B_SERIAL" ] || [ -z "$PHONE_C_SERIAL" ]; then
  echo "Set these first, then rerun:"
  echo ""
  echo "export PHONE_A_SERIAL=\"A06_ADB_SERIAL\""
  echo "export PHONE_B_SERIAL=\"S10_ADB_SERIAL\""
  echo "export PHONE_C_SERIAL=\"A16_ADB_SERIAL\""
  echo ""
  echo "Use this to see serials:"
  echo "adb devices -l"
  echo ""
  exit 1
fi

declare -A ROLES
ROLES["$PHONE_A_SERIAL"]="PHONE_A_A06_SENDER"
ROLES["$PHONE_B_SERIAL"]="PHONE_B_S10_STORE_FORWARD_RELAY"
ROLES["$PHONE_C_SERIAL"]="PHONE_C_A16_DELAYED_RECEIVER_ACK"

for SERIAL in "$PHONE_A_SERIAL" "$PHONE_B_SERIAL" "$PHONE_C_SERIAL"; do
  echo "Checking $SERIAL ..."
  adb -s "$SERIAL" get-state >/dev/null
  {
    echo "SERIAL=$SERIAL"
    echo "ROLE=${ROLES[$SERIAL]}"
    echo "UTC=$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    adb -s "$SERIAL" shell getprop ro.product.model 2>/dev/null | sed 's/^/model=/'
    adb -s "$SERIAL" shell getprop ro.product.manufacturer 2>/dev/null | sed 's/^/manufacturer=/'
    adb -s "$SERIAL" shell getprop ro.build.version.release 2>/dev/null | sed 's/^/android=/'
    adb -s "$SERIAL" shell getprop ro.build.version.sdk 2>/dev/null | sed 's/^/sdk=/'
  } > "$OUT_DIR/${ROLES[$SERIAL]}_device_identity.txt"
done

cat > "$OUT_DIR/run_metadata.json" <<METAEOF
{
  "project": "MauriMesh",
  "runId": "$RUN_ID",
  "createdAtUtc": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "package": "$PKG",
  "proofTag": "$PROOF_TAG",
  "phoneA": {
    "role": "PHONE_A",
    "device": "A06",
    "serial": "$PHONE_A_SERIAL"
  },
  "phoneB": {
    "role": "PHONE_B",
    "device": "S10",
    "serial": "$PHONE_B_SERIAL"
  },
  "phoneC": {
    "role": "PHONE_C",
    "device": "A16",
    "serial": "$PHONE_C_SERIAL"
  },
  "proofTarget": "Store-forward raw-device evidence capture"
}
METAEOF

echo ""
echo "Launching MauriMesh on all three devices..."
for SERIAL in "$PHONE_A_SERIAL" "$PHONE_B_SERIAL" "$PHONE_C_SERIAL"; do
  adb -s "$SERIAL" shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1 || true
done

echo ""
echo "Clearing old logcat buffers for clean proof capture..."
for SERIAL in "$PHONE_A_SERIAL" "$PHONE_B_SERIAL" "$PHONE_C_SERIAL"; do
  adb -s "$SERIAL" logcat -c || true
done

echo ""
echo "Starting raw logcat capture..."
PIDS=()

start_logcat() {
  local SERIAL="$1"
  local ROLE="$2"
  local RAW_FILE="$OUT_DIR/${ROLE}_raw_logcat.log"

  adb -s "$SERIAL" logcat -v threadtime > "$RAW_FILE" 2>&1 &
  local PID="$!"
  PIDS+=("$PID")
  echo "$PID" > "$OUT_DIR/${ROLE}_logcat.pid"
  echo "Started $ROLE logcat PID=$PID"
}

start_logcat "$PHONE_A_SERIAL" "PHONE_A_A06_SENDER"
start_logcat "$PHONE_B_SERIAL" "PHONE_B_S10_STORE_FORWARD_RELAY"
start_logcat "$PHONE_C_SERIAL" "PHONE_C_A16_DELAYED_RECEIVER_ACK"

cat > "$OUT_DIR/operator_instructions.txt" <<'INSTEOF'
MAURIMESH RAW-DEVICE EVIDENCE RUN INSTRUCTIONS

1. Keep this terminal recording logs.
2. Open the Store-Forward Delay Proof screen on A06, S10, and A16.
3. Use one visible packetId.
4. Complete the full proof:
   A06 -> S10 store request
   S10 stores packet
   A16 offline/unavailable confirmed
   S10 hold delay
   A16 returns
   S10 forwards stored packet to A16
   A16 receives stored packet
   A16 ACKs S10
   S10 relays ACK to A06
   A06 receives final ACK
5. When complete, return to this terminal and press ENTER.
INSTEOF

echo ""
echo "============================================================"
echo "CAPTURE IS RUNNING"
echo "============================================================"
echo "Now complete the Store-Forward proof on the phones."
echo "When the proof is complete, press ENTER here to stop capture."
echo "============================================================"
read -r _

echo ""
log "Stopping logcat capture..."

for PID in "${PIDS[@]}"; do
  kill "$PID" >/dev/null 2>&1 || true
done

sleep 2

adb devices -l | tee "$OUT_DIR/adb_devices_after.txt" >/dev/null

echo ""
echo "Creating filtered proof logs..."
for ROLE in PHONE_A_A06_SENDER PHONE_B_S10_STORE_FORWARD_RELAY PHONE_C_A16_DELAYED_RECEIVER_ACK; do
  RAW_FILE="$OUT_DIR/${ROLE}_raw_logcat.log"
  FILTERED_FILE="$OUT_DIR/${ROLE}_maurimesh_filtered.log"

  if [ -f "$RAW_FILE" ]; then
    grep -E "MAURIMESH|packetId=|PACKET_ID|TX_|RX_|ACK_|STORE|FORWARD|HOLD|OFFLINE|RETURNS" "$RAW_FILE" > "$FILTERED_FILE" || true
  else
    touch "$FILTERED_FILE"
  fi
done

echo ""
echo "Extracting possible packet IDs..."
cat "$OUT_DIR"/*_maurimesh_filtered.log 2>/dev/null \
  | grep -Eo 'MMSF-[A-Z0-9]+-[A-Z0-9]+|MM3-[A-Z0-9]+-[A-Z0-9]+|MM-[A-Z0-9]+-[A-Z0-9]+' \
  | sort \
  | uniq -c \
  | sort -nr \
  > "$OUT_DIR/packet_id_candidates.txt" || true

echo ""
echo "Packet ID candidates:"
cat "$OUT_DIR/packet_id_candidates.txt" || true
echo ""

PACKET_ID="${PACKET_ID:-}"

if [ -z "$PACKET_ID" ]; then
  echo "Enter the packetId used in the proof."
  echo "Example: MMSF-TEJFNH-K3FKYM"
  read -r PACKET_ID
fi

echo "$PACKET_ID" > "$OUT_DIR/selected_packet_id.txt"

echo ""
echo "Running raw evidence verifier..."
node "$ROOT/tools/proof-verifiers/verify-maurimesh-raw-evidence-run.js" "$OUT_DIR" "$PACKET_ID" || true

echo ""
echo "Creating SHA-256 manifest for raw evidence folder..."
(
  cd "$OUT_DIR"
  find . -type f -maxdepth 1 -print0 \
    | sort -z \
    | xargs -0 shasum -a 256 \
    > RAW_DEVICE_EVIDENCE_SHA256SUMS.txt
)

echo ""
echo "Creating compressed archive..."
(
  cd "$ROOT"
  mkdir -p archives
  tar -czf "archives/maurimesh-raw-device-evidence-$RUN_ID.tar.gz" "evidence/raw-device/$RUN_ID"
)

echo ""
echo "============================================================"
echo "RAW-DEVICE EVIDENCE RUN COMPLETE"
echo "============================================================"
echo "Folder:"
echo "$OUT_DIR"
echo ""
echo "Archive:"
echo "$ROOT/archives/maurimesh-raw-device-evidence-$RUN_ID.tar.gz"
echo ""
echo "Selected packetId:"
echo "$PACKET_ID"
echo ""
echo "Next:"
echo "Open the verifier report inside the evidence folder."
echo "============================================================"
CAPEOF

cat > "$RAW_VERIFY" <<'JSEOF'
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
JSEOF

cat > "$KIT_VERIFY" <<'JSEOF'
#!/usr/bin/env node
const fs = require("fs");
const path = require("path");

const root = process.cwd();

const requiredFiles = [
  "scripts/proof-capture/maurimesh-raw-device-evidence-run.sh",
  "tools/proof-verifiers/verify-maurimesh-raw-evidence-run.js",
  "tools/proof-verifiers/verify-maurimesh-raw-device-evidence-kit.js",
  "docs/raw-device-evidence-kit/README.md",
  "docs/raw-device-evidence-kit/RAW_DEVICE_EVIDENCE_RUN_CHECKLIST.md",
  "docs/raw-device-evidence-kit/RAW_DEVICE_EVIDENCE_BOUNDARY.md"
];

function fail(reason, details = {}) {
  console.log("");
  console.log("============================================================");
  console.log("MAURIMESH RAW-DEVICE EVIDENCE KIT VERIFY");
  console.log("============================================================");
  console.log("RAW DEVICE KIT VERDICT: FAIL");
  console.log(`Reason: ${reason}`);
  if (Object.keys(details).length) console.log(JSON.stringify(details, null, 2));
  console.log("============================================================");
  console.log("");
  process.exit(1);
}

const missing = requiredFiles.filter((rel) => !fs.existsSync(path.join(root, rel)));

if (missing.length) {
  fail("Required kit files missing.", { missing });
}

console.log("");
console.log("============================================================");
console.log("MAURIMESH RAW-DEVICE EVIDENCE KIT VERIFY");
console.log("============================================================");
console.log("RAW DEVICE KIT VERDICT: PASS");
console.log("Status : READY_TO_CAPTURE");
console.log("Reason : Capture script, raw evidence verifier, checklist, and boundary document exist.");
console.log("============================================================");
console.log("");
JSEOF

cat > "$README" <<'MDEOF'
# MauriMesh Raw-Device Evidence Run Kit

## Status

**READY TO CAPTURE**

This kit prepares the next live proof run using real device logs from:

- PHONE_A: Samsung Galaxy A06 / Sender
- PHONE_B: Samsung Galaxy S10 / Store-forward relay
- PHONE_C: Samsung Galaxy A16 / Delayed receiver + ACK

## Important

Run the capture script on the Mac terminal where ADB can see the phones.

## Setup

On the Mac:

```bash
adb devices -l
````

Set the three serials:

```bash
export PHONE_A_SERIAL="A06_SERIAL_HERE"
export PHONE_B_SERIAL="S10_SERIAL_HERE"
export PHONE_C_SERIAL="A16_SERIAL_HERE"
```

Then run from project root:

```bash
bash scripts/proof-capture/maurimesh-raw-device-evidence-run.sh
```

## What It Captures

* ADB device list before and after
* Device identity files
* Raw logcat from A06
* Raw logcat from S10
* Raw logcat from A16
* Filtered MauriMesh proof logs
* Packet ID candidates
* Selected packet ID
* Raw evidence verifier report
* SHA-256 sums
* Compressed evidence archive

## Target Proof

Store-forward delayed delivery:

A06 sender → S10 stores packet → A16 unavailable → S10 hold delay → A16 returns → S10 forwards stored packet → A16 receives → A16 ACKs S10 → S10 relays ACK → A06 receives final ACK.
MDEOF

cat > "$CHECKLIST" <<'MDEOF'

# Raw-Device Evidence Run Checklist

## Before Starting

* [ ] A06 has MauriMesh installed.
* [ ] S10 has MauriMesh installed.
* [ ] A16 has MauriMesh installed.
* [ ] ADB sees all three phones.
* [ ] Screen recording is ready on all three phones.
* [ ] Battery level is safe on all devices.
* [ ] Packet ID will be visible or copied.
* [ ] Replit/project folder is synced to the Mac if needed.

## Terminal Setup

Run:

```bash
adb devices -l
```

Set:

```bash
export PHONE_A_SERIAL="A06_SERIAL_HERE"
export PHONE_B_SERIAL="S10_SERIAL_HERE"
export PHONE_C_SERIAL="A16_SERIAL_HERE"
```

Start capture:

```bash
bash scripts/proof-capture/maurimesh-raw-device-evidence-run.sh
```

## During Proof

* [ ] Start screen recording on A06.
* [ ] Start screen recording on S10.
* [ ] Start screen recording on A16.
* [ ] Open Store-Forward Delay Proof screen.
* [ ] Confirm one packet ID.
* [ ] Complete every store-forward stage.
* [ ] Approve the proof.
* [ ] Return to terminal and press ENTER.

## After Proof

* [ ] Confirm RAW EVIDENCE VERDICT.
* [ ] Save the evidence folder.
* [ ] Save the tar.gz archive.
* [ ] Copy packet ID into the master archive.
* [ ] Do not overwrite the raw logs.
  MDEOF

cat > "$BOUNDARY" <<'MDEOF'

# Raw-Device Evidence Boundary

## What This Kit Proves After Capture

When the capture run passes, it proves that the selected packet ID and required store-forward proof stages were found in raw ADB/logcat captures from the three-device evidence folder.

## What It Does Not Prove Yet

It does not prove:

* Independent third-party certification.
* RF-layer laboratory capture.
* Carrier approval.
* Emergency-service approval.
* Full production security audit.
* Long-duration unattended reliability.

## Correct Claim After PASS

The correct claim after a successful raw-device evidence run is:

**MauriMesh has a synchronized raw-device evidence folder showing the Store-Forward proof sequence across A06, S10, and A16 logs for one selected packet ID.**
MDEOF

chmod +x "$CAPTURE_SCRIPT" "$RAW_VERIFY" "$KIT_VERIFY"

echo ""
echo "Running raw-device evidence kit verifier..."
node "$KIT_VERIFY"

echo ""
echo "Creating kit archive..."
tar -czf "$ARCHIVE" 
docs/raw-device-evidence-kit 
scripts/proof-capture/maurimesh-raw-device-evidence-run.sh 
tools/proof-verifiers/verify-maurimesh-raw-evidence-run.js 
tools/proof-verifiers/verify-maurimesh-raw-device-evidence-kit.js

echo ""
echo "============================================================"
echo "MAURIMESH RAW-DEVICE EVIDENCE KIT COMPLETE"
echo "============================================================"
echo "Capture script:"
echo "$CAPTURE_SCRIPT"
echo ""
echo "Raw verifier:"
echo "$RAW_VERIFY"
echo ""
echo "Kit docs:"
echo "$KIT_DIR"
echo ""
echo "Archive:"
echo "$ARCHIVE"
echo ""
echo "Expected result: RAW DEVICE KIT VERDICT: PASS"
echo "============================================================"
