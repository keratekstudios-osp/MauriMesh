#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH COMPLETION STATUS AUDITOR"
echo "Completion % + missing integration report"
echo "============================================================"
echo ""

ROOT="$(pwd)"
DOCS="$ROOT/docs"
SCRIPTS="$ROOT/scripts"
REPORTS="$ROOT/reports"
BACKUP="$ROOT/backup-before-completion-status-auditor-$(date +%Y%m%d-%H%M%S)"

mkdir -p "$DOCS" "$SCRIPTS" "$REPORTS" "$BACKUP"

cat > "$BACKUP/README.txt" <<'TXT'
Backup marker before installing MauriMesh Completion Status Auditor.

This installer creates:
scripts/maurimesh-completion-status-auditor.mjs
docs/MAURIMESH_COMPLETION_STATUS_AUDIT_GUIDE.md
reports/

It does not delete or modify existing app code.
TXT

cat > "$SCRIPTS/maurimesh-completion-status-auditor.mjs" <<'JS'
import fs from "fs";
import path from "path";

const root = process.cwd();
const reportsDir = path.join(root, "reports");
fs.mkdirSync(reportsDir, { recursive: true });

const IGNORE_DIRS = new Set([
  ".git",
  "node_modules",
  ".gradle",
  "build",
  "dist",
  ".expo",
  ".next",
  "coverage",
  "ios/Pods",
]);

const SOURCE_EXTENSIONS = new Set([
  ".ts",
  ".tsx",
  ".js",
  ".jsx",
  ".mjs",
  ".cjs",
  ".kt",
  ".java",
  ".rs",
  ".swift",
  ".json",
  ".md",
  ".xml",
  ".gradle",
]);

function walk(dir, out = []) {
  if (!fs.existsSync(dir)) return out;

  const entries = fs.readdirSync(dir, { withFileTypes: true });

  for (const entry of entries) {
    const full = path.join(dir, entry.name);
    const rel = path.relative(root, full);

    if (entry.isDirectory()) {
      const ignored =
        IGNORE_DIRS.has(entry.name) ||
        IGNORE_DIRS.has(rel) ||
        rel.includes("node_modules") ||
        rel.includes(".git");

      if (!ignored) walk(full, out);
      continue;
    }

    const ext = path.extname(entry.name);
    if (SOURCE_EXTENSIONS.has(ext) || entry.name.includes("gradle")) {
      out.push(full);
    }
  }

  return out;
}

const files = walk(root);

function readSafe(file) {
  try {
    return fs.readFileSync(file, "utf8");
  } catch {
    return "";
  }
}

const corpus = files.map((file) => {
  const rel = path.relative(root, file);
  const text = readSafe(file);
  return { file, rel, text };
});

function findMatches(patterns) {
  const results = [];

  for (const item of corpus) {
    for (const pattern of patterns) {
      if (typeof pattern === "string") {
        if (item.text.toLowerCase().includes(pattern.toLowerCase())) {
          results.push({
            file: item.rel,
            pattern,
          });
        }
      } else if (pattern instanceof RegExp) {
        if (pattern.test(item.text)) {
          results.push({
            file: item.rel,
            pattern: pattern.toString(),
          });
        }
      }
    }
  }

  const seen = new Set();
  return results.filter((r) => {
    const key = `${r.file}:${r.pattern}`;
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  });
}

function statusFromScore(score) {
  if (score >= 90) return "working/near-complete";
  if (score >= 70) return "mostly integrated";
  if (score >= 45) return "partial";
  if (score >= 20) return "scaffolded";
  return "missing/high-risk";
}

const integrations = [
  {
    id: "offline-local-save",
    name: "Standalone Offline Local Save",
    weight: 10,
    required: [
      {
        label: "Offline save engine exists",
        weight: 20,
        patterns: ["OfflineSaveEngine", "maurimesh_offline_records_v1", "saveMessage", "saveProofEvent"],
      },
      {
        label: "App hydrates saved messages/proof/settings",
        weight: 20,
        patterns: ["getByScope", "loadMeshMessages", "AsyncStorage.getItem", "hydrate"],
      },
      {
        label: "Save actions wired to user changes",
        weight: 25,
        patterns: ["saveMessage(", "savePeer(", "saveFriend(", "saveSetting(", "saveQueueItem("],
      },
      {
        label: "Offline status UI exists",
        weight: 15,
        patterns: ["OfflineSaveStatusPanel", "Unsynced Events", "Standalone Offline Local Mode"],
      },
      {
        label: "Queued sync exists",
        weight: 20,
        patterns: ["OfflineFirstSyncEngine", "syncQueued", "syncStatus", "queued"],
      },
    ],
  },
  {
    id: "secure-auth",
    name: "Secure Auth + Session Boundary",
    weight: 8,
    required: [
      {
        label: "No public EXPO API key auth",
        weight: 25,
        antiPatterns: ["EXPO_PUBLIC_MESH_API_KEY", "apiKey"],
        patterns: ["Authorization", "Bearer"],
      },
      {
        label: "Server login requires real credential",
        weight: 25,
        patterns: ["password", "verifyPassword", "passwordHash", "SecureAuthEngine"],
      },
      {
        label: "Bearer token validation exists",
        weight: 20,
        patterns: ["requireAuth", "verifyBearer", "expiresAt", "revokedAt"],
      },
      {
        label: "Mobile sends bearer token",
        weight: 15,
        patterns: ["Authorization", "Bearer ${session.token}", "Bearer"],
      },
      {
        label: "Offline fallback login removed",
        weight: 15,
        antiPatterns: ["offline-token", "local-device", "fallback session"],
        patterns: ["Login blocked", "Authentication failed", "clearSession"],
      },
    ],
  },
  {
    id: "api-server-activity",
    name: "API Server Activity",
    weight: 7,
    required: [
      {
        label: "API server route files exist",
        weight: 20,
        patterns: ["Router", "app.listen", "listen(", "/healthz"],
      },
      {
        label: "Health endpoint exists and is safe",
        weight: 15,
        patterns: ["healthz", "status", "ok"],
      },
      {
        label: "Readiness/status endpoint exists",
        weight: 15,
        patterns: ["readiness", "runtimeTruth", "ProductionReadiness"],
      },
      {
        label: "Simulation/API activity endpoint exists",
        weight: 25,
        patterns: ["/sim", "sim/activity", "simulation", "real-simulation"],
      },
      {
        label: "Protected API routes use auth",
        weight: 25,
        patterns: ["requireAuth", "Authorization", "Bearer"],
      },
    ],
  },
  {
    id: "proof-ledger",
    name: "Proof Ledger",
    weight: 9,
    required: [
      {
        label: "Proof ledger engine exists",
        weight: 20,
        patterns: ["ProofLedgerEngine", "ProofEventLedger", "proofLedgerEngine", "recordProof"],
      },
      {
        label: "Packet sent/received/ACK events recorded",
        weight: 25,
        patterns: ["PACKET_SENT", "PACKET_RECEIVED", "ACK_RECEIVED", "packet_sent", "ack_received"],
      },
      {
        label: "Simulation vs physical proof separated",
        weight: 20,
        patterns: ["simulation", "physical", "validatePhysicalProof", "PHYSICAL_PROOF_CONFIRMED"],
      },
      {
        label: "Proof ledger UI exists",
        weight: 15,
        patterns: ["ProofLedgerPanel", "proof ledger", "Proof"],
      },
      {
        label: "Proof persistence exists",
        weight: 20,
        patterns: ["proof_ledger", "saveProofEvent", "AsyncStorage", "insert"],
      },
    ],
  },
  {
    id: "ble-runtime",
    name: "BLE Runtime Discovery + Send/Receive",
    weight: 10,
    required: [
      {
        label: "BLE scan exists",
        weight: 20,
        patterns: ["BlePlxCompat", "startDeviceScan", "BLE_SCAN", "TX_BLE_FOUND"],
      },
      {
        label: "BLE advertise/GATT server exists",
        weight: 20,
        patterns: ["advertise", "BLE_ADVERTISING_STARTED", "GATT", "onCharacteristicWriteRequest"],
      },
      {
        label: "BLE send path exists",
        weight: 20,
        patterns: ["TX_BLE_START", "sendViaBle", "trySendViaBle", "writeCharacteristic"],
      },
      {
        label: "BLE receive path exists",
        weight: 20,
        patterns: ["RX_BLE", "handleIncomingPacket", "packet_received", "DELIVER"],
      },
      {
        label: "BLE errors/logs captured",
        weight: 20,
        patterns: ["TX_BLE_ERROR", "RuntimeErrorLedger", "logcat", "MauriMeshProof"],
      },
    ],
  },
  {
    id: "ack-routing",
    name: "ACK Lifecycle + Reverse Path",
    weight: 8,
    required: [
      {
        label: "ACK send/receive exists",
        weight: 30,
        patterns: ["ACK", "ackId", "ACK_RECEIVED", "markBleAck"],
      },
      {
        label: "Reverse-path ACK concept exists",
        weight: 20,
        patterns: ["reverse", "Reverse", "reverse path", "Strict Reverse"],
      },
      {
        label: "ACK validation exists",
        weight: 20,
        patterns: ["validateAck", "validateMauriMeshAckWithRustCore"],
      },
      {
        label: "ACK proof recorded",
        weight: 15,
        patterns: ["ACK_RECEIVED", "ack_received", "proof"],
      },
      {
        label: "ACK timeout/store-forward handling exists",
        weight: 15,
        patterns: ["ACK_WAITING", "timeout", "pendingAck", "store-forward"],
      },
    ],
  },
  {
    id: "hybrid-signal-hop",
    name: "Hybrid Signal Hop BLE → Wi-Fi → Internet",
    weight: 10,
    required: [
      {
        label: "Hybrid hop engine exists",
        weight: 20,
        patterns: ["HybridSignalHopEngine", "HybridRouteEngine", "HybridSignalHopPanel"],
      },
      {
        label: "BLE discovery starts hybrid path",
        weight: 15,
        patterns: ["BLE_DISCOVERY", "BLE_PEER_FOUND", "CAPABILITY_EXCHANGE"],
      },
      {
        label: "Wi-Fi upgrade exists",
        weight: 20,
        patterns: ["WIFI_CANDIDATE_FOUND", "WIFI_UPGRADE_ATTEMPT", "WIFI_DELIVERY", "sendViaWifi"],
      },
      {
        label: "Internet gateway path exists",
        weight: 15,
        patterns: ["INTERNET_GATEWAY_FOUND", "INTERNET_DELIVERY", "sendViaInternet", "internetGatewayUrl"],
      },
      {
        label: "Store-forward fallback exists",
        weight: 15,
        patterns: ["STORE_FORWARD_QUEUED", "queueStoreForward", "STORE_FORWARD"],
      },
      {
        label: "Self-healing learning exists",
        weight: 15,
        patterns: ["HybridLearningEngine", "recordSuccess", "recordFailure", "SELF_HEALED"],
      },
    ],
  },
  {
    id: "rust-core",
    name: "Rust Core Engine",
    weight: 8,
    required: [
      {
        label: "Rust crate exists",
        weight: 20,
        filePatterns: ["rust/maurimesh-core/Cargo.toml"],
        patterns: ["maurimesh-core"],
      },
      {
        label: "Rust packet/route/ack/proof modules exist",
        weight: 25,
        patterns: ["score_route", "validate_ack", "build_packet", "create_proof_event"],
      },
      {
        label: "TypeScript Rust bridge exists",
        weight: 20,
        patterns: ["RustCoreBridge", "RustFallbackEngine", "typescript-fallback"],
      },
      {
        label: "Rust UI panel exists",
        weight: 15,
        patterns: ["RustCoreStatusPanel", "Run Full Rust Core Flow"],
      },
      {
        label: "App does not depend on 127.0.0.1:4300",
        weight: 20,
        antiPatterns: ["127.0.0.1:4300", "localhost:4300"],
        patterns: ["typescript-fallback", "RustCoreBridge"],
      },
    ],
  },
  {
    id: "store-forward",
    name: "Store-and-Forward Queue",
    weight: 8,
    required: [
      {
        label: "Queue engine/store exists",
        weight: 25,
        patterns: ["store-forward", "StoreForward", "queueStoreForward", "saveQueueItem"],
      },
      {
        label: "Retry decision exists",
        weight: 20,
        patterns: ["retry", "retryCount", "maxRetries", "decideQueue"],
      },
      {
        label: "Pending ACK queue exists",
        weight: 20,
        patterns: ["pendingAck", "ACK_WAITING", "ackReceived"],
      },
      {
        label: "Offline persistence for queue exists",
        weight: 20,
        patterns: ["saveQueueItem", "syncStatus", "queued", "AsyncStorage"],
      },
      {
        label: "Queue failure/drop policy exists",
        weight: 15,
        patterns: ["shouldDrop", "max retries", "manual review"],
      },
    ],
  },
  {
    id: "dashboard-ui",
    name: "Dashboard + Monitoring UI",
    weight: 7,
    required: [
      {
        label: "Dashboard exists",
        weight: 20,
        patterns: ["Dashboard", "dashboard", "Runtime", "Monitoring"],
      },
      {
        label: "Proof/debug panels exist",
        weight: 20,
        patterns: ["ProofLedgerPanel", "RustCoreStatusPanel", "HybridSignalHopPanel", "OfflineSaveStatusPanel"],
      },
      {
        label: "API connected/offline status exists",
        weight: 15,
        patterns: ["API Connected", "API Disconnected", "Offline Local Mode"],
      },
      {
        label: "Real-time activity/status exists",
        weight: 20,
        patterns: ["poll", "setInterval", "latest", "activity", "runtime truth"],
      },
      {
        label: "Simulation vs physical badge exists",
        weight: 25,
        patterns: ["Simulation", "Physical", "simulation", "physical"],
      },
    ],
  },
  {
    id: "testing-quality-gate",
    name: "Testing + Quality Gate",
    weight: 7,
    required: [
      {
        label: "Test scripts exist",
        weight: 25,
        patterns: ["test-rust-core-engine", "test-hybrid-signal-hop", "test-production-engines", "completion-status"],
      },
      {
        label: "Production readiness gate exists",
        weight: 20,
        patterns: ["ProductionReadinessGate", "readiness", "blockers", "warnings"],
      },
      {
        label: "No-JS extension/check gate exists",
        weight: 10,
        patterns: ["check:no-js-ext", "extension scan", ".js-extension"],
      },
      {
        label: "Runtime error ledger exists",
        weight: 20,
        patterns: ["RuntimeErrorLedger", "recordRuntimeTransportError"],
      },
      {
        label: "Build/test commands documented",
        weight: 25,
        patterns: ["npm run", "cargo test", "gradlew", "EAS", "assemble"],
      },
    ],
  },
  {
    id: "physical-two-phone-proof",
    name: "Physical Two-Phone Proof",
    weight: 8,
    required: [
      {
        label: "Two-phone proof mode exists",
        weight: 20,
        patterns: ["TwoPhoneProofMode", "startTwoPhoneProofSender", "startTwoPhoneProofReceiver"],
      },
      {
        label: "Physical BLE logs exist",
        weight: 25,
        patterns: ["MauriMeshProof", "TX_BLE_START", "RX_BLE", "ACK_RECEIVED", "logcat"],
      },
      {
        label: "Sender/receiver UI exists",
        weight: 15,
        patterns: ["Start Sender", "Start Receiver", "PHONE_A", "PHONE_B"],
      },
      {
        label: "ACK completes delivery",
        weight: 20,
        patterns: ["DELIVERED", "ACK_RECEIVED", "markBleAck"],
      },
      {
        label: "Physical proof separated from simulation",
        weight: 20,
        patterns: ["PHYSICAL_PROOF_CONFIRMED", "simulation", "physical"],
      },
    ],
  },
];

function evaluateCriterion(criterion) {
  const matches = findMatches(criterion.patterns ?? []);
  const fileMatches = [];

  for (const fp of criterion.filePatterns ?? []) {
    if (fs.existsSync(path.join(root, fp))) {
      fileMatches.push({ file: fp, pattern: "file exists" });
    }
  }

  const antiMatches = findMatches(criterion.antiPatterns ?? []);

  let passed = matches.length > 0 || fileMatches.length > 0;
  let antiPenalty = antiMatches.length > 0;

  let score = passed ? criterion.weight : 0;
  if (antiPenalty) {
    score = Math.max(0, Math.round(score * 0.35));
  }

  return {
    label: criterion.label,
    weight: criterion.weight,
    score,
    passed,
    antiPenalty,
    matches: [...fileMatches, ...matches].slice(0, 8),
    antiMatches: antiMatches.slice(0, 8),
  };
}

function evaluateIntegration(integration) {
  const criteria = integration.required.map(evaluateCriterion);
  const max = integration.required.reduce((sum, c) => sum + c.weight, 0);
  const raw = criteria.reduce((sum, c) => sum + c.score, 0);
  const percent = max === 0 ? 0 : Math.round((raw / max) * 100);

  const missing = criteria
    .filter((c) => !c.passed || c.antiPenalty)
    .map((c) => ({
      item: c.label,
      reason: c.antiPenalty
        ? "Risk pattern still present or incomplete removal."
        : "Required code/path not found by audit.",
      antiMatches: c.antiMatches,
    }));

  return {
    id: integration.id,
    name: integration.name,
    weight: integration.weight,
    percent,
    status: statusFromScore(percent),
    criteria,
    missing,
  };
}

const evaluated = integrations.map(evaluateIntegration);

const totalWeight = evaluated.reduce((sum, item) => sum + item.weight, 0);
const weightedScore = evaluated.reduce((sum, item) => sum + item.percent * item.weight, 0);
const overallPercent = Math.round(weightedScore / totalWeight);

const integrationsLeft = evaluated
  .filter((item) => item.percent < 90)
  .sort((a, b) => a.percent - b.percent);

const blockers = evaluated
  .flatMap((item) =>
    item.missing.map((missing) => ({
      integration: item.name,
      item: missing.item,
      reason: missing.reason,
    }))
  );

const report = {
  generatedAt: new Date().toISOString(),
  root,
  scannedFiles: files.length,
  overallPercent,
  overallStatus: statusFromScore(overallPercent),
  integrations: evaluated,
  integrationsLeft: integrationsLeft.map((item) => ({
    id: item.id,
    name: item.name,
    percent: item.percent,
    status: item.status,
    missing: item.missing.map((m) => m.item),
  })),
  blockers,
};

const jsonPath = path.join(reportsDir, "maurimesh-completion-status.json");
fs.writeFileSync(jsonPath, JSON.stringify(report, null, 2));

function mdEscape(value) {
  return String(value ?? "").replace(/\|/g, "\\|");
}

let md = "";
md += "# MauriMesh Completion Status Report\n\n";
md += `Generated: ${report.generatedAt}\n\n`;
md += `Scanned files: ${report.scannedFiles}\n\n`;
md += `## Overall Completion\n\n`;
md += `**${overallPercent}% — ${report.overallStatus}**\n\n`;

md += "## Integration Status\n\n";
md += "| Integration | Completion | Status |\n";
md += "|---|---:|---|\n";

for (const item of evaluated.sort((a, b) => b.percent - a.percent)) {
  md += `| ${mdEscape(item.name)} | ${item.percent}% | ${mdEscape(item.status)} |\n`;
}

md += "\n## Integrations Left To Complete\n\n";

if (integrationsLeft.length === 0) {
  md += "No integrations detected below 90% by this audit.\n\n";
} else {
  for (const item of integrationsLeft) {
    md += `### ${item.name} — ${item.percent}% (${item.status})\n\n`;
    if (item.missing.length === 0) {
      md += "- No missing criteria detected, but score remains below complete due to partial evidence.\n";
    } else {
      for (const missing of item.missing) {
        md += `- ${missing.item}: ${missing.reason}\n`;
      }
    }
    md += "\n";
  }
}

md += "## Detailed Criteria\n\n";

for (const item of evaluated) {
  md += `### ${item.name}\n\n`;
  md += `Completion: **${item.percent}%**\n\n`;
  md += "| Criterion | Score | Evidence |\n";
  md += "|---|---:|---|\n";

  for (const criterion of item.criteria) {
    const evidence = criterion.matches.length
      ? criterion.matches.map((m) => `${m.file} (${m.pattern})`).join("<br>")
      : criterion.antiPenalty
        ? `Risk found: ${criterion.antiMatches.map((m) => `${m.file} (${m.pattern})`).join("<br>")}`
        : "No evidence found";

    md += `| ${mdEscape(criterion.label)} | ${criterion.score}/${criterion.weight} | ${mdEscape(evidence)} |\n`;
  }

  md += "\n";
}

md += "## Next Replit Agent Instruction\n\n";
md += "```text\n";
md += "Open reports/maurimesh-completion-status.json and reports/maurimesh-completion-status.md.\n";
md += "Complete the lowest percentage integrations first.\n";
md += "Do not mark any integration complete unless the real UI path, runtime path, device/native path, persistence path, proof ledger path, and tests are wired.\n";
md += "Report exact files changed and rerun node scripts/maurimesh-completion-status-auditor.mjs after each integration.\n";
md += "```\n";

const mdPath = path.join(reportsDir, "maurimesh-completion-status.md");
fs.writeFileSync(mdPath, md);

console.log("");
console.log("============================================================");
console.log("MAURIMESH COMPLETION STATUS");
console.log("============================================================");
console.log("");
console.log(`Overall Completion: ${overallPercent}% — ${report.overallStatus}`);
console.log(`Scanned files: ${files.length}`);
console.log("");
console.log("Integration Status:");
for (const item of evaluated.sort((a, b) => b.percent - a.percent)) {
  console.log(`- ${item.name}: ${item.percent}% — ${item.status}`);
}
console.log("");
console.log("Integrations Left To Complete:");
if (integrationsLeft.length === 0) {
  console.log("- None detected below 90%.");
} else {
  for (const item of integrationsLeft) {
    console.log(`- ${item.name}: ${item.percent}% — ${item.status}`);
    for (const missing of item.missing.slice(0, 5)) {
      console.log(`  • ${missing.item}`);
    }
  }
}
console.log("");
console.log("Reports:");
console.log(`- ${path.relative(root, mdPath)}`);
console.log(`- ${path.relative(root, jsonPath)}`);
console.log("");
JS

cat > "$DOCS/MAURIMESH_COMPLETION_STATUS_AUDIT_GUIDE.md" <<'MD'
# MauriMesh Completion Status Audit Guide

## Run

```bash
node scripts/maurimesh-completion-status-auditor.mjs
