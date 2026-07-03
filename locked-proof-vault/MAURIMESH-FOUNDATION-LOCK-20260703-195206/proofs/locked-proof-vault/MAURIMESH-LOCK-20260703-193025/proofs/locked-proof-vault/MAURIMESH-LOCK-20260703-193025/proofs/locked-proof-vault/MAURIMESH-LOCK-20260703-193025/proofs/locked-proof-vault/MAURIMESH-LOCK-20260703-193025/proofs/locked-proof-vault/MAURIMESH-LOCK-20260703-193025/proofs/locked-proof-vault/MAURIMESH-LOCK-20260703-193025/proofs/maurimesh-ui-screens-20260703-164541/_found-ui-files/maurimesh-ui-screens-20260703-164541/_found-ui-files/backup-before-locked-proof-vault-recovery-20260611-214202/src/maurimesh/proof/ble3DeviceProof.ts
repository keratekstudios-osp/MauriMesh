export type ThreeDeviceProofStage = {
  id: string;
  title: string;
  device: "PHONE_A" | "PHONE_B" | "PHONE_C";
  label: string;
  expectedLog: string;
};

export const BLE_3_DEVICE_PROOF = {
  status: "PENDING_DEVICE_PROOF",
  title: "MauriMesh 3-Device Hop Proof",
  milestone: "3-device relay path validation",
  packetPrefix: "MM3",
  devices: {
    phoneA: {
      name: "Samsung Galaxy A06",
      role: "PHONE_A / Sender / Packet origin",
      connection: "Wi-Fi ADB / Same Wi-Fi as Mac",
    },
    phoneB: {
      name: "Samsung S10",
      role: "PHONE_B / Relay / Middle hop",
      connection: "Wi-Fi ADB / Same Wi-Fi as Mac",
    },
    phoneC: {
      name: "Samsung Galaxy A16",
      role: "PHONE_C / Receiver / ACK source",
      connection: "USB Debugging",
    },
  },
  forwardPath: "A06 TX -> S10 RX -> S10 RELAY -> A16 RX",
  ackPath: "A16 ACK -> S10 ACK RELAY -> A06 ACK RECEIVED",
  passRule:
    "PASS is valid only when the same packetId appears across A06 TX, S10 RX, S10 RELAY, A16 RX, A16 ACK, S10 ACK RELAY, and A06 ACK logs/screenshots.",
  truth:
    "This screen controls proof order and operator timing. It does not fake BLE. Real 3-device proof is only valid with matching APK/device logs and screenshots.",
};

export const BLE_3_DEVICE_STAGES: ThreeDeviceProofStage[] = [
  {
    id: "PACKET_ID_GENERATED",
    title: "Generate Packet ID",
    device: "PHONE_A",
    label: "A06 creates unique 3-device packet identity.",
    expectedLog: "PHONE_A | PACKET_ID_GENERATED | packetId=<same_packet_id>",
  },
  {
    id: "TX_A06_TO_S10",
    title: "A06 TX -> S10",
    device: "PHONE_A",
    label: "A06 transmits packet toward S10 relay.",
    expectedLog: "PHONE_A | TX_A06_TO_S10 | packetId=<same_packet_id>",
  },
  {
    id: "RX_S10_FROM_A06",
    title: "S10 RX from A06",
    device: "PHONE_B",
    label: "S10 receives packet from A06.",
    expectedLog: "PHONE_B | RX_S10_FROM_A06 | packetId=<same_packet_id>",
  },
  {
    id: "RELAY_S10_TO_A16",
    title: "S10 Relay -> A16",
    device: "PHONE_B",
    label: "S10 relays packet to A16 final receiver.",
    expectedLog: "PHONE_B | RELAY_S10_TO_A16 | packetId=<same_packet_id>",
  },
  {
    id: "RX_A16_FROM_S10",
    title: "A16 RX from S10",
    device: "PHONE_C",
    label: "A16 receives packet from S10 relay.",
    expectedLog: "PHONE_C | RX_A16_FROM_S10 | packetId=<same_packet_id>",
  },
  {
    id: "ACK_A16_TO_S10",
    title: "A16 ACK -> S10",
    device: "PHONE_C",
    label: "A16 sends ACK back to S10.",
    expectedLog: "PHONE_C | ACK_A16_TO_S10 | packetId=<same_packet_id>",
  },
  {
    id: "ACK_RELAY_S10_TO_A06",
    title: "S10 ACK Relay -> A06",
    device: "PHONE_B",
    label: "S10 relays ACK back to A06.",
    expectedLog: "PHONE_B | ACK_RELAY_S10_TO_A06 | packetId=<same_packet_id>",
  },
  {
    id: "ACK_RECEIVED_A06",
    title: "A06 ACK Received",
    device: "PHONE_A",
    label: "A06 confirms ACK returned through full 3-device path.",
    expectedLog: "PHONE_A | ACK_RECEIVED_A06 | packetId=<same_packet_id>",
  },
];

export const NEXT_PROOF_EXAM = {
  title: "Next Exam: Store-Forward Delay Proof",
  status: "READY_AFTER_3_DEVICE_PASS",
  goal:
    "After 3-device proof passes, test whether PHONE_B can hold a packet when PHONE_C is unavailable, then forward when PHONE_C returns.",
  path: "A06 TX -> S10 STORE -> A16 RETURNS -> S10 FORWARD -> A16 RX -> ACK BACK",
  passRule:
    "PASS only when packetId is stored, held, forwarded after rediscovery, received by A16, and ACK returns to A06.",
};
