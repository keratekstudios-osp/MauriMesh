import AsyncStorage from "@react-native-async-storage/async-storage";
import type { MeshNodeRecord, MeshTruthLevel } from "./types";

const STORAGE_KEY = "maurimesh.live.meshNodeRegistry.v1";

function nowIso(): string {
  return new Date().toISOString();
}

function stableNodeId(address?: string, name?: string): string {
  const raw = `${address || "unknown-address"}::${name || "unknown-name"}`;
  let hash = 0;
  for (let i = 0; i < raw.length; i += 1) {
    hash = (hash * 31 + raw.charCodeAt(i)) >>> 0;
  }
  return `node_${hash.toString(16)}`;
}

export async function loadMeshNodeRegistry(): Promise<MeshNodeRecord[]> {
  try {
    const raw = await AsyncStorage.getItem(STORAGE_KEY);
    if (!raw) return [];
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

export async function saveMeshNodeRegistry(nodes: MeshNodeRecord[]): Promise<void> {
  await AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(nodes.slice(0, 500)));
}

export async function clearMeshNodeRegistry(): Promise<void> {
  await AsyncStorage.removeItem(STORAGE_KEY);
}

export async function upsertBleScanNode(input: {
  address?: string;
  name?: string;
  rssi?: number;
  source: string;
  truthLevel?: MeshTruthLevel;
}): Promise<MeshNodeRecord[]> {
  const existing = await loadMeshNodeRegistry();

  const id = stableNodeId(input.address, input.name);
  const timestamp = nowIso();

  const current = existing.find((node) => node.id === id);

  const updated: MeshNodeRecord = current
    ? {
        ...current,
        label: input.name || current.label || "BLE device",
        address: input.address || current.address,
        name: input.name || current.name,
        lastSeenAt: timestamp,
        seenCount: current.seenCount + 1,
        lastRssi: input.rssi ?? current.lastRssi,
        transport: "BLE_SCAN",
        truthLevel: input.truthLevel || "physical_proof",
        source: input.source,
      }
    : {
        id,
        label: input.name || "BLE device",
        address: input.address,
        name: input.name,
        role: "candidate",
        firstSeenAt: timestamp,
        lastSeenAt: timestamp,
        seenCount: 1,
        lastRssi: input.rssi,
        transport: "BLE_SCAN",
        truthLevel: input.truthLevel || "physical_proof",
        source: input.source,
      };

  const without = existing.filter((node) => node.id !== id);
  const next = [updated, ...without].slice(0, 500);

  await saveMeshNodeRegistry(next);
  return next;
}
