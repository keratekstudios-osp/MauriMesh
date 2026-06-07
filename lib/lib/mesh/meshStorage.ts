/**
 * meshStorage — AsyncStorage persistence layer for MauriMesh.
 *
 * Stores:
 *   - Received messages (inbox)
 *   - Outbound queue (packets waiting for BLE)
 *   - Seen packet IDs (dedup)
 *   - Known peer node IDs
 *   - Device node ID (delegated to deviceIdentity.ts)
 */

import AsyncStorage from "@react-native-async-storage/async-storage";
import type { MeshPacket } from "./maurimesh-intelligent-contract";

const KEYS = {
  INBOX:    "@maurimesh/inbox",
  QUEUE:    "@maurimesh/queue",
  SEEN_IDS: "@maurimesh/seenIds",
  PEERS:    "@maurimesh/peers",
} as const;

const MAX_INBOX   = 500;
const MAX_QUEUE   = 500;
const MAX_SEEN    = 2000;
const SEEN_TTL_MS = 10 * 60 * 1000; // 10 minutes

// ── Inbox ─────────────────────────────────────────────────────────────────────

export interface StoredMessage {
  id: string;
  fromNodeId: string;
  toNodeId: string;
  payload: string;
  timestamp: number;
  transport: "ble" | "bridge";
}

export async function loadInbox(): Promise<StoredMessage[]> {
  try {
    const raw = await AsyncStorage.getItem(KEYS.INBOX);
    return raw ? (JSON.parse(raw) as StoredMessage[]) : [];
  } catch {
    return [];
  }
}

export async function appendToInbox(msg: StoredMessage): Promise<void> {
  try {
    const existing = await loadInbox();
    if (existing.some((m) => m.id === msg.id)) return;
    const updated = [msg, ...existing].slice(0, MAX_INBOX);
    await AsyncStorage.setItem(KEYS.INBOX, JSON.stringify(updated));
  } catch {
    // non-fatal
  }
}

export async function clearInbox(): Promise<void> {
  await AsyncStorage.removeItem(KEYS.INBOX);
}

// ── Outbound queue ────────────────────────────────────────────────────────────

export async function loadQueue(): Promise<MeshPacket[]> {
  try {
    const raw = await AsyncStorage.getItem(KEYS.QUEUE);
    return raw ? (JSON.parse(raw) as MeshPacket[]) : [];
  } catch {
    return [];
  }
}

export async function saveQueue(packets: MeshPacket[]): Promise<void> {
  try {
    await AsyncStorage.setItem(
      KEYS.QUEUE,
      JSON.stringify(packets.slice(0, MAX_QUEUE))
    );
  } catch {
    // non-fatal
  }
}

export async function clearQueue(): Promise<void> {
  await AsyncStorage.removeItem(KEYS.QUEUE);
}

// ── Seen IDs (dedup) ──────────────────────────────────────────────────────────

interface SeenEntry { id: string; seenAt: number }

export async function loadSeenIds(): Promise<SeenEntry[]> {
  try {
    const raw = await AsyncStorage.getItem(KEYS.SEEN_IDS);
    return raw ? (JSON.parse(raw) as SeenEntry[]) : [];
  } catch {
    return [];
  }
}

export async function markIdSeen(id: string): Promise<void> {
  try {
    const existing = await loadSeenIds();
    if (existing.some((e) => e.id === id)) return;
    const now = Date.now();
    const pruned = existing
      .filter((e) => now - e.seenAt < SEEN_TTL_MS)
      .slice(0, MAX_SEEN - 1);
    await AsyncStorage.setItem(
      KEYS.SEEN_IDS,
      JSON.stringify([{ id, seenAt: now }, ...pruned])
    );
  } catch {
    // non-fatal
  }
}

export async function isIdSeen(id: string): Promise<boolean> {
  const entries = await loadSeenIds();
  const now = Date.now();
  return entries.some((e) => e.id === id && now - e.seenAt < SEEN_TTL_MS);
}

// ── Known peers ───────────────────────────────────────────────────────────────

export interface StoredPeer {
  nodeId: string;
  displayName?: string;
  lastSeen: number;
  rssi?: number;
}

export async function loadPeers(): Promise<StoredPeer[]> {
  try {
    const raw = await AsyncStorage.getItem(KEYS.PEERS);
    return raw ? (JSON.parse(raw) as StoredPeer[]) : [];
  } catch {
    return [];
  }
}

export async function upsertPeer(peer: StoredPeer): Promise<void> {
  try {
    const existing = await loadPeers();
    const filtered = existing.filter((p) => p.nodeId !== peer.nodeId);
    await AsyncStorage.setItem(
      KEYS.PEERS,
      JSON.stringify([peer, ...filtered].slice(0, 100))
    );
  } catch {
    // non-fatal
  }
}
