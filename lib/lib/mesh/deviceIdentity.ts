import AsyncStorage from "@react-native-async-storage/async-storage";

const NODE_ID_KEY = "@maurimesh/nodeId";
const NODE_NAME_KEY = "@maurimesh/nodeName";

let _cachedNodeId: string | null = null;

/**
 * Return the persistent node ID, creating and storing it on first call.
 * The same ID is reused for the lifetime of the installation.
 */
export async function getOrCreateNodeId(): Promise<string> {
  if (_cachedNodeId) return _cachedNodeId;

  const stored = await AsyncStorage.getItem(NODE_ID_KEY);
  if (stored) {
    _cachedNodeId = stored;
    return stored;
  }

  const id = generateNodeId();
  await AsyncStorage.setItem(NODE_ID_KEY, id);
  _cachedNodeId = id;
  return id;
}

/**
 * Return a human-readable display name derived from the node ID.
 * Stored so it stays consistent across launches.
 */
export async function getNodeDisplayName(): Promise<string> {
  const stored = await AsyncStorage.getItem(NODE_NAME_KEY);
  if (stored) return stored;

  const nodeId = await getOrCreateNodeId();
  const suffix = nodeId.slice(-5).toUpperCase();
  const name = `MeshNode-${suffix}`;
  await AsyncStorage.setItem(NODE_NAME_KEY, name);
  return name;
}

/**
 * Override the display name (used by settings screen).
 */
export async function setNodeDisplayName(name: string): Promise<void> {
  await AsyncStorage.setItem(NODE_NAME_KEY, name.trim().slice(0, 32));
}

// ── Internal ──────────────────────────────────────────────────────────────────

function generateNodeId(): string {
  const ts = Date.now().toString(36);
  const rand = Math.random().toString(36).slice(2, 10);
  return `mm-${ts}-${rand}`;
}
