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
