export type MauriSystemBrainSnapshot = {
  mode: "BROWSER_SAFE" | "NATIVE_PENDING" | "SERVER_PENDING";
  status: "READY" | "SIMULATION" | "UNAVAILABLE";
  message: string;
  layers: {
    name: string;
    status: "active" | "protected" | "pending-native" | "server-only";
  }[];
  truth: string;
};

export async function getMauriSystemBrainSnapshot(): Promise<MauriSystemBrainSnapshot> {
  return {
    mode: "BROWSER_SAFE",
    status: "SIMULATION",
    message:
      "MauriMesh is running in static Replit preview mode with safe simulation fallback.",
    layers: [
      { name: "Messenger UI", status: "active" },
      { name: "Mesh Status UI", status: "active" },
      { name: "Living Mesh Preview", status: "active" },
      { name: "BLE Runtime", status: "pending-native" },
      { name: "ACK / Routing / Store-Forward", status: "protected" },
      { name: "System Brain File Ledger", status: "server-only" },
      { name: "Tikanga Governance", status: "protected" },
      { name: "Self-Healing Runtime", status: "protected" }
    ],
    truth:
      "Replit static preview proves the web UI layer. Real BLE, ACK, native routing, and offline delivery still require APK/device validation."
  };
}

export async function runMauriSystemBrainDemo() {
  return {
    ok: true,
    mode: "BROWSER_SAFE",
    message: "Demo route prepared in UI-safe simulation mode."
  };
}

export async function ackMauriSystemBrainRoute() {
  return {
    ok: true,
    mode: "BROWSER_SAFE",
    message: "ACK simulated in UI-safe mode."
  };
}

export async function failMauriSystemBrainRoute() {
  return {
    ok: true,
    mode: "BROWSER_SAFE",
    message: "Failure simulated in UI-safe mode."
  };
}
