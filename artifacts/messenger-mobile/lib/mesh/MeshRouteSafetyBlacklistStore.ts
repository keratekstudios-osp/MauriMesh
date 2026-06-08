import AsyncStorage from "@react-native-async-storage/async-storage";

export const ROUTE_SAFETY_PERSISTENCE_MOBILE_MARKER =
  "ROUTE_SAFETY_PERSISTENCE_MOBILE_20260608_A";

export type PersistedRouteBlacklistEntry = {
  routeKey: string;
  reason: string;
  failureCount: number;
  blacklistedAt: string;
  expiresAt: string;
  cooldownMs: number;
  source: string;
};

const STORAGE_KEY = "maurimesh.routeSafety.blacklist.v1";

function nowMs(): number {
  return Date.now();
}

function parseTime(value: string): number {
  const parsed = Date.parse(value);
  return Number.isFinite(parsed) ? parsed : 0;
}

export async function loadActiveRouteBlacklistEntries(
  cooldownMs: number
): Promise<PersistedRouteBlacklistEntry[]> {
  try {
    const raw = await AsyncStorage.getItem(STORAGE_KEY);
    if (!raw) return [];

    const parsed = JSON.parse(raw);
    const entries: PersistedRouteBlacklistEntry[] = Array.isArray(parsed) ? parsed : [];
    const current = nowMs();

    const active = entries.filter((entry) => {
      const expiresAt = parseTime(entry.expiresAt);
      const blacklistedAt = parseTime(entry.blacklistedAt);
      const ageMs = current - blacklistedAt;

      return expiresAt > current && ageMs <= cooldownMs;
    });

    if (active.length !== entries.length) {
      await AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(active));
    }

    return active;
  } catch {
    return [];
  }
}

export async function saveRouteBlacklistEntry(
  entry: PersistedRouteBlacklistEntry
): Promise<void> {
  const existing = await loadActiveRouteBlacklistEntries(entry.cooldownMs);
  const without = existing.filter((item) => item.routeKey !== entry.routeKey);
  const next = [entry, ...without].slice(0, 1000);
  await AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(next));
}

export async function clearRouteBlacklistStore(): Promise<void> {
  await AsyncStorage.removeItem(STORAGE_KEY);
}
