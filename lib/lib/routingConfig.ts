import AsyncStorage from "@react-native-async-storage/async-storage";
import {
  mauriMeshEngine,
  resolveRoutingConfig,
  isRoutingPreset,
  DEFAULT_ROUTING_PRESET,
  DEFAULT_ROUTING_CONFIG,
  RoutingPreset,
  RoutingEngineConfig,
} from "../mauri-mesh-engine/src/index";

const STORAGE_KEY = "maurimesh_routing_preset_v1";
const CUSTOM_KEY = "maurimesh_routing_custom_v1";

/**
 * The active routing "mode". Either one of the three quick-start presets or an
 * "Advanced (Custom)" mode in which the individual `RoutingEngineConfig`
 * dimensions are tuned by the user. Persisted under {@link STORAGE_KEY}.
 */
export type RoutingMode = RoutingPreset | "custom";

/**
 * What the device is configured to run: a named preset, or a custom partial
 * config. Custom always carries an explicit `config` so the stored overrides
 * can be fed straight back through the engine's `setConfig()` path.
 */
export type RoutingSelection =
  | { mode: RoutingPreset }
  | { mode: "custom"; config: Partial<RoutingEngineConfig> };

/**
 * UI metadata describing each tunable `RoutingEngineConfig` dimension that the
 * Advanced (Custom) mode exposes. Defaults are read live from
 * `DEFAULT_ROUTING_CONFIG` so the sliders/steppers always centre on whatever
 * the engine ships with. `scale`/`unit` are presentation-only (e.g. show a
 * millisecond field in seconds); the stored value stays in engine units.
 */
export type RoutingDimensionKey = keyof RoutingEngineConfig;

export type RoutingDimension = {
  key: RoutingDimensionKey;
  label: string;
  help: string;
  min: number;
  max: number;
  step: number;
  /** Divide the engine value by this for display (e.g. 1000 for ms -> s). */
  scale: number;
  /** Unit suffix shown after the scaled value. */
  unit: string;
};

export const ROUTING_DIMENSIONS: readonly RoutingDimension[] = [
  {
    key: "trustBlockThreshold",
    label: "Trust block threshold",
    help: "Quarantine a peer once its trust falls below this. Higher = reroute away from flaky peers sooner.",
    min: 5,
    max: 60,
    step: 5,
    scale: 1,
    unit: "",
  },
  {
    key: "peerBlockCooldownMs",
    label: "Peer block cooldown",
    help: "How long a quarantined peer stays blocked before the mesh retries it. Lower = retry sooner.",
    min: 5000,
    max: 120000,
    step: 5000,
    scale: 1000,
    unit: "s",
  },
  {
    key: "rehabTrust",
    label: "Rehab trust",
    help: "Trust a rehabilitated peer is restored to. It must re-earn standing through successful deliveries.",
    min: 5,
    max: 60,
    step: 5,
    scale: 1,
    unit: "",
  },
  {
    key: "congestionWindowMs",
    label: "Congestion window",
    help: "Sliding window over which recent relay load is counted for traffic shaping.",
    min: 1000,
    max: 30000,
    step: 1000,
    scale: 1000,
    unit: "s",
  },
  {
    key: "congestionPenaltyPerPacket",
    label: "Congestion penalty / packet",
    help: "Score penalty per recent packet a relay carried. Higher = spread load harder across peers.",
    min: 0,
    max: 20,
    step: 1,
    scale: 1,
    unit: "",
  },
  {
    key: "congestionMaxPenalty",
    label: "Max congestion penalty",
    help: "Upper bound on the congestion penalty so a strong relay is never fully starved.",
    min: 0,
    max: 60,
    step: 5,
    scale: 1,
    unit: "",
  },
];

function clamp(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, value));
}

/**
 * Keep only the known numeric dimensions, coerced to finite numbers and clamped
 * to each dimension's allowed range. Guards against malformed stored JSON and
 * stops unrelated keys from leaking into the engine config.
 */
export function sanitizeRoutingConfig(
  input: unknown
): Partial<RoutingEngineConfig> {
  const out: Partial<RoutingEngineConfig> = {};
  if (!input || typeof input !== "object") return out;
  const obj = input as Record<string, unknown>;
  for (const dim of ROUTING_DIMENSIONS) {
    const raw = obj[dim.key];
    if (typeof raw === "number" && Number.isFinite(raw)) {
      out[dim.key] = clamp(raw, dim.min, dim.max);
    }
  }
  return out;
}

/**
 * The full set of effective config values for a selection, with every
 * dimension resolved (defaults merged with the selection's overrides). Handy
 * for seeding the Advanced (Custom) editor from whatever is currently active.
 */
export function resolveSelectionValues(
  selection: RoutingSelection
): RoutingEngineConfig {
  const overrides =
    selection.mode === "custom"
      ? selection.config
      : resolveRoutingConfig(selection.mode);
  return { ...DEFAULT_ROUTING_CONFIG, ...overrides };
}

async function getStoredCustomConfig(): Promise<Partial<RoutingEngineConfig>> {
  try {
    const raw = await AsyncStorage.getItem(CUSTOM_KEY);
    if (!raw) return {};
    return sanitizeRoutingConfig(JSON.parse(raw));
  } catch {
    return {};
  }
}

/**
 * Read the persisted routing-sensitivity preset. Returns the default preset
 * when nothing is saved or the stored value is unrecognised, so behaviour is
 * unchanged for users who never touched the setting. Custom mode reports the
 * default preset here; use {@link getStoredRoutingSelection} for the full shape.
 */
export async function getStoredRoutingPreset(): Promise<RoutingPreset> {
  try {
    const raw = await AsyncStorage.getItem(STORAGE_KEY);
    return isRoutingPreset(raw) ? raw : DEFAULT_ROUTING_PRESET;
  } catch {
    return DEFAULT_ROUTING_PRESET;
  }
}

/**
 * Read the full persisted selection: a named preset, or custom mode with its
 * stored partial config. Falls back to the default preset when nothing is saved.
 */
export async function getStoredRoutingSelection(): Promise<RoutingSelection> {
  try {
    const raw = await AsyncStorage.getItem(STORAGE_KEY);
    if (raw === "custom") {
      return { mode: "custom", config: await getStoredCustomConfig() };
    }
    return { mode: isRoutingPreset(raw) ? raw : DEFAULT_ROUTING_PRESET };
  } catch {
    return { mode: DEFAULT_ROUTING_PRESET };
  }
}

export async function saveRoutingPreset(preset: RoutingPreset): Promise<void> {
  try {
    await AsyncStorage.setItem(STORAGE_KEY, preset);
  } catch {}
}

export async function clearStoredRoutingPreset(): Promise<void> {
  try {
    await AsyncStorage.removeItem(STORAGE_KEY);
    await AsyncStorage.removeItem(CUSTOM_KEY);
  } catch {}
}

/** Apply a preset to the shared engine immediately (without persisting it). */
export function applyRoutingPresetToEngine(preset: RoutingPreset): void {
  mauriMeshEngine.setConfig(resolveRoutingConfig(preset));
}

/** Apply any selection (preset or custom) to the shared engine immediately. */
export function applyRoutingSelectionToEngine(
  selection: RoutingSelection
): void {
  if (selection.mode === "custom") {
    mauriMeshEngine.setConfig(sanitizeRoutingConfig(selection.config));
  } else {
    applyRoutingPresetToEngine(selection.mode);
  }
}

/** Persist the chosen preset and apply it to the shared engine. */
export async function setRoutingPreset(preset: RoutingPreset): Promise<void> {
  applyRoutingPresetToEngine(preset);
  await saveRoutingPreset(preset);
}

/**
 * Persist a custom partial config (Advanced mode) and apply it to the shared
 * engine. The config is sanitised before both storing and applying so only the
 * known, in-range dimensions ever reach the engine.
 */
export async function setCustomRoutingConfig(
  config: Partial<RoutingEngineConfig>
): Promise<void> {
  const clean = sanitizeRoutingConfig(config);
  mauriMeshEngine.setConfig(clean);
  try {
    await AsyncStorage.setItem(STORAGE_KEY, "custom");
    await AsyncStorage.setItem(CUSTOM_KEY, JSON.stringify(clean));
  } catch {}
}

/**
 * Load the saved selection and apply it to the shared engine. Call once on app
 * startup so the persisted choice (preset or custom) survives restarts. Returns
 * the active mode.
 */
export async function initRoutingConfig(): Promise<RoutingMode> {
  const selection = await getStoredRoutingSelection();
  applyRoutingSelectionToEngine(selection);
  return selection.mode;
}
