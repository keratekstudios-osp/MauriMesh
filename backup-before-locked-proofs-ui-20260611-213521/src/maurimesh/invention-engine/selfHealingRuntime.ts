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
