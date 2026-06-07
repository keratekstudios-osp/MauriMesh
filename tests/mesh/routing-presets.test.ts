import { describe, it, expect } from "vitest";
import {
  ROUTING_PRESETS,
  DEFAULT_ROUTING_PRESET,
  isRoutingPreset,
  resolveRoutingConfig,
} from "../../lib/mauri-mesh-engine/src/routingPresets";
import { MauriMeshP2PEngine } from "../../lib/mauri-mesh-engine/src/mauriMeshP2PEngine";
import { DEFAULT_ROUTING_CONFIG } from "../../lib/mauri-mesh-engine/src/selfGovernanceRoutingEngine";

describe("routing presets", () => {
  it("exposes the three presets and a balanced default", () => {
    expect(Object.keys(ROUTING_PRESETS).sort()).toEqual([
      "aggressive",
      "balanced",
      "stable",
    ]);
    expect(DEFAULT_ROUTING_PRESET).toBe("balanced");
  });

  it("balanced carries no overrides so it reproduces engine defaults", () => {
    expect(resolveRoutingConfig("balanced")).toEqual({});
    const engine = new MauriMeshP2PEngine("local", resolveRoutingConfig("balanced"));
    expect(engine.getConfig()).toEqual(DEFAULT_ROUTING_CONFIG);
  });

  it("orders sensitivity along the reroute axis (stable < default < aggressive)", () => {
    const stable = resolveRoutingConfig("stable");
    const aggressive = resolveRoutingConfig("aggressive");
    expect(stable.trustBlockThreshold).toBeLessThan(
      DEFAULT_ROUTING_CONFIG.trustBlockThreshold
    );
    expect(aggressive.trustBlockThreshold).toBeGreaterThan(
      DEFAULT_ROUTING_CONFIG.trustBlockThreshold
    );
    expect(aggressive.peerBlockCooldownMs).toBeLessThan(
      DEFAULT_ROUTING_CONFIG.peerBlockCooldownMs
    );
  });

  it("validates preset names with the type guard", () => {
    expect(isRoutingPreset("aggressive")).toBe(true);
    expect(isRoutingPreset("balanced")).toBe(true);
    expect(isRoutingPreset("stable")).toBe(true);
    expect(isRoutingPreset("nope")).toBe(false);
    expect(isRoutingPreset(null)).toBe(false);
    expect(isRoutingPreset(undefined)).toBe(false);
  });
});

describe("MauriMeshP2PEngine.setConfig", () => {
  it("applies a preset's overrides to the live engine", () => {
    const engine = new MauriMeshP2PEngine("local");
    engine.setConfig(resolveRoutingConfig("aggressive"));
    expect(engine.getConfig().trustBlockThreshold).toBe(40);
    expect(engine.getConfig().peerBlockCooldownMs).toBe(1000 * 15);
  });

  it("restores defaults when switching back to balanced ({})", () => {
    const engine = new MauriMeshP2PEngine("local");
    engine.setConfig(resolveRoutingConfig("aggressive"));
    engine.setConfig(resolveRoutingConfig("balanced"));
    expect(engine.getConfig()).toEqual(DEFAULT_ROUTING_CONFIG);
  });
});
