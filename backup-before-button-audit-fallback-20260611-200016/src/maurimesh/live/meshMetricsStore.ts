import AsyncStorage from "@react-native-async-storage/async-storage";
import type { MeshMetricSnapshot } from "./types";

const STORAGE_KEY = "maurimesh.live.meshMetricSnapshots.v1";

export async function loadMeshMetricSnapshots(): Promise<MeshMetricSnapshot[]> {
  try {
    const raw = await AsyncStorage.getItem(STORAGE_KEY);
    if (!raw) return [];
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

export async function appendMeshMetricSnapshot(
  snapshot: MeshMetricSnapshot
): Promise<MeshMetricSnapshot[]> {
  const existing = await loadMeshMetricSnapshots();
  const next = [snapshot, ...existing].slice(0, 300);
  await AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(next));
  return next;
}

export async function clearMeshMetricSnapshots(): Promise<void> {
  await AsyncStorage.removeItem(STORAGE_KEY);
}
