export type ThreeHopStage =
  | "PHONE_A_TX_BLE_START"
  | "PHONE_B_RX_BLE_FROM_A"
  | "PHONE_B_RELAY_TX_TO_C"
  | "PHONE_C_RX_BLE_FROM_B"
  | "PHONE_C_STRICT_ACK_SENT"
  | "PHONE_B_RELAY_ACK_FROM_C"
  | "PHONE_A_STRICT_OR_RELAY_ACK_RECEIVED";

export type ThreeHopProofEvent = {
  proofId: string;
  packetId: string;
  routeId: string;
  phoneRole: "PHONE_A" | "PHONE_B" | "PHONE_C";
  stage: ThreeHopStage;
  timestamp: string;
  detail: string;
};

export const threeHopProofTemplate = {
  proofId: "MM-3HOP-20260610-193726",
  packetId: "pkt3hop-20260610-193726",
  routeId: "route-A-B-C-20260610-193726",
  path: ["PHONE_A", "PHONE_B", "PHONE_C"],
  ackPath: ["PHONE_C", "PHONE_B", "PHONE_A"],
  requiredStages: [
    "PHONE_A_TX_BLE_START",
    "PHONE_B_RX_BLE_FROM_A",
    "PHONE_B_RELAY_TX_TO_C",
    "PHONE_C_RX_BLE_FROM_B",
    "PHONE_C_STRICT_ACK_SENT",
    "PHONE_B_RELAY_ACK_FROM_C",
    "PHONE_A_STRICT_OR_RELAY_ACK_RECEIVED",
  ] as ThreeHopStage[],
};

export function formatThreeHopProofLine(event: ThreeHopProofEvent) {
  return [
    "[MauriMesh3HopProof]",
    `proofId=${event.proofId}`,
    `packetId=${event.packetId}`,
    `routeId=${event.routeId}`,
    `phoneRole=${event.phoneRole}`,
    `stage=${event.stage}`,
    `timestamp=${event.timestamp}`,
    `detail=${event.detail}`,
  ].join(" ");
}
