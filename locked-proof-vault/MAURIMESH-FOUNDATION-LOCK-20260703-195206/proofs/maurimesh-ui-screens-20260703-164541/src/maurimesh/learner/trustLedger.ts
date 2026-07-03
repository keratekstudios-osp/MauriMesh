import { DeviceTrust, LearnerEvidence } from "./types";

export function buildTrustLedger(evidence: LearnerEvidence[]): DeviceTrust[] {
  const roles = Array.from(new Set(evidence.map((e) => e.role))).filter(Boolean);

  return roles.map((role) => {
    const rows = evidence.filter((e) => e.role === role);
    const successCount = rows.filter((e) =>
      /ACK|EXAM_APPROVED|RX_|TX_|RELAY|PASS|CONNECTED/i.test(e.rawLine)
    ).length;
    const failCount = rows.filter((e) =>
      /ERROR|FAIL|offline|unauthorized|Host is down|NO_PACKET|INCONCLUSIVE/i.test(e.rawLine)
    ).length;

    const trustScore = Math.max(0, Math.min(100, 50 + successCount * 5 - failCount * 8));

    return {
      role,
      successCount,
      failCount,
      lastSeen: rows.at(-1)?.timestamp,
      trustScore,
      notes: [
        trustScore >= 80 ? "High trust for current evidence set." : "Needs more proof cycles.",
        failCount > 0 ? "Has observed failure signals." : "No failure signals in current memory.",
      ],
    };
  });
}
