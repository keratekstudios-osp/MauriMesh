export type TwoPhoneHotspotStage =
  | "PHONE_A_HOTSPOT_ON"
  | "PHONE_A_GATEWAY_READY"
  | "PHONE_B_CONNECTED_TO_PHONE_A_HOTSPOT"
  | "PHONE_B_TX_PACKET_START"
  | "PHONE_A_GATEWAY_RX_FROM_B"
  | "PHONE_A_GATEWAY_FORWARD_ATTEMPT"
  | "PHONE_A_GATEWAY_FORWARD_SUCCESS"
  | "PHONE_A_GATEWAY_ACK_TO_B"
  | "PHONE_B_ACK_RECEIVED";

export type TwoPhoneHotspotProofEvent = {
  proofId: string;
  packetId: string;
  routeId: string;
  phoneRole: "PHONE_A_GATEWAY" | "PHONE_B_CLIENT";
  stage: TwoPhoneHotspotStage;
  timestamp: string;
  detail: string;
};

export const twoPhoneHotspotProofTemplate = {
  proofId: "MM-HOTSPOT-2PHONE-20260610-200534",
  packetId: "pkt-hotspot-20260610-200534",
  routeId: "route-phoneB-phoneA-hotspot-20260610-200534",
  path: ["PHONE_B_CLIENT", "PHONE_A_HOTSPOT_GATEWAY", "INTERNET_OR_API"],
  requiredStages: [
    "PHONE_A_HOTSPOT_ON",
    "PHONE_A_GATEWAY_READY",
    "PHONE_B_CONNECTED_TO_PHONE_A_HOTSPOT",
    "PHONE_B_TX_PACKET_START",
    "PHONE_A_GATEWAY_RX_FROM_B",
    "PHONE_A_GATEWAY_FORWARD_ATTEMPT",
    "PHONE_A_GATEWAY_FORWARD_SUCCESS",
    "PHONE_A_GATEWAY_ACK_TO_B",
    "PHONE_B_ACK_RECEIVED",
  ] as TwoPhoneHotspotStage[],
};

export function formatTwoPhoneHotspotProofLine(event: TwoPhoneHotspotProofEvent) {
  return [
    "[MauriMeshHotspotProof]",
    `proofId=${event.proofId}`,
    `packetId=${event.packetId}`,
    `routeId=${event.routeId}`,
    `phoneRole=${event.phoneRole}`,
    `stage=${event.stage}`,
    `timestamp=${event.timestamp}`,
    `detail=${event.detail}`,
  ].join(" ");
}
