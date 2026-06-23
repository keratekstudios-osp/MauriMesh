import { SelfHealingDecision } from "./types";

export function evaluateSelfHealing(input?: {
  missingRoutes?: number;
  failedProofs?: number;
  staleSignals?: number;
  typeScriptPassed?: boolean;
}): SelfHealingDecision {
  const missingRoutes = input?.missingRoutes ?? 0;
  const failedProofs = input?.failedProofs ?? 0;
  const staleSignals = input?.staleSignals ?? 1;
  const typeScriptPassed = input?.typeScriptPassed ?? true;

  const penalty =
    missingRoutes * 12 +
    failedProofs * 18 +
    staleSignals * 6 +
    (typeScriptPassed ? 0 : 30);

  const healthScore = Math.max(0, Math.min(100, 100 - penalty));

  const detectedFaults: string[] = [];
  const repairActions: string[] = [];

  if (missingRoutes > 0) {
    detectedFaults.push("Missing or unwired route detected.");
    repairActions.push("Use backup route registry and SafeNavButton fallback.");
  }

  if (failedProofs > 0) {
    detectedFaults.push("Proof confidence gap detected.");
    repairActions.push("Capture packet hash, ACK, route, timestamp, and logcat evidence.");
  }

  if (staleSignals > 0) {
    detectedFaults.push("Stale mesh signal detected.");
    repairActions.push("Refresh mesh status and re-score route candidates.");
  }

  if (!typeScriptPassed) {
    detectedFaults.push("TypeScript failed.");
    repairActions.push("Block release until TypeScript passes.");
  }

  if (detectedFaults.length === 0) {
    repairActions.push("Maintain current state. Continue monitoring.");
  }

  return {
    healthScore,
    detectedFaults,
    repairActions,
    homeostasis:
      healthScore >= 90
        ? "stable"
        : healthScore >= 70
          ? "watching"
          : healthScore >= 45
            ? "repairing"
            : "critical",
  };
}
