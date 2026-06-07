#!/usr/bin/env bash
set -euo pipefail

echo "=================================================="
echo "MauriMesh 155+ Layer Operating Runtime Installer"
echo "Structure: 12 domains x 13 layers = 156 layers"
echo "Safe merge mode: ON"
echo "Native destructive changes: OFF"
echo "=================================================="

mkdir -p src/operating backups

if [ -f package.json ]; then
  cp package.json "backups/package.json.155-operating.$(date +%Y%m%d-%H%M%S).bak"
fi

cat > src/operating/mauriOperatingTypes.ts <<'TS'
export type MauriOperatingDomain =
  | "foundation"
  | "physical"
  | "transport"
  | "packet"
  | "routing"
  | "learning"
  | "healing"
  | "tikanga"
  | "whanau"
  | "observability"
  | "experience"
  | "proof";

export type MauriLayerState =
  | "idle"
  | "observing"
  | "ready"
  | "learning"
  | "fallback"
  | "repairing"
  | "blocked";

export type MauriLayerCriticality =
  | "core"
  | "high"
  | "medium"
  | "support";

export type MauriOperatingLayer = {
  id: string;
  index: number;
  domain: MauriOperatingDomain;
  name: string;
  purpose: string;
  criticality: MauriLayerCriticality;
  state: MauriLayerState;
  score: number;
  learnsFrom: MauriOperatingDomain[];
  teachesTo: MauriOperatingDomain[];
};

export type MauriOperatingSignal = {
  id: string;
  at: number;
  sourceLayerId: string;
  type:
    | "observe"
    | "route_success"
    | "route_failure"
    | "ack_received"
    | "peer_seen"
    | "peer_lost"
    | "fallback_used"
    | "repair_started"
    | "repair_success"
    | "tikanga_warning"
    | "truth_required"
    | "proof_required"
    | "runtime_tick";
  confidence: number;
  impact: number;
  lesson: string;
  data?: Record<string, unknown>;
};

export type MauriDomainScore = {
  domain: MauriOperatingDomain;
  score: number;
  layers: number;
  ready: number;
  learning: number;
  fallback: number;
  repairing: number;
  blocked: number;
};

export type MauriOperatingDecision =
  | "operate_strong"
  | "operate_monitored"
  | "fallback_store_forward"
  | "self_heal"
  | "block_unsafe_or_unproven";

export type MauriOperatingSnapshot = {
  at: number;
  layerCount: number;
  domainScores: MauriDomainScore[];
  wholeSystemScore: number;
  decision: MauriOperatingDecision;
  truth: string;
  strongestLayers: MauriOperatingLayer[];
  weakestLayers: MauriOperatingLayer[];
  latestSignals: MauriOperatingSignal[];
};
TS

cat > src/operating/mauri155LayerCatalog.ts <<'TS'
import {
  MauriOperatingDomain,
  MauriOperatingLayer,
} from "./mauriOperatingTypes";

const domainPurposes: Record<MauriOperatingDomain, string> = {
  foundation:
    "identity, shared types, contracts, configuration, versioning, and stable system law",
  physical:
    "device body, Bluetooth permissions, power, foreground runtime, radio health, and hardware proof boundary",
  transport:
    "BLE scan, BLE advertise, BLE GATT, peer-to-peer transport, relay transport, and fallback transport",
  packet:
    "packet structure, encryption envelope, dedupe, TTL, fragmentation, reassembly, and ACK identity",
  routing:
    "route score, JumpCode, √2 balance, relay selection, path memory, latency, and congestion logic",
  learning:
    "permanent memory, cross-layer learning, score updates, pattern recognition, and route wisdom",
  healing:
    "watchdog, replacement layer, last-known-good mode, repair loop, crash containment, and recovery",
  tikanga:
    "purpose, consent, truth labels, kaitiaki safety, manaaki outcome, and cultural intelligence compatibility",
  whanau:
    "peer table, friend graph, trust graph, group resilience, path whakapapa, and relationship memory",
  observability:
    "Living Mesh, telemetry truth, logs, metrics, snapshots, proof reports, and debugging visibility",
  experience:
    "login, dashboard, chat, settings, add friend, pixel calling shell, and human control surface",
  proof:
    "Replit logic proof, TypeScript proof, API proof, APK proof, ADB/logcat proof, and physical phone evidence",
};

const layerNames: Record<MauriOperatingDomain, string[]> = {
  foundation: [
    "Shared Type Contract",
    "Runtime Config",
    "Identity Contract",
    "Device Identity",
    "Version Contract",
    "Permission Contract",
    "Packet Contract",
    "Route Contract",
    "Learning Contract",
    "Tikanga Contract",
    "Proof Contract",
    "Storage Contract",
    "System Law",
  ],
  physical: [
    "Bluetooth Permission Body",
    "BLE Radio State",
    "Foreground Service Guard",
    "Battery State Guard",
    "Thermal State Guard",
    "Device Capability Scan",
    "Android Runtime Bridge",
    "iOS Runtime Bridge",
    "Hardware Availability",
    "Physical Device Detector",
    "Radio Error Guard",
    "Power Optimizer",
    "Native Boundary Stop Guard",
  ],
  transport: [
    "BLE Scan Loop",
    "BLE Advertise Loop",
    "BLE GATT Server",
    "BLE GATT Client",
    "BLE Packet Send Shell",
    "BLE Packet Receive Shell",
    "Peer-to-Peer Channel",
    "Device-to-Device Channel",
    "Relay Channel",
    "Store-Forward Channel",
    "Transport Fallback",
    "Transport Health Score",
    "Transport Truth Label",
  ],
  packet: [
    "Packet ID",
    "Packet Envelope",
    "Packet Encryption",
    "Packet Signature",
    "Packet Deduplication",
    "TTL Guard",
    "Hop Count Guard",
    "Fragmentation",
    "Reassembly",
    "ACK Packet",
    "Reverse Path ACK",
    "Priority Field",
    "Payload Integrity",
  ],
  routing: [
    "Route Table",
    "Route Score",
    "RSSI Weight",
    "Latency Weight",
    "ACK Weight",
    "Recency Weight",
    "JumpCode Path",
    "√2 Balance",
    "Relay Selector",
    "Congestion Guard",
    "Loop Prevention",
    "Path Memory",
    "Route Decision Gate",
  ],
  learning: [
    "Permanent Runtime Memory",
    "Cross-Layer Learning Bus",
    "Route Success Lesson",
    "Route Failure Lesson",
    "ACK Lesson",
    "Peer Availability Lesson",
    "RSSI Pattern Lesson",
    "Latency Pattern Lesson",
    "Fallback Lesson",
    "JumpCode Lesson",
    "Tikanga Lesson",
    "Self-Heal Lesson",
    "Restart Memory Lesson",
  ],
  healing: [
    "Watchdog Loop",
    "Failure Detector",
    "Fallback Activator",
    "Replacement Layer",
    "Last Known Good State",
    "Repair Queue",
    "Retry Backoff",
    "Crash Containment",
    "State Rehydration",
    "Peer Return Recovery",
    "ACK Recovery",
    "Queue Drain Recovery",
    "Healing Score",
  ],
  tikanga: [
    "Purpose Check",
    "Consent Check",
    "Truth Label Check",
    "No Fake BLE Proof",
    "No Fake Telemetry",
    "Manaaki Outcome",
    "Kaitiaki Safety",
    "Tapu Safety Boundary",
    "Whakapapa Continuity",
    "Community Benefit",
    "Risk Reduction",
    "Ethical Route Gate",
    "Cultural Intelligence Compatibility",
  ],
  whanau: [
    "Peer Table",
    "Trusted Peer Memory",
    "Friend Graph",
    "Group Graph",
    "Relay Relationship",
    "Path Whakapapa",
    "Known Safe Peer",
    "Unknown Peer Caution",
    "Blocked Peer Exclusion",
    "Stale Peer Marking",
    "Peer Return Detection",
    "Community Route Health",
    "Whānau Resilience Score",
  ],
  observability: [
    "Living Mesh Snapshot",
    "Node Snapshot",
    "Route Beam Snapshot",
    "Queue Snapshot",
    "Learning Snapshot",
    "Whare Balance Snapshot",
    "Telemetry Truth",
    "Log Stream",
    "Runtime Health",
    "API Health",
    "Proof Log",
    "ADB Logcat Parser",
    "Operator Report",
  ],
  experience: [
    "Login Screen",
    "Dashboard Screen",
    "Chat Screen",
    "Settings Screen",
    "Add Friend Screen",
    "Living Mesh Screen",
    "Mesh Status Screen",
    "Pixel Calling Shell",
    "Status Pill",
    "Signal Card",
    "Route Visibility",
    "Truth Notice",
    "User Control Surface",
  ],
  proof: [
    "Replit Logic Proof",
    "TypeScript Proof",
    "Runtime Validation",
    "API Health Proof",
    "Simulation Label Proof",
    "No Fake BLE Claim Proof",
    "APK Build Proof",
    "Physical Phone Proof",
    "BLE Scan Proof",
    "BLE Advertise Proof",
    "GATT Transfer Proof",
    "ADB Logcat Proof",
    "Final Evidence Report",
  ],
};

const allDomains = Object.keys(layerNames) as MauriOperatingDomain[];

function scoreByCriticality(index: number): "core" | "high" | "medium" | "support" {
  if (index <= 3) return "core";
  if (index <= 7) return "high";
  if (index <= 10) return "medium";
  return "support";
}

export const mauri155LayerCatalog: MauriOperatingLayer[] = allDomains.flatMap(
  (domain, domainIndex) =>
    layerNames[domain].map((name, layerIndex) => {
      const globalIndex = domainIndex * 13 + layerIndex + 1;

      return {
        id: `mauri_${String(globalIndex).padStart(3, "0")}_${domain}_${name
          .toLowerCase()
          .replace(/[^a-z0-9]+/g, "_")
          .replace(/^_|_$/g, "")}`,
        index: globalIndex,
        domain,
        name,
        purpose: `${name} supports ${domainPurposes[domain]}.`,
        criticality: scoreByCriticality(layerIndex + 1),
        state: "idle",
        score: domain === "proof" || domain === "physical" ? 0.45 : 0.72,
        learnsFrom: allDomains.filter(d => d !== domain),
        teachesTo: allDomains.filter(d => d !== domain),
      };
    })
);

export function getMauriLayerCount(): number {
  return mauri155LayerCatalog.length;
}

export function getMauriDomains(): MauriOperatingDomain[] {
  return allDomains;
}
TS

cat > src/operating/mauri155OperatingRuntime.ts <<'TS'
import {
  MauriDomainScore,
  MauriOperatingDecision,
  MauriOperatingLayer,
  MauriOperatingSignal,
  MauriOperatingSnapshot,
} from "./mauriOperatingTypes";
import { mauri155LayerCatalog } from "./mauri155LayerCatalog";

function clamp01(value: number): number {
  if (!Number.isFinite(value)) return 0;
  return Math.max(0, Math.min(1, value));
}

function id(prefix: string): string {
  return `${prefix}_${Date.now().toString(36)}_${Math.random()
    .toString(36)
    .slice(2, 10)}`;
}

export class Mauri155OperatingRuntime {
  private layers = new Map<string, MauriOperatingLayer>();
  private signals: MauriOperatingSignal[] = [];

  constructor() {
    for (const layer of mauri155LayerCatalog) {
      this.layers.set(layer.id, { ...layer });
    }
  }

  start(): MauriOperatingSnapshot {
    this.emit({
      sourceLayerId: "runtime",
      type: "runtime_tick",
      confidence: 1,
      impact: 0.8,
      lesson:
        "MauriMesh 155+ operating runtime started. Every layer has a purpose and learns with the whole system.",
    });

    this.setDomainState("foundation", "ready", 0.92);
    this.setDomainState("learning", "learning", 0.88);
    this.setDomainState("tikanga", "ready", 0.9);
    this.setDomainState("observability", "observing", 0.78);
    this.setDomainState("experience", "ready", 0.8);

    return this.snapshot();
  }

  observeLayer(layerId: string, scoreDelta: number, lesson: string): void {
    const layer = this.layers.get(layerId);
    if (!layer) return;

    layer.state = "learning";
    layer.score = clamp01(layer.score + scoreDelta);

    this.emit({
      sourceLayerId: layerId,
      type: "observe",
      confidence: 0.85,
      impact: Math.abs(scoreDelta),
      lesson,
      data: {
        domain: layer.domain,
        layer: layer.name,
        score: layer.score,
      },
    });

    this.shareLearning(layer);
  }

  teachRouteSuccess(peerId: string, packetId: string): void {
    this.boostDomains(["routing", "packet", "learning", "whanau", "observability"], 0.04);

    this.emit({
      sourceLayerId: "routing",
      type: "route_success",
      confidence: 0.95,
      impact: 0.9,
      lesson:
        "Route success teaches routing, packet integrity, ACK confidence, whānau trust, and Living Mesh visibility.",
      data: { peerId, packetId },
    });
  }

  teachRouteFailure(peerId: string, packetId: string): void {
    this.reduceDomains(["routing", "transport"], 0.04);
    this.boostDomains(["healing", "learning"], 0.06);
    this.setDomainState("healing", "repairing");

    this.emit({
      sourceLayerId: "routing",
      type: "route_failure",
      confidence: 0.9,
      impact: 0.85,
      lesson:
        "Route failure activates store-forward, JumpCode, √2 balance, self-healing, and proof logging.",
      data: { peerId, packetId },
    });
  }

  teachAckReceived(peerId: string, packetId: string): void {
    this.boostDomains(["packet", "routing", "learning", "whanau"], 0.05);

    this.emit({
      sourceLayerId: "packet",
      type: "ack_received",
      confidence: 0.97,
      impact: 0.92,
      lesson:
        "ACK received. The system learns delivery truth, peer trust, latency expectation, and route quality.",
      data: { peerId, packetId },
    });
  }

  teachPhysicalBleRequired(reason: string): void {
    this.setDomainState("proof", "fallback", 0.5);
    this.setDomainState("physical", "fallback", 0.5);

    this.emit({
      sourceLayerId: "proof",
      type: "proof_required",
      confidence: 1,
      impact: 0.95,
      lesson:
        "Physical BLE proof is required. Replit can validate logic, but APK plus physical phones prove Bluetooth runtime.",
      data: { reason },
    });
  }

  teachTikangaWarning(reason: string): void {
    this.boostDomains(["tikanga", "observability"], 0.03);
    this.reduceDomains(["routing", "transport"], 0.02);

    this.emit({
      sourceLayerId: "tikanga",
      type: "tikanga_warning",
      confidence: 0.96,
      impact: 0.88,
      lesson:
        "Tikanga warning. Purpose, truth, consent, and safety override speed.",
      data: { reason },
    });
  }

  snapshot(): MauriOperatingSnapshot {
    const layers = [...this.layers.values()];
    const domainNames = Array.from(new Set(layers.map(layer => layer.domain)));

    const domainScores: MauriDomainScore[] = domainNames.map(domain => {
      const group = layers.filter(layer => layer.domain === domain);
      return {
        domain,
        score:
          group.reduce((sum, layer) => sum + layer.score, 0) /
          Math.max(1, group.length),
        layers: group.length,
        ready: group.filter(layer => layer.state === "ready").length,
        learning: group.filter(layer => layer.state === "learning").length,
        fallback: group.filter(layer => layer.state === "fallback").length,
        repairing: group.filter(layer => layer.state === "repairing").length,
        blocked: group.filter(layer => layer.state === "blocked").length,
      };
    });

    const wholeSystemScore =
      domainScores.reduce((sum, domain) => sum + domain.score, 0) /
      Math.max(1, domainScores.length);

    return {
      at: Date.now(),
      layerCount: layers.length,
      domainScores: domainScores.map(domain => ({
        ...domain,
        score: Number(domain.score.toFixed(4)),
      })),
      wholeSystemScore: Number(wholeSystemScore.toFixed(4)),
      decision: this.decide(wholeSystemScore),
      truth:
        "This is the one giant MauriMesh operating runtime. Replit proves logic only. Physical BLE proof requires APK plus physical phones.",
      strongestLayers: [...layers]
        .sort((a, b) => b.score - a.score)
        .slice(0, 12),
      weakestLayers: [...layers]
        .sort((a, b) => a.score - b.score)
        .slice(0, 12),
      latestSignals: this.signals.slice(-20),
    };
  }

  private emit(input: Omit<MauriOperatingSignal, "id" | "at">): void {
    this.signals.push({
      ...input,
      id: id("signal"),
      at: Date.now(),
      confidence: clamp01(input.confidence),
      impact: clamp01(input.impact),
    });

    if (this.signals.length > 1000) {
      this.signals = this.signals.slice(-500);
    }
  }

  private setDomainState(
    domain: MauriOperatingLayer["domain"],
    state: MauriOperatingLayer["state"],
    score?: number
  ): void {
    for (const layer of this.layers.values()) {
      if (layer.domain === domain) {
        layer.state = state;
        if (score !== undefined) layer.score = clamp01(score);
      }
    }
  }

  private boostDomains(domains: MauriOperatingLayer["domain"][], amount: number): void {
    for (const layer of this.layers.values()) {
      if (domains.includes(layer.domain)) {
        layer.score = clamp01(layer.score + amount);
        layer.state = layer.state === "idle" ? "learning" : layer.state;
      }
    }
  }

  private reduceDomains(domains: MauriOperatingLayer["domain"][], amount: number): void {
    for (const layer of this.layers.values()) {
      if (domains.includes(layer.domain)) {
        layer.score = clamp01(layer.score - amount);
        if (layer.score < 0.45) layer.state = "fallback";
      }
    }
  }

  private shareLearning(source: MauriOperatingLayer): void {
    for (const targetDomain of source.teachesTo) {
      for (const layer of this.layers.values()) {
        if (layer.domain === targetDomain) {
          layer.score = clamp01(layer.score + 0.005);
        }
      }
    }
  }

  private decide(score: number): MauriOperatingDecision {
    if (score >= 0.85) return "operate_strong";
    if (score >= 0.68) return "operate_monitored";
    if (score >= 0.5) return "fallback_store_forward";
    if (score >= 0.28) return "self_heal";
    return "block_unsafe_or_unproven";
  }
}
TS

cat > src/operating/validateMauri155OperatingRuntime.ts <<'TS'
import { getMauriLayerCount } from "./mauri155LayerCatalog";
import { Mauri155OperatingRuntime } from "./mauri155OperatingRuntime";

async function main() {
  const runtime = new Mauri155OperatingRuntime();

  const startSnapshot = runtime.start();

  runtime.teachRouteSuccess("peer-alpha", "packet-001");
  runtime.teachAckReceived("peer-alpha", "packet-001");
  runtime.teachRouteFailure("peer-beta", "packet-002");
  runtime.teachTikangaWarning("Do not claim live BLE proof inside Replit.");
  runtime.teachPhysicalBleRequired(
    "Real BLE proof requires APK, physical phones, and ADB/logcat."
  );

  const finalSnapshot = runtime.snapshot();

  console.log("");
  console.log("==================================================");
  console.log("MAURIMESH 155+ OPERATING RUNTIME VALIDATION");
  console.log("==================================================");
  console.log(`Layer count: ${getMauriLayerCount()}`);
  console.log(`Start decision: ${startSnapshot.decision}`);
  console.log(`Final decision: ${finalSnapshot.decision}`);
  console.log("");
  console.log(JSON.stringify(finalSnapshot, null, 2));
  console.log("==================================================");

  if (getMauriLayerCount() < 155) {
    throw new Error("Layer count is below 155.");
  }
}

main().catch(error => {
  console.error("[MauriMesh][155OperatingRuntime] validation failed", error);
  process.exit(1);
});
TS

cat > src/operating/MAURIMESH_155_OPERATING_STRUCTURE.md <<'MD'
# MauriMesh 155+ Layer Operating Runtime

## Perfect structure

12 operating domains × 13 layers each = 156 layers.

This avoids one messy file and creates one coordinated operating runtime.

## Domains

1. Foundation
2. Physical
3. Transport
4. Packet
5. Routing
6. Learning
7. Healing
8. Tikanga
9. Whānau
10. Observability
11. Experience
12. Proof

## Runtime loop

observe -> learn -> score -> balance -> decide -> act -> ACK/fail -> heal -> snapshot -> repeat

## Decision rules

- operate_strong
- operate_monitored
- fallback_store_forward
- self_heal
- block_unsafe_or_unproven

## Truth rule

Replit validates logic only.
Physical BLE proof requires APK + physical phones + ADB/logcat.
MD

node <<'NODE'
const fs = require("fs");

if (!fs.existsSync("package.json")) {
  console.log("package.json not found. Skipping package script merge.");
  process.exit(0);
}

const pkg = JSON.parse(fs.readFileSync("package.json", "utf8"));
pkg.scripts = pkg.scripts || {};

function addScript(name, value) {
  if (!pkg.scripts[name]) pkg.scripts[name] = value;
}

addScript("mauri:155:validate", "tsx src/operating/validateMauri155OperatingRuntime.ts");
addScript("mauri:operating:validate", "tsx src/operating/validateMauri155OperatingRuntime.ts");
addScript("mauri:typecheck", "tsc --noEmit");

pkg.devDependencies = pkg.devDependencies || {};
if (!pkg.devDependencies.tsx && !(pkg.dependencies && pkg.dependencies.tsx)) {
  pkg.devDependencies.tsx = "latest";
}
if (!pkg.devDependencies.typescript && !(pkg.dependencies && pkg.dependencies.typescript)) {
  pkg.devDependencies.typescript = "latest";
}

fs.writeFileSync("package.json", JSON.stringify(pkg, null, 2) + "\n");
console.log("package.json safely updated.");
NODE

echo ""
echo "=================================================="
echo "MauriMesh 155+ Operating Runtime installed."
echo ""
echo "Files created:"
find src/operating -type f | sort
echo ""
echo "Next commands:"
echo "npm install"
echo "npm run mauri:155:validate"
echo "npm run mauri:typecheck"
echo "=================================================="
