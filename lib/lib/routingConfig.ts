import AsyncStorage from "@react-native-async-storage/async-storage";
import {
  mauriMeshEngine,
  resolveRoutingConfig,
  isRoutingPreset,
  DEFAULT_ROUTING_PRESET,
  RoutingPreset,
} from "../mauri-mesh-engine/src/index";

const STORAGE_KEY = "maurimesh_routing_preset_v1";

/**
 * Read the persisted routing-sensitivity preset. Returns the default preset
 * when nothing is saved or the stored value is unrecognised, so behaviour is
 * unchanged for users who never touched the setting.
 */
export async function getStoredRoutingPreset(): Promise<RoutingPreset> {
  try {
    const raw = await AsyncStorage.getItem(STORAGE_KEY);
    return isRoutingPreset(raw) ? raw : DEFAULT_ROUTING_PRESET;
  } catch {
    return DEFAULT_ROUTING_PRESET;
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
  } catch {}
}

/** Apply a preset to the shared engine immediately (without persisting it). */
export function applyRoutingPresetToEngine(preset: RoutingPreset): void {
  mauriMeshEngine.setConfig(resolveRoutingConfig(preset));
}

/** Persist the chosen preset and apply it to the shared engine. */
export async function setRoutingPreset(preset: RoutingPreset): Promise<void> {
  applyRoutingPresetToEngine(preset);
  await saveRoutingPreset(preset);
}

/**
 * Load the saved preset and apply it to the shared engine. Call once on app
 * startup so the persisted choice survives restarts.
 */
export async function initRoutingConfig(): Promise<RoutingPreset> {
  const preset = await getStoredRoutingPreset();
  applyRoutingPresetToEngine(preset);
  return preset;
}
