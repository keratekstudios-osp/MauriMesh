#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH STORE-FORWARD PROOF VERIFIER INSTALL"
echo "External verifier for packetId MMSF-TEJFNH-K3FKYM"
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"

mkdir -p \
  "$ROOT/tools/proof-verifiers" \
  "$ROOT/docs/proof-archives/store-forward" \
  "$ROOT/docs/proof-certificates"

LOG_FILE="$ROOT/docs/proof-archives/store-forward/store_forward_MMSF-TEJFNH-K3FKYM.log"
VERIFIER="$ROOT/tools/proof-verifiers/verify-store-forward-proof.js"
CERT="$ROOT/docs/proof-certificates/store_forward_MMSF-TEJFNH-K3FKYM_certificate.md"
REPORT="$ROOT/docs/proof-certificates/store_forward_MMSF-TEJFNH-K3FKYM_verifier_report.json"

backup_if_exists() {
  local file="$1"
  if [ -f "$file" ]; then
    cp "$file" "$file.backup-$STAMP"
    echo "Backup created: $file.backup-$STAMP"
  fi
}

backup_if_exists "$LOG_FILE"
backup_if_exists "$VERIFIER"
backup_if_exists "$CERT"
backup_if_exists "$REPORT"

cat > "$LOG_FILE" <<'LOGEOF'
2026-06-13T16:45:57.828Z | MAURIMESH_STORE_FORWARD_PROOF | PHONE_A | A06 | PACKET_ID_CONFIRMED | packetId=MMSF-TEJFNH-K3FKYM | Store-forward packetId confirmed.
2026-06-13T16:46:34.318Z | MAURIMESH_STORE_FORWARD_PROOF | PHONE_A | A06 | TX_A06_TO_S10_STORE_REQUEST | packetId=MMSF-TEJFNH-K3FKYM | A06 TX -> S10 Store Request
2026-06-13T16:46:35.618Z | MAURIMESH_STORE_FORWARD_PROOF | PHONE_B | S10 | S10_STORE_PACKET | packetId=MMSF-TEJFNH-K3FKYM | S10 Stores Packet
2026-06-13T16:46:38.433Z | MAURIMESH_STORE_FORWARD_PROOF | PHONE_C | A16 | A16_OFFLINE_CONFIRMED | packetId=MMSF-TEJFNH-K3FKYM | A16 Offline / Unavailable Confirmed
2026-06-13T16:46:45.420Z | MAURIMESH_STORE_FORWARD_PROOF | PHONE_B | S10 | S10_HOLD_DELAY | packetId=MMSF-TEJFNH-K3FKYM | S10 Hold Delay
2026-06-13T16:46:50.099Z | MAURIMESH_STORE_FORWARD_PROOF | PHONE_C | A16 | A16_RETURNS | packetId=MMSF-TEJFNH-K3FKYM | A16 Returns / Rediscovered
2026-06-13T16:46:56.316Z | MAURIMESH_STORE_FORWARD_PROOF | PHONE_B | S10 | S10_FORWARD_STORED_TO_A16 | packetId=MMSF-TEJFNH-K3FKYM | S10 Forwards Stored Packet -> A16
2026-06-13T16:46:58.776Z | MAURIMESH_STORE_FORWARD_PROOF | PHONE_C | A16 | RX_A16_STORED_PACKET | packetId=MMSF-TEJFNH-K3FKYM | A16 Receives Stored Packet
2026-06-13T16:47:01.499Z | MAURIMESH_STORE_FORWARD_PROOF | PHONE_C | A16 | ACK_A16_TO_S10_STORED | packetId=MMSF-TEJFNH-K3FKYM | A16 ACK -> S10
2026-06-13T16:47:14.960Z | MAURIMESH_STORE_FORWARD_PROOF | PHONE_B | S10 | ACK_RELAY_S10_TO_A06_STORED | packetId=MMSF-TEJFNH-K3FKYM | S10 ACK Relay -> A06
2026-06-13T16:47:46.027Z | MAURIMESH_STORE_FORWARD_PROOF | PHONE_A | A06 | ACK_RECEIVED_A06_STORED | packetId=MMSF-TEJFNH-K3FKYM | A06 ACK Received
LOGEOF

cat > "$VERIFIER" <<'JSEOF'
#!/usr/bin/env node
const fs = require("fs");
const path = require("path");

const root = process.cwd();

const expectedPacketId = "MMSF-TEJFNH-K3FKYM";

const logFile =
  process.argv[2] ||
  path.join(root, "docs/proof-archives/store-forward/store_forward_MMSF-TEJFNH-K3FKYM.log");

const reportFile = path.join(
  root,
  "docs/proof-certificates/store_forward_MMSF-TEJFNH-K3FKYM_verifier_report.json"
);

const certFile = path.join(
  root,
  "docs/proof-certificates/store_forward_MMSF-TEJFNH-K3FKYM_certificate.md"
);

const expectedStages = [
  {
    role: "PHONE_A",
    device: "A06",
    stage: "PACKET_ID_CONFIRMED",
    meaning: "A06 locks the store-forward packet identity."
  },
  {
    role: "PHONE_A",
    device: "A06",
    stage: "TX_A06_TO_S10_STORE_REQUEST",
    meaning: "A06 sends the packet to S10 for store-forward relay."
  },
  {
    role: "PHONE_B",
    device: "S10",
    stage: "S10_STORE_PACKET",
    meaning: "S10 stores the packet instead of dropping it."
  },
  {
    role: "PHONE_C",
    device: "A16",
    stage: "A16_OFFLINE_CONFIRMED",
    meaning: "A16 temporary unavailability is explicitly logged."
  },
  {
    role: "PHONE_B",
    device: "S10",
    stage: "S10_HOLD_DELAY",
    meaning: "S10 holds the packet across delay."
  },
  {
    role: "PHONE_C",
    device: "A16",
    stage: "A16_RETURNS",
    meaning: "A16 returns / is rediscovered."
  },
  {
    role: "PHONE_B",
    device: "S10",
    stage: "S10_FORWARD_STORED_TO_A16",
    meaning: "S10 forwards the stored packet to A16."
  },
  {
    role: "PHONE_C",
    device: "A16",
    stage: "RX_A16_STORED_PACKET",
    meaning: "A16 receives the stored packet."
  },
  {
    role: "PHONE_C",
    device: "A16",
    stage: "ACK_A16_TO_S10_STORED",
    meaning: "A16 sends stored-packet ACK to S10."
  },
  {
    role: "PHONE_B",
    device: "S10",
    stage: "ACK_RELAY_S10_TO_A06_STORED",
    meaning: "S10 relays the ACK back to A06."
  },
  {
    role: "PHONE_A",
    device: "A06",
    stage: "ACK_RECEIVED_A06_STORED",
    meaning: "A06 receives final store-forward ACK."
  }
];

function fail(reason, details = {}) {
  return {
    verdict: "FAIL",
    packetId: expectedPacketId,
    reason,
    ...details
  };
}

function pass(details = {}) {
  return {
    verdict: "PASS",
    packetId: expectedPacketId,
    reason: "All required store-forward proof stages were found in correct order with matching packetId, role, and device.",
    ...details
  };
}

function parseLine(line, index) {
  const parts = line.split("|").map((p) => p.trim());
  if (parts.length < 7) {
    return {
      invalid: true,
      index,
      line,
      reason: "Expected at least 7 pipe-delimited fields."
    };
  }

  const timestamp = parts[0];
  const proofTag = parts[1];
  const role = parts[2];
  const device = parts[3];
  const stage = parts[4];
  const packetPart = parts[5];
  const message = parts.slice(6).join(" | ");

  const packetMatch = packetPart.match(/packetId=([A-Z0-9-]+)/);

  return {
    index,
    timestamp,
    proofTag,
    role,
    device,
    stage,
    packetId: packetMatch ? packetMatch[1] : null,
    message,
    line
  };
}

function verify() {
  if (!fs.existsSync(logFile)) {
    return fail("Log file not found.", { logFile });
  }

  const raw = fs.readFileSync(logFile, "utf8");
  const lines = raw
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter(Boolean);

  if (lines.length === 0) {
    return fail("Log file is empty.", { logFile });
  }

  const events = lines.map(parseLine);

  const invalid = events.filter((event) => event.invalid);
  if (invalid.length > 0) {
    return fail("Invalid log line format detected.", { invalid });
  }

  const wrongTag = events.filter(
    (event) => event.proofTag !== "MAURIMESH_STORE_FORWARD_PROOF"
  );
  if (wrongTag.length > 0) {
    return fail("Wrong proof tag detected.", { wrongTag });
  }

  const packetIds = [...new Set(events.map((event) => event.packetId))];

  if (packetIds.length !== 1 || packetIds[0] !== expectedPacketId) {
    return fail("Packet ID mismatch detected.", {
      expectedPacketId,
      observedPacketIds: packetIds
    });
  }

  let cursor = 0;
  const matched = [];

  for (const expected of expectedStages) {
    const foundIndex = events.findIndex((event, index) => {
      return (
        index >= cursor &&
        event.role === expected.role &&
        event.device === expected.device &&
        event.stage === expected.stage &&
        event.packetId === expectedPacketId
      );
    });

    if (foundIndex === -1) {
      return fail("Missing required proof stage.", {
        missing: expected,
        matchedStages: matched,
        remainingEvents: events.slice(cursor)
      });
    }

    matched.push({
      order: matched.length + 1,
      expected,
      actual: events[foundIndex]
    });

    cursor = foundIndex + 1;
  }

  const timestamps = matched.map((item) => item.actual.timestamp);
  const firstTime = Date.parse(timestamps[0]);
  const lastTime = Date.parse(timestamps[timestamps.length - 1]);

  const elapsedMs =
    Number.isFinite(firstTime) && Number.isFinite(lastTime)
      ? lastTime - firstTime
      : null;

  const requiredSpecials = [
    "A16_OFFLINE_CONFIRMED",
    "S10_HOLD_DELAY",
    "A16_RETURNS",
    "ACK_RECEIVED_A06_STORED"
  ];

  const missingSpecials = requiredSpecials.filter(
    (stage) => !events.some((event) => event.stage === stage)
  );

  if (missingSpecials.length > 0) {
    return fail("Missing store-forward delay special condition.", {
      missingSpecials
    });
  }

  return pass({
    logFile,
    eventCount: events.length,
    verifiedStageCount: matched.length,
    requiredStageCount: expectedStages.length,
    elapsedMs,
    elapsedSeconds: elapsedMs === null ? null : +(elapsedMs / 1000).toFixed(3),
    matchedStages: matched.map((item) => ({
      order: item.order,
      timestamp: item.actual.timestamp,
      role: item.actual.role,
      device: item.actual.device,
      stage: item.actual.stage,
      packetId: item.actual.packetId,
      meaning: item.expected.meaning,
      message: item.actual.message
    }))
  });
}

function writeOutputs(result) {
  fs.mkdirSync(path.dirname(reportFile), { recursive: true });

  fs.writeFileSync(reportFile, JSON.stringify(result, null, 2));

  const stageRows = (result.matchedStages || [])
    .map((stage) => {
      return `| ${stage.order} | ${stage.timestamp} | ${stage.role} | ${stage.device} | ${stage.stage} | ${stage.packetId} |`;
    })
    .join("\n");

  const cert = `# MauriMesh Store-Forward Delay Proof — External Verifier ${result.verdict}

## Proof Identity

- Proof: Store-Forward Delay Proof
- Packet ID: \`${expectedPacketId}\`
- External verifier result: **${result.verdict}**
- Log file: \`${logFile}\`
- Verified at: ${new Date().toISOString()}

## Verdict

${result.verdict === "PASS" ? "The cloned proof log passed external verification." : "The cloned proof log failed external verification."}

Reason: ${result.reason}

## Required Store-Forward Chain

A06 sender → S10 store-forward relay → A16 delayed receiver returns → A16 ACK → S10 ACK relay → A06 final ACK.

## Verified Stage Table

| # | Timestamp | Role | Device | Stage | Packet ID |
|---:|---|---|---|---|---|
${stageRows || "| - | - | - | - | - | - |"}

## Verification Rules Applied

1. Same packet ID across all proof events.
2. Correct proof tag: \`MAURIMESH_STORE_FORWARD_PROOF\`.
3. Correct role/device binding: PHONE_A/A06, PHONE_B/S10, PHONE_C/A16.
4. Required stage order preserved.
5. Temporary receiver loss confirmed: \`A16_OFFLINE_CONFIRMED\`.
6. Store delay confirmed: \`S10_HOLD_DELAY\`.
7. Receiver rediscovery confirmed: \`A16_RETURNS\`.
8. Final ACK returned to A06: \`ACK_RECEIVED_A06_STORED\`.

## Timing

- Event count: ${result.eventCount ?? "N/A"}
- Verified stages: ${result.verifiedStageCount ?? "N/A"} / ${result.requiredStageCount ?? expectedStages.length}
- Elapsed milliseconds: ${result.elapsedMs ?? "N/A"}
- Elapsed seconds: ${result.elapsedSeconds ?? "N/A"}

## Archive Status

This certificate is derived from the cloned proof log for packet \`${expectedPacketId}\`.
Keep this certificate, the copied proof report, the screenshot, and the original device logs together.
`;

  fs.writeFileSync(certFile, cert);
}

const result = verify();
writeOutputs(result);

console.log("");
console.log("============================================================");
console.log("MAURIMESH STORE-FORWARD EXTERNAL VERIFIER");
console.log("============================================================");
console.log(`Verdict: ${result.verdict}`);
console.log(`Packet : ${result.packetId}`);
console.log(`Reason : ${result.reason}`);
console.log(`Report : ${reportFile}`);
console.log(`Cert   : ${certFile}`);
console.log("============================================================");
console.log("");

if (result.verdict !== "PASS") {
  process.exit(1);
}
JSEOF

chmod +x "$VERIFIER"

echo ""
echo "Running verifier..."
node "$VERIFIER" "$LOG_FILE"

echo ""
echo "============================================================"
echo "STORE-FORWARD PROOF VERIFIER COMPLETE"
echo "============================================================"
echo "Log cloned to:"
echo "$LOG_FILE"
echo ""
echo "Verifier:"
echo "$VERIFIER"
echo ""
echo "Certificate:"
echo "$CERT"
echo ""
echo "JSON report:"
echo "$REPORT"
echo ""
echo "Expected result: PASS"
echo "============================================================"
