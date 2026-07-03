import { createProtocolDecision, MAORI_PROTOCOL_TERMS } from "./MaoriProtocolRegistry";
import { MaoriProtocolDecision } from "./MaoriProtocolTypes";

export function evaluateMaoriProtocolForScreen(screen: string): MaoriProtocolDecision {
  const normalized = screen.toLowerCase();

  if (normalized.includes("jumpcode")) {
    return createProtocolDecision({
      screen,
      termIds: [
        "tikanga",
        "whakapapa-ara",
        "whanaungatanga",
        "kaitiakitanga",
        "kaore-ano",
        "apk-proof",
      ],
      action: "APK_PROOF_REQUIRED",
      risk: "HIGH",
      source: "BACKUP_PROTOCOL_REGISTRY",
    });
  }

  if (normalized.includes("test")) {
    return createProtocolDecision({
      screen,
      termIds: [
        "tikanga",
        "mauri",
        "arotake",
        "kaore-ano",
        "apk-proof",
      ],
      action: "APK_PROOF_REQUIRED",
      risk: "HIGH",
      source: "BACKUP_PROTOCOL_REGISTRY",
    });
  }

  if (normalized.includes("proof") || normalized.includes("device")) {
    return createProtocolDecision({
      screen,
      termIds: [
        "mana",
        "mauri",
        "whakapapa-ara",
        "arotake",
        "kaore-ano",
        "apk-proof",
      ],
      action: "APK_PROOF_REQUIRED",
      risk: "HIGH",
      source: "BACKUP_PROTOCOL_REGISTRY",
    });
  }

  if (normalized.includes("message") || normalized.includes("ack")) {
    return createProtocolDecision({
      screen,
      termIds: [
        "tikanga",
        "whakapapa-ara",
        "whanaungatanga",
        "kaitiakitanga",
        "kaore-ano",
      ],
      action: "MULTI_DEVICE_PROOF_REQUIRED",
      risk: "HIGH",
      source: "BACKUP_PROTOCOL_REGISTRY",
    });
  }

  if (normalized.includes("tikanga") || normalized.includes("governance")) {
    return createProtocolDecision({
      screen,
      termIds: [
        "tikanga",
        "tapu",
        "noa",
        "mana",
        "rangatiratanga",
        "kaitiakitanga",
        "arotake",
      ],
      action: "APPROVED_WITH_WARNING",
      risk: "PROTECTED",
      source: "PRIMARY_TIKANGA_ENGINE",
    });
  }

  return createProtocolDecision({
    screen,
    termIds: [
      "tikanga",
      "mauri",
      "mana",
      "kaitiakitanga",
      "kaore-ano",
    ],
    action: "APPROVED_WITH_WARNING",
    risk: "MEDIUM",
    source: "SAFE_FALLBACK_PROTOCOL",
  });
}

export function getMaoriProtocolBackupSummary() {
  return {
    totalTerms: MAORI_PROTOCOL_TERMS.length,
    primaryTerms: MAORI_PROTOCOL_TERMS.filter((term) => term.source === "PRIMARY_TIKANGA_ENGINE").length,
    backupTerms: MAORI_PROTOCOL_TERMS.filter((term) => term.source === "BACKUP_PROTOCOL_REGISTRY").length,
    fallbackTerms: MAORI_PROTOCOL_TERMS.filter((term) => term.source === "SAFE_FALLBACK_PROTOCOL").length,
    proofLabels: MAORI_PROTOCOL_TERMS.map((term) => term.proofLabel),
    status: "MAORI_PROTOCOL_FALLBACK_READY",
    truth:
      "Primary Tikanga terms, backup protocol terms, and safe fallback terms are available for APK proof UI.",
  };
}
