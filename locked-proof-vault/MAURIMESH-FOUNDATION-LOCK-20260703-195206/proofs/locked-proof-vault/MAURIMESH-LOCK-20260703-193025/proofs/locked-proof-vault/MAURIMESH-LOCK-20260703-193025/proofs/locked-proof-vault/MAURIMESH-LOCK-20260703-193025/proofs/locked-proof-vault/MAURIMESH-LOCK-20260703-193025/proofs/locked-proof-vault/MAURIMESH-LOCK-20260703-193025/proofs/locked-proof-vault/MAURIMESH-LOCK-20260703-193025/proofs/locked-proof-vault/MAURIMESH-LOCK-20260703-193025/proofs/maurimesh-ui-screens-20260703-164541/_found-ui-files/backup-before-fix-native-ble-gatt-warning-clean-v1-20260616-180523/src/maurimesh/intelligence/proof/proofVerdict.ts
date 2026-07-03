import { MauriMeshProofSignal, MauriMeshProofVerdict } from "../types";

export const REQUIRED_3_DEVICE_EVENTS = [
  "PACKET_ID_CONFIRMED",
  "TX_A06_TO_S10",
  "RX_S10_FROM_A06",
  "RELAY_S10_TO_A16",
  "RX_A16_FROM_S10",
  "ACK_A16_TO_S10",
  "ACK_RELAY_S10_TO_A06",
  "ACK_RECEIVED_A06",
  "EXAM_APPROVED",
];

export const REQUIRED_STORE_FORWARD_EVENTS = [
  "PACKET_ID_CONFIRMED",
  "TX_A06_TO_S10_STORE_REQUEST",
  "S10_STORE_PACKET",
  "A16_OFFLINE_CONFIRMED",
  "S10_HOLD_DELAY",
  "A16_RETURNS",
  "S10_FORWARD_STORED_TO_A16",
  "RX_A16_STORED_PACKET",
  "ACK_A16_TO_S10_STORED",
  "ACK_RELAY_S10_TO_A06_STORED",
  "ACK_RECEIVED_A06_STORED",
  "EXAM_APPROVED",
];

export function mauriMeshProofVerdict(input: {
  packetId: string;
  signals: MauriMeshProofSignal[];
  requiredEvents: string[];
}): MauriMeshProofVerdict {
  const samePacketSignals = input.signals.filter((signal) => signal.packetId === input.packetId);
  const foundEvents = Array.from(new Set(samePacketSignals.map((signal) => signal.event)));
  const missingEvents = input.requiredEvents.filter((event) => !foundEvents.includes(event));

  const nativeBleGattPacketBoundPass =
    missingEvents.length === 0 &&
    samePacketSignals.some(
      (signal) =>
        signal.transport === "BLE_GATT" &&
        (signal.source === "ANDROID_NATIVE" || signal.source === "LOGCAT")
    );

  if (nativeBleGattPacketBoundPass) {
    return {
      packetId: input.packetId,
      truthClass: "NATIVE_BLE_GATT_PACKET_BOUND",
      decision: "APPROVED",
      requiredEvents: input.requiredEvents,
      foundEvents,
      missingEvents,
      nativeBleGattPacketBoundPass: false,
      reason: "Same packetId found across required path with native BLE/GATT evidence.",
    };
  }

  if (missingEvents.length === 0) {
    return {
      packetId: input.packetId,
      truthClass: "APK_PROOF_SCREEN_WORKFLOW",
      decision: "APPROVED_WITH_WARNING",
      requiredEvents: input.requiredEvents,
      foundEvents,
      missingEvents,
      nativeBleGattPacketBoundPass: false,
      reason: "Required APK proof workflow path complete, but native BLE/GATT packet-bound evidence is missing.",
    };
  }

  return {
    packetId: input.packetId,
    truthClass: "INCONCLUSIVE",
    decision: "REVIEW_REQUIRED",
    requiredEvents: input.requiredEvents,
    foundEvents,
    missingEvents,
    nativeBleGattPacketBoundPass: false,
    reason: "Required packet path is incomplete.",
  };
}
