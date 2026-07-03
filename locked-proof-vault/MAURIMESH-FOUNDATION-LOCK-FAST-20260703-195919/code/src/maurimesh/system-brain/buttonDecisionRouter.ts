import fs from "fs";
import path from "path";
import { ButtonDecision } from "./systemTypes";

const BUTTON_MAP: ButtonDecision[] = [
  {
    screen: "dashboard",
    buttonTitle: "Invention Engine",
    targetRoute: "/invention-engine",
    decisionLayer: "Living Self-Governed AI Mesh",
    reason: "Controls demo, ACK, fail, reset, route plan, ledger, and synth output.",
    status: "CONNECTED",
  },
  {
    screen: "dashboard",
    buttonTitle: "Invention Register",
    targetRoute: "/invention-register",
    decisionLayer: "Invention Register",
    reason: "Lists every invention and proof boundary.",
    status: "CONNECTED",
  },
  {
    screen: "dashboard",
    buttonTitle: "Governance",
    targetRoute: "/governance",
    decisionLayer: "Tikanga Protocol Engine",
    reason: "Tests tapu, noa, whānau, and Kia Kaha governance decisions.",
    status: "CONNECTED",
  },
  {
    screen: "dashboard",
    buttonTitle: "Route Lab",
    targetRoute: "/route-lab",
    decisionLayer: "Adaptive Mesh Routing Intelligence",
    reason: "Tests route choice, ACK learning, failure learning, and trust updates.",
    status: "CONNECTED",
  },
  {
    screen: "dashboard",
    buttonTitle: "System Check",
    targetRoute: "/system-check",
    decisionLayer: "Completion Puller",
    reason: "Audits what is wired, what is learning, and what still needs native proof.",
    status: "CONNECTED",
  },
  {
    screen: "dashboard",
    buttonTitle: "Chat",
    targetRoute: "/chat",
    decisionLayer: "Hybrid Human-AI-Network Protocol",
    reason: "Sends user messages through Mauri AI, governance, routing, and store-forward logic.",
    status: "CONNECTED",
  },
  {
    screen: "dashboard",
    buttonTitle: "Living Mesh",
    targetRoute: "/living-mesh",
    decisionLayer: "Living Mesh Visual Proof Layer",
    reason: "Displays nodes, routes, and route decisions.",
    status: "CONNECTED",
  },
  {
    screen: "dashboard",
    buttonTitle: "Mesh Status",
    targetRoute: "/mesh-status",
    decisionLayer: "Delivery Proof and ACK Ledger",
    reason: "Shows ledger, trust memory, route memory, and synth state.",
    status: "CONNECTED",
  },
  {
    screen: "dashboard",
    buttonTitle: "Add Friend",
    targetRoute: "/add-friend",
    decisionLayer: "Offline-First Identity Mesh Messenger",
    reason: "Belongs to identity, QR, nearby discovery, and contact onboarding.",
    status: "NEEDS_NATIVE_PROOF",
  },
  {
    screen: "dashboard",
    buttonTitle: "Pixel Calling",
    targetRoute: "/pixel-calling",
    decisionLayer: "Hybrid Transport Routing Layer",
    reason: "Belongs to future real-time media transport; Replit is UI shell only.",
    status: "NEEDS_NATIVE_PROOF",
  },
  {
    screen: "dashboard",
    buttonTitle: "Settings",
    targetRoute: "/settings",
    decisionLayer: "Self-Governance Layer",
    reason: "Settings should control language, privacy, runtime mode, and truth boundaries.",
    status: "CONNECTED",
  },
];

function routeExists(route: string): boolean {
  const clean = route.replace(/^\//, "");
  const candidates = [
    path.join(process.cwd(), "app", `${clean}.tsx`),
    path.join(process.cwd(), "app", clean, "index.tsx"),
  ];
  return candidates.some((file) => fs.existsSync(file));
}

export function getButtonDecisions(): ButtonDecision[] {
  return BUTTON_MAP.map((button) => ({
    ...button,
    status:
      button.status === "NEEDS_NATIVE_PROOF"
        ? button.status
        : routeExists(button.targetRoute)
          ? "CONNECTED"
          : "MISSING_SCREEN",
  }));
}

export function scanMauriButtons(): Array<{
  file: string;
  title: string;
  hasRouterPush: boolean;
}> {
  const appDir = path.join(process.cwd(), "app");
  const results: Array<{ file: string; title: string; hasRouterPush: boolean }> = [];

  if (!fs.existsSync(appDir)) return results;

  for (const file of fs.readdirSync(appDir)) {
    if (!file.endsWith(".tsx")) continue;

    const full = path.join(appDir, file);
    const text = fs.readFileSync(full, "utf8");

    const regex = /MauriButton\s+title="([^"]+)"/g;
    let match: RegExpExecArray | null;

    while ((match = regex.exec(text))) {
      const windowText = text.slice(Math.max(0, match.index - 300), match.index + 500);
      results.push({
        file: `app/${file}`,
        title: match[1],
        hasRouterPush: /router\.push|router\.replace|onPress=\{[a-zA-Z0-9_]+\}/.test(windowText),
      });
    }
  }

  return results;
}
