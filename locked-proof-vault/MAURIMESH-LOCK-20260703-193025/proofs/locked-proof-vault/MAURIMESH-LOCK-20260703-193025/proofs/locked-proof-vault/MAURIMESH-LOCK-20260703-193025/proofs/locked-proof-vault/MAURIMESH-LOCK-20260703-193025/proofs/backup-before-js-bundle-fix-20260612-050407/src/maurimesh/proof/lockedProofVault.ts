export type LockedProofStatus = "PASSED" | "PENDING" | "FAILED";

export type LockedProofStage = {
  order: number;
  role: string;
  device: string;
  stage: string;
  summary: string;
};

export type LockedProofRecord = {
  proofId: string;
  title: string;
  status: LockedProofStatus;
  packetId: string;
  route: string;
  proofClass: string;
  evidenceStatus: string;
  truthRule: string;
  stages: LockedProofStage[];
};

export const LOCKED_PROOF_VAULT: LockedProofRecord[] = [
  {
    proofId: "MM-PROOF-002-2HOP",
    title: "MauriMesh 2-Hop Device Proof",
    status: "PASSED",
    packetId: "MM-MQ94C3HX-VOZO1H",
    route: "PHONE_A/A06 -> PHONE_B/S10 relay -> ACK_BACK_TO_PHONE_A",
    proofClass: "Physical APK/device proof",
    evidenceStatus: "LOCKED",
    truthRule:
      "PASS only if the same packetId appears across sender, relay, and ACK return evidence.",
    stages: [
      {
        order: 1,
        role: "PHONE_A",
        device: "A06",
        stage: "TX_TO_RELAY",
        summary: "A06 sender proof packet created and sent toward S10 relay.",
      },
      {
        order: 2,
        role: "PHONE_B",
        device: "S10",
        stage: "RELAY_ACK_BACK",
        summary: "S10 relay returned ACK path back to PHONE_A.",
      },
    ],
  },
  {
    proofId: "MM-PROOF-003-3DEVICE-HOP",
    title: "MauriMesh 3-Device Hop Relay Proof",
    status: "PASSED",
    packetId: "MM3-JSY73G-JKDXYR",
    route: "A06 -> S10 -> A16 -> S10 -> A06 ACK",
    proofClass: "Physical APK/logcat 3-device relay proof",
    evidenceStatus: "LOCKED",
    truthRule:
      "PASS only if the same packetId appears across PHONE_A, PHONE_B, PHONE_C, and final ACK back to PHONE_A.",
    stages: [
      {
        order: 1,
        role: "PHONE_A",
        device: "A06",
        stage: "PACKET_ID_GENERATED",
        summary: "A06 generated and confirmed the 3-device proof packet.",
      },
      {
        order: 2,
        role: "PHONE_A",
        device: "A06",
        stage: "TX_A06_TO_S10",
        summary: "A06 transmitted packet to S10 relay.",
      },
      {
        order: 3,
        role: "PHONE_B",
        device: "S10",
        stage: "RX_S10_FROM_A06",
        summary: "S10 received packet from A06.",
      },
      {
        order: 4,
        role: "PHONE_B",
        device: "S10",
        stage: "RELAY_S10_TO_A16",
        summary: "S10 relayed packet to A16.",
      },
      {
        order: 5,
        role: "PHONE_C",
        device: "A16",
        stage: "RX_A16_FROM_S10",
        summary: "A16 received packet from S10.",
      },
      {
        order: 6,
        role: "PHONE_C",
        device: "A16",
        stage: "ACK_A16_TO_S10",
        summary: "A16 returned ACK to S10.",
      },
      {
        order: 7,
        role: "PHONE_B",
        device: "S10",
        stage: "ACK_RELAY_S10_TO_A06",
        summary: "S10 relayed ACK back to A06.",
      },
      {
        order: 8,
        role: "PHONE_A",
        device: "A06",
        stage: "ACK_RECEIVED_A06",
        summary: "A06 received final ACK through full path.",
      },
    ],
  },
  {
    proofId: "MM-PROOF-004-STORE-FORWARD",
    title: "MauriMesh Store-Forward Delay Proof",
    status: "PASSED",
    packetId: "MMSF-KVM5AQ-ZK423E",
    route:
      "A06 -> S10 STORE -> A16 OFFLINE -> A16 RETURNS -> S10 FORWARD -> A16 ACK -> S10 -> A06 ACK",
    proofClass: "Physical APK/logcat store-forward delay proof",
    evidenceStatus: "LOCKED",
    truthRule:
      "PASS only if the same packetId appears across store, hold, rediscovery, forward, receiver RX, ACK relay, and final A06 ACK.",
    stages: [
      {
        order: 1,
        role: "PHONE_A",
        device: "A06",
        stage: "PACKET_ID_CONFIRMED",
        summary: "A06 confirmed store-forward packet.",
      },
      {
        order: 2,
        role: "PHONE_A",
        device: "A06",
        stage: "TX_A06_TO_S10_STORE_REQUEST",
        summary: "A06 sent store request to S10.",
      },
      {
        order: 3,
        role: "PHONE_B",
        device: "S10",
        stage: "S10_STORE_PACKET",
        summary: "S10 stored packet for delayed delivery.",
      },
      {
        order: 4,
        role: "PHONE_C",
        device: "A16",
        stage: "A16_OFFLINE_CONFIRMED",
        summary: "A16 unavailable/offline state confirmed.",
      },
      {
        order: 5,
        role: "PHONE_B",
        device: "S10",
        stage: "S10_HOLD_DELAY",
        summary: "S10 held packet while receiver was unavailable.",
      },
      {
        order: 6,
        role: "PHONE_C",
        device: "A16",
        stage: "A16_RETURNS",
        summary: "A16 returned/reappeared.",
      },
      {
        order: 7,
        role: "PHONE_B",
        device: "S10",
        stage: "S10_FORWARD_STORED_TO_A16",
        summary: "S10 forwarded stored packet to A16.",
      },
      {
        order: 8,
        role: "PHONE_C",
        device: "A16",
        stage: "RX_A16_STORED_PACKET",
        summary: "A16 received stored packet.",
      },
      {
        order: 9,
        role: "PHONE_C",
        device: "A16",
        stage: "ACK_A16_TO_S10_STORED",
        summary: "A16 ACK returned to S10.",
      },
      {
        order: 10,
        role: "PHONE_B",
        device: "S10",
        stage: "ACK_RELAY_S10_TO_A06_STORED",
        summary: "S10 relayed stored ACK back to A06.",
      },
      {
        order: 11,
        role: "PHONE_A",
        device: "A06",
        stage: "ACK_RECEIVED_A06_STORED",
        summary: "A06 received final stored ACK.",
      },
    ],
  },
];

export function getLockedProofVaultReport(): string {
  return LOCKED_PROOF_VAULT.map((proof) => {
    const stageLines = proof.stages
      .map(
        (stage) =>
          `${stage.order}. ${stage.role} / ${stage.device} | ${stage.stage} | ${stage.summary}`,
      )
      .join("\n");

    return [
      proof.title,
      `Proof ID: ${proof.proofId}`,
      `Status: ${proof.status}`,
      `Packet ID: ${proof.packetId}`,
      `Route: ${proof.route}`,
      `Class: ${proof.proofClass}`,
      `Evidence: ${proof.evidenceStatus}`,
      `Truth rule: ${proof.truthRule}`,
      "",
      stageLines,
    ].join("\n");
  }).join("\n\n---\n\n");
}
