#!/usr/bin/env bash
set -euo pipefail

mkdir -p src/proof

cat > src/proof/ProofSession.ts <<'TS'
import AsyncStorage from "@react-native-async-storage/async-storage";

export type ProofPhoneRole = "PHONE_A" | "PHONE_B" | "PHONE_C";

export type ProofSession = {
  packetId: string;
  startedAt: string;
  updatedAt: string;
  phase:
    | "CREATED"
    | "BLE_SCAN_PREFLIGHT"
    | "GATT_EXAM"
    | "DIRECTIONAL_RELAY"
    | "VAULT_HEALTH"
    | "READY_FOR_LOGCAT_VERIFY";
  roles: {
    PHONE_A: string;
    PHONE_B: string;
    PHONE_C: string;
  };
  completedStages: string[];
  blockedEvents: number;
  nativeVerified: boolean;
  checksum: string;
};

const KEY = "maurimesh_current_proof_session";

export function makePacketId(prefix = "MMN-DIRECT"): string {
  const rand = Math.random().toString(36).slice(2, 8).toUpperCase();
  return `${prefix}-${Date.now().toString(36).toUpperCase()}-${rand}`;
}

export function simpleChecksum(text: string): string {
  let hash = 2166136261;
  for (let i = 0; i < text.length; i += 1) {
    hash ^= text.charCodeAt(i);
    hash = Math.imul(hash, 16777619);
  }
  return (hash >>> 0).toString(16).padStart(8, "0").toUpperCase();
}

export function withChecksum(session: Omit<ProofSession, "checksum">): ProofSession {
  return {
    ...session,
    checksum: simpleChecksum(JSON.stringify(session)),
  };
}

export async function createProofSession(packetId = makePacketId()): Promise<ProofSession> {
  const base = {
    packetId,
    startedAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
    phase: "CREATED" as const,
    roles: {
      PHONE_A: "A06 / SENDER",
      PHONE_B: "S10 / RELAY",
      PHONE_C: "A16 / RECEIVER",
    },
    completedStages: [],
    blockedEvents: 0,
    nativeVerified: false,
  };
  const session = withChecksum(base);
  await AsyncStorage.setItem(KEY, JSON.stringify(session));
  return session;
}

export async function getProofSession(): Promise<ProofSession> {
  const raw = await AsyncStorage.getItem(KEY);
  if (!raw) return createProofSession("MMN-DIRECT1-RELAY01");
  return JSON.parse(raw) as ProofSession;
}

export async function updateProofSession(
  patch: Partial<Omit<ProofSession, "checksum">>
): Promise<ProofSession> {
  const current = await getProofSession();
  const nextBase = {
    ...current,
    ...patch,
    updatedAt: new Date().toISOString(),
  };
  const { checksum: _old, ...withoutChecksum } = nextBase;
  const next = withChecksum(withoutChecksum);
  await AsyncStorage.setItem(KEY, JSON.stringify(next));
  return next;
}

export async function addProofStage(stage: string): Promise<ProofSession> {
  const current = await getProofSession();
  const completedStages = Array.from(new Set([...current.completedStages, stage]));
  return updateProofSession({ completedStages });
}

export async function addBlockedEvent(): Promise<ProofSession> {
  const current = await getProofSession();
  return updateProofSession({ blockedEvents: current.blockedEvents + 1 });
}

export async function resetProofSession(): Promise<ProofSession> {
  await AsyncStorage.removeItem(KEY);
  return createProofSession("MMN-DIRECT1-RELAY01");
}
TS

python3 <<'PY'
from pathlib import Path

# Patch proof vault packet parser to recognize native MMN packets.
for p in Path("app").glob("*proof-vault-health*.tsx"):
    s = p.read_text()
    old = r'MM3-[A-Z0-9]+-[A-Z0-9]+|MMSF-[A-Z0-9]+-[A-Z0-9]+|MM-[A-Z0-9]+-[A-Z0-9]+'
    new = r'MMN-[A-Z0-9-]+|MM3-[A-Z0-9]+-[A-Z0-9]+|MMSF-[A-Z0-9]+-[A-Z0-9]+|MM-[A-Z0-9]+-[A-Z0-9]+'
    if old in s and 'MMN-[A-Z0-9-]+' not in s:
        s = s.replace(old, new)
        p.write_text(s)
        print(f"PATCHED_NATIVE_PACKET_PARSER {p}")

# Add dashboard links if dashboard exists.
p = Path("app/dashboard.tsx")
if p.exists():
    s = p.read_text()
    inserts = [
        ('/native-ble-scan-proof', '<MauriButton title="BLE Scan Proof" onPress={() => router.push("/native-ble-scan-proof")} />'),
        ('/native-gatt-exam-guide', '<MauriButton title="GATT Exam Guide" onPress={() => router.push("/native-gatt-exam-guide")} />'),
        ('/native-gatt-directional-relay-proof', '<MauriButton title="Directional GATT Relay" onPress={() => router.push("/native-gatt-directional-relay-proof")} />'),
        ('/proof-vault-health', '<MauriButton title="Proof Vault Health" onPress={() => router.push("/proof-vault-health")} />'),
    ]
    anchor = '<MauriButton title="Settings" onPress={() => router.push("/settings")} />'
    add = []
    for route, line in inserts:
        if route not in s:
            add.append("        " + line)
    if add and anchor in s:
        s = s.replace(anchor, "\n".join(add) + "\n        " + anchor)
        p.write_text(s)
        print("PATCHED_DASHBOARD_PROOF_SUITE_LINKS")
PY

npx tsc --noEmit
npx expo export --platform android

echo "FINAL_POLISH_READY_FOR_APK_BUILD"
