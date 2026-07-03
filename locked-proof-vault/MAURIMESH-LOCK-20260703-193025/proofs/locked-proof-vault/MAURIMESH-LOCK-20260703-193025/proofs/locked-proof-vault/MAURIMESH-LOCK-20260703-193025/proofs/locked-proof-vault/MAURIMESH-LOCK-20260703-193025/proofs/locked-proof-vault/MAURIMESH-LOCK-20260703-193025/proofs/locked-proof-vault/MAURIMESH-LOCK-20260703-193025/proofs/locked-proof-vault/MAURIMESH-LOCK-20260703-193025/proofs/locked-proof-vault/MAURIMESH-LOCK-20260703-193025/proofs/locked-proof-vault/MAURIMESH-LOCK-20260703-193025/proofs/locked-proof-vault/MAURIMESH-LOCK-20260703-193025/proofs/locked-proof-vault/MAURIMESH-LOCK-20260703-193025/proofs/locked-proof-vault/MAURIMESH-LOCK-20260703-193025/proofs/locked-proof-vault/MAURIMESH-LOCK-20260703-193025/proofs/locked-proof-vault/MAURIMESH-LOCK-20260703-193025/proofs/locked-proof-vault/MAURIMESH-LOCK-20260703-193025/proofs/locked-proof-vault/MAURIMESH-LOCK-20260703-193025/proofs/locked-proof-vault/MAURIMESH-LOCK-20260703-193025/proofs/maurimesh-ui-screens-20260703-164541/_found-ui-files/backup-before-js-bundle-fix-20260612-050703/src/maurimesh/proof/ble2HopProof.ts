export const BLE_2_HOP_PROOF = {
  status: "PASSED",
  packetId: "MM-MQ94C3HX-VOZO1H",
  title: "MauriMesh 2-Hop BLE Proof",
  path: "A06 TX -> S10 RX -> S10 ACK -> A06 ACK",
  devices: {
    phoneA: "Samsung A06 / PHONE A / Sender",
    phoneB: "Samsung S10 / PHONE B / Relay ACK",
  },
  truth:
    "Physical APK/two-phone proof. This must not be confused with Replit simulation.",
  sequence: [
    "A06 generated packet ID",
    "A06 transmitted packet toward S10",
    "S10 received packet from A06",
    "S10 relayed ACK back toward A06",
    "A06 confirmed ACK returned from S10",
  ],
  proofLog: [
    "PACKET_ID: MM-MQ94C3HX-VOZO1H",
    "A06_SENDER: TX_A06_TO_S10 packetId=MM-MQ94C3HX-VOZO1H",
    "S10_RELAY: RX_S10_FROM_A06 packetId=MM-MQ94C3HX-VOZO1H",
    "S10_RELAY: ACK_RELAY_S10_TO_A06 packetId=MM-MQ94C3HX-VOZO1H",
    "A06_SENDER: ACK_BACK_TO_A06 packetId=MM-MQ94C3HX-VOZO1H",
    "RESULT: 2-HOP BLE PROOF PASSED",
  ],
};
