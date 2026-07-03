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
