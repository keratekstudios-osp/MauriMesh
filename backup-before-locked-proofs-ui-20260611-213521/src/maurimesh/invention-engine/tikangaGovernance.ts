import { CulturalState, GovernanceDecision, MeshNode, MeshPacket } from "./types";

export class TikangaGovernance {
  decide(packet: MeshPacket, fromNode?: MeshNode, toNode?: MeshNode): GovernanceDecision {
    const restrictions: string[] = [];

    if (!fromNode) {
      restrictions.push("Sender identity not observed.");
    }

    if (fromNode?.trust === "BLOCKED") {
      return {
        approved: false,
        reason: "Sender is blocked by trust policy.",
        culturalState: "TAPU_PROTECTED",
        restrictions: ["Blocked identity cannot send through mesh."],
      };
    }

    if (toNode?.trust === "BLOCKED") {
      return {
        approved: false,
        reason: "Recipient is blocked by trust policy.",
        culturalState: "TAPU_PROTECTED",
        restrictions: ["Blocked recipient cannot receive through mesh."],
      };
    }

    if (packet.culturalState === "TAPU_PROTECTED") {
      restrictions.push("Only trusted or verified routes may carry protected packet.");
    }

    if (packet.culturalState === "KIA_KAHA_EMERGENCY") {
      restrictions.push("Emergency route allowed, but must preserve identity and delivery proof.");
    }

    return {
      approved: true,
      reason: "Packet approved under MauriMesh governance policy.",
      culturalState: packet.culturalState,
      restrictions,
    };
  }

  classifyMessage(body: string): CulturalState {
    const text = body.toLowerCase();

    if (
      text.includes("emergency") ||
      text.includes("help") ||
      text.includes("danger") ||
      text.includes("kia kaha")
    ) {
      return "KIA_KAHA_EMERGENCY";
    }

    if (
      text.includes("private") ||
      text.includes("confidential") ||
      text.includes("tapu")
    ) {
      return "TAPU_PROTECTED";
    }

    if (
      text.includes("family") ||
      text.includes("whānau") ||
      text.includes("whanau")
    ) {
      return "WHANAUNGATANGA_TRUSTED";
    }

    return "NOA_OPEN";
  }
}
