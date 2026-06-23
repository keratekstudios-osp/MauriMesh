export type UiRemainderTask = {
  id: string;
  title: string;
  area: "screen" | "component" | "native-proof" | "data" | "design-system" | "navigation";
  priority: "P0" | "P1" | "P2" | "P3";
  status: "missing" | "partial" | "ready" | "requires-device-proof";
  why: string;
  build: string[];
  acceptance: string[];
};

export const uiRemainderTasks: UiRemainderTask[] = [
  {
    id: "ui-001",
    title: "Proof Ledger Screen",
    area: "screen",
    priority: "P0",
    status: "missing",
    why: "You need a visual proof page showing packet ID, hash, route, ACK state, timestamp, and truth label.",
    build: [
      "Create app/proof-ledger.tsx",
      "Create src/components/ProofLedgerPanel.tsx",
      "Show packet proof rows",
      "Clearly label SIMULATION vs DEVICE PROOF",
      "Add dashboard button to /proof-ledger"
    ],
    acceptance: [
      "Screen opens without crash",
      "Shows packet ID, route, hash, ACK status",
      "Does not claim real BLE unless APK/device proof exists"
    ]
  },
  {
    id: "ui-002",
    title: "Route Lab Screen",
    area: "screen",
    priority: "P0",
    status: "missing",
    why: "You need a UI where routing decisions are visible: BLE, Wi-Fi, relay, internet fallback, TTL, trust, and path score.",
    build: [
      "Create app/route-lab.tsx",
      "Create src/components/RouteDecisionPanel.tsx",
      "Show candidate routes",
      "Show chosen route reason",
      "Add dashboard button to /route-lab"
    ],
    acceptance: [
      "Shows at least 3 route candidates",
      "Shows selected route",
      "Shows why the system selected that route"
    ]
  },
  {
    id: "ui-003",
    title: "Tikanga Engine Screen",
    area: "screen",
    priority: "P0",
    status: "missing",
    why: "The governance engine needs a dedicated screen showing approve/warn/review/refuse decisions.",
    build: [
      "Create app/tikanga-engine.tsx",
      "Create src/components/TikangaDecisionCard.tsx",
      "Show mana, tapu/noa, cultural risk, decision, and audit note",
      "Add dashboard button to /tikanga-engine"
    ],
    acceptance: [
      "Shows governance decision",
      "Shows cultural risk level",
      "Shows audit trail message"
    ]
  },
  {
    id: "ui-004",
    title: "Self-Healing Screen",
    area: "screen",
    priority: "P1",
    status: "missing",
    why: "The living system needs a screen showing faults, repairs, resilience, and homeostasis.",
    build: [
      "Create app/self-healing.tsx",
      "Create src/components/SelfHealingPanel.tsx",
      "Show detected fault",
      "Show repair action",
      "Show resilience score",
      "Add dashboard button to /self-healing"
    ],
    acceptance: [
      "Shows health state",
      "Shows repair queue",
      "Shows resilience score"
    ]
  },
  {
    id: "ui-005",
    title: "Device Proof Screen",
    area: "native-proof",
    priority: "P0",
    status: "requires-device-proof",
    why: "Real BLE, QR camera, native Bluetooth, and packet ACK proof cannot be proven by Replit preview.",
    build: [
      "Create app/device-proof.tsx",
      "Create src/components/DeviceProofCard.tsx",
      "Show APK required checklist",
      "Show phone A / phone B status",
      "Show permission readiness",
      "Add dashboard button to /device-proof"
    ],
    acceptance: [
      "Shows APK/device requirements",
      "Does not fake BLE proof",
      "Can display pasted logcat proof later"
    ]
  },
  {
    id: "ui-006",
    title: "Operator Console Screen",
    area: "screen",
    priority: "P1",
    status: "missing",
    why: "You need one command screen for system state, API URL, mode, build status, and completion percentage.",
    build: [
      "Create app/operator-console.tsx",
      "Show UI completion score",
      "Show API base URL",
      "Show current app mode",
      "Show build readiness",
      "Add dashboard button to /operator-console"
    ],
    acceptance: [
      "Shows project mode",
      "Shows completion score",
      "Shows warnings clearly"
    ]
  },
  {
    id: "ui-007",
    title: "MauriCore Status Panel",
    area: "component",
    priority: "P1",
    status: "missing",
    why: "MauriCore needs a compact reusable panel for living memory, governance, BLE runtime, and routing state.",
    build: [
      "Create src/components/MauriCoreStatusPanel.tsx",
      "Use it on Dashboard",
      "Use it on Governance or BLE Runtime screen"
    ],
    acceptance: [
      "Reusable component imports cleanly",
      "Shows core state",
      "Shows no false native claims"
    ]
  },
  {
    id: "ui-008",
    title: "Dashboard Final Button Wiring",
    area: "navigation",
    priority: "P0",
    status: "partial",
    why: "Every completed or planned screen must be reachable from Dashboard or UI Roadmap.",
    build: [
      "Add buttons for /proof-ledger",
      "Add buttons for /route-lab",
      "Add buttons for /tikanga-engine",
      "Add buttons for /self-healing",
      "Add buttons for /device-proof",
      "Add buttons for /operator-console",
      "Add buttons for /ui-roadmap"
    ],
    acceptance: [
      "Every screen opens from dashboard",
      "No dead buttons",
      "No route crash"
    ]
  },
  {
    id: "ui-009",
    title: "Empty State and Error State Design",
    area: "design-system",
    priority: "P2",
    status: "partial",
    why: "All screens need consistent empty/error/loading states so the APK does not look unfinished.",
    build: [
      "Create EmptyState component",
      "Create ErrorState component",
      "Create LoadingState component",
      "Use across Mesh Status, Living Mesh, Proof Ledger, Route Lab"
    ],
    acceptance: [
      "Every async screen has loading state",
      "Every failed API state has safe fallback",
      "No blank screens"
    ]
  },
  {
    id: "ui-010",
    title: "Final Design Polish Layer",
    area: "design-system",
    priority: "P3",
    status: "partial",
    why: "After function is complete, the UI needs premium visual consistency.",
    build: [
      "Standardize page headers",
      "Standardize cards",
      "Standardize spacing",
      "Add status pills to every technical screen",
      "Keep greenstone/emerald design language"
    ],
    acceptance: [
      "All screens feel like one product",
      "No mixed random styles",
      "Readable on Android phone"
    ]
  }
];

export function getUiRemainderSummary() {
  const total = uiRemainderTasks.length;
  const p0 = uiRemainderTasks.filter((t) => t.priority === "P0").length;
  const missing = uiRemainderTasks.filter((t) => t.status === "missing").length;
  const partial = uiRemainderTasks.filter((t) => t.status === "partial").length;
  const deviceProof = uiRemainderTasks.filter((t) => t.status === "requires-device-proof").length;

  return {
    total,
    p0,
    missing,
    partial,
    deviceProof,
    message:
      "This roadmap shows what remains to complete the MauriMesh UI layer before final APK/device proof."
  };
}
