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
