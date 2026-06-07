import { describe, it, expect, beforeEach, vi } from "vitest";

// In-memory AsyncStorage stand-in. Hoisted so the vi.mock factory can close
// over it safely (vi.mock is lifted above the imports below).
const { store } = vi.hoisted(() => ({ store: new Map<string, string>() }));

vi.mock("@react-native-async-storage/async-storage", () => ({
  default: {
    getItem: async (k: string) => (store.has(k) ? store.get(k)! : null),
    setItem: async (k: string, v: string) => {
      store.set(k, v);
    },
    removeItem: async (k: string) => {
      store.delete(k);
    },
  },
}));

import {
  getStoredRoutingPreset,
  getStoredRoutingSelection,
  setRoutingPreset,
  setCustomRoutingConfig,
  sanitizeRoutingConfig,
  resolveSelectionValues,
  ROUTING_DIMENSIONS,
  initRoutingConfig,
} from "../../lib/lib/routingConfig";
import { mauriMeshEngine } from "../../lib/mauri-mesh-engine/src/index";
import { DEFAULT_ROUTING_CONFIG } from "../../lib/mauri-mesh-engine/src/selfGovernanceRoutingEngine";

beforeEach(() => {
  store.clear();
  mauriMeshEngine.setConfig({});
});

describe("routingConfig persistence", () => {
  it("defaults to balanced when nothing is stored", async () => {
    expect(await getStoredRoutingPreset()).toBe("balanced");
  });

  it("falls back to defaults on an unrecognised stored value", async () => {
    store.set("maurimesh_routing_preset_v1", "garbage");
    expect(await getStoredRoutingPreset()).toBe("balanced");
  });

  it("persists the chosen preset and re-applies it at startup", async () => {
    await setRoutingPreset("aggressive");

    // Simulate a fresh boot: engine back to defaults, then init from storage.
    mauriMeshEngine.setConfig({});
    expect(mauriMeshEngine.getConfig()).toEqual(DEFAULT_ROUTING_CONFIG);

    const applied = await initRoutingConfig();
    expect(applied).toBe("aggressive");
    expect(mauriMeshEngine.getConfig().trustBlockThreshold).toBe(40);
  });
});

describe("custom routing config", () => {
  it("sanitizes to the known dimensions and clamps out-of-range values", () => {
    const clean = sanitizeRoutingConfig({
      trustBlockThreshold: 999, // above max -> clamped
      rehabTrust: -10, // below min -> clamped
      congestionPenaltyPerPacket: 4,
      bogusKey: 5, // dropped
      peerBlockCooldownMs: "nope", // non-number -> dropped
    });
    expect(clean.trustBlockThreshold).toBe(60);
    expect(clean.rehabTrust).toBe(5);
    expect(clean.congestionPenaltyPerPacket).toBe(4);
    expect("bogusKey" in clean).toBe(false);
    expect("peerBlockCooldownMs" in clean).toBe(false);
  });

  it("persists a custom config, applies it, and survives a restart", async () => {
    await setCustomRoutingConfig({
      trustBlockThreshold: 50,
      congestionMaxPenalty: 55,
    });
    expect(mauriMeshEngine.getConfig().trustBlockThreshold).toBe(50);
    expect(mauriMeshEngine.getConfig().congestionMaxPenalty).toBe(55);

    // getStoredRoutingPreset stays backward-compatible for custom mode.
    expect(await getStoredRoutingPreset()).toBe("balanced");

    const selection = await getStoredRoutingSelection();
    expect(selection.mode).toBe("custom");
    if (selection.mode === "custom") {
      expect(selection.config.trustBlockThreshold).toBe(50);
    }

    // Simulate a fresh boot.
    mauriMeshEngine.setConfig({});
    const applied = await initRoutingConfig();
    expect(applied).toBe("custom");
    expect(mauriMeshEngine.getConfig().trustBlockThreshold).toBe(50);
    expect(mauriMeshEngine.getConfig().congestionMaxPenalty).toBe(55);
  });

  it("resolveSelectionValues fills every dimension from defaults", () => {
    const values = resolveSelectionValues({
      mode: "custom",
      config: { trustBlockThreshold: 42 },
    });
    expect(values.trustBlockThreshold).toBe(42);
    for (const dim of ROUTING_DIMENSIONS) {
      expect(typeof values[dim.key]).toBe("number");
    }
    expect(values.rehabTrust).toBe(DEFAULT_ROUTING_CONFIG.rehabTrust);
  });
});
