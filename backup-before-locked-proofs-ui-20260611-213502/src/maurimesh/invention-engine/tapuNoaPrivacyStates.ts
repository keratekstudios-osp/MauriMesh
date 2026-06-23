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
