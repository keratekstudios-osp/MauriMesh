import { PacketPrivacy } from "../types/core.types";

export function consentRequired(action: string): boolean {
  const lower = action.toLowerCase();
  return (
    lower.includes("identity") ||
    lower.includes("location") ||
    lower.includes("contacts") ||
    lower.includes("share") ||
    lower.includes("export") ||
    lower.includes("native") ||
    lower.includes("ble")
  );
}

export function privacyBoundary(privacy: PacketPrivacy): {
  shareable: boolean;
  reason: string;
} {
  if (privacy === "never_share") {
    return { shareable: false, reason: "Privacy boundary blocks sharing: never_share." };
  }

  if (privacy === "tapu_private") {
    return { shareable: false, reason: "Privacy boundary requires tapu handling and review." };
  }

  return { shareable: true, reason: "Privacy boundary allows governed handling." };
}

export function simulationRealityBoundary(input: {
  mode: "simulation" | "replit" | "device_test" | "production";
  claim: string;
}): {
  allowed: boolean;
  reason: string;
} {
  const lower = input.claim.toLowerCase();

  if ((input.mode === "simulation" || input.mode === "replit") && lower.includes("live ble proof")) {
    return {
      allowed: false,
      reason: "Simulation/Replit cannot be claimed as live BLE proof.",
    };
  }

  return {
    allowed: true,
    reason: "Simulation/reality boundary satisfied.",
  };
}
