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
