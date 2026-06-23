import { generateIntelligenceReport } from "./IntelligenceOrchestrator";
import {
  DeviceReadinessDecision,
  GovernanceDecision,
  IntelligenceReport,
  IntelligenceSignal,
  ProofDecision,
  RouteCandidate,
  RouteDecision,
  SelfHealingDecision,
} from "./types";

export type BackupIntelligenceState = {
  primaryAvailable: boolean;
  backupActivated: boolean;
  failoverReason: string;
  report: IntelligenceReport;
  protection: BackupProtectionSummary;
};

export type BackupProtectionSummary = {
  protectedEngines: string[];
  fallbackRules: string[];
  emergencyDefaults: string[];
  finalTruth: string;
};

function safeSignal(
  id: string,
  name: string,
  score: number,
  detail: string
): IntelligenceSignal {
  return {
    id,
    name,
    score,
    status:
      score >= 90
        ? "excellent"
        : score >= 75
          ? "good"
          : score >= 50
            ? "warning"
            : "critical",
    detail,
  };
}

function fallbackRoute(): RouteDecision {
  const selected: RouteCandidate = {
    id: "backup_route_dashboard",
    name: "Backup Safe Route → Dashboard",
    transport: "HYBRID",
    latencyMs: 50,
    trust: 80,
    energyCost: 20,
    deliveryConfidence: 82,
    available: true,
  };

  return {
    selected,
    candidates: [selected],
    reason:
      "Backup route selected because primary route intelligence was unavailable or failed.",
    score: 82,
  };
}

function fallbackProof(): ProofDecision {
  return {
    packetId: "MM-BACKUP-PROOF-UI-001",
    hashPresent: true,
    ackPresent: false,
    routePresent: true,
    timestampPresent: true,
    deviceLogPresent: false,
    confidence: 54,
    truth:
      "Backup proof state only. Real BLE proof still requires APK/device logcat evidence.",
  };
}

function fallbackGovernance(): GovernanceDecision {
  return {
    action: "approved_with_warning",
    culturalRisk: "medium",
    manaProtection: 88,
    auditNote:
      "Backup governance active. Allow UI display, require proof labels, block false live BLE claims.",
  };
}

function fallbackSelfHealing(): SelfHealingDecision {
  return {
    healthScore: 78,
    detectedFaults: ["Primary intelligence unavailable or uncertain."],
    repairActions: [
      "Use backup intelligence report.",
      "Keep UI operational.",
      "Route user to Operator Console or Device Proof if confidence drops.",
      "Do not claim real BLE until device proof exists.",
    ],
    homeostasis: "watching",
  };
}

function fallbackDeviceReadiness(): DeviceReadinessDecision {
  return {
    readinessScore: 60,
    requiredProof: [
      "Confirm APK build.",
      "Run two-phone test.",
      "Capture TX/RX/ACK logcat proof.",
    ],
    readyForReplit: true,
    readyForApk: true,
    readyForRealBleProof: false,
  };
}

export function generateBackupIntelligenceReport(reason = "Manual backup intelligence check"): IntelligenceReport {
  const route = fallbackRoute();
  const proof = fallbackProof();
  const governance = fallbackGovernance();
  const selfHealing = fallbackSelfHealing();
  const deviceReadiness = fallbackDeviceReadiness();

  const signals: IntelligenceSignal[] = [
    safeSignal(
      "backup_route",
      "Backup Routing Intelligence",
      route.score,
      route.reason
    ),
    safeSignal(
      "backup_proof",
      "Backup Proof Intelligence",
      proof.confidence,
      proof.truth
    ),
    safeSignal(
      "backup_governance",
      "Backup Tikanga Governance",
      governance.manaProtection,
      governance.auditNote
    ),
    safeSignal(
      "backup_self_healing",
      "Backup Self-Healing",
      selfHealing.healthScore,
      `Homeostasis: ${selfHealing.homeostasis}`
    ),
    safeSignal(
      "backup_device_readiness",
      "Backup Device Readiness",
      deviceReadiness.readinessScore,
      "Ready for Replit/APK UI checks. Real BLE proof still requires phones."
    ),
  ];

  const overallScore = Math.round(
    signals.reduce((sum, signal) => sum + signal.score, 0) / signals.length
  );

  return {
    mode: "SIMULATION",
    overallScore,
    signals,
    route,
    proof,
    governance,
    selfHealing,
    deviceReadiness,
    finalTruth:
      `Backup intelligence active: ${reason}. This protects decision flow and UI readiness. It does not prove real BLE without APK/device logcat evidence.`,
  };
}

export function generateProtectedIntelligenceReport(): BackupIntelligenceState {
  try {
    const primary = generateIntelligenceReport();

    return {
      primaryAvailable: true,
      backupActivated: false,
      failoverReason: "Primary intelligence completed successfully.",
      report: primary,
      protection: getBackupProtectionSummary(),
    };
  } catch (error) {
    return {
      primaryAvailable: false,
      backupActivated: true,
      failoverReason:
        error instanceof Error ? error.message : "Unknown primary intelligence failure.",
      report: generateBackupIntelligenceReport("Primary intelligence failed"),
      protection: getBackupProtectionSummary(),
    };
  }
}

export function forceBackupIntelligence(reason = "Forced backup intelligence mode"): BackupIntelligenceState {
  return {
    primaryAvailable: false,
    backupActivated: true,
    failoverReason: reason,
    report: generateBackupIntelligenceReport(reason),
    protection: getBackupProtectionSummary(),
  };
}

export function getBackupProtectionSummary(): BackupProtectionSummary {
  return {
    protectedEngines: [
      "RouteIntelligence",
      "ProofIntelligence",
      "TikangaIntelligence",
      "SelfHealingIntelligence",
      "DeviceReadinessIntelligence",
      "IntelligenceOrchestrator",
    ],
    fallbackRules: [
      "If primary report fails, activate backup report.",
      "If proof confidence is incomplete, show APK/device proof required.",
      "If route scoring fails, use safe dashboard/operator fallback.",
      "If governance confidence is uncertain, approve with warning and require proof labels.",
      "If device readiness is incomplete, block real BLE claim.",
    ],
    emergencyDefaults: [
      "Route fallback: /dashboard",
      "Proof fallback: UI proof only",
      "Governance fallback: approved_with_warning",
      "Self-healing fallback: watching",
      "Device fallback: APK/device proof required",
    ],
    finalTruth:
      "Backup intelligence protects UI and decision flow only. It is not a replacement for real native BLE proof.",
  };
}
