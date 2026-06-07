#!/usr/bin/env bash
set -euo pipefail

echo "=================================================="
echo "MauriMesh AI Routing + Governance Intelligence"
echo "Safe merge mode: ON"
echo "=================================================="

mkdir -p src/ai src/routing src/governance backups

if [ -f package.json ]; then
  cp package.json "backups/package.json.ai-routing-governance.$(date +%Y%m%d-%H%M%S).bak"
fi

cat > src/ai/mauriAiTypes.ts <<'TS'
export type MauriAiDecision =
  | "send_direct"
  | "send_relay"
  | "send_jumpcode"
  | "store_forward"
  | "self_heal"
  | "block_unsafe"
  | "require_physical_proof";

export type MauriAiSignal = {
  peerId?: string;
  packetId?: string;
  rssi?: number;
  latencyMs?: number;
  ackSuccess?: boolean;
  routeFailure?: boolean;
  peerTrusted?: boolean;
  peerStale?: boolean;
  queueDepth?: number;
  batterySafe?: boolean;
  tikangaSafe?: boolean;
  physicalBleProven?: boolean;
};

export type MauriAiRouteCandidate = {
  peerId: string;
  routeId: string;
  hops: number;
  rssi: number;
  latencyMs: number;
  ackRate: number;
  trustScore: number;
  queuePressure: number;
  lastSeenAgeMs: number;
};

export type MauriAiRouteScore = {
  peerId: string;
  routeId: string;
  score: number;
  reason: string[];
};

export type MauriAiGovernanceResult = {
  allowed: boolean;
  decision: MauriAiDecision;
  score: number;
  warnings: string[];
  truth: string;
};

export type MauriAiRuntimeSnapshot = {
  at: number;
  decision: MauriAiDecision;
  selectedRoute?: MauriAiRouteScore;
  routeScores: MauriAiRouteScore[];
  governance: MauriAiGovernanceResult;
  memory: {
    learnedEvents: number;
    routeSuccess: number;
    routeFailure: number;
    storedPackets: number;
    forwardedPackets: number;
    healedEvents: number;
  };
  truth: string;
};
TS

cat > src/routing/mauriAiRoutingIntelligence.ts <<'TS'
import {
  MauriAiRouteCandidate,
  MauriAiRouteScore,
  MauriAiSignal,
} from "../ai/mauriAiTypes";

function clamp01(value: number): number {
  if (!Number.isFinite(value)) return 0;
  return Math.max(0, Math.min(1, value));
}

export class MauriAiRoutingIntelligence {
  scoreRoute(candidate: MauriAiRouteCandidate): MauriAiRouteScore {
    const signalScore = clamp01((candidate.rssi + 100) / 70);
    const latencyScore = clamp01(1 - Math.min(candidate.latencyMs, 3000) / 3000);
    const ackScore = clamp01(candidate.ackRate);
    const trustScore = clamp01(candidate.trustScore);
    const hopScore = clamp01(1 - Math.min(candidate.hops, 8) / 8);
    const queueScore = clamp01(1 - Math.min(candidate.queuePressure, 100) / 100);
    const recencyScore = clamp01(1 - Math.min(candidate.lastSeenAgeMs, 120000) / 120000);

    const score = clamp01(
      signalScore * 0.18 +
        latencyScore * 0.16 +
        ackScore * 0.24 +
        trustScore * 0.18 +
        hopScore * 0.08 +
        queueScore * 0.08 +
        recencyScore * 0.08
    );

    const reason = [
      `signal=${signalScore.toFixed(2)}`,
      `latency=${latencyScore.toFixed(2)}`,
      `ack=${ackScore.toFixed(2)}`,
      `trust=${trustScore.toFixed(2)}`,
      `hops=${hopScore.toFixed(2)}`,
      `queue=${queueScore.toFixed(2)}`,
      `recency=${recencyScore.toFixed(2)}`,
    ];

    return {
      peerId: candidate.peerId,
      routeId: candidate.routeId,
      score,
      reason,
    };
  }

  chooseBestRoute(candidates: MauriAiRouteCandidate[]): MauriAiRouteScore | undefined {
    return candidates
      .map(candidate => this.scoreRoute(candidate))
      .sort((a, b) => b.score - a.score)[0];
  }

  learnFromSignal(signal: MauriAiSignal): string {
    if (signal.ackSuccess) return "ACK success strengthens route trust and future selection.";
    if (signal.routeFailure) return "Route failure lowers direct confidence and increases fallback pressure.";
    if (signal.peerStale) return "Stale peer should be deprioritized and store-forward considered.";
    if (signal.rssi !== undefined) return "RSSI signal updates physical route strength.";
    return "Signal observed and retained for future route scoring.";
  }
}
TS

cat > src/routing/hybridAiRoutingLogic.ts <<'TS'
import {
  MauriAiDecision,
  MauriAiRouteCandidate,
  MauriAiRouteScore,
  MauriAiSignal,
} from "../ai/mauriAiTypes";
import { MauriAiRoutingIntelligence } from "./mauriAiRoutingIntelligence";

export class HybridAiRoutingLogic {
  private routing = new MauriAiRoutingIntelligence();

  decide(
    signal: MauriAiSignal,
    candidates: MauriAiRouteCandidate[]
  ): {
    decision: MauriAiDecision;
    selectedRoute?: MauriAiRouteScore;
    routeScores: MauriAiRouteScore[];
    reason: string;
  } {
    const routeScores = candidates
      .map(candidate => this.routing.scoreRoute(candidate))
      .sort((a, b) => b.score - a.score);

    const selectedRoute = routeScores[0];

    if (!signal.physicalBleProven) {
      return {
        decision: "require_physical_proof",
        selectedRoute,
        routeScores,
        reason: "Physical BLE proof required before claiming live Bluetooth operation.",
      };
    }

    if (signal.tikangaSafe === false) {
      return {
        decision: "block_unsafe",
        selectedRoute,
        routeScores,
        reason: "Tikanga/governance safety blocked unsafe action.",
      };
    }

    if (!selectedRoute) {
      return {
        decision: "store_forward",
        routeScores,
        reason: "No route candidate available. Store-forward required.",
      };
    }

    if (selectedRoute.score >= 0.82) {
      return {
        decision: "send_direct",
        selectedRoute,
        routeScores,
        reason: "Strong direct route available.",
      };
    }

    if (selectedRoute.score >= 0.62) {
      return {
        decision: "send_relay",
        selectedRoute,
        routeScores,
        reason: "Moderate route available. Relay mode recommended.",
      };
    }

    if (selectedRoute.score >= 0.42) {
      return {
        decision: "send_jumpcode",
        selectedRoute,
        routeScores,
        reason: "Weak route. JumpCode alternate path recommended.",
      };
    }

    if ((signal.queueDepth ?? 0) > 0 || signal.peerStale) {
      return {
        decision: "store_forward",
        selectedRoute,
        routeScores,
        reason: "Peer unavailable or queue pressure detected. Store-forward selected.",
      };
    }

    return {
      decision: "self_heal",
      selectedRoute,
      routeScores,
      reason: "Route confidence too low. Self-healing should repair path.",
    };
  }
}
TS

cat > src/routing/jumpCodeEngine.ts <<'TS'
import { MauriAiRouteCandidate } from "../ai/mauriAiTypes";

export type JumpCodePath = {
  id: string;
  fromPeerId: string;
  toPeerId: string;
  relayPeerIds: string[];
  jumpScore: number;
  reason: string[];
};

function clamp01(value: number): number {
  if (!Number.isFinite(value)) return 0;
  return Math.max(0, Math.min(1, value));
}

export class JumpCodeEngine {
  createJumpCodePath(
    fromPeerId: string,
    toPeerId: string,
    candidates: MauriAiRouteCandidate[]
  ): JumpCodePath {
    const relays = candidates
      .filter(candidate => candidate.peerId !== fromPeerId && candidate.peerId !== toPeerId)
      .sort((a, b) => b.ackRate + b.trustScore - (a.ackRate + a.trustScore))
      .slice(0, 3);

    const avgRelay =
      relays.length === 0
        ? 0
        : relays.reduce((sum, relay) => sum + relay.ackRate + relay.trustScore, 0) /
          (relays.length * 2);

    const jumpScore = clamp01(avgRelay * 0.7 + Math.min(relays.length, 3) / 3 * 0.3);

    return {
      id: `jump_${Date.now().toString(36)}_${Math.random().toString(36).slice(2, 8)}`,
      fromPeerId,
      toPeerId,
      relayPeerIds: relays.map(relay => relay.peerId),
      jumpScore,
      reason: [
        `relayCount=${relays.length}`,
        `avgRelayTrustAck=${avgRelay.toFixed(2)}`,
        `jumpScore=${jumpScore.toFixed(2)}`,
      ],
    };
  }

  shouldUseJumpCode(bestRouteScore: number): boolean {
    return bestRouteScore < 0.62 && bestRouteScore >= 0.32;
  }
}
TS

cat > src/routing/storeForwardIntelligence.ts <<'TS'
export type StoreForwardPacket = {
  packetId: string;
  peerId: string;
  payload: unknown;
  createdAt: number;
  lastAttemptAt: number;
  attempts: number;
  maxAttempts: number;
  ttlMs: number;
  priority: number;
};

export type StoreForwardDecision = {
  shouldStore: boolean;
  shouldRetryNow: boolean;
  shouldDrop: boolean;
  reason: string;
  nextRetryMs: number;
};

export class StoreForwardIntelligence {
  private queue = new Map<string, StoreForwardPacket>();

  store(packet: Omit<StoreForwardPacket, "createdAt" | "lastAttemptAt" | "attempts">): void {
    this.queue.set(packet.packetId, {
      ...packet,
      createdAt: Date.now(),
      lastAttemptAt: 0,
      attempts: 0,
    });
  }

  decide(packet: StoreForwardPacket): StoreForwardDecision {
    const age = Date.now() - packet.createdAt;
    const expired = age > packet.ttlMs;
    const maxed = packet.attempts >= packet.maxAttempts;

    if (expired) {
      return {
        shouldStore: false,
        shouldRetryNow: false,
        shouldDrop: true,
        reason: "Packet TTL expired.",
        nextRetryMs: 0,
      };
    }

    if (maxed) {
      return {
        shouldStore: false,
        shouldRetryNow: false,
        shouldDrop: true,
        reason: "Packet max retry attempts reached.",
        nextRetryMs: 0,
      };
    }

    const backoff = Math.min(30000, 1000 * Math.pow(2, packet.attempts));
    const ready = Date.now() - packet.lastAttemptAt >= backoff;

    return {
      shouldStore: true,
      shouldRetryNow: ready,
      shouldDrop: false,
      reason: ready ? "Packet ready for retry." : "Packet waiting for backoff window.",
      nextRetryMs: backoff,
    };
  }

  markAttempt(packetId: string): void {
    const packet = this.queue.get(packetId);
    if (!packet) return;
    packet.attempts += 1;
    packet.lastAttemptAt = Date.now();
  }

  remove(packetId: string): void {
    this.queue.delete(packetId);
  }

  snapshot() {
    return {
      queued: this.queue.size,
      packets: [...this.queue.values()].map(packet => ({
        packetId: packet.packetId,
        peerId: packet.peerId,
        attempts: packet.attempts,
        ageMs: Date.now() - packet.createdAt,
        priority: packet.priority,
        decision: this.decide(packet),
      })),
    };
  }
}
TS

cat > src/governance/aiGovernanceIntelligence.ts <<'TS'
import {
  MauriAiDecision,
  MauriAiGovernanceResult,
  MauriAiSignal,
} from "../ai/mauriAiTypes";

function clamp01(value: number): number {
  if (!Number.isFinite(value)) return 0;
  return Math.max(0, Math.min(1, value));
}

export class AiGovernanceIntelligence {
  evaluate(signal: MauriAiSignal, proposedDecision: MauriAiDecision): MauriAiGovernanceResult {
    const warnings: string[] = [];

    let score = 1;

    if (!signal.physicalBleProven) {
      score -= 0.35;
      warnings.push("Physical BLE is not proven in this runtime.");
    }

    if (signal.tikangaSafe === false) {
      score -= 0.5;
      warnings.push("Tikanga safety check failed.");
    }

    if (signal.peerTrusted === false) {
      score -= 0.2;
      warnings.push("Peer is not trusted.");
    }

    if (signal.batterySafe === false) {
      score -= 0.15;
      warnings.push("Battery state is unsafe for aggressive routing.");
    }

    score = clamp01(score);

    if (score < 0.35) {
      return {
        allowed: false,
        decision: "block_unsafe",
        score,
        warnings,
        truth: "Governance blocked unsafe or unproven action.",
      };
    }

    if (!signal.physicalBleProven && proposedDecision !== "store_forward") {
      return {
        allowed: false,
        decision: "require_physical_proof",
        score,
        warnings,
        truth: "Physical proof required before live BLE routing claims.",
      };
    }

    return {
      allowed: true,
      decision: proposedDecision,
      score,
      warnings,
      truth: "Governance allowed action with current safety score.",
    };
  }
}
TS

cat > src/ai/mauriAiIntelligenceRuntime.ts <<'TS'
import {
  MauriAiRouteCandidate,
  MauriAiRuntimeSnapshot,
  MauriAiSignal,
} from "./mauriAiTypes";
import { HybridAiRoutingLogic } from "../routing/hybridAiRoutingLogic";
import { JumpCodeEngine } from "../routing/jumpCodeEngine";
import { StoreForwardIntelligence } from "../routing/storeForwardIntelligence";
import { AiGovernanceIntelligence } from "../governance/aiGovernanceIntelligence";

export class MauriAiIntelligenceRuntime {
  private hybridRouting = new HybridAiRoutingLogic();
  private jumpCode = new JumpCodeEngine();
  private storeForward = new StoreForwardIntelligence();
  private governance = new AiGovernanceIntelligence();

  private memory = {
    learnedEvents: 0,
    routeSuccess: 0,
    routeFailure: 0,
    storedPackets: 0,
    forwardedPackets: 0,
    healedEvents: 0,
  };

  decide(signal: MauriAiSignal, candidates: MauriAiRouteCandidate[]): MauriAiRuntimeSnapshot {
    this.memory.learnedEvents += 1;

    const routeDecision = this.hybridRouting.decide(signal, candidates);
    const governance = this.governance.evaluate(signal, routeDecision.decision);

    if (signal.ackSuccess) this.memory.routeSuccess += 1;
    if (signal.routeFailure) this.memory.routeFailure += 1;

    if (governance.decision === "store_forward") {
      this.memory.storedPackets += 1;
    }

    if (governance.decision === "self_heal") {
      this.memory.healedEvents += 1;
    }

    if (
      routeDecision.selectedRoute &&
      this.jumpCode.shouldUseJumpCode(routeDecision.selectedRoute.score)
    ) {
      this.jumpCode.createJumpCodePath(
        signal.peerId ?? "local",
        routeDecision.selectedRoute.peerId,
        candidates
      );
    }

    return {
      at: Date.now(),
      decision: governance.decision,
      selectedRoute: routeDecision.selectedRoute,
      routeScores: routeDecision.routeScores,
      governance,
      memory: { ...this.memory },
      truth:
        "Mauri AI routing intelligence is active. Replit validates logic only. Real BLE proof requires APK plus physical phones.",
    };
  }

  storePacket(packetId: string, peerId: string, payload: unknown): void {
    this.storeForward.store({
      packetId,
      peerId,
      payload,
      maxAttempts: 12,
      ttlMs: 120000,
      priority: 5,
    });
    this.memory.storedPackets += 1;
  }

  storeForwardSnapshot() {
    return this.storeForward.snapshot();
  }
}
TS

cat > src/ai/validateMauriAiIntelligenceRuntime.ts <<'TS'
import { MauriAiIntelligenceRuntime } from "./mauriAiIntelligenceRuntime";
import { MauriAiRouteCandidate, MauriAiSignal } from "./mauriAiTypes";

async function main() {
  const runtime = new MauriAiIntelligenceRuntime();

  const candidates: MauriAiRouteCandidate[] = [
    {
      peerId: "peer-alpha",
      routeId: "route-alpha",
      hops: 1,
      rssi: -48,
      latencyMs: 120,
      ackRate: 0.94,
      trustScore: 0.9,
      queuePressure: 5,
      lastSeenAgeMs: 1000,
    },
    {
      peerId: "peer-beta",
      routeId: "route-beta",
      hops: 2,
      rssi: -70,
      latencyMs: 800,
      ackRate: 0.62,
      trustScore: 0.72,
      queuePressure: 20,
      lastSeenAgeMs: 20000,
    },
    {
      peerId: "peer-gamma",
      routeId: "route-gamma",
      hops: 3,
      rssi: -84,
      latencyMs: 1600,
      ackRate: 0.38,
      trustScore: 0.6,
      queuePressure: 55,
      lastSeenAgeMs: 60000,
    },
  ];

  const replitSignal: MauriAiSignal = {
    peerId: "peer-alpha",
    packetId: "packet-001",
    physicalBleProven: false,
    tikangaSafe: true,
    peerTrusted: true,
    batterySafe: true,
    ackSuccess: true,
  };

  const physicalSignal: MauriAiSignal = {
    peerId: "peer-alpha",
    packetId: "packet-002",
    physicalBleProven: true,
    tikangaSafe: true,
    peerTrusted: true,
    batterySafe: true,
    ackSuccess: true,
  };

  runtime.storePacket("packet-store-001", "peer-beta", {
    text: "Store-forward test payload",
  });

  console.log("");
  console.log("==================================================");
  console.log("MAURI AI ROUTING INTELLIGENCE VALIDATION");
  console.log("==================================================");

  console.log("");
  console.log("REPLIT LOGIC DECISION");
  console.log(JSON.stringify(runtime.decide(replitSignal, candidates), null, 2));

  console.log("");
  console.log("PHYSICAL BLE-PROVEN DECISION");
  console.log(JSON.stringify(runtime.decide(physicalSignal, candidates), null, 2));

  console.log("");
  console.log("STORE-FORWARD SNAPSHOT");
  console.log(JSON.stringify(runtime.storeForwardSnapshot(), null, 2));

  console.log("==================================================");
}

main().catch(error => {
  console.error("[MauriMesh][MauriAiIntelligenceRuntime] validation failed", error);
  process.exit(1);
});
TS

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

addScript("mauri:ai:validate", "tsx src/ai/validateMauriAiIntelligenceRuntime.ts");
addScript("mauri:ai:typecheck", "tsc --noEmit");
addScript("mauri:ai:proof", "tsx src/ai/validateMauriAiIntelligenceRuntime.ts && tsc --noEmit");

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
echo "Mauri AI Routing + Governance Intelligence installed."
echo ""
echo "Files created:"
find src/ai src/routing src/governance -type f | sort
echo ""
echo "Next commands:"
echo "npm install"
echo "npm run mauri:ai:validate"
echo "npm run mauri:ai:typecheck"
echo "=================================================="
