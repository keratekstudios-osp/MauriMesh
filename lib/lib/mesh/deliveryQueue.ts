/**
 * deliveryQueue — persistent retry queue for outbound MauriMesh messages.
 *
 * Each entry tracks the message id, the text + destination needed to
 * reconstruct a MeshPacket, a retry counter, exponential next-retry time,
 * and a TTL so stale entries expire automatically.
 *
 * Max retries : 12
 * Backoff     : 2^retryCount * 1 s, capped at 5 min
 * TTL         : 48 h from creation
 */

import AsyncStorage from "@react-native-async-storage/async-storage";

const KEY = "@maurimesh/delivery_queue_v1";

export const MAX_RETRIES = 12;
const MAX_ENTRIES = 200;
const BASE_BACKOFF_MS = 1_000;
const MAX_BACKOFF_MS = 5 * 60 * 1_000;
const DEFAULT_TTL_MS = 48 * 60 * 60 * 1_000;

export interface DeliveryQueueEntry {
  id: string;
  packetId: string;
  text: string;
  toNode: string;
  fromNode: string;
  retryCount: number;
  nextRetryAt: number;
  expiresAt: number;
  createdAt: number;
}

async function _persist(entries: DeliveryQueueEntry[]): Promise<void> {
  try {
    await AsyncStorage.setItem(KEY, JSON.stringify(entries.slice(0, MAX_ENTRIES)));
  } catch {
    // non-fatal
  }
}

export async function loadDeliveryQueue(): Promise<DeliveryQueueEntry[]> {
  try {
    const raw = await AsyncStorage.getItem(KEY);
    const all: DeliveryQueueEntry[] = raw ? (JSON.parse(raw) as DeliveryQueueEntry[]) : [];
    const now = Date.now();
    return all.filter((e) => e.retryCount < MAX_RETRIES && e.expiresAt > now);
  } catch {
    return [];
  }
}

export async function enqueueForDelivery(
  entry: Omit<DeliveryQueueEntry, "retryCount" | "nextRetryAt" | "expiresAt" | "createdAt">
): Promise<void> {
  const queue = await loadDeliveryQueue();
  if (queue.some((e) => e.id === entry.id)) return;
  const now = Date.now();
  const newEntry: DeliveryQueueEntry = {
    ...entry,
    retryCount: 0,
    nextRetryAt: now + BASE_BACKOFF_MS,
    expiresAt: now + DEFAULT_TTL_MS,
    createdAt: now,
  };
  await _persist([...queue, newEntry]);
  console.log(`[MauriMesh][Queue] enqueued id=${entry.id} toNode=${entry.toNode}`);
}

export async function getRetryable(): Promise<DeliveryQueueEntry[]> {
  const queue = await loadDeliveryQueue();
  const now = Date.now();
  return queue.filter((e) => e.nextRetryAt <= now);
}

export async function markRetried(id: string): Promise<void> {
  const queue = await loadDeliveryQueue();
  const updated = queue.map((e) => {
    if (e.id !== id) return e;
    const retryCount = e.retryCount + 1;
    const backoff = Math.min(BASE_BACKOFF_MS * Math.pow(2, retryCount), MAX_BACKOFF_MS);
    console.log(`[MauriMesh][Queue] retry ${retryCount}/${MAX_RETRIES} id=${id} next=${backoff}ms`);
    return { ...e, retryCount, nextRetryAt: Date.now() + backoff };
  });
  await _persist(updated);
}

export async function removeFromDeliveryQueue(id: string): Promise<void> {
  const queue = await loadDeliveryQueue();
  const next = queue.filter((e) => e.id !== id);
  if (next.length !== queue.length) {
    await _persist(next);
    console.log(`[MauriMesh][Queue] removed id=${id}`);
  }
}

export async function clearDeliveryQueue(): Promise<void> {
  await AsyncStorage.removeItem(KEY);
}
