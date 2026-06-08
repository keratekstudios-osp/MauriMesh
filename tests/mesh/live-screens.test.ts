import { describe, it, expect, vi, beforeEach } from "vitest";
import React from "react";
import { renderToStaticMarkup } from "react-dom/server";
import type {
  LiveMeshState,
  MeshMetricSnapshot,
  MeshNodeRecord,
} from "../../src/maurimesh/live/types";

// Smoke / render coverage for the live mesh + network screens. The native BLE
// source is absent on web/CI, so these screens must render their honest empty
// (no peers) state AND a populated (mocked peers/metrics) state without
// crashing. We stub react-native primitives to host elements and render with
// react-dom/server so no native runtime is required. This proves no live BLE —
// the data is mocked.

// react-native is not loadable in a node test runner, so map its primitives to
// plain host elements that react-dom/server can render to a string.
vi.mock("react-native", async () => {
  const ReactMod = await import("react");
  const host = (tag: string) => {
    const C = (props: { children?: unknown }) =>
      ReactMod.createElement(tag, null, props?.children as never);
    return C;
  };
  return {
    View: host("div"),
    ScrollView: host("div"),
    Text: host("span"),
    TouchableOpacity: host("div"),
    StyleSheet: { create: (s: unknown) => s },
  };
});

vi.mock("expo-router", () => ({
  useRouter: () => ({
    back: () => {},
    push: () => {},
    replace: () => {},
    navigate: () => {},
  }),
}));

// Controlled mesh state the mocked hook returns. `hoisted` lets the mock factory
// reference it despite vi.mock hoisting.
const mesh = vi.hoisted(() => ({ state: null as unknown as LiveMeshState }));

vi.mock("../../src/maurimesh/live/useLiveMesh", () => ({
  useLiveMesh: () => ({
    state: mesh.state,
    loading: false,
    refresh: async () => mesh.state,
    startScan: async () => mesh.state,
    stopScan: async () => mesh.state,
  }),
}));

// Screens under test (imported AFTER the mocks above are declared/hoisted).
import MeshIndexScreen from "../../app/mesh/index";
import BleDiscoveryScreen from "../../app/mesh/ble-discovery";
import PeerMappingScreen from "../../app/mesh/peer-mapping";
import SignalStrengthScreen from "../../app/mesh/signal-strength";
import StoreForwardQueueScreen from "../../app/mesh/store-forward-queue";
import AckTrackingScreen from "../../app/mesh/ack-tracking";
import RouteHealthScreen from "../../app/network/route-health";

function emptyMetrics(): MeshMetricSnapshot {
  return {
    createdAt: new Date(0).toISOString(),
    scanActive: false,
    discoveredCount: 0,
    nodeCount: 0,
    routeCount: 0,
    deliveryCount: 0,
    relayCount: 0,
    ackCount: 0,
    failureCount: 0,
    averageLatencyMs: 0,
    truthLevel: "not_proven",
  };
}

function emptyState(): LiveMeshState {
  return {
    marker: "TEST_EMPTY",
    updatedAt: new Date(0).toISOString(),
    nativeModulePresent: false,
    permissionsGranted: false,
    scanActive: false,
    discoveredCount: 0,
    nodes: [],
    metrics: emptyMetrics(),
    lastNativeStatus: {
      module: "MauriMeshBle",
      mode: "not_loaded",
      modulePresent: false,
      blePermissions: false,
      liveBleActive: false,
      scanActive: false,
      discoveredCount: 0,
    },
    truthBoundary: "No mesh delivery claim is made until proven on hardware.",
  };
}

function node(id: string, over: Partial<MeshNodeRecord> = {}): MeshNodeRecord {
  const now = new Date().toISOString();
  return {
    id,
    label: `Node-${id}`,
    address: `AA:BB:CC:00:00:${id}`,
    name: `Node-${id}`,
    role: "peer",
    firstSeenAt: now,
    lastSeenAt: now,
    seenCount: 5,
    lastRssi: -58,
    transport: "BLE_SCAN",
    truthLevel: "native_status",
    source: "test",
    ...over,
  };
}

function populatedState(): LiveMeshState {
  const s = emptyState();
  s.marker = "TEST_POPULATED";
  s.nativeModulePresent = true;
  s.permissionsGranted = true;
  s.scanActive = true;
  s.discoveredCount = 2;
  s.nodes = [node("01"), node("02", { lastRssi: -80, seenCount: 1 })];
  s.metrics = {
    ...emptyMetrics(),
    scanActive: true,
    discoveredCount: 2,
    nodeCount: 2,
    routeCount: 2,
    deliveryCount: 4,
    relayCount: 3,
    ackCount: 4,
    failureCount: 1,
    averageLatencyMs: 120,
    truthLevel: "native_status",
  };
  return s;
}

function render(Screen: React.ComponentType): string {
  return renderToStaticMarkup(React.createElement(Screen));
}

type Case = {
  name: string;
  Screen: React.ComponentType;
  title: string;
  emptyText: string;
  populatedText: string;
};

const cases: Case[] = [
  {
    name: "app/mesh/index",
    Screen: MeshIndexScreen,
    title: "Mesh Network",
    emptyText: "0 live · 0 known",
    populatedText: "2 live · 2 known",
  },
  {
    name: "app/mesh/ble-discovery",
    Screen: BleDiscoveryScreen,
    title: "BLE Discovery",
    emptyText: "No BLE nodes discovered yet",
    populatedText: "Node-01",
  },
  {
    name: "app/mesh/peer-mapping",
    Screen: PeerMappingScreen,
    title: "Peer Mapping",
    emptyText: "No peers mapped yet",
    populatedText: "ONLINE",
  },
  {
    name: "app/mesh/signal-strength",
    Screen: SignalStrengthScreen,
    title: "Signal Strength",
    emptyText: "No live signal readings yet",
    populatedText: "Node-01",
  },
  {
    name: "app/mesh/store-forward-queue",
    Screen: StoreForwardQueueScreen,
    title: "Store-Forward Queue",
    emptyText: "store-forward queue is empty",
    populatedText: "Pending relays",
  },
  {
    name: "app/mesh/ack-tracking",
    Screen: AckTrackingScreen,
    title: "ACK Tracking",
    emptyText: "No acknowledgement paths yet",
    populatedText: "ACKED",
  },
  {
    name: "app/network/route-health",
    Screen: RouteHealthScreen,
    title: "Route Health",
    emptyText: "No routes to score yet",
    populatedText: "Node-01",
  },
];

describe("live mesh screens — empty state renders without crashing", () => {
  beforeEach(() => {
    mesh.state = emptyState();
  });

  for (const c of cases) {
    it(`${c.name} renders its title and honest empty state`, () => {
      let markup = "";
      expect(() => {
        markup = render(c.Screen);
      }).not.toThrow();
      expect(markup).toContain(c.title);
      expect(markup).toContain(c.emptyText);
      // Anti-tautology: the live-state marker must NOT appear when empty.
      expect(markup).not.toContain(c.populatedText);
    });
  }
});

describe("live mesh screens — populated state renders without crashing", () => {
  beforeEach(() => {
    mesh.state = populatedState();
  });

  for (const c of cases) {
    it(`${c.name} renders live peers/metrics`, () => {
      let markup = "";
      expect(() => {
        markup = render(c.Screen);
      }).not.toThrow();
      expect(markup).toContain(c.title);
      expect(markup).toContain(c.populatedText);
      // Anti-tautology: the empty-state marker must NOT appear when populated.
      expect(markup).not.toContain(c.emptyText);
    });
  }
});
