import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root      = path.resolve(__dirname, "..");
const base      = path.join(root, "artifacts", "messenger-mobile", "src", "maurimesh", "hybrid-hop");

const required = [
  "types.ts",
  "hash.ts",
  "HybridLearningEngine.ts",
  "HybridProofLedger.ts",
  "HybridCapabilityExchangeEngine.ts",
  "HybridRouteEngine.ts",
  "HybridTransportAdapter.ts",
  "HybridSignalHopEngine.ts",
  "HybridSimulationEngine.ts",
  "index.ts",
  "ui/HybridSignalHopPanel.tsx",
];

let failed = 0;

console.log("\n=== MauriMesh Hybrid Signal Hop Engine — file checks ===\n");

for (const file of required) {
  const full = path.join(base, file);
  if (!fs.existsSync(full)) {
    console.log(`  FAIL  missing ${file}`);
    failed += 1;
  } else {
    console.log(`  PASS  found   ${file}`);
  }
}

// Check device-proof wiring
const deviceProof = path.join(root, "artifacts", "messenger-mobile", "app", "device-proof.tsx");
const proofSrc    = fs.existsSync(deviceProof) ? fs.readFileSync(deviceProof, "utf8") : "";
const proofWired  = proofSrc.includes("HybridSignalHopPanel");
if (!proofWired) {
  console.log("  FAIL  HybridSignalHopPanel not found in device-proof.tsx");
  failed += 1;
} else {
  console.log("  PASS  HybridSignalHopPanel wired in device-proof.tsx");
}

// Check productionRuntime wiring
const runtimePath = path.join(
  root,
  "artifacts",
  "messenger-mobile",
  "src",
  "maurimesh",
  "production-engines",
  "productionRuntime.ts",
);
const runtimeSrc   = fs.existsSync(runtimePath) ? fs.readFileSync(runtimePath, "utf8") : "";
const runtimeWired = runtimeSrc.includes("hybridSignalHopEngine");
if (!runtimeWired) {
  console.log("  FAIL  hybridSignalHopEngine not wired in productionRuntime.ts");
  failed += 1;
} else {
  console.log("  PASS  hybridSignalHopEngine wired in productionRuntime.ts");
}

// Check docs
const docsPath = path.join(root, "docs", "HYBRID_SIGNAL_HOP_AGENT_PROMPT.md");
if (!fs.existsSync(docsPath)) {
  console.log("  FAIL  missing docs/HYBRID_SIGNAL_HOP_AGENT_PROMPT.md");
  failed += 1;
} else {
  console.log("  PASS  found docs/HYBRID_SIGNAL_HOP_AGENT_PROMPT.md");
}

console.log();

if (failed > 0) {
  console.log(`FAILED: ${failed} issue(s).\n`);
  process.exit(1);
}

console.log("ALL HYBRID SIGNAL HOP FILE CHECKS PASSED.\n");
