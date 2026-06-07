#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH INVENTION ENGINE INSTALLER"
echo "Living AI + Tikanga + Hybrid Routing + Self-Healing Mesh"
echo "============================================================"
echo ""

ROOT="$(pwd)"
ENGINE="$ROOT/src/maurimesh/invention-engine"
BACKUP="$ROOT/backup-before-invention-engine-$(date +%Y%m%d-%H%M%S)"

mkdir -p "$BACKUP"
mkdir -p "$ENGINE"

echo "Creating protected backup marker..."
cat > "$BACKUP/README.txt" <<'BACKUP'
Backup marker created before MauriMesh Invention Engine install.
This installer creates new files only under:
src/maurimesh/invention-engine

It does not delete existing BLE/router/ACK/store-forward files.
BACKUP

# ============================================================
# 1. TYPES
# ============================================================

cat > "$ENGINE/types.ts" <<'TS'
export type TransportKind =
  | "BLE"
  | "WIFI_DIRECT"
  | "LOCAL_WIFI"
  | "INTERNET"
  | "SATELLITE"
  | "STORE_FORWARD";

export type NodeRole =
  | "ENDPOINT"
  | "RELAY"
  | "GATEWAY"
  | "SUPERNODE"
  | "ANCHOR"
  | "UNKNOWN";

export type TrustLevel =
  | "BLOCKED"
  | "UNKNOWN"
  | "OBSERVED"
  | "TRUSTED"
  | "VERIFIED"
  | "GUARDIAN";

export type CulturalState =
  | "NOA_OPEN"
  | "TAPU_PROTECTED"
  | "WHANAUNGATANGA_TRUSTED"
  | "MANAAKITANGA_CARE"
  | "KAITIAKITANGA_GUARDIAN"
  | "KIA_KAHA_EMERGENCY";

export type DeliveryStatus =
  | "CREATED"
  | "QUEUED"
  | "ROUTING"
  | "SENT"
  | "RELAYED"
  | "STORED"
  | "DELIVERED"
  | "ACKED"
  | "FAILED"
  | "HEALING"
  | "DEFERRED";

export type MeshNode = {
  id: string;
  label?: string;
  role: NodeRole;
  trust: TrustLevel;
  batteryPct: number;
  signalPct: number;
  online: boolean;
  lastSeenMs: number;
  transports: TransportKind[];
  culturalState?: CulturalState;
};

export type MeshPacket = {
  id: string;
  from: string;
  to: string;
  body: string;
  createdAtMs: number;
  ttl: number;
  priority: number;
  culturalState: CulturalState;
  encrypted?: boolean;
  metadata?: Record<string, unknown>;
};

export type RouteHop = {
  nodeId: string;
  transport: TransportKind;
  score: number;
  reason: string;
};

export type RoutePlan = {
  packetId: string;
  hops: RouteHop[];
  totalScore: number;
  transport: TransportKind;
  decisionReason: string;
  storeAndForward: boolean;
  governanceApproved: boolean;
};

export type DeliveryLedgerEvent = {
  packetId: string;
  status: DeliveryStatus;
  atMs: number;
  nodeId?: string;
  route?: string[];
  reason?: string;
};

export type LearningMemory = {
  routeKey: string;
  successCount: number;
  failureCount: number;
  averageLatencyMs: number;
  trustDelta: number;
  lastUpdatedMs: number;
};

export type GovernanceDecision = {
  approved: boolean;
  reason: string;
  culturalState: CulturalState;
  restrictions: string[];
};

export type SynthAgentName = "CLEO_SYNTH" | "CHANELLE_SYNTH";

export type SynthMessage = {
  agent: SynthAgentName;
  tone: "calm" | "protective" | "educational" | "technical" | "emergency";
  text: string;
};

export type EngineResult = {
  packet: MeshPacket;
  governance: GovernanceDecision;
  routePlan: RoutePlan;
  ledger: DeliveryLedgerEvent[];
  synth: SynthMessage[];
};
TS

# ============================================================
# 2. UTILITIES
# ============================================================

cat > "$ENGINE/utils.ts" <<'TS'
export function nowMs(): number {
  return Date.now();
}

export function clamp(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, value));
}

export function safeId(prefix: string): string {
  const rand = Math.random().toString(36).slice(2, 10);
  return `${prefix}-${Date.now()}-${rand}`;
}

export function routeKey(nodes: string[]): string {
  return nodes.join(">");
}

export function weightedScore(parts: Array<[number, number]>): number {
  const totalWeight = parts.reduce((sum, [, weight]) => sum + weight, 0);
  if (totalWeight <= 0) return 0;
  return parts.reduce((sum, [value, weight]) => sum + value * weight, 0) / totalWeight;
}
TS

# ============================================================
# 3. OFFLINE-FIRST IDENTITY MESH MESSENGER
# ============================================================

cat > "$ENGINE/offlineIdentityMesh.ts" <<'TS'
import { MeshNode, TrustLevel } from "./types";
import { nowMs } from "./utils";

export type MeshIdentity = {
  deviceId: string;
  publicKey: string;
  displayName: string;
  trust: TrustLevel;
  createdAtMs: number;
  rotatedAtMs: number;
};

export class OfflineFirstIdentityMesh {
  private identities = new Map<string, MeshIdentity>();

  createIdentity(displayName: string): MeshIdentity {
    const id = `mmid-${Math.random().toString(36).slice(2)}-${Date.now()}`;
    const identity: MeshIdentity = {
      deviceId: id,
      publicKey: `pub-${id}`,
      displayName,
      trust: "OBSERVED",
      createdAtMs: nowMs(),
      rotatedAtMs: nowMs(),
    };
    this.identities.set(id, identity);
    return identity;
  }

  registerNodeIdentity(node: MeshNode): MeshIdentity {
    const existing = this.identities.get(node.id);
    if (existing) return existing;

    const identity: MeshIdentity = {
      deviceId: node.id,
      publicKey: `pub-${node.id}`,
      displayName: node.label || node.id,
      trust: node.trust,
      createdAtMs: nowMs(),
      rotatedAtMs: nowMs(),
    };

    this.identities.set(node.id, identity);
    return identity;
  }

  verifyKnownIdentity(deviceId: string): boolean {
    const identity = this.identities.get(deviceId);
    return Boolean(identity && identity.trust !== "BLOCKED");
  }

  promoteTrust(deviceId: string, trust: TrustLevel): void {
    const identity = this.identities.get(deviceId);
    if (!identity) return;
    identity.trust = trust;
  }

  listIdentities(): MeshIdentity[] {
    return Array.from(this.identities.values());
  }
}
TS

# ============================================================
# 4. LIVING ROUTE MEMORY
# ============================================================

cat > "$ENGINE/livingRouteMemory.ts" <<'TS'
import { LearningMemory } from "./types";
import { nowMs, routeKey } from "./utils";

export class LivingRouteMemory {
  private memory = new Map<string, LearningMemory>();

  recordSuccess(nodes: string[], latencyMs: number): LearningMemory {
    const key = routeKey(nodes);
    const existing = this.memory.get(key) || {
      routeKey: key,
      successCount: 0,
      failureCount: 0,
      averageLatencyMs: latencyMs,
      trustDelta: 0,
      lastUpdatedMs: nowMs(),
    };

    const total = existing.successCount + 1;
    existing.averageLatencyMs =
      (existing.averageLatencyMs * existing.successCount + latencyMs) / total;
    existing.successCount += 1;
    existing.trustDelta += 0.03;
    existing.lastUpdatedMs = nowMs();

    this.memory.set(key, existing);
    return existing;
  }

  recordFailure(nodes: string[]): LearningMemory {
    const key = routeKey(nodes);
    const existing = this.memory.get(key) || {
      routeKey: key,
      successCount: 0,
      failureCount: 0,
      averageLatencyMs: 9999,
      trustDelta: 0,
      lastUpdatedMs: nowMs(),
    };

    existing.failureCount += 1;
    existing.trustDelta -= 0.05;
    existing.lastUpdatedMs = nowMs();

    this.memory.set(key, existing);
    return existing;
  }

  scoreRoute(nodes: string[]): number {
    const key = routeKey(nodes);
    const mem = this.memory.get(key);
    if (!mem) return 0.5;

    const attempts = mem.successCount + mem.failureCount;
    const successRatio = attempts === 0 ? 0.5 : mem.successCount / attempts;
    const latencyScore = Math.max(0, 1 - mem.averageLatencyMs / 10000);
    const trustScore = Math.max(0, Math.min(1, 0.5 + mem.trustDelta));

    return successRatio * 0.5 + latencyScore * 0.25 + trustScore * 0.25;
  }

  exportMemory(): LearningMemory[] {
    return Array.from(this.memory.values());
  }
}
TS

# ============================================================
# 5. TIKANGA-BASED GOVERNANCE
# ============================================================

cat > "$ENGINE/tikangaGovernance.ts" <<'TS'
import { CulturalState, GovernanceDecision, MeshNode, MeshPacket } from "./types";

export class TikangaGovernance {
  decide(packet: MeshPacket, fromNode?: MeshNode, toNode?: MeshNode): GovernanceDecision {
    const restrictions: string[] = [];

    if (!fromNode) {
      restrictions.push("Sender identity not observed.");
    }

    if (fromNode?.trust === "BLOCKED") {
      return {
        approved: false,
        reason: "Sender is blocked by trust policy.",
        culturalState: "TAPU_PROTECTED",
        restrictions: ["Blocked identity cannot send through mesh."],
      };
    }

    if (toNode?.trust === "BLOCKED") {
      return {
        approved: false,
        reason: "Recipient is blocked by trust policy.",
        culturalState: "TAPU_PROTECTED",
        restrictions: ["Blocked recipient cannot receive through mesh."],
      };
    }

    if (packet.culturalState === "TAPU_PROTECTED") {
      restrictions.push("Only trusted or verified routes may carry protected packet.");
    }

    if (packet.culturalState === "KIA_KAHA_EMERGENCY") {
      restrictions.push("Emergency route allowed, but must preserve identity and delivery proof.");
    }

    return {
      approved: true,
      reason: "Packet approved under MauriMesh governance policy.",
      culturalState: packet.culturalState,
      restrictions,
    };
  }

  classifyMessage(body: string): CulturalState {
    const text = body.toLowerCase();

    if (
      text.includes("emergency") ||
      text.includes("help") ||
      text.includes("danger") ||
      text.includes("kia kaha")
    ) {
      return "KIA_KAHA_EMERGENCY";
    }

    if (
      text.includes("private") ||
      text.includes("confidential") ||
      text.includes("tapu")
    ) {
      return "TAPU_PROTECTED";
    }

    if (
      text.includes("family") ||
      text.includes("whānau") ||
      text.includes("whanau")
    ) {
      return "WHANAUNGATANGA_TRUSTED";
    }

    return "NOA_OPEN";
  }
}
TS

# ============================================================
# 6. MAURI AI ROUTING CONSCIENCE
# ============================================================

cat > "$ENGINE/mauriAiRoutingConscience.ts" <<'TS'
import { GovernanceDecision, MeshNode, MeshPacket, RoutePlan, TransportKind } from "./types";
import { LivingRouteMemory } from "./livingRouteMemory";
import { clamp, weightedScore } from "./utils";

export class MauriAiRoutingConscience {
  constructor(private memory: LivingRouteMemory) {}

  chooseRoute(
    packet: MeshPacket,
    nodes: MeshNode[],
    governance: GovernanceDecision
  ): RoutePlan {
    if (!governance.approved) {
      return {
        packetId: packet.id,
        hops: [],
        totalScore: 0,
        transport: "STORE_FORWARD",
        decisionReason: `Governance rejected packet: ${governance.reason}`,
        storeAndForward: true,
        governanceApproved: false,
      };
    }

    const sender = nodes.find((n) => n.id === packet.from);
    const receiver = nodes.find((n) => n.id === packet.to);
    const onlineTrusted = nodes.filter(
      (n) =>
        n.online &&
        n.trust !== "BLOCKED" &&
        n.batteryPct > 8 &&
        n.signalPct > 10
    );

    if (sender && receiver && receiver.online) {
      const directTransport = this.bestTransport(sender, receiver);
      const routeNodes = [sender.id, receiver.id];
      const score = this.scoreNode(receiver) * 0.7 + this.memory.scoreRoute(routeNodes) * 0.3;

      return {
        packetId: packet.id,
        hops: [
          {
            nodeId: receiver.id,
            transport: directTransport,
            score,
            reason: "Direct recipient route available.",
          },
        ],
        totalScore: score,
        transport: directTransport,
        decisionReason: "Mauri AI selected direct route.",
        storeAndForward: false,
        governanceApproved: true,
      };
    }

    const relays = onlineTrusted
      .filter((n) => n.role === "RELAY" || n.role === "GATEWAY" || n.role === "SUPERNODE")
      .map((n) => {
        const nodeScore = this.scoreNode(n);
        const memoryScore = this.memory.scoreRoute([packet.from, n.id, packet.to]);
        const culturalScore =
          packet.culturalState === "TAPU_PROTECTED" && n.trust !== "VERIFIED" && n.trust !== "GUARDIAN"
            ? 0.2
            : 1;

        return {
          node: n,
          score: weightedScore([
            [nodeScore, 0.45],
            [memoryScore, 0.35],
            [culturalScore, 0.2],
          ]),
        };
      })
      .sort((a, b) => b.score - a.score);

    const bestRelay = relays[0];

    if (!bestRelay) {
      return {
        packetId: packet.id,
        hops: [],
        totalScore: 0.35,
        transport: "STORE_FORWARD",
        decisionReason: "No safe online relay found. Packet should be stored.",
        storeAndForward: true,
        governanceApproved: true,
      };
    }

    const transport = this.pickRelayTransport(bestRelay.node);

    return {
      packetId: packet.id,
      hops: [
        {
          nodeId: bestRelay.node.id,
          transport,
          score: bestRelay.score,
          reason: "Best available trusted relay selected.",
        },
      ],
      totalScore: bestRelay.score,
      transport,
      decisionReason: "Mauri AI selected relay route with store-forward fallback.",
      storeAndForward: true,
      governanceApproved: true,
    };
  }

  private scoreNode(node: MeshNode): number {
    const signal = node.signalPct / 100;
    const battery = node.batteryPct / 100;
    const trust =
      node.trust === "GUARDIAN" ? 1 :
      node.trust === "VERIFIED" ? 0.9 :
      node.trust === "TRUSTED" ? 0.75 :
      node.trust === "OBSERVED" ? 0.55 :
      node.trust === "UNKNOWN" ? 0.35 : 0;

    const role =
      node.role === "SUPERNODE" ? 1 :
      node.role === "GATEWAY" ? 0.9 :
      node.role === "RELAY" ? 0.78 :
      node.role === "ANCHOR" ? 0.72 :
      node.role === "ENDPOINT" ? 0.45 : 0.3;

    return clamp(
      weightedScore([
        [signal, 0.3],
        [battery, 0.2],
        [trust, 0.35],
        [role, 0.15],
      ]),
      0,
      1
    );
  }

  private bestTransport(a: MeshNode, b: MeshNode): TransportKind {
    const shared = a.transports.filter((t) => b.transports.includes(t));
    if (shared.includes("WIFI_DIRECT")) return "WIFI_DIRECT";
    if (shared.includes("BLE")) return "BLE";
    if (shared.includes("LOCAL_WIFI")) return "LOCAL_WIFI";
    if (shared.includes("INTERNET")) return "INTERNET";
    return "STORE_FORWARD";
  }

  private pickRelayTransport(node: MeshNode): TransportKind {
    if (node.transports.includes("WIFI_DIRECT")) return "WIFI_DIRECT";
    if (node.transports.includes("BLE")) return "BLE";
    if (node.transports.includes("LOCAL_WIFI")) return "LOCAL_WIFI";
    if (node.transports.includes("INTERNET")) return "INTERNET";
    return "STORE_FORWARD";
  }
}
TS

# ============================================================
# 7. CLEO + CHANELLE SYNTH AI FEDERATION
# ============================================================

cat > "$ENGINE/cleoChanelleSynthFederation.ts" <<'TS'
import { EngineResult, SynthMessage } from "./types";

export class CleoChanelleSynthFederation {
  explain(result: EngineResult): SynthMessage[] {
    const messages: SynthMessage[] = [];

    messages.push({
      agent: "CLEO_SYNTH",
      tone: "calm",
      text: `Packet ${result.packet.id} was checked by governance: ${result.governance.reason}`,
    });

    messages.push({
      agent: "CHANELLE_SYNTH",
      tone: result.packet.culturalState === "KIA_KAHA_EMERGENCY" ? "emergency" : "educational",
      text: result.routePlan.storeAndForward
        ? "The message can be safely stored and forwarded when the next trusted path appears."
        : "A direct route is available now, so the message can move immediately.",
    });

    if (!result.governance.approved) {
      messages.push({
        agent: "CLEO_SYNTH",
        tone: "protective",
        text: "This message was stopped because the safety rules did not approve the route.",
      });
    }

    return messages;
  }
}
TS

# ============================================================
# 8. SELF-HEALING MESSENGER RUNTIME
# ============================================================

cat > "$ENGINE/selfHealingRuntime.ts" <<'TS'
import { DeliveryLedgerEvent, MeshNode, MeshPacket } from "./types";
import { nowMs } from "./utils";

export type HealingAction = {
  type:
    | "REMOVE_STALE_NODE"
    | "REQUEUE_PACKET"
    | "DOWNGRADE_ROUTE"
    | "WAIT_FOR_RELAY"
    | "NO_ACTION";
  reason: string;
  targetId?: string;
};

export class SelfHealingRuntime {
  findHealingActions(
    nodes: MeshNode[],
    queuedPackets: MeshPacket[],
    ledger: DeliveryLedgerEvent[]
  ): HealingAction[] {
    const actions: HealingAction[] = [];
    const current = nowMs();

    for (const node of nodes) {
      const staleMs = current - node.lastSeenMs;
      if (!node.online && staleMs > 5 * 60 * 1000) {
        actions.push({
          type: "REMOVE_STALE_NODE",
          targetId: node.id,
          reason: `Node ${node.id} is stale and offline.`,
        });
      }
    }

    for (const packet of queuedPackets) {
      const events = ledger.filter((e) => e.packetId === packet.id);
      const failed = events.some((e) => e.status === "FAILED");
      const acked = events.some((e) => e.status === "ACKED");

      if (failed && !acked) {
        actions.push({
          type: "REQUEUE_PACKET",
          targetId: packet.id,
          reason: `Packet ${packet.id} failed without ACK. Requeue required.`,
        });
      }
    }

    if (actions.length === 0) {
      actions.push({
        type: "NO_ACTION",
        reason: "Runtime health stable.",
      });
    }

    return actions;
  }
}
TS

# ============================================================
# 9. STORE AND FORWARD SOCIAL MESH
# ============================================================

cat > "$ENGINE/storeAndForwardSocialMesh.ts" <<'TS'
import { DeliveryLedgerEvent, MeshPacket } from "./types";
import { nowMs } from "./utils";

export class StoreAndForwardSocialMesh {
  private queue = new Map<string, MeshPacket>();

  store(packet: MeshPacket): DeliveryLedgerEvent {
    this.queue.set(packet.id, packet);
    return {
      packetId: packet.id,
      status: "STORED",
      atMs: nowMs(),
      reason: "Packet stored for future trusted delivery path.",
    };
  }

  releaseForRecipient(recipientId: string): MeshPacket[] {
    const ready: MeshPacket[] = [];

    for (const packet of this.queue.values()) {
      if (packet.to === recipientId) {
        ready.push(packet);
        this.queue.delete(packet.id);
      }
    }

    return ready;
  }

  listQueued(): MeshPacket[] {
    return Array.from(this.queue.values());
  }

  has(packetId: string): boolean {
    return this.queue.has(packetId);
  }
}
TS

# ============================================================
# 10. LIVING MESH VISUAL PROOF LAYER
# ============================================================

cat > "$ENGINE/livingMeshVisualProof.ts" <<'TS'
import { DeliveryLedgerEvent, MeshNode, RoutePlan } from "./types";

export type VisualProofNode = {
  id: string;
  label: string;
  role: string;
  trust: string;
  online: boolean;
  signalPct: number;
  batteryPct: number;
};

export type VisualProofRoute = {
  packetId: string;
  path: string[];
  score: number;
  transport: string;
  storeAndForward: boolean;
  reason: string;
};

export type VisualProofSnapshot = {
  nodes: VisualProofNode[];
  routes: VisualProofRoute[];
  recentLedger: DeliveryLedgerEvent[];
};

export class LivingMeshVisualProof {
  snapshot(
    nodes: MeshNode[],
    routePlans: RoutePlan[],
    ledger: DeliveryLedgerEvent[]
  ): VisualProofSnapshot {
    return {
      nodes: nodes.map((n) => ({
        id: n.id,
        label: n.label || n.id,
        role: n.role,
        trust: n.trust,
        online: n.online,
        signalPct: n.signalPct,
        batteryPct: n.batteryPct,
      })),
      routes: routePlans.map((r) => ({
        packetId: r.packetId,
        path: r.hops.map((h) => h.nodeId),
        score: r.totalScore,
        transport: r.transport,
        storeAndForward: r.storeAndForward,
        reason: r.decisionReason,
      })),
      recentLedger: ledger.slice(-20),
    };
  }
}
TS

# ============================================================
# 11. HYBRID HUMAN-AI-NETWORK PROTOCOL
# ============================================================

cat > "$ENGINE/hybridHumanAiNetworkProtocol.ts" <<'TS'
import { CulturalState, MeshPacket } from "./types";
import { safeId, nowMs } from "./utils";

export class HybridHumanAiNetworkProtocol {
  createPacket(input: {
    from: string;
    to: string;
    body: string;
    culturalState: CulturalState;
    priority?: number;
    ttl?: number;
  }): MeshPacket {
    return {
      id: safeId("pkt"),
      from: input.from,
      to: input.to,
      body: input.body,
      createdAtMs: nowMs(),
      ttl: input.ttl ?? 8,
      priority: input.priority ?? 5,
      culturalState: input.culturalState,
      encrypted: true,
      metadata: {
        protocol: "MAURIMESH_HYBRID_HUMAN_AI_NETWORK",
        version: "1.0.0",
      },
    };
  }
}
TS

# ============================================================
# 12. KIA KAHA EMERGENCY ROUTING MODE
# ============================================================

cat > "$ENGINE/kiaKahaEmergencyRouting.ts" <<'TS'
import { MeshPacket } from "./types";

export class KiaKahaEmergencyRouting {
  strengthen(packet: MeshPacket): MeshPacket {
    if (packet.culturalState !== "KIA_KAHA_EMERGENCY") return packet;

    return {
      ...packet,
      priority: 10,
      ttl: Math.max(packet.ttl, 12),
      metadata: {
        ...packet.metadata,
        emergencyMode: true,
        emergencyRule: "KIA_KAHA_PRIORITY_WITH_GOVERNANCE",
      },
    };
  }

  isEmergency(packet: MeshPacket): boolean {
    return packet.culturalState === "KIA_KAHA_EMERGENCY";
  }
}
TS

# ============================================================
# 13. TAPU / NOA DIGITAL PRIVACY STATES
# ============================================================

cat > "$ENGINE/tapuNoaPrivacyStates.ts" <<'TS'
import { CulturalState, MeshPacket, MeshNode } from "./types";

export class TapuNoaPrivacyStates {
  canRelay(packet: MeshPacket, node: MeshNode): boolean {
    if (packet.culturalState === "NOA_OPEN") return node.trust !== "BLOCKED";

    if (packet.culturalState === "TAPU_PROTECTED") {
      return node.trust === "VERIFIED" || node.trust === "GUARDIAN";
    }

    if (packet.culturalState === "KIA_KAHA_EMERGENCY") {
      return node.trust !== "BLOCKED" && node.batteryPct > 5;
    }

    return node.trust === "TRUSTED" || node.trust === "VERIFIED" || node.trust === "GUARDIAN";
  }

  applyPrivacyMetadata(packet: MeshPacket): MeshPacket {
    const privacy =
      packet.culturalState === "TAPU_PROTECTED"
        ? "RESTRICTED"
        : packet.culturalState === "NOA_OPEN"
          ? "OPEN"
          : "CONTEXTUAL";

    return {
      ...packet,
      metadata: {
        ...packet.metadata,
        privacyState: privacy,
        culturalState: packet.culturalState,
      },
    };
  }

  label(state: CulturalState): string {
    switch (state) {
      case "NOA_OPEN":
        return "Noa / Open";
      case "TAPU_PROTECTED":
        return "Tapu / Protected";
      case "KIA_KAHA_EMERGENCY":
        return "Kia Kaha / Emergency";
      case "WHANAUNGATANGA_TRUSTED":
        return "Whanaungatanga / Trusted relationship";
      case "MANAAKITANGA_CARE":
        return "Manaakitanga / Care";
      case "KAITIAKITANGA_GUARDIAN":
        return "Kaitiakitanga / Guardian";
      default:
        return state;
    }
  }
}
TS

# ============================================================
# 14. PATHWAY + PIPELINE DUAL ARCHITECTURE
# ============================================================

cat > "$ENGINE/pathwayPipelineArchitecture.ts" <<'TS'
import { DeliveryLedgerEvent, MeshPacket, RoutePlan } from "./types";
import { nowMs } from "./utils";

export type PipelineStage =
  | "CREATE"
  | "CLASSIFY"
  | "GOVERN"
  | "PRIVACY"
  | "ROUTE"
  | "SEND_OR_STORE"
  | "ACK"
  | "LEARN"
  | "HEAL"
  | "VISUALIZE";

export type PipelineTrace = {
  packetId: string;
  stages: Array<{
    stage: PipelineStage;
    atMs: number;
    detail: string;
  }>;
};

export class PathwayPipelineArchitecture {
  createTrace(packet: MeshPacket): PipelineTrace {
    return {
      packetId: packet.id,
      stages: [
        {
          stage: "CREATE",
          atMs: nowMs(),
          detail: "Packet created by Hybrid Human-AI-Network Protocol.",
        },
      ],
    };
  }

  addStage(trace: PipelineTrace, stage: PipelineStage, detail: string): PipelineTrace {
    trace.stages.push({
      stage,
      atMs: nowMs(),
      detail,
    });
    return trace;
  }

  routeToLedger(packet: MeshPacket, routePlan: RoutePlan): DeliveryLedgerEvent {
    return {
      packetId: packet.id,
      status: routePlan.storeAndForward ? "STORED" : "SENT",
      atMs: nowMs(),
      route: routePlan.hops.map((h) => h.nodeId),
      reason: routePlan.decisionReason,
    };
  }
}
TS

# ============================================================
# 15. DECENTRALISED TRUST MEMORY
# ============================================================

cat > "$ENGINE/decentralisedTrustMemory.ts" <<'TS'
import { MeshNode, TrustLevel } from "./types";
import { clamp } from "./utils";

export type TrustRecord = {
  nodeId: string;
  score: number;
  successes: number;
  failures: number;
  lastReason: string;
};

export class DecentralisedTrustMemory {
  private trust = new Map<string, TrustRecord>();

  observeSuccess(nodeId: string, reason = "Successful relay or ACK."): TrustRecord {
    const record = this.getOrCreate(nodeId);
    record.successes += 1;
    record.score = clamp(record.score + 0.04, 0, 1);
    record.lastReason = reason;
    this.trust.set(nodeId, record);
    return record;
  }

  observeFailure(nodeId: string, reason = "Failed relay or missing ACK."): TrustRecord {
    const record = this.getOrCreate(nodeId);
    record.failures += 1;
    record.score = clamp(record.score - 0.07, 0, 1);
    record.lastReason = reason;
    this.trust.set(nodeId, record);
    return record;
  }

  applyToNode(node: MeshNode): MeshNode {
    const record = this.trust.get(node.id);
    if (!record) return node;

    return {
      ...node,
      trust: this.scoreToTrust(record.score),
    };
  }

  scoreToTrust(score: number): TrustLevel {
    if (score <= 0.05) return "BLOCKED";
    if (score < 0.3) return "UNKNOWN";
    if (score < 0.55) return "OBSERVED";
    if (score < 0.78) return "TRUSTED";
    if (score < 0.93) return "VERIFIED";
    return "GUARDIAN";
  }

  exportTrust(): TrustRecord[] {
    return Array.from(this.trust.values());
  }

  private getOrCreate(nodeId: string): TrustRecord {
    return (
      this.trust.get(nodeId) || {
        nodeId,
        score: 0.5,
        successes: 0,
        failures: 0,
        lastReason: "Initial observation.",
      }
    );
  }
}
TS

# ============================================================
# 16. MESH MESSENGER AS COMMUNITY INFRASTRUCTURE
# ============================================================

cat > "$ENGINE/communityInfrastructure.ts" <<'TS'
import { MeshNode } from "./types";

export type CommunityProfile = {
  id: string;
  name: string;
  purpose:
    | "FAMILY"
    | "IWI"
    | "SCHOOL"
    | "HOSPITAL"
    | "SECURITY"
    | "EMERGENCY"
    | "RURAL"
    | "PUBLIC_GOOD";
  guardians: string[];
  allowedRelays: string[];
};

export class CommunityInfrastructure {
  private communities = new Map<string, CommunityProfile>();

  createCommunity(profile: CommunityProfile): CommunityProfile {
    this.communities.set(profile.id, profile);
    return profile;
  }

  canNodeServeCommunity(node: MeshNode, communityId: string): boolean {
    const community = this.communities.get(communityId);
    if (!community) return false;

    if (node.trust === "BLOCKED") return false;
    if (community.guardians.includes(node.id)) return true;
    if (community.allowedRelays.includes(node.id)) return true;

    return node.role === "GATEWAY" || node.role === "SUPERNODE";
  }

  listCommunities(): CommunityProfile[] {
    return Array.from(this.communities.values());
  }
}
TS

# ============================================================
# 17. LIVING SELF-GOVERNED AI MESH ORCHESTRATOR
# ============================================================

cat > "$ENGINE/livingSelfGovernedAiMesh.ts" <<'TS'
import {
  DeliveryLedgerEvent,
  EngineResult,
  MeshNode,
  MeshPacket,
  RoutePlan,
} from "./types";
import { OfflineFirstIdentityMesh } from "./offlineIdentityMesh";
import { LivingRouteMemory } from "./livingRouteMemory";
import { TikangaGovernance } from "./tikangaGovernance";
import { MauriAiRoutingConscience } from "./mauriAiRoutingConscience";
import { CleoChanelleSynthFederation } from "./cleoChanelleSynthFederation";
import { SelfHealingRuntime } from "./selfHealingRuntime";
import { StoreAndForwardSocialMesh } from "./storeAndForwardSocialMesh";
import { LivingMeshVisualProof } from "./livingMeshVisualProof";
import { HybridHumanAiNetworkProtocol } from "./hybridHumanAiNetworkProtocol";
import { KiaKahaEmergencyRouting } from "./kiaKahaEmergencyRouting";
import { TapuNoaPrivacyStates } from "./tapuNoaPrivacyStates";
import { PathwayPipelineArchitecture } from "./pathwayPipelineArchitecture";
import { DecentralisedTrustMemory } from "./decentralisedTrustMemory";
import { CommunityInfrastructure } from "./communityInfrastructure";
import { nowMs } from "./utils";

export class LivingSelfGovernedAiMesh {
  readonly identity = new OfflineFirstIdentityMesh();
  readonly routeMemory = new LivingRouteMemory();
  readonly governance = new TikangaGovernance();
  readonly routingAi = new MauriAiRoutingConscience(this.routeMemory);
  readonly synth = new CleoChanelleSynthFederation();
  readonly healing = new SelfHealingRuntime();
  readonly storeForward = new StoreAndForwardSocialMesh();
  readonly visualProof = new LivingMeshVisualProof();
  readonly protocol = new HybridHumanAiNetworkProtocol();
  readonly kiaKaha = new KiaKahaEmergencyRouting();
  readonly privacy = new TapuNoaPrivacyStates();
  readonly pipeline = new PathwayPipelineArchitecture();
  readonly trustMemory = new DecentralisedTrustMemory();
  readonly community = new CommunityInfrastructure();

  private nodes: MeshNode[] = [];
  private ledger: DeliveryLedgerEvent[] = [];
  private routePlans: RoutePlan[] = [];

  setNodes(nodes: MeshNode[]): void {
    this.nodes = nodes.map((n) => {
      this.identity.registerNodeIdentity(n);
      return this.trustMemory.applyToNode(n);
    });
  }

  getNodes(): MeshNode[] {
    return this.nodes;
  }

  send(input: {
    from: string;
    to: string;
    body: string;
    priority?: number;
  }): EngineResult {
    const culturalState = this.governance.classifyMessage(input.body);

    let packet: MeshPacket = this.protocol.createPacket({
      from: input.from,
      to: input.to,
      body: input.body,
      culturalState,
      priority: input.priority,
    });

    const trace = this.pipeline.createTrace(packet);
    this.pipeline.addStage(trace, "CLASSIFY", `Message classified as ${culturalState}.`);

    packet = this.privacy.applyPrivacyMetadata(packet);
    this.pipeline.addStage(trace, "PRIVACY", "Tapu/Noa privacy metadata applied.");

    packet = this.kiaKaha.strengthen(packet);
    if (this.kiaKaha.isEmergency(packet)) {
      this.pipeline.addStage(trace, "GOVERN", "Kia Kaha emergency priority strengthened.");
    }

    const fromNode = this.nodes.find((n) => n.id === packet.from);
    const toNode = this.nodes.find((n) => n.id === packet.to);

    const governance = this.governance.decide(packet, fromNode, toNode);
    this.pipeline.addStage(trace, "GOVERN", governance.reason);

    const routePlan = this.routingAi.chooseRoute(packet, this.nodes, governance);
    this.routePlans.push(routePlan);
    this.pipeline.addStage(trace, "ROUTE", routePlan.decisionReason);

    const createdEvent: DeliveryLedgerEvent = {
      packetId: packet.id,
      status: "CREATED",
      atMs: packet.createdAtMs,
      nodeId: packet.from,
      reason: "Packet created.",
    };

    const queuedEvent: DeliveryLedgerEvent = {
      packetId: packet.id,
      status: "QUEUED",
      atMs: nowMs(),
      nodeId: packet.from,
      reason: "Packet queued for route decision.",
    };

    const routeEvent = this.pipeline.routeToLedger(packet, routePlan);

    this.ledger.push(createdEvent, queuedEvent, routeEvent);

    if (routePlan.storeAndForward) {
      const stored = this.storeForward.store(packet);
      this.ledger.push(stored);
      this.pipeline.addStage(trace, "SEND_OR_STORE", "Packet stored for forward delivery.");
    } else {
      this.pipeline.addStage(trace, "SEND_OR_STORE", "Packet ready for immediate send.");
    }

    if (routePlan.hops.length > 0) {
      for (const hop of routePlan.hops) {
        this.trustMemory.observeSuccess(hop.nodeId, "Selected as healthy route candidate.");
      }
    }

    const healingActions = this.healing.findHealingActions(
      this.nodes,
      this.storeForward.listQueued(),
      this.ledger
    );

    this.pipeline.addStage(
      trace,
      "HEAL",
      healingActions.map((a) => a.reason).join(" | ")
    );

    const resultBase: EngineResult = {
      packet,
      governance,
      routePlan,
      ledger: this.ledger.filter((e) => e.packetId === packet.id),
      synth: [],
    };

    const result: EngineResult = {
      ...resultBase,
      synth: this.synth.explain(resultBase),
    };

    return result;
  }

  ack(packetId: string, routeNodes: string[], latencyMs: number): void {
    this.ledger.push({
      packetId,
      status: "ACKED",
      atMs: nowMs(),
      route: routeNodes,
      reason: "Delivery acknowledged.",
    });

    this.routeMemory.recordSuccess(routeNodes, latencyMs);

    for (const nodeId of routeNodes) {
      this.trustMemory.observeSuccess(nodeId, "ACK confirmed route trust.");
    }
  }

  fail(packetId: string, routeNodes: string[], reason: string): void {
    this.ledger.push({
      packetId,
      status: "FAILED",
      atMs: nowMs(),
      route: routeNodes,
      reason,
    });

    this.routeMemory.recordFailure(routeNodes);

    for (const nodeId of routeNodes) {
      this.trustMemory.observeFailure(nodeId, reason);
    }
  }

  visualSnapshot() {
    return this.visualProof.snapshot(this.nodes, this.routePlans, this.ledger);
  }

  ledgerExport(): DeliveryLedgerEvent[] {
    return [...this.ledger];
  }

  routeMemoryExport() {
    return this.routeMemory.exportMemory();
  }

  trustMemoryExport() {
    return this.trustMemory.exportTrust();
  }
}
TS

# ============================================================
# 18. INDEX EXPORTS
# ============================================================

cat > "$ENGINE/index.ts" <<'TS'
export * from "./types";
export * from "./offlineIdentityMesh";
export * from "./livingRouteMemory";
export * from "./tikangaGovernance";
export * from "./mauriAiRoutingConscience";
export * from "./cleoChanelleSynthFederation";
export * from "./selfHealingRuntime";
export * from "./storeAndForwardSocialMesh";
export * from "./livingMeshVisualProof";
export * from "./hybridHumanAiNetworkProtocol";
export * from "./kiaKahaEmergencyRouting";
export * from "./tapuNoaPrivacyStates";
export * from "./pathwayPipelineArchitecture";
export * from "./decentralisedTrustMemory";
export * from "./communityInfrastructure";
export * from "./livingSelfGovernedAiMesh";
TS

# ============================================================
# 19. DEMO / TEST FILE
# ============================================================

cat > "$ENGINE/demo.ts" <<'TS'
import { LivingSelfGovernedAiMesh, MeshNode } from "./index";

const engine = new LivingSelfGovernedAiMesh();

const nodes: MeshNode[] = [
  {
    id: "PHONE_A",
    label: "Devan Phone",
    role: "ENDPOINT",
    trust: "VERIFIED",
    batteryPct: 88,
    signalPct: 92,
    online: true,
    lastSeenMs: Date.now(),
    transports: ["BLE", "WIFI_DIRECT", "LOCAL_WIFI"],
    culturalState: "WHANAUNGATANGA_TRUSTED",
  },
  {
    id: "PHONE_B",
    label: "Relay Phone",
    role: "RELAY",
    trust: "TRUSTED",
    batteryPct: 71,
    signalPct: 80,
    online: true,
    lastSeenMs: Date.now(),
    transports: ["BLE", "WIFI_DIRECT"],
  },
  {
    id: "PHONE_C",
    label: "Recipient Phone",
    role: "ENDPOINT",
    trust: "OBSERVED",
    batteryPct: 64,
    signalPct: 45,
    online: false,
    lastSeenMs: Date.now() - 60000,
    transports: ["BLE"],
  },
];

engine.setNodes(nodes);

const result = engine.send({
  from: "PHONE_A",
  to: "PHONE_C",
  body: "Kia kaha, emergency help message through MauriMesh.",
});

console.log("");
console.log("============================================================");
console.log("MAURIMESH INVENTION ENGINE DEMO RESULT");
console.log("============================================================");
console.log(JSON.stringify(result, null, 2));

console.log("");
console.log("============================================================");
console.log("VISUAL SNAPSHOT");
console.log("============================================================");
console.log(JSON.stringify(engine.visualSnapshot(), null, 2));
TS

# ============================================================
# 20. OPTIONAL PACKAGE SCRIPT PATCH
# ============================================================

node <<'NODE'
const fs = require("fs");
const path = "package.json";

if (!fs.existsSync(path)) {
  console.log("package.json not found. Skipping script patch.");
  process.exit(0);
}

const pkg = JSON.parse(fs.readFileSync(path, "utf8"));
pkg.scripts = pkg.scripts || {};
pkg.scripts["maurimesh:invention-demo"] = "tsx src/maurimesh/invention-engine/demo.ts";
pkg.scripts["maurimesh:check"] = "tsc --noEmit";

pkg.devDependencies = pkg.devDependencies || {};
pkg.devDependencies["tsx"] = pkg.devDependencies["tsx"] || "latest";
pkg.devDependencies["typescript"] = pkg.devDependencies["typescript"] || "latest";

fs.writeFileSync(path, JSON.stringify(pkg, null, 2));
console.log("package.json patched with MauriMesh invention scripts.");
NODE

echo ""
echo "============================================================"
echo "MAURIMESH INVENTION ENGINE INSTALLED"
echo "============================================================"
echo ""
echo "Created:"
echo "  src/maurimesh/invention-engine/"
echo ""
echo "Run:"
echo "  npm install"
echo "  npm run maurimesh:check"
echo "  npm run maurimesh:invention-demo"
echo ""
echo "Truth:"
echo "  This is the full TypeScript invention-engine scaffold."
echo "  It does not replace native BLE, APK proof, or real device testing."
echo "  It protects and defines every invention as code modules."
echo ""
