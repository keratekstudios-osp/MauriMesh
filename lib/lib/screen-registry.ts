// Typed registry of all planned screens in the MauriMesh mobile app.
// Status: "implemented" = full screen exists; "placeholder" = ComingSoonScreen rendered.
// Add a new entry here whenever a route is wired up in app/.

export type ScreenStatus = "implemented" | "placeholder";

export interface ScreenEntry {
  name: string;
  route: string;
  status: ScreenStatus;
}

export const SCREEN_REGISTRY: ScreenEntry[] = [
  // ── Core ─────────────────────────────────────────────────────────────
  { name: "Dashboard",       route: "/dashboard",          status: "implemented" },
  { name: "Chat",            route: "/chat",               status: "implemented" },
  { name: "Login",           route: "/login",              status: "implemented" },
  { name: "Sign Up",         route: "/signup",             status: "implemented" },
  { name: "Forgot Password", route: "/forgot-password",    status: "implemented" },

  // ── Navigation targets from Dashboard ────────────────────────────────
  { name: "Living Mesh",     route: "/living-mesh",        status: "implemented" },
  { name: "Mesh Status",     route: "/mesh-status",        status: "implemented" },
  { name: "Configuration",   route: "/configuration",      status: "implemented" },
  { name: "Mesh Network",    route: "/mesh",               status: "implemented" },
  { name: "Network",         route: "/network",            status: "implemented" },
  { name: "Trust",           route: "/trust",              status: "implemented" },
  { name: "Calling",         route: "/calling",            status: "implemented" },
  { name: "Settings",        route: "/settings",           status: "implemented" },

  // ── Placeholder screens (integration pending) ─────────────────────────
  { name: "Contacts",        route: "/contacts",           status: "placeholder" },
  { name: "Profile",         route: "/profile",            status: "placeholder" },
  { name: "Invite",          route: "/invite",             status: "placeholder" },

  // ── Friend / QR ──────────────────────────────────────────────────────
  { name: "QR Add Friend",   route: "/add-friend",         status: "implemented" },
  { name: "Scan Friend",     route: "/scan-friend",        status: "implemented" },
  { name: "My QR",           route: "/my-qr",              status: "implemented" },

  // ── Diagnostics / Platform ───────────────────────────────────────────
  { name: "Diagnostics",     route: "/diagnostic-logs",    status: "implemented" },
  { name: "Local Storage",   route: "/local-storage",      status: "implemented" },
  { name: "Session Recovery",route: "/session-recovery",   status: "implemented" },
  { name: "Biometric Unlock",route: "/biometric-unlock",   status: "implemented" },
  { name: "Device Proof",    route: "/device-proof",       status: "implemented" },

  // ── Settings sub-screens ─────────────────────────────────────────────
  { name: "Appearance",        route: "/settings/appearance",        status: "implemented" },
  { name: "Language",          route: "/settings/language",          status: "implemented" },
  { name: "Notifications",     route: "/settings/notifications",     status: "implemented" },
  { name: "Permissions",       route: "/settings/permissions",       status: "implemented" },
  { name: "Offline Controls",  route: "/settings/offline-controls",  status: "implemented" },
  { name: "Device Pairing",    route: "/settings/device-pairing",    status: "implemented" },
  { name: "Security",          route: "/settings/security",          status: "implemented" },
  { name: "Privacy",           route: "/settings/privacy",           status: "implemented" },
  { name: "Export / Import",   route: "/settings/export-import",     status: "implemented" },
  { name: "Backend Connect",   route: "/settings/backend-connect",   status: "implemented" },

  // ── Trust sub-screens ────────────────────────────────────────────────
  { name: "Trust Engine",     route: "/trust/trust-engine",      status: "implemented" },
  { name: "Tikanga Engine",   route: "/trust/tikanga-engine",    status: "implemented" },
  { name: "Governance Rules", route: "/trust/governance-rules",  status: "implemented" },
  { name: "Reputation System",route: "/trust/reputation-system", status: "implemented" },
  { name: "Node Integrity",   route: "/trust/node-integrity",    status: "implemented" },

  // ── Network sub-screens ──────────────────────────────────────────────
  { name: "Connectivity",       route: "/network/connectivity",        status: "implemented" },
  { name: "Delivery Analytics", route: "/network/delivery-analytics",  status: "implemented" },
  { name: "Network Diagnostics",route: "/network/diagnostics",         status: "implemented" },
  { name: "Latency Monitoring", route: "/network/latency-monitoring",  status: "implemented" },
  { name: "Packet Analysis",    route: "/network/packet-analysis",     status: "implemented" },
  { name: "Route Health",       route: "/network/route-health",        status: "implemented" },

  // ── Calling sub-screens ──────────────────────────────────────────────
  { name: "Active Call",          route: "/calling/active-call",           status: "implemented" },
  { name: "Incoming Call",        route: "/calling/incoming-call",         status: "implemented" },
  { name: "Adaptive Quality",     route: "/calling/adaptive-quality",      status: "implemented" },
  { name: "Call Analytics",       route: "/calling/call-analytics",        status: "implemented" },
  { name: "Reconstruction Engine",route: "/calling/reconstruction-engine", status: "implemented" },
  { name: "Signal Visualization", route: "/calling/signal-visualization",  status: "implemented" },

  // ── Mesh sub-screens ─────────────────────────────────────────────────
  { name: "ACK Tracking",      route: "/mesh/ack-tracking",        status: "implemented" },
  { name: "BLE Discovery",     route: "/mesh/ble-discovery",       status: "implemented" },
  { name: "Peer Mapping",      route: "/mesh/peer-mapping",        status: "implemented" },
  { name: "Relay Analytics",   route: "/mesh/relay-analytics",     status: "implemented" },
  { name: "Route Visualization",route: "/mesh/route-visualization",status: "implemented" },
  { name: "Signal Strength",   route: "/mesh/signal-strength",     status: "implemented" },
  { name: "Store Forward Queue",route: "/mesh/store-forward-queue",status: "implemented" },

  // ── Tabs ─────────────────────────────────────────────────────────────
  { name: "Messages Tab",  route: "/(tabs)/index",    status: "implemented" },
  { name: "Settings Tab",  route: "/(tabs)/settings", status: "implemented" },

  // ── Platform sub-screens ─────────────────────────────────────────────
  { name: "Accessibility",     route: "/platform/accessibility",     status: "implemented" },
  { name: "AI Assistant",      route: "/platform/ai-assistant",      status: "implemented" },
  { name: "Background Sync",   route: "/platform/background-sync",   status: "implemented" },
  { name: "Developer Mode",    route: "/platform/developer-mode",    status: "implemented" },
  { name: "Emergency Mode",    route: "/platform/emergency-mode",    status: "implemented" },
  { name: "Encryption Keys",   route: "/platform/encryption-keys",   status: "implemented" },
  { name: "Export Backup",     route: "/platform/export-backup",     status: "implemented" },
  { name: "OTA Updates",       route: "/platform/ota-updates",       status: "implemented" },
  { name: "Push Notifications",route: "/platform/push-notifications",status: "implemented" },
  { name: "Storage Management",route: "/platform/storage-management",status: "implemented" },
];

// Set of routes whose screens are placeholder-only.
// safeNavigate uses this to route through the fallback screen.
export const PLACEHOLDER_ROUTES = new Set<string>(
  SCREEN_REGISTRY
    .filter((s) => s.status === "placeholder")
    .map((s) => s.route),
);

// Full set of registered routes (implemented + placeholder).
export const REGISTERED_ROUTES = new Set<string>(
  SCREEN_REGISTRY.map((s) => s.route),
);
