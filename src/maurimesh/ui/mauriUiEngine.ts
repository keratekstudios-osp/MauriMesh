import {
  LivingSelfGovernedAiMesh,
  MeshNode,
  EngineResult,
} from "../invention-engine";

export type UiMeshNode = {
  id: string;
  label: string;
  status: "online" | "relay" | "offline";
  signal: number;
  x: number;
  y: number;
};

export type UiMeshRoute = {
  from: string;
  to: string;
  quality: number;
};

export type UiEngineSnapshot = {
  mode: "LIVE_ENGINE" | "SIMULATION" | "UNAVAILABLE";
  message: string;
  nodes: UiMeshNode[];
  routes: UiMeshRoute[];
  ledgerCount: number;
  trustCount: number;
  routeMemoryCount: number;
  lastResult?: EngineResult;
  rawVisualSnapshot: unknown;
};

const engine = new LivingSelfGovernedAiMesh();

let lastResult: EngineResult | undefined;

const defaultNodes: MeshNode[] = [
  {
    id: "PHONE_A",
    label: "Devan Phone",
    role: "ENDPOINT",
    trust: "VERIFIED",
    batteryPct: 88,
    signalPct: 92,
    online: true,
    lastSeenMs: Date.now(),
    transports: ["BLE", "WIFI_DIRECT", "LOCAL_WIFI", "INTERNET"],
    culturalState: "WHANAUNGATANGA_TRUSTED",
  },
  {
    id: "PHONE_B",
    label: "Relay Phone",
    role: "RELAY",
    trust: "TRUSTED",
    batteryPct: 71,
    signalPct: 80,
    online: true,
    lastSeenMs: Date.now(),
    transports: ["BLE", "WIFI_DIRECT"],
  },
  {
    id: "PHONE_C",
    label: "Recipient Phone",
    role: "ENDPOINT",
    trust: "OBSERVED",
    batteryPct: 64,
    signalPct: 45,
    online: false,
    lastSeenMs: Date.now() - 60000,
    transports: ["BLE"],
  },
  {
    id: "GATEWAY_D",
    label: "Gateway D",
    role: "GATEWAY",
    trust: "VERIFIED",
    batteryPct: 97,
    signalPct: 89,
    online: true,
    lastSeenMs: Date.now(),
    transports: ["LOCAL_WIFI", "INTERNET"],
  },
];

engine.setNodes(defaultNodes);

function xyForNode(index: number): { x: number; y: number } {
  const positions = [
    { x: 18, y: 30 },
    { x: 46, y: 55 },
    { x: 77, y: 28 },
    { x: 66, y: 78 },
    { x: 30, y: 78 },
    { x: 84, y: 56 },
  ];
  return positions[index % positions.length];
}

function toUiNodes(nodes: MeshNode[]): UiMeshNode[] {
  return nodes.map((node, index) => {
    const pos = xyForNode(index);
    return {
      id: node.id,
      label: node.label || node.id,
      status: !node.online ? "offline" : node.role === "RELAY" || node.role === "GATEWAY" || node.role === "SUPERNODE" ? "relay" : "online",
      signal: node.signalPct,
      x: pos.x,
      y: pos.y,
    };
  });
}

function toUiRoutes(result?: EngineResult): UiMeshRoute[] {
  if (!result) {
    return [
      { from: "PHONE_A", to: "PHONE_B", quality: 88 },
      { from: "PHONE_B", to: "PHONE_C", quality: 62 },
      { from: "PHONE_B", to: "GATEWAY_D", quality: 81 },
    ];
  }

  const routes: UiMeshRoute[] = [];
  const hops = result.routePlan.hops;

  if (hops.length === 0) {
    routes.push({
      from: result.packet.from,
      to: result.packet.to,
      quality: Math.round(result.routePlan.totalScore * 100),
    });
    return routes;
  }

  let previous = result.packet.from;
  for (const hop of hops) {
    routes.push({
      from: previous,
      to: hop.nodeId,
      quality: Math.round(hop.score * 100),
    });
    previous = hop.nodeId;
  }

  if (previous !== result.packet.to) {
    routes.push({
      from: previous,
      to: result.packet.to,
      quality: Math.round(result.routePlan.totalScore * 100),
    });
  }

  return routes;
}

export function getMauriUiEngine() {
  return engine;
}

export function runDemoMessage(body?: string): EngineResult {
  lastResult = engine.send({
    from: "PHONE_A",
    to: "PHONE_C",
    body: body || "Kia kaha, emergency help message through MauriMesh.",
  });

  return lastResult;
}

export function sendUiMessage(input: {
  from?: string;
  to?: string;
  body: string;
}): EngineResult {
  lastResult = engine.send({
    from: input.from || "PHONE_A",
    to: input.to || "PHONE_C",
    body: input.body,
  });

  return lastResult;
}

export function ackLastRoute(): void {
  if (!lastResult) return;
  const routeNodes = [
    lastResult.packet.from,
    ...lastResult.routePlan.hops.map((h) => h.nodeId),
    lastResult.packet.to,
  ];
  engine.ack(lastResult.packet.id, routeNodes, 420);
}

export function failLastRoute(reason = "[SIMULATION] Manual UI failure simulation."): void {
  if (!lastResult) return;
  const routeNodes = [
    lastResult.packet.from,
    ...lastResult.routePlan.hops.map((h) => h.nodeId),
    lastResult.packet.to,
  ];
  engine.fail(lastResult.packet.id, routeNodes, reason);
}

export function getUiEngineSnapshot(): UiEngineSnapshot {
  const rawVisualSnapshot = engine.visualSnapshot();

  return {
    mode: "LIVE_ENGINE",
    message:
      "MauriMesh invention engine is wired to Replit UI. This is logic-engine proof, not native BLE proof.",
    nodes: toUiNodes(engine.getNodes()),
    routes: toUiRoutes(lastResult),
    ledgerCount: engine.ledgerExport().length,
    trustCount: engine.trustMemoryExport().length,
    routeMemoryCount: engine.routeMemoryExport().length,
    lastResult,
    rawVisualSnapshot,
  };
}

export function resetUiEngineDemo(): UiEngineSnapshot {
  engine.setNodes(defaultNodes);
  lastResult = undefined;
  return getUiEngineSnapshot();
}
