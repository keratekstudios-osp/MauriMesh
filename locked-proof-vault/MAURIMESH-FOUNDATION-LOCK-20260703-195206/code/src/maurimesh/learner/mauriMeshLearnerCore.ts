import { learnFromBadDecision } from "./badDecisionLearner";
import { scorePacketEvidence } from "./decisionScoring";
import { rememberEvidenceBlock } from "./evidenceMemory";
import { planRecoveryFromLog } from "./recoveryPlanner";
import { buildTrustLedger } from "./trustLedger";

export function runMauriMeshLearnerCore(logText: string, packetId?: string) {
  const evidence = rememberEvidenceBlock(logText);
  const detectedPacket =
    packetId ||
    evidence.find((e) => e.packetId && e.packetId !== "NO_PACKET_ID")?.packetId ||
    "NO_PACKET_ID";

  const decision = scorePacketEvidence(detectedPacket, evidence);
  const recoveryFromDecision = learnFromBadDecision(decision);
  const recoveryFromLog = planRecoveryFromLog(logText);
  const trustLedger = buildTrustLedger(evidence);

  return {
    generatedAt: new Date().toISOString(),
    packetId: detectedPacket,
    evidenceCount: evidence.length,
    evidence,
    decision,
    recovery: recoveryFromDecision || recoveryFromLog,
    trustLedger,
    truth:
      "Learner Core classifies evidence and recommends recovery. It does not claim native BLE/GATT PASS without native transport packet evidence.",
  };
}
