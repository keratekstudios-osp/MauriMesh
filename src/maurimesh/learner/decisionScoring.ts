import { LearnerEvidence, RouteDecision } from "./types";

const required3Device = [
  "TX_A06_TO_S10",
  "RX_S10_FROM_A06",
  "RELAY_S10_TO_A16",
  "RX_A16_FROM_S10",
  "ACK_A16_TO_S10",
  "ACK_RELAY_S10_TO_A06",
  "ACK_RECEIVED_A06",
  "EXAM_APPROVED",
];

export function scorePacketEvidence(packetId: string, evidence: LearnerEvidence[]): RouteDecision {
  const packet = evidence.filter((e) => e.packetId === packetId);
  const joined = packet.map((e) => e.rawLine).join("\n");

  const stageHits = required3Device.filter((stage) => joined.includes(stage)).length;
  const nativeHits = packet.filter((e) => e.proofClass === "NATIVE_BLE_GATT_PACKET_BOUND").length;
  const bridgeHits = packet.filter((e) => e.proofClass === "BRIDGE_LOG_ONLY").length;
  const workflowHits = packet.filter(
    (e) => e.proofClass === "APK_WORKFLOW_PROOF" || e.proofClass === "REACTNATIVEJS_MONITOR_PROOF"
  ).length;

  let score = stageHits * 8 + nativeHits * 15 + workflowHits * 4 + bridgeHits * 2;
  score = Math.min(100, score);

  const verdict =
    nativeHits > 0 && stageHits >= 7
      ? "PASS_CANDIDATE"
      : stageHits >= 7
        ? "ATTEMPT_LOCKED"
        : "INCONCLUSIVE";

  const reason =
    nativeHits > 0
      ? "Packet has native BLE/GATT-marked evidence. Verify path continuity before lock."
      : stageHits >= 7
        ? "Packet has full workflow path but native BLE/GATT transport remains unconfirmed."
        : "Packet evidence is incomplete.";

  return {
    id: `decision-${packetId}-${Date.now()}`,
    timestamp: new Date().toISOString(),
    packetId,
    route: ["A06_PHONE_A", "S10_PHONE_B", "A16_PHONE_C", "S10_PHONE_B", "A06_PHONE_A"],
    decision: "CLASSIFY_PACKET_PROOF",
    score,
    reason,
    verdict,
  };
}
