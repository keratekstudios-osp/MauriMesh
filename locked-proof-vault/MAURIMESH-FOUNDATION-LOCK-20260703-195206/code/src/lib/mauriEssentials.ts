import { getUiEngineSnapshot } from "../maurimesh/ui/mauriUiEngine";

export type InventionStatus =
  | "CODED_LOGIC"
  | "UI_WIRED"
  | "NEEDS_NATIVE_PROOF"
  | "NEEDS_FIELD_TEST"
  | "PROTECTED_CONCEPT";

export type MauriInventionRecord = {
  id: number;
  name: string;
  status: InventionStatus;
  reason: string;
  enhances: string;
  proofBoundary: string;
};

export const MAURIMESH_INVENTION_REGISTER: MauriInventionRecord[] = [
  {
    id: 1,
    name: "Offline-First Identity Mesh Messenger",
    status: "CODED_LOGIC",
    reason: "Gives devices identity before depending on internet or SIM-based delivery.",
    enhances: "Allows MauriMesh to act as a trusted local messenger during weak or failed connectivity.",
    proofBoundary: "Needs APK and physical phone validation for native BLE identity exchange.",
  },
  {
    id: 2,
    name: "Living Route Memory",
    status: "CODED_LOGIC",
    reason: "Records route success, failure, latency, and trust change.",
    enhances: "Makes routing stronger over time instead of static.",
    proofBoundary: "Needs real packet outcomes from phones to become field-proven.",
  },
  {
    id: 3,
    name: "Tikanga-Based Network Governance",
    status: "UI_WIRED",
    reason: "Adds cultural and ethical decision rules before route selection.",
    enhances: "Prevents raw speed or automation from overriding safety, consent, and protocol.",
    proofBoundary: "Needs cultural review before public or iwi/community deployment.",
  },
  {
    id: 4,
    name: "Mauri AI Routing Conscience",
    status: "CODED_LOGIC",
    reason: "Balances signal, battery, trust, urgency, privacy, and delivery chance.",
    enhances: "Makes the network intelligent without becoming reckless.",
    proofBoundary: "Needs field telemetry to tune weighting.",
  },
  {
    id: 5,
    name: "Cleo + Chanelle Synth AI Federation",
    status: "UI_WIRED",
    reason: "Creates a human-facing explanation layer for mesh decisions.",
    enhances: "Helps users understand routing, delivery, emergency state, and safety.",
    proofBoundary: "Needs voice/personality layer later if used as real synth AI.",
  },
  {
    id: 6,
    name: "Self-Healing Messenger Runtime",
    status: "CODED_LOGIC",
    reason: "Detects failed packets, stale nodes, missing ACKs, and recovery actions.",
    enhances: "Keeps the system alive under real-world failure.",
    proofBoundary: "Needs Android background service integration.",
  },
  {
    id: 7,
    name: "Store-and-Forward Social Mesh",
    status: "CODED_LOGIC",
    reason: "Stores messages when the recipient is unavailable and forwards later.",
    enhances: "Allows delayed offline delivery across broken time windows.",
    proofBoundary: "Needs persistent encrypted local storage in APK.",
  },
  {
    id: 8,
    name: "Living Mesh Visual Proof Layer",
    status: "UI_WIRED",
    reason: "Shows nodes, routes, ledger, route quality, and engine state.",
    enhances: "Turns invisible routing into visible proof.",
    proofBoundary: "Needs live native telemetry feed for real-world proof.",
  },
  {
    id: 9,
    name: "Hybrid Human-AI-Network Protocol",
    status: "CODED_LOGIC",
    reason: "Combines user intent, AI routing, governance, and device network behaviour.",
    enhances: "Makes MauriMesh a coordination protocol, not only a chat app.",
    proofBoundary: "Needs full integration with native send/receive pipeline.",
  },
  {
    id: 10,
    name: "Kia Kaha Emergency Routing Mode",
    status: "CODED_LOGIC",
    reason: "Raises priority, TTL, and emergency routing behaviour under urgent conditions.",
    enhances: "Positions MauriMesh for outage and safety use cases.",
    proofBoundary: "Needs strict abuse prevention and physical test proof.",
  },
  {
    id: 11,
    name: "Tapu / Noa Digital Privacy States",
    status: "CODED_LOGIC",
    reason: "Applies contextual privacy states to packets and relay permissions.",
    enhances: "Adds deeper privacy than simple public/private toggles.",
    proofBoundary: "Needs legal and cultural review before public claims.",
  },
  {
    id: 12,
    name: "Pathway + Pipeline Dual Architecture",
    status: "CODED_LOGIC",
    reason: "Separates where a message travels from how it is processed.",
    enhances: "Improves debugging, scaling, and proof reporting.",
    proofBoundary: "Needs full production telemetry logging.",
  },
  {
    id: 13,
    name: "Decentralised Trust Memory",
    status: "CODED_LOGIC",
    reason: "Lets node trust rise or fall based on behaviour.",
    enhances: "Reduces reliance on unreliable or unsafe relays.",
    proofBoundary: "Needs anti-spoofing and signed relay evidence.",
  },
  {
    id: 14,
    name: "Mesh Messenger as Community Infrastructure",
    status: "PROTECTED_CONCEPT",
    reason: "Frames the messenger as local community resilience infrastructure.",
    enhances: "Supports families, iwi, schools, hospitals, security, rural areas, and emergencies.",
    proofBoundary: "Needs pilot partners and deployment governance.",
  },
  {
    id: 15,
    name: "Living Self-Governed AI Mesh",
    status: "UI_WIRED",
    reason: "Unifies mesh routing, self-learning, self-healing, governance, cultural protocol, and synth explanation.",
    enhances: "Creates the master MauriMesh operating model.",
    proofBoundary: "Needs APK proof, two-phone proof, and multi-device field testing.",
  },
];

export type MauriAuditItem = {
  name: string;
  status: "PASS" | "WARN" | "FAIL";
  detail: string;
};

export type MauriCompletionAudit = {
  score: number;
  summary: string;
  items: MauriAuditItem[];
};

export function getMauriCompletionAudit(): MauriCompletionAudit {
  const snapshot = getUiEngineSnapshot();

  const items: MauriAuditItem[] = [
    {
      name: "Invention engine bridge",
      status: snapshot.mode === "LIVE_ENGINE" ? "PASS" : "FAIL",
      detail: snapshot.message,
    },
    {
      name: "Living mesh nodes",
      status: snapshot.nodes.length > 0 ? "PASS" : "FAIL",
      detail: `${snapshot.nodes.length} node(s) visible to UI.`,
    },
    {
      name: "Route visualisation",
      status: snapshot.routes.length > 0 ? "PASS" : "WARN",
      detail: `${snapshot.routes.length} route(s) visible to UI.`,
    },
    {
      name: "Delivery ledger",
      status: snapshot.ledgerCount > 0 ? "PASS" : "WARN",
      detail:
        snapshot.ledgerCount > 0
          ? `${snapshot.ledgerCount} ledger event(s) recorded.`
          : "No ledger events yet. Run a demo message.",
    },
    {
      name: "Trust memory",
      status: snapshot.trustCount > 0 ? "PASS" : "WARN",
      detail:
        snapshot.trustCount > 0
          ? `${snapshot.trustCount} trust record(s) active.`
          : "No trust memory yet. Run a demo and ACK/fail route.",
    },
    {
      name: "Route memory",
      status: snapshot.routeMemoryCount > 0 ? "PASS" : "WARN",
      detail:
        snapshot.routeMemoryCount > 0
          ? `${snapshot.routeMemoryCount} route learning record(s) active.`
          : "No learned route yet. ACK a route to create memory.",
    },
    {
      name: "Native BLE proof",
      status: "WARN",
      detail: "Not proven in Replit. Requires Android APK and physical phones.",
    },
    {
      name: "Wi-Fi Direct proof",
      status: "WARN",
      detail: "Not proven in Replit. Requires native Android integration.",
    },
    {
      name: "Background runtime proof",
      status: "WARN",
      detail: "Not proven in Replit. Requires Android service validation.",
    },
  ];

  const pass = items.filter((i) => i.status === "PASS").length;
  const score = Math.round((pass / items.length) * 100);

  return {
    score,
    summary:
      "MauriMesh inventions and UI are wired as a Replit-safe logic layer. Native transport proof remains APK/device work.",
    items,
  };
}
