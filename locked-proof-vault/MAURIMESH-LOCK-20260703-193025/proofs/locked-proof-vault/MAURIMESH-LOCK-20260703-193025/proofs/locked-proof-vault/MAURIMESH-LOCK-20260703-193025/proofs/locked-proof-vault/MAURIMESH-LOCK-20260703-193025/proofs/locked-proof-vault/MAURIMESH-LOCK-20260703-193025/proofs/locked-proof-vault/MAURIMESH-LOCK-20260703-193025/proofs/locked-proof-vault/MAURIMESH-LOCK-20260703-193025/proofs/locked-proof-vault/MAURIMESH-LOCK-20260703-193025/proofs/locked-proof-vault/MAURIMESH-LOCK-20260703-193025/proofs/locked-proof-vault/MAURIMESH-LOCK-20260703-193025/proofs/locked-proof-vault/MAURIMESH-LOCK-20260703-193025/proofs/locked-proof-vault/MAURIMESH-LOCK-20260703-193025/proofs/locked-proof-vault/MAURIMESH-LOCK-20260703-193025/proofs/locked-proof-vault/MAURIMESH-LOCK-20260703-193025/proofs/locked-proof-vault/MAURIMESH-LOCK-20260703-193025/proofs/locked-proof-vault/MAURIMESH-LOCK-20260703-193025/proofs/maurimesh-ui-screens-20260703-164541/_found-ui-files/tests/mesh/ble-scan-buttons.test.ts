import { describe, it, expect, vi, beforeEach } from "vitest";
import React from "react";
import { renderToStaticMarkup } from "react-dom/server";
import type { LiveMeshState } from "../../src/maurimesh/live/types";

// Interaction-wiring coverage for app/mesh/ble-discovery.tsx — the only live
// mesh screen with action buttons. The render-smoke suite proves the screen
// renders; this suite proves the Start / Stop / Refresh buttons are actually
// wired to the useLiveMesh hook's startScan/stopScan/refresh actions, and that
// the button label/variant/disabled reflect scanActive + loading. We capture
// LiveButton's props during render (no event dispatcher needed) and assert the
// onPress identity + invoke it to confirm the hook action fires. Mocked — no
// live BLE.

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
  useRouter: () => ({ back: () => {}, push: () => {}, replace: () => {} }),
}));

// Capture every LiveButton's props as the screen renders.
type ButtonProps = {
  label: string;
  onPress: () => void;
  variant?: "primary" | "secondary" | "danger";
  disabled?: boolean;
};
const captured = vi.hoisted(() => ({ buttons: [] as ButtonProps[] }));

vi.mock("../../src/maurimesh/live/liveMeshUi", () => {
  const passthrough = (props: { children?: unknown }) =>
    (props?.children as never) ?? null;
  return {
    LiveScreen: passthrough,
    Card: passthrough,
    Line: () => null,
    Pill: () => null,
    StatRow: () => null,
    Bars: () => null,
    EmptyNote: () => null,
    LiveButton: (props: ButtonProps) => {
      captured.buttons.push(props);
      return null;
    },
    COLORS: {
      green: "#00D084",
      blue: "#4FC3F7",
      amber: "#F59E0B",
      red: "#FF4D5E",
      muted: "#64748B",
    },
  };
});

// Controlled hook state + spy actions returned by the mocked useLiveMesh.
const hook = vi.hoisted(() => ({
  state: null as unknown as LiveMeshState,
  loading: false,
  startScan: vi.fn(),
  stopScan: vi.fn(),
  refresh: vi.fn(),
}));

vi.mock("../../src/maurimesh/live/useLiveMesh", () => ({
  useLiveMesh: () => ({
    state: hook.state,
    loading: hook.loading,
    startScan: hook.startScan,
    stopScan: hook.stopScan,
    refresh: hook.refresh,
  }),
}));

import BleDiscoveryScreen from "../../app/mesh/ble-discovery";

function baseState(over: Partial<LiveMeshState> = {}): LiveMeshState {
  return {
    marker: "TEST",
    updatedAt: new Date(0).toISOString(),
    nativeModulePresent: false,
    permissionsGranted: false,
    scanActive: false,
    discoveredCount: 0,
    nodes: [],
    metrics: {
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
    },
    lastNativeStatus: {
      module: "MauriMeshBle",
      mode: "not_loaded",
      modulePresent: false,
      blePermissions: false,
      liveBleActive: false,
      scanActive: false,
      discoveredCount: 0,
    },
    truthBoundary: "No mesh delivery claim is made.",
    ...over,
  };
}

function renderScreen() {
  renderToStaticMarkup(React.createElement(BleDiscoveryScreen));
}

function byLabelIncludes(text: string): ButtonProps | undefined {
  return captured.buttons.find((b) => b.label.includes(text));
}

beforeEach(() => {
  captured.buttons.length = 0;
  hook.startScan.mockReset();
  hook.stopScan.mockReset();
  hook.refresh.mockReset();
  hook.loading = false;
  hook.state = baseState();
});

describe("ble-discovery buttons — idle (not scanning)", () => {
  beforeEach(() => {
    hook.state = baseState({ scanActive: false });
    renderScreen();
  });

  it("renders a primary Start button wired to startScan", () => {
    const start = byLabelIncludes("Start BLE Scan");
    expect(start).toBeDefined();
    expect(start?.variant).toBe("primary");
    expect(start?.disabled).toBe(false);
    expect(start?.onPress).toBe(hook.startScan);

    start?.onPress();
    expect(hook.startScan).toHaveBeenCalledTimes(1);
    expect(hook.stopScan).not.toHaveBeenCalled();
  });

  it("renders a Refresh button wired to refresh", () => {
    const refresh = byLabelIncludes("Refresh");
    expect(refresh).toBeDefined();
    expect(refresh?.variant).toBe("secondary");
    expect(refresh?.onPress).toBe(hook.refresh);

    refresh?.onPress();
    expect(hook.refresh).toHaveBeenCalledTimes(1);
  });
});

describe("ble-discovery buttons — scanning active", () => {
  beforeEach(() => {
    hook.state = baseState({ scanActive: true });
    renderScreen();
  });

  it("renders a danger Stop button wired to stopScan", () => {
    const stop = byLabelIncludes("Stop BLE Scan");
    expect(stop).toBeDefined();
    expect(stop?.variant).toBe("danger");
    expect(stop?.onPress).toBe(hook.stopScan);

    stop?.onPress();
    expect(hook.stopScan).toHaveBeenCalledTimes(1);
    expect(hook.startScan).not.toHaveBeenCalled();
  });
});

describe("ble-discovery buttons — loading while idle", () => {
  beforeEach(() => {
    hook.loading = true;
    hook.state = baseState({ scanActive: false });
    renderScreen();
  });

  it("shows Working… and disables both buttons; refresh stays secondary", () => {
    const working = byLabelIncludes("Working…");
    const refresh = byLabelIncludes("Refresh");
    expect(working).toBeDefined();
    expect(working?.disabled).toBe(true);
    expect(refresh?.disabled).toBe(true);
    expect(refresh?.variant).toBe("secondary");
  });
});

describe("ble-discovery buttons — loading while scanning active", () => {
  beforeEach(() => {
    hook.loading = true;
    hook.state = baseState({ scanActive: true });
    renderScreen();
  });

  it("keeps the action button danger + Working… + disabled, refresh disabled secondary", () => {
    const working = byLabelIncludes("Working…");
    const refresh = byLabelIncludes("Refresh");
    expect(working).toBeDefined();
    expect(working?.variant).toBe("danger");
    expect(working?.disabled).toBe(true);
    // Loading takes precedence over the Stop label, but the variant still
    // reflects scanActive (danger), and the handler is still stopScan.
    expect(working?.onPress).toBe(hook.stopScan);
    expect(refresh?.disabled).toBe(true);
    expect(refresh?.variant).toBe("secondary");
  });
});
