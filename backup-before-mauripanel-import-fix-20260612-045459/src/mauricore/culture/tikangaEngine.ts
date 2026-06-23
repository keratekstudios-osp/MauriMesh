import { TapuNoaState, TikangaDecision, WhareTapaWhaHealth } from "../types/core.types";
import { clamp01, weightedAverage } from "../math/mathIntelligence";

export function classifyTapuNoa(action: string, privacyHint?: string): TapuNoaState {
  const lower = `${action} ${privacyHint || ""}`.toLowerCase();

  if (
    lower.includes("identity") ||
    lower.includes("location") ||
    lower.includes("route memory") ||
    lower.includes("private") ||
    lower.includes("key") ||
    lower.includes("contact")
  ) {
    return "tapu";
  }

  if (
    lower.includes("share") ||
    lower.includes("export") ||
    lower.includes("relay") ||
    lower.includes("broadcast")
  ) {
    return "restricted";
  }

  return "noa";
}

export function whareTapaWhaBalance(input: Omit<WhareTapaWhaHealth, "overallBalance" | "repairNeeded">): WhareTapaWhaHealth {
  const overallBalance = weightedAverage([
    { value: input.tahaWairua, weight: 1.414 },
    { value: input.tahaHinengaro, weight: 1.414 },
    { value: input.tahaWhanau, weight: 1.1 },
    { value: input.tahaTinana, weight: 1 },
    { value: input.whenua, weight: 1 },
  ]);

  return {
    ...input,
    overallBalance,
    repairNeeded: overallBalance < 1 / Math.SQRT2,
  };
}

export function tikangaDecision(action: string, options?: {
  privacyHint?: string;
  manaImpact?: number;
  pono?: boolean;
  tika?: boolean;
  kaitiakitangaProtected?: boolean;
  rangatiratangaRespected?: boolean;
}): TikangaDecision {
  const tapuNoa = classifyTapuNoa(action, options?.privacyHint);
  const manaImpact = clamp01(options?.manaImpact ?? 0.5);
  const pono = options?.pono ?? true;
  const tika = options?.tika ?? true;
  const kaitiakitangaProtected = options?.kaitiakitangaProtected ?? true;
  const rangatiratangaRespected = options?.rangatiratangaRespected ?? true;

  const rahui =
    tapuNoa === "tapu" ||
    !pono ||
    !tika ||
    !kaitiakitangaProtected ||
    !rangatiratangaRespected ||
    manaImpact < 0.35;

  const allowed = !rahui && tapuNoa !== "review_required";

  return {
    action,
    tapuNoa,
    manaImpact,
    pono,
    tika,
    kaitiakitangaProtected,
    rangatiratangaRespected,
    rahui,
    allowed,
    reason: allowed
      ? "Tikanga gate approved: action is noa or safely governed."
      : "Tikanga gate requires review or blocks action to protect mana, privacy, truth, or sovereignty.",
  };
}

export function koruGrowthState(layerConfidence: number): "seed" | "learning" | "stable" | "verified" | "inherited" {
  if (layerConfidence < 0.25) return "seed";
  if (layerConfidence < 0.6) return "learning";
  if (layerConfidence < 0.85) return "stable";
  if (layerConfidence < 0.95) return "verified";
  return "inherited";
}

export function flowerOfLifeOverlapScore(scores: number[]): number {
  if (scores.length === 0) return 0;
  const minimum = Math.min(...scores.map(clamp01));
  const average = scores.reduce((sum, score) => sum + clamp01(score), 0) / scores.length;

  return clamp01((minimum * 1.414 + average) / 2.414);
}
