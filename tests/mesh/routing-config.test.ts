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
  setRoutingPreset,
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
