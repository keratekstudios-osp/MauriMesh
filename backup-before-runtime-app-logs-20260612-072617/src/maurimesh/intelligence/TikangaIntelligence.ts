import { GovernanceDecision } from "./types";

export function evaluateTikangaGovernance(input?: {
  containsProtectedTerms?: boolean;
  publicClaimRisk?: boolean;
  userSafetyRisk?: boolean;
  culturalContextPresent?: boolean;
}): GovernanceDecision {
  const containsProtectedTerms = input?.containsProtectedTerms ?? false;
  const publicClaimRisk = input?.publicClaimRisk ?? true;
  const userSafetyRisk = input?.userSafetyRisk ?? false;
  const culturalContextPresent = input?.culturalContextPresent ?? true;

  if (userSafetyRisk) {
    return {
      action: "review_required",
      culturalRisk: "high",
      manaProtection: 92,
      auditNote: "Safety risk detected. Human review required before release.",
    };
  }

  if (containsProtectedTerms && !culturalContextPresent) {
    return {
      action: "review_required",
      culturalRisk: "protected",
      manaProtection: 95,
      auditNote: "Protected cultural terms require context and review.",
    };
  }

  if (publicClaimRisk) {
    return {
      action: "approved_with_warning",
      culturalRisk: "medium",
      manaProtection: 86,
      auditNote:
        "Public claims should be backed by proof. Use truthful labels: UI, simulation, APK required, or device proof.",
    };
  }

  return {
    action: "approved",
    culturalRisk: "low",
    manaProtection: 90,
    auditNote: "Governance check passed.",
  };
}
