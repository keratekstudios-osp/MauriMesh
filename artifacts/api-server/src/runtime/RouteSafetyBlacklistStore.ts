import fs from "fs";
import path from "path";

export const ROUTE_SAFETY_PERSISTENCE_SERVER_MARKER =
  "ROUTE_SAFETY_PERSISTENCE_SERVER_20260608_A";

export type ServerRouteBlacklistEntry = {
  routeKey: string;
  reason: string;
  failureCount: number;
  blacklistedAt: string;
  expiresAt: string;
  cooldownMs: number;
  source: string;
};

const STORE_DIR =
  process.env.MAURIMESH_RUNTIME_DIR ||
  path.join(process.cwd(), ".maurimesh-runtime");

const STORE_FILE = path.join(STORE_DIR, "route-safety-blacklist.jsonl");

function ensureStoreDir() {
  if (!fs.existsSync(STORE_DIR)) {
    fs.mkdirSync(STORE_DIR, { recursive: true });
  }
}

function parseTime(value: string): number {
  const parsed = Date.parse(value);
  return Number.isFinite(parsed) ? parsed : 0;
}

export async function loadActiveRouteBlacklistEntries(
  cooldownMs: number
): Promise<ServerRouteBlacklistEntry[]> {
  try {
    ensureStoreDir();

    if (!fs.existsSync(STORE_FILE)) return [];

    const now = Date.now();
    const latestByRoute = new Map<string, ServerRouteBlacklistEntry>();

    const lines = fs
      .readFileSync(STORE_FILE, "utf8")
      .split("\n")
      .map((line) => line.trim())
      .filter(Boolean);

    for (const line of lines) {
      try {
        const entry = JSON.parse(line) as ServerRouteBlacklistEntry;
        const blacklistedAt = parseTime(entry.blacklistedAt);
        const expiresAt = parseTime(entry.expiresAt);
        const ageMs = now - blacklistedAt;

        if (expiresAt > now && ageMs <= cooldownMs) {
          latestByRoute.set(entry.routeKey, entry);
        }
      } catch {
        // Skip malformed persisted line.
      }
    }

    return Array.from(latestByRoute.values());
  } catch {
    return [];
  }
}

export async function saveRouteBlacklistEntry(
  entry: ServerRouteBlacklistEntry
): Promise<void> {
  ensureStoreDir();
  fs.appendFileSync(STORE_FILE, JSON.stringify(entry) + "\n");
}

export function getRouteSafetyBlacklistStorePath(): string {
  ensureStoreDir();
  return STORE_FILE;
}
