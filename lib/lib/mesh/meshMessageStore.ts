import AsyncStorage from "@react-native-async-storage/async-storage";
import type { ChatMessage } from "../store/meshStore";

// ── Types ─────────────────────────────────────────────────────────────────────

export type StoredMeshMessage = {
  id: string;
  chatId: string;
  from: string;
  to: string;
  text: string;
  priority: string;
  hopCount?: number;
  timestamp: number;
  via: "maurimesh";
  status?: string;
};

// ── Storage key & limits ──────────────────────────────────────────────────────

const KEY = "maurimesh_messages_v1";
const MAX_STORED = 1000;

// ── Core CRUD ─────────────────────────────────────────────────────────────────

export async function loadMeshMessages(): Promise<StoredMeshMessage[]> {
  try {
    const raw = await AsyncStorage.getItem(KEY);
    return raw ? (JSON.parse(raw) as StoredMeshMessage[]) : [];
  } catch {
    return [];
  }
}

export async function saveMeshMessage(msg: StoredMeshMessage): Promise<void> {
  try {
    const current = await loadMeshMessages();
    if (current.some((m) => m.id === msg.id)) return;
    const updated = [msg, ...current].slice(0, MAX_STORED);
    await AsyncStorage.setItem(KEY, JSON.stringify(updated));
  } catch {
    // non-fatal — in-memory store still reflects the message
  }
}

export async function updateMeshMessageStatus(
  id: string,
  status: string
): Promise<void> {
  try {
    const current = await loadMeshMessages();
    const idx = current.findIndex((m) => m.id === id);
    if (idx === -1) return;
    current[idx] = { ...current[idx], status };
    await AsyncStorage.setItem(KEY, JSON.stringify(current));
  } catch {
    // non-fatal
  }
}

export async function saveMeshMessages(
  messages: StoredMeshMessage[]
): Promise<void> {
  try {
    await AsyncStorage.setItem(
      KEY,
      JSON.stringify(messages.slice(0, MAX_STORED))
    );
  } catch {
    // non-fatal
  }
}

export async function clearMeshMessages(): Promise<void> {
  await AsyncStorage.removeItem(KEY);
}

// ── Converters ────────────────────────────────────────────────────────────────

/**
 * Converts a persisted StoredMeshMessage back into a ChatMessage for the
 * Zustand store. `myNodeId` is needed to determine sender direction.
 */
export function storedToChatMessage(
  stored: StoredMeshMessage,
  myNodeId: string
): ChatMessage {
  const isMe = stored.from === myNodeId;
  const status = (stored.status ?? (isMe ? "sent" : "delivered")) as ChatMessage["status"];
  return {
    id: stored.id,
    text: stored.text,
    sender: isMe ? "me" : "other",
    senderId: isMe ? undefined : stored.from,
    timestamp: new Date(stored.timestamp).toLocaleTimeString([], {
      hour: "2-digit",
      minute: "2-digit",
    }),
    timeMs: stored.timestamp,
    status,
    transport: stored.via === "maurimesh" ? "bridge" : "ble",
    read: !isMe,
  };
}

/**
 * Converts a Zustand ChatMessage into the StoredMeshMessage shape so it can
 * be persisted. `myNodeId` fills in the `from` field for outbound messages.
 */
export function chatMessageToStored(
  msg: ChatMessage,
  myNodeId: string
): StoredMeshMessage {
  return {
    id: msg.id,
    chatId: msg.sender === "me" ? "BROADCAST" : (msg.senderId ?? "unknown"),
    from: msg.sender === "me" ? myNodeId : (msg.senderId ?? "unknown"),
    to: msg.sender === "me" ? "BROADCAST" : myNodeId,
    text: msg.text,
    priority: "NORMAL",
    hopCount: 1,
    timestamp: msg.timeMs,
    via: "maurimesh",
  };
}
