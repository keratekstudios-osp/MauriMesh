export const totalProofIdentity = {
  generatedAt: new Date().toISOString(),
  twoHopRequired: [
    "MauriMeshWifiProof",
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
  ],
  threeHopRequired: [
    "PHONE_A_TX_BLE_START",
    "PHONE_B_RX_BLE_FROM_A",
    "PHONE_B_RELAY_TX_TO_C",
    "PHONE_C_RX_BLE_FROM_B",
    "PHONE_C_STRICT_ACK_SENT",
    "PHONE_B_RELAY_ACK_FROM_C",
    "PHONE_A_STRICT_OR_RELAY_ACK_RECEIVED",
  ],
};

export function proofLine(tag: string, stage: string) {
  return [
    `[${tag}]`,
    `stage=${stage}`,
    `timestamp=${new Date().toISOString()}`,
    "status=APP_AUTOTEST",
  ].join(" ");
}
