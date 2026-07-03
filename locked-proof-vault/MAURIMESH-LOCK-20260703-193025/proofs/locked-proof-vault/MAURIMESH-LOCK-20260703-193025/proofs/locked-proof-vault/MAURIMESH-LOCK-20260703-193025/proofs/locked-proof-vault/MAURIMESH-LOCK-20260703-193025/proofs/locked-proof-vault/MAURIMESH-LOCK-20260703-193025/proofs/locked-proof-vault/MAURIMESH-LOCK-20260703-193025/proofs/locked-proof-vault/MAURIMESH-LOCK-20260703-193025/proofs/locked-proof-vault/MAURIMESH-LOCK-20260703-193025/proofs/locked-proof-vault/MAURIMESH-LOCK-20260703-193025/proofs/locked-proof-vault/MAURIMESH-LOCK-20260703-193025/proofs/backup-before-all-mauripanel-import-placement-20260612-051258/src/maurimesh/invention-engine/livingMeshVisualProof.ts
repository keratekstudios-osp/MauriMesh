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
