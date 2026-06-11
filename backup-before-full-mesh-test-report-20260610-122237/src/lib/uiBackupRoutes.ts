export type UiRouteKey =
  | "login"
  | "dashboard"
  | "chat"
  | "settings"
  | "addFriend"
  | "livingMesh"
  | "meshStatus"
  | "pixelCalling"
  | "uiRoadmap"
  | "proofLedger"
  | "routeLab"
  | "tikangaEngine"
  | "selfHealing"
  | "deviceProof"
  | "operatorConsole"
  | "mauriCoreGovernance"
  | "mauriCoreBleRuntime"
  | "intelligence"
  | "backupIntelligence"
  | "deviceHardware"
  | "nativeTelemetry"
  | "hardwareRuntime"
  | "bleHardwareRuntime"
  | "hybridWifiBleMesh";

export type UiBackupRoute = {
  key: UiRouteKey;
  title: string;
  route: string;
  fallbackRoute: string;
  critical: boolean;
  purpose: string;
};

export const uiBackupRoutes: UiBackupRoute[] = [
  {
    key: "login",
    title: "Login",
    route: "/login",
    fallbackRoute: "/dashboard",
    critical: true,
    purpose: "Entry screen and safe return point.",
  },
  {
    key: "dashboard",
    title: "Dashboard",
    route: "/dashboard",
    fallbackRoute: "/login",
    critical: true,
    purpose: "Main navigation hub.",
  },
  {
    key: "chat",
    title: "Chat",
    route: "/chat",
    fallbackRoute: "/dashboard",
    critical: true,
    purpose: "Messenger UI shell.",
  },
  {
    key: "settings",
    title: "Settings",
    route: "/settings",
    fallbackRoute: "/dashboard",
    critical: true,
    purpose: "User controls and logout.",
  },
  {
    key: "addFriend",
    title: "Add Friend",
    route: "/add-friend",
    fallbackRoute: "/dashboard",
    critical: true,
    purpose: "QR and nearby mesh friend UI shell.",
  },
  {
    key: "livingMesh",
    title: "Living Mesh",
    route: "/living-mesh",
    fallbackRoute: "/mesh-status",
    critical: true,
    purpose: "Mesh visualizer and simulation/live status view.",
  },
  {
    key: "meshStatus",
    title: "Mesh Status",
    route: "/mesh-status",
    fallbackRoute: "/dashboard",
    critical: true,
    purpose: "Mesh API/simulation status.",
  },
  {
    key: "pixelCalling",
    title: "Pixel Calling",
    route: "/pixel-calling",
    fallbackRoute: "/dashboard",
    critical: false,
    purpose: "Calling UI shell, not real transport proof.",
  },
  {
    key: "uiRoadmap",
    title: "UI Roadmap",
    route: "/ui-roadmap",
    fallbackRoute: "/dashboard",
    critical: true,
    purpose: "Remaining UI work and completion map.",
  },
  {
    key: "proofLedger",
    title: "Proof Ledger",
    route: "/proof-ledger",
    fallbackRoute: "/device-proof",
    critical: true,
    purpose: "Packet/hash/ACK proof UI.",
  },
  {
    key: "routeLab",
    title: "Route Lab",
    route: "/route-lab",
    fallbackRoute: "/mesh-status",
    critical: true,
    purpose: "Hybrid route decision UI.",
  },
  {
    key: "tikangaEngine",
    title: "Tikanga Engine",
    route: "/tikanga-engine",
    fallbackRoute: "/mauricore-governance",
    critical: true,
    purpose: "Governance decision UI.",
  },
  {
    key: "selfHealing",
    title: "Self-Healing",
    route: "/self-healing",
    fallbackRoute: "/operator-console",
    critical: true,
    purpose: "Repair queue and resilience UI.",
  },
  {
    key: "deviceProof",
    title: "Device Proof",
    route: "/device-proof",
    fallbackRoute: "/proof-ledger",
    critical: true,
    purpose: "APK/device proof checklist.",
  },
  {
    key: "operatorConsole",
    title: "Operator Console",
    route: "/operator-console",
    fallbackRoute: "/dashboard",
    critical: true,
    purpose: "System readiness and operator state.",
  },
  {
    key: "mauriCoreGovernance",
    title: "MauriCore Governance",
    route: "/mauricore-governance",
    fallbackRoute: "/tikanga-engine",
    critical: true,
    purpose: "MauriCore governance view.",
  },
  {
    key: "mauriCoreBleRuntime",
    title: "MauriCore BLE Runtime",
    route: "/mauricore-ble-runtime",
    fallbackRoute: "/device-proof",
    critical: true,
    purpose: "BLE runtime readiness UI.",
  },,
  {
    key: "intelligence",
    title: "Intelligence",
    route: "/intelligence",
    fallbackRoute: "/operator-console",
    critical: true,
    purpose: "Intelligence orchestration dashboard.",
  },
  {
    key: "backupIntelligence",
    title: "Backup Intelligence",
    route: "/backup-intelligence",
    fallbackRoute: "/intelligence",
    critical: true,
    purpose: "Failover intelligence and safe decision backup.",
  },
  {
    key: "deviceHardware",
    title: "Device Hardware",
    route: "/device-hardware",
    fallbackRoute: "/operator-console",
    critical: true,
    purpose: "Device hardware stabilisation and runtime optimisation.",
  },
  {
    key: "nativeTelemetry",
    title: "Native Telemetry",
    route: "/native-telemetry",
    fallbackRoute: "/device-hardware",
    critical: true,
    purpose: "APK-ready native hardware telemetry bridge.",
  },
  {
    key: "hardwareRuntime",
    title: "Hardware Runtime",
    route: "/hardware-runtime",
    fallbackRoute: "/native-telemetry",
    critical: true,
    purpose: "Hardware-aware runtime optimisation controller.",
  },
  {
    key: "bleHardwareRuntime",
    title: "BLE Hardware Runtime",
    route: "/ble-hardware-runtime",
    fallbackRoute: "/hardware-runtime",
    critical: true,
    purpose: "BLE runtime tuning with hardware-aware backup policy.",
  },
  {
    key: "hybridWifiBleMesh",
    title: "Hybrid Wi-Fi BLE Mesh",
    route: "/hybrid-wifi-ble-mesh",
    fallbackRoute: "/ble-hardware-runtime",
    critical: true,
    purpose: "Backup hybrid transport routing across BLE, relay, store-forward, Wi-Fi and gateway paths.",
  },
  {
    key: "messageFallback",
    title: "Message Queue + ACK Fallback",
    route: "/message-fallback",
    fallbackRoute: "/hybrid-wifi-ble-mesh",
    critical: true,
    purpose: "Durable message queue, retry planning, ACK fallback, and pending proof protection.",
  },
  {
    key: "pixelCallingBackup",
    title: "Pixel Calling Backup Fallback",
    route: "/pixel-calling-backup",
    fallbackRoute: "/message-fallback",
    critical: true,
    purpose: "Fallback-backup route for failed Pixel Calling runtime.",
  },
  {
    key: "aiPixelReconstruction",
    title: "AI Pixel Reconstruction",
    route: "/ai-pixel-reconstruction",
    fallbackRoute: "/pixel-reconstruction-ack",
    critical: true,
    purpose: "1080p compressed source to AI 32K reconstruction target with ACK proof.",
  }
];

export function getUiRoute(key: UiRouteKey): UiBackupRoute {
  const found = uiBackupRoutes.find((route) => route.key === key);

  if (!found) {
    return {
      key: "dashboard",
      title: "Dashboard",
      route: "/dashboard",
      fallbackRoute: "/login",
      critical: true,
      purpose: "Emergency fallback route.",
    };
  }

  return found;
}

export function getRouteFallback(route: string): string {
  return (
    uiBackupRoutes.find((item) => item.route === route)?.fallbackRoute ||
    "/dashboard"
  );
}

export function getRouteTitle(route: string): string {
  return uiBackupRoutes.find((item) => item.route === route)?.title || "Dashboard";
}

// Pixel Calling fallback route: /message-fallback

// MauriMesh Test Layer backup route marker
export const MAURIMESH_TEST_LAYER_ROUTE = "/test-layer";

// MauriMesh Māori Protocols backup route marker
export const MAURIMESH_MAORI_PROTOCOLS_ROUTE = "/maori-protocols";

// MauriMesh JumpCode Proof backup route
export const MAURIMESH_JUMPCODE_PROOF_ROUTE = "/jumpcode-proof";

// MauriMesh Evolution Layer backup route marker
export const MAURIMESH_EVOLUTION_LAYER_ROUTE = "/evolution-layer";
