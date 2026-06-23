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
