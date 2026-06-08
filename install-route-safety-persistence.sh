#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "ROUTE SAFETY PERSISTENCE INSTALLER"
echo "Keeps blacklist protection alive across app/API restarts"
echo "Mobile: durable blacklist via AsyncStorage/SQLite-safe adapter"
echo "Server: durable blacklist via JSONL DB-safe fallback"
echo "Does NOT persist full seen-packet cache"
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$HOME/maurimesh-router-backups/route-safety-persistence-$STAMP"

MOBILE_GUARD="$ROOT/artifacts/messenger-mobile/lib/mesh/MeshRouteSafetyGuard.ts"
SERVER_ENGINE="$ROOT/artifacts/api-server/src/runtime/RouteSafetyEngine.ts"
DB_SCHEMA="$ROOT/lib/db/src/schema/mesh.ts"

MOBILE_DIR="$(dirname "$MOBILE_GUARD")"
SERVER_DIR="$(dirname "$SERVER_ENGINE")"
DB_DIR="$(dirname "$DB_SCHEMA")"

DOCS="$ROOT/docs"
SCRIPTS="$ROOT/scripts"

mkdir -p "$BACKUP" "$MOBILE_DIR" "$SERVER_DIR" "$DB_DIR" "$DOCS" "$SCRIPTS"

echo ""
echo "1. Backup current files"
cp "$MOBILE_GUARD" "$BACKUP/MeshRouteSafetyGuard.ts" 2>/dev/null || true
cp "$SERVER_ENGINE" "$BACKUP/RouteSafetyEngine.ts" 2>/dev/null || true
cp "$DB_SCHEMA" "$BACKUP/mesh.ts" 2>/dev/null || true
cp package.json "$BACKUP/package.json" 2>/dev/null || true

echo "Backup: $BACKUP"

echo ""
echo "2. Install mobile persistent blacklist store"

cat > "$MOBILE_DIR/MeshRouteSafetyBlacklistStore.ts" <<'TS'
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
TS

echo ""
echo "3. Patch or create mobile MeshRouteSafetyGuard"

if [ ! -f "$MOBILE_GUARD" ]; then
cat > "$MOBILE_GUARD" <<'TS'
import {
  loadActiveRouteBlacklistEntries,
  saveRouteBlacklistEntry,
} from "./MeshRouteSafetyBlacklistStore";

export const MESH_ROUTE_SAFETY_GUARD_MARKER =
  "MESH_ROUTE_SAFETY_GUARD_PERSISTENT_20260608_A";

export type RouteSafetyDecision =
  | { ok: true; reason: "accepted" }
  | { ok: false; reason: "blacklisted" | "ttl_expired" | "duplicate" | "malformed" };

type FailureRecord = {
  count: number;
  lastFailureAt: number;
  reason: string;
};

export class MeshRouteSafetyGuard {
  private seenPackets = new Set<string>();
  private failureCounts = new Map<string, FailureRecord>();
  private blacklistedRoutes = new Map<string, number>();
  private hydrated = false;

  constructor(
    private readonly options: {
      failureThreshold?: number;
      cooldownMs?: number;
      seenCacheLimit?: number;
    } = {}
  ) {}

  private get failureThreshold() {
    return this.options.failureThreshold ?? 3;
  }

  private get cooldownMs() {
    return this.options.cooldownMs ?? 10 * 60 * 1000;
  }

  private get seenCacheLimit() {
    return this.options.seenCacheLimit ?? 5000;
  }

  async init(): Promise<void> {
    if (this.hydrated) return;

    const entries = await loadActiveRouteBlacklistEntries(this.cooldownMs);
    const now = Date.now();

    for (const entry of entries) {
      const expiresAt = Date.parse(entry.expiresAt);
      if (Number.isFinite(expiresAt) && expiresAt > now) {
        this.blacklistedRoutes.set(entry.routeKey, expiresAt);
      }
    }

    this.hydrated = true;
  }

  async checkPacket(input: {
    packetId?: string;
    routeKey: string;
    ttl?: number;
    raw?: unknown;
  }): Promise<RouteSafetyDecision> {
    await this.init();

    const now = Date.now();
    const blacklistExpiry = this.blacklistedRoutes.get(input.routeKey);

    if (blacklistExpiry && blacklistExpiry > now) {
      return { ok: false, reason: "blacklisted" };
    }

    if (!input.routeKey || !input.raw) {
      await this.recordFailure(input.routeKey || "unknown", "malformed");
      return { ok: false, reason: "malformed" };
    }

    if (typeof input.ttl === "number" && input.ttl <= 0) {
      await this.recordFailure(input.routeKey, "ttl_expired");
      return { ok: false, reason: "ttl_expired" };
    }

    if (input.packetId && this.seenPackets.has(input.packetId)) {
      await this.recordFailure(input.routeKey, "duplicate");
      return { ok: false, reason: "duplicate" };
    }

    if (input.packetId) {
      this.seenPackets.add(input.packetId);
      this.trimSeenCache();
    }

    return { ok: true, reason: "accepted" };
  }

  async recordFailure(routeKey: string, reason: string): Promise<void> {
    await this.init();

    const key = routeKey || "unknown";
    const current = this.failureCounts.get(key) || {
      count: 0,
      lastFailureAt: 0,
      reason,
    };

    const next: FailureRecord = {
      count: current.count + 1,
      lastFailureAt: Date.now(),
      reason,
    };

    this.failureCounts.set(key, next);

    if (next.count >= this.failureThreshold) {
      const expiresAtMs = Date.now() + this.cooldownMs;
      this.blacklistedRoutes.set(key, expiresAtMs);

      await saveRouteBlacklistEntry({
        routeKey: key,
        reason,
        failureCount: next.count,
        blacklistedAt: new Date().toISOString(),
        expiresAt: new Date(expiresAtMs).toISOString(),
        cooldownMs: this.cooldownMs,
        source: MESH_ROUTE_SAFETY_GUARD_MARKER,
      });
    }
  }

  isBlacklisted(routeKey: string): boolean {
    const expiry = this.blacklistedRoutes.get(routeKey);
    return Boolean(expiry && expiry > Date.now());
  }

  getBlacklistSnapshot() {
    const now = Date.now();

    return Array.from(this.blacklistedRoutes.entries())
      .filter(([, expiresAt]) => expiresAt > now)
      .map(([routeKey, expiresAt]) => ({
        routeKey,
        expiresAt: new Date(expiresAt).toISOString(),
      }));
  }

  private trimSeenCache(): void {
    if (this.seenPackets.size <= this.seenCacheLimit) return;

    const keep = Array.from(this.seenPackets).slice(-this.seenCacheLimit);
    this.seenPackets = new Set(keep);
  }
}

export const meshRouteSafetyGuard = new MeshRouteSafetyGuard();
TS
else
python3 <<'PY'
from pathlib import Path
import re

path = Path("artifacts/messenger-mobile/lib/mesh/MeshRouteSafetyGuard.ts")
text = path.read_text()
original = text

if "MeshRouteSafetyBlacklistStore" not in text:
    text = '''import {
  loadActiveRouteBlacklistEntries,
  saveRouteBlacklistEntry,
} from "./MeshRouteSafetyBlacklistStore";
''' + text

if "ROUTE_SAFETY_PERSISTENCE_MOBILE_20260608_A" not in text:
    text += '''

export const ROUTE_SAFETY_PERSISTENCE_MOBILE_GUARD_PATCH =
  "ROUTE_SAFETY_PERSISTENCE_MOBILE_20260608_A";
'''

if "hydratePersistentBlacklist" not in text:
    insert = '''
  private routeSafetyPersistenceHydrated = false;

  async hydratePersistentBlacklist(cooldownMsOverride?: number): Promise<void> {
    if (this.routeSafetyPersistenceHydrated) return;

    const cooldownMs =
      cooldownMsOverride ??
      ((this as any).cooldownMs as number | undefined) ??
      ((this as any).options?.cooldownMs as number | undefined) ??
      10 * 60 * 1000;

    const entries = await loadActiveRouteBlacklistEntries(cooldownMs);
    const now = Date.now();

    for (const entry of entries) {
      const expiresAt = Date.parse(entry.expiresAt);
      if (!Number.isFinite(expiresAt) || expiresAt <= now) continue;

      const target =
        ((this as any).blacklistedRoutes as Map<string, number> | undefined) ||
        ((this as any).blacklist as Map<string, number> | undefined);

      if (target && typeof target.set === "function") {
        target.set(entry.routeKey, expiresAt);
      }
    }

    this.routeSafetyPersistenceHydrated = true;
  }

  async persistRouteBlacklistEntry(routeKey: string, reason: string, failureCount = 1): Promise<void> {
    const cooldownMs =
      ((this as any).cooldownMs as number | undefined) ??
      ((this as any).options?.cooldownMs as number | undefined) ??
      10 * 60 * 1000;

    const expiresAtMs = Date.now() + cooldownMs;

    await saveRouteBlacklistEntry({
      routeKey,
      reason,
      failureCount,
      blacklistedAt: new Date().toISOString(),
      expiresAt: new Date(expiresAtMs).toISOString(),
      cooldownMs,
      source: "ROUTE_SAFETY_PERSISTENCE_MOBILE_20260608_A",
    });
  }
'''
    class_match = re.search(r"class\s+MeshRouteSafetyGuard[^{]*\{", text)
    if class_match:
        text = text[:class_match.end()] + "\n" + insert + text[class_match.end():]
    else:
        text += "\n" + insert

if text != original:
    path.write_text(text)
    print("MeshRouteSafetyGuard patched with persistence helpers")
else:
    print("MeshRouteSafetyGuard already patched")
PY
fi

echo ""
echo "4. Install server persistent blacklist store"

cat > "$SERVER_DIR/RouteSafetyBlacklistStore.ts" <<'TS'
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
TS

echo ""
echo "5. Patch or create server RouteSafetyEngine"

if [ ! -f "$SERVER_ENGINE" ]; then
cat > "$SERVER_ENGINE" <<'TS'
import {
  loadActiveRouteBlacklistEntries,
  saveRouteBlacklistEntry,
} from "./RouteSafetyBlacklistStore";

export const ROUTE_SAFETY_ENGINE_MARKER =
  "ROUTE_SAFETY_ENGINE_PERSISTENT_20260608_A";

export type RouteSafetyDecision =
  | { ok: true; reason: "accepted" }
  | { ok: false; reason: "blacklisted" | "ttl_expired" | "duplicate" | "malformed" };

type FailureRecord = {
  count: number;
  lastFailureAt: number;
  reason: string;
};

export class RouteSafetyEngine {
  private seenPackets = new Set<string>();
  private failureCounts = new Map<string, FailureRecord>();
  private blacklistedRoutes = new Map<string, number>();
  private hydrated = false;

  constructor(
    private readonly options: {
      failureThreshold?: number;
      cooldownMs?: number;
      seenCacheLimit?: number;
    } = {}
  ) {}

  private get failureThreshold() {
    return this.options.failureThreshold ?? 3;
  }

  private get cooldownMs() {
    return this.options.cooldownMs ?? 10 * 60 * 1000;
  }

  private get seenCacheLimit() {
    return this.options.seenCacheLimit ?? 10000;
  }

  async init(): Promise<void> {
    if (this.hydrated) return;

    const entries = await loadActiveRouteBlacklistEntries(this.cooldownMs);
    const now = Date.now();

    for (const entry of entries) {
      const expiresAt = Date.parse(entry.expiresAt);
      if (Number.isFinite(expiresAt) && expiresAt > now) {
        this.blacklistedRoutes.set(entry.routeKey, expiresAt);
      }
    }

    this.hydrated = true;
  }

  async checkPacket(input: {
    packetId?: string;
    routeKey: string;
    ttl?: number;
    raw?: unknown;
  }): Promise<RouteSafetyDecision> {
    await this.init();

    const now = Date.now();
    const blacklistExpiry = this.blacklistedRoutes.get(input.routeKey);

    if (blacklistExpiry && blacklistExpiry > now) {
      return { ok: false, reason: "blacklisted" };
    }

    if (!input.routeKey || !input.raw) {
      await this.recordFailure(input.routeKey || "unknown", "malformed");
      return { ok: false, reason: "malformed" };
    }

    if (typeof input.ttl === "number" && input.ttl <= 0) {
      await this.recordFailure(input.routeKey, "ttl_expired");
      return { ok: false, reason: "ttl_expired" };
    }

    if (input.packetId && this.seenPackets.has(input.packetId)) {
      await this.recordFailure(input.routeKey, "duplicate");
      return { ok: false, reason: "duplicate" };
    }

    if (input.packetId) {
      this.seenPackets.add(input.packetId);
      this.trimSeenCache();
    }

    return { ok: true, reason: "accepted" };
  }

  async recordFailure(routeKey: string, reason: string): Promise<void> {
    await this.init();

    const key = routeKey || "unknown";
    const current = this.failureCounts.get(key) || {
      count: 0,
      lastFailureAt: 0,
      reason,
    };

    const next: FailureRecord = {
      count: current.count + 1,
      lastFailureAt: Date.now(),
      reason,
    };

    this.failureCounts.set(key, next);

    if (next.count >= this.failureThreshold) {
      const expiresAtMs = Date.now() + this.cooldownMs;
      this.blacklistedRoutes.set(key, expiresAtMs);

      await saveRouteBlacklistEntry({
        routeKey: key,
        reason,
        failureCount: next.count,
        blacklistedAt: new Date().toISOString(),
        expiresAt: new Date(expiresAtMs).toISOString(),
        cooldownMs: this.cooldownMs,
        source: ROUTE_SAFETY_ENGINE_MARKER,
      });
    }
  }

  isBlacklisted(routeKey: string): boolean {
    const expiry = this.blacklistedRoutes.get(routeKey);
    return Boolean(expiry && expiry > Date.now());
  }

  getBlacklistSnapshot() {
    const now = Date.now();

    return Array.from(this.blacklistedRoutes.entries())
      .filter(([, expiresAt]) => expiresAt > now)
      .map(([routeKey, expiresAt]) => ({
        routeKey,
        expiresAt: new Date(expiresAt).toISOString(),
      }));
  }

  private trimSeenCache(): void {
    if (this.seenPackets.size <= this.seenCacheLimit) return;

    const keep = Array.from(this.seenPackets).slice(-this.seenCacheLimit);
    this.seenPackets = new Set(keep);
  }
}

export const routeSafetyEngine = new RouteSafetyEngine();
TS
else
python3 <<'PY'
from pathlib import Path
import re

path = Path("artifacts/api-server/src/runtime/RouteSafetyEngine.ts")
text = path.read_text()
original = text

if "RouteSafetyBlacklistStore" not in text:
    text = '''import {
  loadActiveRouteBlacklistEntries,
  saveRouteBlacklistEntry,
} from "./RouteSafetyBlacklistStore";
''' + text

if "ROUTE_SAFETY_PERSISTENCE_SERVER_20260608_A" not in text:
    text += '''

export const ROUTE_SAFETY_PERSISTENCE_SERVER_ENGINE_PATCH =
  "ROUTE_SAFETY_PERSISTENCE_SERVER_20260608_A";
'''

if "hydratePersistentBlacklist" not in text:
    insert = '''
  private routeSafetyPersistenceHydrated = false;

  async hydratePersistentBlacklist(cooldownMsOverride?: number): Promise<void> {
    if (this.routeSafetyPersistenceHydrated) return;

    const cooldownMs =
      cooldownMsOverride ??
      ((this as any).cooldownMs as number | undefined) ??
      ((this as any).options?.cooldownMs as number | undefined) ??
      10 * 60 * 1000;

    const entries = await loadActiveRouteBlacklistEntries(cooldownMs);
    const now = Date.now();

    for (const entry of entries) {
      const expiresAt = Date.parse(entry.expiresAt);
      if (!Number.isFinite(expiresAt) || expiresAt <= now) continue;

      const target =
        ((this as any).blacklistedRoutes as Map<string, number> | undefined) ||
        ((this as any).blacklist as Map<string, number> | undefined);

      if (target && typeof target.set === "function") {
        target.set(entry.routeKey, expiresAt);
      }
    }

    this.routeSafetyPersistenceHydrated = true;
  }

  async persistRouteBlacklistEntry(routeKey: string, reason: string, failureCount = 1): Promise<void> {
    const cooldownMs =
      ((this as any).cooldownMs as number | undefined) ??
      ((this as any).options?.cooldownMs as number | undefined) ??
      10 * 60 * 1000;

    const expiresAtMs = Date.now() + cooldownMs;

    await saveRouteBlacklistEntry({
      routeKey,
      reason,
      failureCount,
      blacklistedAt: new Date().toISOString(),
      expiresAt: new Date(expiresAtMs).toISOString(),
      cooldownMs,
      source: "ROUTE_SAFETY_PERSISTENCE_SERVER_20260608_A",
    });
  }
'''
    class_match = re.search(r"class\s+RouteSafetyEngine[^{]*\{", text)
    if class_match:
        text = text[:class_match.end()] + "\n" + insert + text[class_match.end():]
    else:
        text += "\n" + insert

if text != original:
    path.write_text(text)
    print("RouteSafetyEngine patched with persistence helpers")
else:
    print("RouteSafetyEngine already patched")
PY
fi

echo ""
echo "6. Add Drizzle schema table if schema exists"

if [ -f "$DB_SCHEMA" ]; then
python3 <<'PY'
from pathlib import Path

path = Path("lib/db/src/schema/mesh.ts")
text = path.read_text()
original = text

if "routeSafetyBlacklist" not in text:
    if "sqliteTable" not in text:
        text = 'import { sqliteTable, text, integer } from "drizzle-orm/sqlite-core";\n' + text
    elif "integer" not in text.split("\n")[0:20].__str__():
        text = text.replace('from "drizzle-orm/sqlite-core";', ', integer } from "drizzle-orm/sqlite-core";')

    text += '''

export const routeSafetyBlacklist = sqliteTable("route_safety_blacklist", {
  id: text("id").primaryKey(),
  routeKey: text("route_key").notNull(),
  reason: text("reason").notNull(),
  failureCount: integer("failure_count").notNull().default(1),
  blacklistedAt: integer("blacklisted_at", { mode: "timestamp" }).notNull(),
  expiresAt: integer("expires_at", { mode: "timestamp" }).notNull(),
  source: text("source").notNull().default("ROUTE_SAFETY_PERSISTENCE_SERVER_20260608_A"),
});
'''

if text != original:
    path.write_text(text)
    print("DB schema patched with routeSafetyBlacklist")
else:
    print("DB schema already has routeSafetyBlacklist")
PY
else
  cat > "$DB_SCHEMA" <<'TS'
import { sqliteTable, text, integer } from "drizzle-orm/sqlite-core";

export const routeSafetyBlacklist = sqliteTable("route_safety_blacklist", {
  id: text("id").primaryKey(),
  routeKey: text("route_key").notNull(),
  reason: text("reason").notNull(),
  failureCount: integer("failure_count").notNull().default(1),
  blacklistedAt: integer("blacklisted_at", { mode: "timestamp" }).notNull(),
  expiresAt: integer("expires_at", { mode: "timestamp" }).notNull(),
  source: text("source").notNull().default("ROUTE_SAFETY_PERSISTENCE_SERVER_20260608_A"),
});
TS
fi

echo ""
echo "7. Create audit script"

cat > "$SCRIPTS/audit-route-safety-persistence.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo "ROUTE SAFETY PERSISTENCE AUDIT"
echo "============================================================"

echo ""
echo "1. Required mobile files"
test -f artifacts/messenger-mobile/lib/mesh/MeshRouteSafetyGuard.ts && echo "Mobile guard OK"
test -f artifacts/messenger-mobile/lib/mesh/MeshRouteSafetyBlacklistStore.ts && echo "Mobile blacklist store OK"

echo ""
echo "2. Required server files"
test -f artifacts/api-server/src/runtime/RouteSafetyEngine.ts && echo "Server engine OK"
test -f artifacts/api-server/src/runtime/RouteSafetyBlacklistStore.ts && echo "Server blacklist store OK"

echo ""
echo "3. Mobile persistence markers"
grep -RniE "ROUTE_SAFETY_PERSISTENCE_MOBILE|loadActiveRouteBlacklistEntries|saveRouteBlacklistEntry|hydratePersistentBlacklist|persistRouteBlacklistEntry" \
  artifacts/messenger-mobile/lib/mesh 2>/dev/null || true

echo ""
echo "4. Server persistence markers"
grep -RniE "ROUTE_SAFETY_PERSISTENCE_SERVER|loadActiveRouteBlacklistEntries|saveRouteBlacklistEntry|hydratePersistentBlacklist|persistRouteBlacklistEntry" \
  artifacts/api-server/src/runtime 2>/dev/null || true

echo ""
echo "5. DB schema"
grep -RniE "routeSafetyBlacklist|route_safety_blacklist" lib/db/src/schema 2>/dev/null || true

echo ""
echo "6. Seen-cache persistence check"
grep -RniE "seenPackets|seenCache|duplicate" artifacts/messenger-mobile/lib/mesh artifacts/api-server/src/runtime 2>/dev/null || true
echo ""
echo "PASS condition: seen cache may exist in memory, but no separate persisted seen-packet table/store should exist."

echo ""
echo "============================================================"
echo "AUDIT COMPLETE"
echo "============================================================"
SH

chmod +x "$SCRIPTS/audit-route-safety-persistence.sh"

echo ""
echo "8. Create docs"

cat > "$DOCS/route-safety-persistence-20260608.md" <<'MD'
# Route Safety Persistence

Marker:
- `ROUTE_SAFETY_PERSISTENCE_MOBILE_20260608_A`
- `ROUTE_SAFETY_PERSISTENCE_SERVER_20260608_A`

## Goal

Keep route safety protection alive across mobile/API restarts.

## What persists

Persistent:
- active blacklist entries
- route key
- reason
- failure count
- blacklist time
- expiry time

Not persisted:
- full seen-packet cache
- duplicate packet cache

The seen-packet cache stays memory-only because it can grow too large.

## Mobile

Files:
- `artifacts/messenger-mobile/lib/mesh/MeshRouteSafetyGuard.ts`
- `artifacts/messenger-mobile/lib/mesh/MeshRouteSafetyBlacklistStore.ts`

Uses AsyncStorage-compatible persistence. This can be swapped to SQLite later without changing the guard contract.

## Server

Files:
- `artifacts/api-server/src/runtime/RouteSafetyEngine.ts`
- `artifacts/api-server/src/runtime/RouteSafetyBlacklistStore.ts`
- `lib/db/src/schema/mesh.ts`

The runtime store uses a DB-safe JSONL fallback and adds a Drizzle schema table for the dedicated DB path.

## Completion proof

1. Force route failure until blacklist threshold is crossed.
2. Confirm route is blocked.
3. Restart mobile app or API server.
4. Confirm route remains blocked until cooldown expires.
5. Confirm duplicate seen-cache does not persist across restart.
MD

echo ""
echo "9. Validate markers"

grep -RniE "ROUTE_SAFETY_PERSISTENCE|routeSafetyBlacklist|route_safety_blacklist|MeshRouteSafetyBlacklistStore|RouteSafetyBlacklistStore" \
  artifacts lib docs scripts 2>/dev/null || true

echo ""
echo "10. TypeScript check"
npx tsc --noEmit

echo ""
echo "11. Expo export check"
rm -rf dist .expo
npx expo export --platform android --clear

echo ""
echo "12. Run audit"
bash "$SCRIPTS/audit-route-safety-persistence.sh"

echo ""
echo "============================================================"
echo "ROUTE SAFETY PERSISTENCE INSTALLED"
echo "Backup: $BACKUP"
echo ""
echo "Truth boundary:"
echo "- Durable blacklist persistence installed."
echo "- Full seen-packet cache remains memory-only."
echo "- Completion still requires restart proof."
echo "============================================================"
