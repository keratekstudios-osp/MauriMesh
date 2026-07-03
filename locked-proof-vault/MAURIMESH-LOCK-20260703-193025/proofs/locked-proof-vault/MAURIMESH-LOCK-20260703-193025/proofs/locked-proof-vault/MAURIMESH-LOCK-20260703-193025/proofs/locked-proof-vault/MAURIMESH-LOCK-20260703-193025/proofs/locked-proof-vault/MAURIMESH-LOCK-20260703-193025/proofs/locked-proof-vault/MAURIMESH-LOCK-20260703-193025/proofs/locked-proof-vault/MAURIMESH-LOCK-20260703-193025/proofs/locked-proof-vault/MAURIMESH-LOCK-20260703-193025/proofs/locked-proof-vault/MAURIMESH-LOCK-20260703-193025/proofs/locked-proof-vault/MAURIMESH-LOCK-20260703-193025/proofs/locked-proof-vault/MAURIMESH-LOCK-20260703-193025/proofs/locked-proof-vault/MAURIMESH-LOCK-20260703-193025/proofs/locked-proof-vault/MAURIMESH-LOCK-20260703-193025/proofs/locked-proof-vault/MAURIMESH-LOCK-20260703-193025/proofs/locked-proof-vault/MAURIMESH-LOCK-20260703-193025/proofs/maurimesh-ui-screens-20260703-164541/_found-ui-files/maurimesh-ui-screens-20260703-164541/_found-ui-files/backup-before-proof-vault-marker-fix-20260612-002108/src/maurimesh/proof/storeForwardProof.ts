export type StoreForwardStage = {
  id: string;
  role: "PHONE_A" | "PHONE_B" | "PHONE_C";
  title: string;
  description: string;
};

export const STORE_FORWARD_PROOF = {
  title: "MauriMesh Store-Forward Delay Proof",
  status: "READY_AFTER_3_DEVICE_HOP",
  packetPrefix: "MMSF",
  devices: {
    phoneA: "A06 / PHONE_A / Sender",
    phoneB: "S10 / PHONE_B / Store-Forward Relay",
    phoneC: "A16 / PHONE_C / Delayed Receiver + ACK source",
  },
  path: "A06 TX -> S10 STORE -> A16 OFFLINE -> A16 RETURNS -> S10 FORWARD -> A16 RX -> A16 ACK -> S10 ACK RELAY -> A06 ACK",
  passRule:
    "PASS is valid only when the same packetId appears across store, hold, rediscovery, forward, receiver RX, ACK, relay ACK, and final A06 ACK logs/screenshots.",
  truth:
    "This screen controls proof order and operator timing. It does not fake BLE. Real store-forward proof requires matching APK/device logs and screenshots.",
};

export const STORE_FORWARD_STAGES: StoreForwardStage[] = [
  {
    id: "PACKET_ID_CONFIRMED",
    role: "PHONE_A",
    title: "Confirm Store-Forward Packet ID",
    description: "PHONE_A locks the proof packet identity.",
  },
  {
    id: "TX_A06_TO_S10_STORE_REQUEST",
    role: "PHONE_A",
    title: "A06 TX -> S10 Store Request",
    description: "A06 sends packet to S10 while A16 is unavailable.",
  },
  {
    id: "S10_STORE_PACKET",
    role: "PHONE_B",
    title: "S10 Stores Packet",
    description: "S10 stores the packet instead of dropping it.",
  },
  {
    id: "A16_OFFLINE_CONFIRMED",
    role: "PHONE_C",
    title: "A16 Offline / Unavailable Confirmed",
    description: "A16 is temporarily unavailable during hold period.",
  },
  {
    id: "S10_HOLD_DELAY",
    role: "PHONE_B",
    title: "S10 Hold Delay",
    description: "S10 keeps the packet during delay window.",
  },
  {
    id: "A16_RETURNS",
    role: "PHONE_C",
    title: "A16 Returns / Rediscovered",
    description: "A16 comes back and can receive the stored packet.",
  },
  {
    id: "S10_FORWARD_STORED_TO_A16",
    role: "PHONE_B",
    title: "S10 Forwards Stored Packet -> A16",
    description: "S10 forwards the stored packet after rediscovery.",
  },
  {
    id: "RX_A16_STORED_PACKET",
    role: "PHONE_C",
    title: "A16 Receives Stored Packet",
    description: "A16 receives packet after delay.",
  },
  {
    id: "ACK_A16_TO_S10_STORED",
    role: "PHONE_C",
    title: "A16 ACK -> S10",
    description: "A16 sends ACK for delayed packet.",
  },
  {
    id: "ACK_RELAY_S10_TO_A06_STORED",
    role: "PHONE_B",
    title: "S10 ACK Relay -> A06",
    description: "S10 relays delayed ACK back to A06.",
  },
  {
    id: "ACK_RECEIVED_A06_STORED",
    role: "PHONE_A",
    title: "A06 ACK Received",
    description: "A06 confirms delayed store-forward ACK returned.",
  },
];
