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
