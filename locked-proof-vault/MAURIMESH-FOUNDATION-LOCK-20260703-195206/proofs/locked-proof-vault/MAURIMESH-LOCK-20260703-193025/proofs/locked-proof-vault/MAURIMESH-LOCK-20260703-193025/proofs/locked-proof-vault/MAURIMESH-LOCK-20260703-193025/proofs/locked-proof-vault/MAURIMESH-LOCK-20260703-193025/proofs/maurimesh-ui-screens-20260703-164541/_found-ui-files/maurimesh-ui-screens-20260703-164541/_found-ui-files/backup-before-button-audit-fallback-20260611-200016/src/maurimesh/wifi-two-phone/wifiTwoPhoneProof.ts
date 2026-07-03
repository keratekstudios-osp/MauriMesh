export type WifiPhoneRole =
  | "PHONE_A_WIFI_GATEWAY"
  | "PHONE_B_WIFI_CLIENT"
  | "APP_AUTOTEST";

export type WifiProofStage =
  | "WIFI_PROOF_ROUTE_OPENED"
  | "PHONE_A_WIFI_GATEWAY_SELECTED"
  | "PHONE_A_HOTSPOT_CONFIRMED_ON"
  | "PHONE_A_GATEWAY_READY"
  | "PHONE_B_WIFI_CLIENT_SELECTED"
  | "PHONE_B_CONNECTED_TO_PHONE_A_WIFI"
  | "PHONE_B_WIFI_TX_START"
  | "PHONE_A_WIFI_RX_FROM_B"
  | "PHONE_A_WIFI_FORWARD_ATTEMPT"
  | "PHONE_A_WIFI_FORWARD_SUCCESS"
  | "PHONE_A_WIFI_ACK_TO_B"
  | "PHONE_B_WIFI_ACK_RECEIVED"
  | "WIFI_PHONE_A_DETECTED"
  | "WIFI_PHONE_B_DETECTED"
  | "BOTH_WIFI_PHONES_DETECTED"
  | "WIFI_2HOP_READY";

export const wifiProofIdentity = {
  proofId: `MM-WIFI-2PHONE-${Date.now()}`,
  networkKey: `maurimesh-wifi-proof-${Date.now()}`,
  path: "PHONE_B_WIFI_CLIENT -> PHONE_A_WIFI_GATEWAY -> INTERNET_OR_API",
  requiredStages: [
    "WIFI_PROOF_ROUTE_OPENED",
    "PHONE_A_WIFI_GATEWAY_SELECTED",
    "PHONE_A_HOTSPOT_CONFIRMED_ON",
    "PHONE_A_GATEWAY_READY",
    "PHONE_B_WIFI_CLIENT_SELECTED",
    "PHONE_B_CONNECTED_TO_PHONE_A_WIFI",
    "PHONE_B_WIFI_TX_START",
    "PHONE_A_WIFI_RX_FROM_B",
    "PHONE_A_WIFI_FORWARD_ATTEMPT",
    "PHONE_A_WIFI_FORWARD_SUCCESS",
    "PHONE_A_WIFI_ACK_TO_B",
    "PHONE_B_WIFI_ACK_RECEIVED",
    "WIFI_PHONE_A_DETECTED",
    "WIFI_PHONE_B_DETECTED",
    "BOTH_WIFI_PHONES_DETECTED",
    "WIFI_2HOP_READY",
  ] as WifiProofStage[],
};

export function makeWifiLine(role: WifiPhoneRole, stage: WifiProofStage, detail: string) {
  return [
    "[MauriMeshWifiProof]",
    `proofId=${wifiProofIdentity.proofId}`,
    `networkKey=${wifiProofIdentity.networkKey}`,
    `phoneRole=${role}`,
    `stage=${stage}`,
    `timestamp=${new Date().toISOString()}`,
    `detail=${detail}`,
  ].join(" ");
}
