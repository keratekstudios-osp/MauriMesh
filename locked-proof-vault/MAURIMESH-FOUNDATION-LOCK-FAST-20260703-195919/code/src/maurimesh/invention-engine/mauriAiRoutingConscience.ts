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
