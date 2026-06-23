import {
  MaoriProtocolAction,
  MaoriProtocolDecision,
  MaoriProtocolRisk,
  MaoriProtocolSource,
  MaoriProtocolTerm,
} from "./MaoriProtocolTypes";

export const MAORI_PROTOCOL_TERMS: MaoriProtocolTerm[] = [
  {
    id: "tikanga",
    reo: "Tikanga",
    english: "Correct protocol / governance",
    engineeringMeaning:
      "Rules that decide whether a route, packet, proof claim, or UI action is safe and honest.",
    risk: "HIGH",
    action: "APPROVED_WITH_WARNING",
    source: "PRIMARY_TIKANGA_ENGINE",
    proofLabel: "TIKANGA_GOVERNANCE_VISIBLE",
  },
  {
    id: "tapu",
    reo: "Tapu",
    english: "Protected / restricted state",
    engineeringMeaning:
      "Protected packet, identity, route, or data state requiring stronger proof and careful handling.",
    risk: "PROTECTED",
    action: "REVIEW_REQUIRED",
    source: "PRIMARY_TIKANGA_ENGINE",
    proofLabel: "TAPU_PROTECTED_STATE_VISIBLE",
  },
  {
    id: "noa",
    reo: "Noa",
    english: "Open / safe state",
    engineeringMeaning:
      "Low-risk state where route display or message handling is allowed with standard proof labels.",
    risk: "LOW",
    action: "APPROVED",
    source: "PRIMARY_TIKANGA_ENGINE",
    proofLabel: "NOA_SAFE_STATE_VISIBLE",
  },
  {
    id: "mana",
    reo: "Mana",
    english: "Authority, dignity, integrity",
    engineeringMeaning:
      "Protects user control, identity dignity, trust score, and non-false public claims.",
    risk: "HIGH",
    action: "APPROVED_WITH_WARNING",
    source: "PRIMARY_TIKANGA_ENGINE",
    proofLabel: "MANA_INTEGRITY_VISIBLE",
  },
  {
    id: "mauri",
    reo: "Mauri",
    english: "Living integrity / life force",
    engineeringMeaning:
      "System health, packet integrity, device readiness, and living mesh state.",
    risk: "MEDIUM",
    action: "APPROVED_WITH_WARNING",
    source: "PRIMARY_TIKANGA_ENGINE",
    proofLabel: "MAURI_SYSTEM_INTEGRITY_VISIBLE",
  },
  {
    id: "whakapapa-ara",
    reo: "Whakapapa Ara",
    english: "Route lineage",
    engineeringMeaning:
      "The route history of a packet: sender, relay, receiver, ACK, proof hash, and audit trail.",
    risk: "HIGH",
    action: "APK_PROOF_REQUIRED",
    source: "BACKUP_PROTOCOL_REGISTRY",
    proofLabel: "WHAKAPAPA_ARA_ROUTE_LINEAGE_VISIBLE",
  },
  {
    id: "kaitiakitanga",
    reo: "Kaitiakitanga",
    english: "Protective stewardship",
    engineeringMeaning:
      "Protects battery, privacy, cultural safety, device limits, and honest proof boundaries.",
    risk: "HIGH",
    action: "APPROVED_WITH_WARNING",
    source: "BACKUP_PROTOCOL_REGISTRY",
    proofLabel: "KAITIAKITANGA_PROTECTION_VISIBLE",
  },
  {
    id: "rangatiratanga",
    reo: "Rangatiratanga",
    english: "Self-determination / user control",
    engineeringMeaning:
      "User control over identity, routing, privacy, permissions, and proof sharing.",
    risk: "HIGH",
    action: "APPROVED_WITH_WARNING",
    source: "BACKUP_PROTOCOL_REGISTRY",
    proofLabel: "RANGATIRATANGA_USER_CONTROL_VISIBLE",
  },
  {
    id: "whanaungatanga",
    reo: "Whanaungatanga",
    english: "Trusted relationship path",
    engineeringMeaning:
      "Trust relationship between peers, relay memory, route confidence, and ACK learning.",
    risk: "MEDIUM",
    action: "APPROVED_WITH_WARNING",
    source: "BACKUP_PROTOCOL_REGISTRY",
    proofLabel: "WHANAUNGATANGA_TRUST_PATH_VISIBLE",
  },
  {
    id: "arotake",
    reo: "Arotake",
    english: "Review required",
    engineeringMeaning:
      "Human or operator review is required before claiming proof, delivery, identity, or cultural authority.",
    risk: "PROTECTED",
    action: "REVIEW_REQUIRED",
    source: "SAFE_FALLBACK_PROTOCOL",
    proofLabel: "AROTAKE_REVIEW_REQUIRED_VISIBLE",
  },
  {
    id: "whakaaetia",
    reo: "Whakaaetia",
    english: "Approved",
    engineeringMeaning:
      "Action is allowed when proof and safety requirements are satisfied.",
    risk: "LOW",
    action: "APPROVED",
    source: "SAFE_FALLBACK_PROTOCOL",
    proofLabel: "WHAKAAETIA_APPROVED_VISIBLE",
  },
  {
    id: "whakatupato",
    reo: "Whakatūpato",
    english: "Warning",
    engineeringMeaning:
      "Allow display or testing, but warn that device/APK/BLE proof is incomplete.",
    risk: "MEDIUM",
    action: "APPROVED_WITH_WARNING",
    source: "SAFE_FALLBACK_PROTOCOL",
    proofLabel: "WHAKATUPATO_WARNING_VISIBLE",
  },
  {
    id: "kaore-ano",
    reo: "Kāore anō kia whakamātau",
    english: "Not yet proven",
    engineeringMeaning:
      "No real device proof exists yet. Do not claim live BLE, ACK, relay, or raw 32K proof.",
    risk: "HIGH",
    action: "APK_PROOF_REQUIRED",
    source: "SAFE_FALLBACK_PROTOCOL",
    proofLabel: "KAORE_ANO_KIA_WHAKAMATAU_NOT_PROVEN_VISIBLE",
  },
  {
    id: "apk-proof",
    reo: "Me whakamātau ki te APK",
    english: "APK proof required",
    engineeringMeaning:
      "Requires installed APK, physical device, permissions, and logcat evidence.",
    risk: "HIGH",
    action: "APK_PROOF_REQUIRED",
    source: "SAFE_FALLBACK_PROTOCOL",
    proofLabel: "ME_WHAKAMATAU_KI_TE_APK_VISIBLE",
  },
];

export function getProtocolTerm(id: string): MaoriProtocolTerm {
  const found = MAORI_PROTOCOL_TERMS.find((term) => term.id === id);
  if (found) return found;

  return {
    id: "fallback",
    reo: "Kawa Pūrua",
    english: "Backup protocol",
    engineeringMeaning:
      "The requested protocol term was not available, so MauriMesh used a safe fallback label.",
    risk: "MEDIUM",
    action: "UNAVAILABLE_FALLBACK",
    source: "SAFE_FALLBACK_PROTOCOL",
    proofLabel: "KAWA_PURUA_BACKUP_PROTOCOL_VISIBLE",
  };
}

export function createProtocolDecision(input: {
  screen: string;
  termIds?: string[];
  action?: MaoriProtocolAction;
  risk?: MaoriProtocolRisk;
  source?: MaoriProtocolSource;
}): MaoriProtocolDecision {
  const terms = (input.termIds && input.termIds.length > 0
    ? input.termIds
    : ["tikanga", "mauri", "mana", "kaore-ano", "apk-proof"]
  ).map(getProtocolTerm);

  const highestRisk = input.risk || pickHighestRisk(terms.map((term) => term.risk));
  const action = input.action || pickStrongestAction(terms.map((term) => term.action));
  const source = input.source || pickBestSource(terms.map((term) => term.source));

  const warnings: string[] = [];

  if (action === "APK_PROOF_REQUIRED") {
    warnings.push(
      "Me whakamātau ki te APK — installed APK and device proof are required before claiming live function.",
    );
  }

  if (action === "MULTI_DEVICE_PROOF_REQUIRED") {
    warnings.push(
      "Me whakamātau ki ngā waea maha — multi-phone proof is required before claiming mesh delivery.",
    );
  }

  if (highestRisk === "PROTECTED") {
    warnings.push(
      "Arotake — protected cultural or proof state requires review before strong public claims.",
    );
  }

  return {
    id: `maori_protocol_${input.screen.replace(/[^a-z0-9]+/gi, "_").toLowerCase()}`,
    screen: input.screen,
    action,
    source,
    risk: highestRisk,
    reoSummary:
      "Tikanga, mana, mauri, tapu/noa, whakapapa ara, kaitiakitanga, rangatiratanga, me te whanaungatanga kua whakahokia ki tēnei mata.",
    englishSummary:
      "Māori protocol labels are restored on this screen with primary, backup, and safe fallback governance.",
    terms,
    warnings,
    truthBoundary:
      "This protocol layer restores visible te reo Māori and Tikanga proof labels. It does not by itself prove real BLE, ACK, relay, native telemetry, or APK runtime success.",
  };
}

function pickHighestRisk(risks: MaoriProtocolRisk[]): MaoriProtocolRisk {
  if (risks.includes("PROTECTED")) return "PROTECTED";
  if (risks.includes("HIGH")) return "HIGH";
  if (risks.includes("MEDIUM")) return "MEDIUM";
  return "LOW";
}

function pickStrongestAction(actions: MaoriProtocolAction[]): MaoriProtocolAction {
  if (actions.includes("REFUSED")) return "REFUSED";
  if (actions.includes("REVIEW_REQUIRED")) return "REVIEW_REQUIRED";
  if (actions.includes("MULTI_DEVICE_PROOF_REQUIRED")) return "MULTI_DEVICE_PROOF_REQUIRED";
  if (actions.includes("APK_PROOF_REQUIRED")) return "APK_PROOF_REQUIRED";
  if (actions.includes("APPROVED_WITH_WARNING")) return "APPROVED_WITH_WARNING";
  if (actions.includes("UNAVAILABLE_FALLBACK")) return "UNAVAILABLE_FALLBACK";
  return "APPROVED";
}

function pickBestSource(sources: MaoriProtocolSource[]): MaoriProtocolSource {
  if (sources.includes("PRIMARY_TIKANGA_ENGINE")) return "PRIMARY_TIKANGA_ENGINE";
  if (sources.includes("BACKUP_PROTOCOL_REGISTRY")) return "BACKUP_PROTOCOL_REGISTRY";
  return "SAFE_FALLBACK_PROTOCOL";
}
