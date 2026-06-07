import type { RoutingEngineConfig } from "./types";

/**
 * User-facing "routing sensitivity" presets. Each preset maps to a
 * `Partial<RoutingEngineConfig>` that retunes the self-healing and
 * traffic-control layers of the AI routing engine. Missing fields are filled
 * from `DEFAULT_ROUTING_CONFIG` by the engine, so a preset only states the
 * dimensions it intends to change.
 *
 * The axis is "how aggressively the mesh reroutes": how quickly a flaky peer is
 * quarantined, how soon it is retried, and how hard busy relays are penalised.
 *
 * "balanced" intentionally carries NO overrides ({}), so it reproduces the
 * engine's built-in defaults exactly — existing users see no behaviour change.
 */
export type RoutingPreset = "stable" | "balanced" | "aggressive";

export const DEFAULT_ROUTING_PRESET: RoutingPreset = "balanced";

export const ROUTING_PRESETS: Record<
  RoutingPreset,
  {
    label: string;
    description: string;
    config: Partial<RoutingEngineConfig>;
  }
> = {
  stable: {
    label: "Stable",
    description:
      "Tolerant. Holds onto flaky peers longer and reroutes reluctantly — best for sparse or slow-changing meshes.",
    config: {
      trustBlockThreshold: 15,
      peerBlockCooldownMs: 1000 * 60,
      congestionPenaltyPerPacket: 3,
      congestionMaxPenalty: 18,
    },
  },
  balanced: {
    label: "Balanced",
    description:
      "The engine defaults. A sensible middle ground for most meshes.",
    config: {},
  },
  aggressive: {
    label: "Aggressive",
    description:
      "Reroutes fast. Quarantines flaky peers quickly, retries sooner, and spreads load hard — best for dense or noisy meshes.",
    config: {
      trustBlockThreshold: 40,
      peerBlockCooldownMs: 1000 * 15,
      congestionPenaltyPerPacket: 10,
      congestionMaxPenalty: 45,
    },
  },
};

export function isRoutingPreset(value: unknown): value is RoutingPreset {
  return value === "stable" || value === "balanced" || value === "aggressive";
}

/** Resolve a preset name to the partial config the engine should run with. */
export function resolveRoutingConfig(
  preset: RoutingPreset
): Partial<RoutingEngineConfig> {
  return { ...ROUTING_PRESETS[preset].config };
}
