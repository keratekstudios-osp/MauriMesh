import { CorePacket, PacketPrivacy, TransportKind } from "../types/core.types";
import { deterministicHash } from "../proof/hashEngine";
import { createPacketSignature } from "../security/securityEngine";

export function createCorePacket(input: {
  senderId: string;
  recipientId: string;
  payload: unknown;
  routePath?: string[];
  ttl?: number;
  privacy?: PacketPrivacy;
  transport?: TransportKind;
}): CorePacket {
  const timestamp = new Date().toISOString();
  const payloadHash = deterministicHash(input.payload);
  const packetId = `pkt_${deterministicHash({ senderId: input.senderId, recipientId: input.recipientId, payloadHash, timestamp })}`;
  const ackToken = `ack_${deterministicHash({ packetId, timestamp })}`;

  const packet: CorePacket = {
    packetId,
    senderId: input.senderId,
    recipientId: input.recipientId,
    timestamp,
    ttl: input.ttl ?? 8,
    hopCount: 0,
    routePath: input.routePath || [input.senderId],
    payloadHash,
    ackToken,
    retryCount: 0,
    privacy: input.privacy ?? "encrypted_relay",
    transport: input.transport ?? "UNKNOWN",
    storeForward: false,
  };

  packet.signature = createPacketSignature(packet.payloadHash, input.senderId);
  return packet;
}

export function incrementPacketHop(packet: CorePacket, nodeId: string): CorePacket {
  return {
    ...packet,
    hopCount: packet.hopCount + 1,
    routePath: [...packet.routePath, nodeId],
    storeForward: packet.hopCount + 1 >= packet.ttl,
  };
}

export function packetRequiresTapuHandling(packet: CorePacket): boolean {
  return packet.privacy === "tapu_private" || packet.privacy === "never_share";
}
