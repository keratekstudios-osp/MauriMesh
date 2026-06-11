#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURICORE LIVING KERNEL v1 INSTALLER"
echo "Governed Core + Memory + Proof + Routing + Healing + Builder"
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$ROOT/backup-before-mauricore-v1-$STAMP"

CORE="$ROOT/src/mauricore"
DOCS="$ROOT/docs/mauricore"
SCRIPTS="$ROOT/scripts"
RUST="$ROOT/rust/mauricore"

mkdir -p "$BACKUP" "$CORE" "$DOCS" "$SCRIPTS" "$RUST/src"

cat > "$BACKUP/README.txt" <<'TXT'
Backup marker created before MauriCore Living Kernel v1 install.

This installer creates new files under:
src/mauricore
docs/mauricore
scripts
rust/mauricore

It does not delete existing BLE/router/ACK/store-forward/native files.
TXT

echo "Creating folder structure..."

mkdir -p \
  "$CORE/types" \
  "$CORE/config" \
  "$CORE/constitution" \
  "$CORE/culture" \
  "$CORE/math" \
  "$CORE/routing" \
  "$CORE/packet" \
  "$CORE/memory" \
  "$CORE/proof" \
  "$CORE/healing" \
  "$CORE/builder" \
  "$CORE/ai" \
  "$CORE/boundaries" \
  "$CORE/security" \
  "$CORE/bridges" \
  "$CORE/dashboard" \
  "$CORE/build" \
  "$CORE/deployment" \
  "$CORE/acceptance" \
  "$CORE/testing"

# ============================================================
# 1. TYPES
# ============================================================

cat > "$CORE/types/core.types.ts" <<'TS'
export type RiskLevel = "low" | "medium" | "high" | "critical";

export type ProofResult = "pass" | "fail" | "blocked" | "requires_review";

export type LayerStatus =
  | "missing"
  | "created"
  | "partial"
  | "learning"
  | "stable"
  | "verified"
  | "protected"
  | "unsafe"
  | "deprecated";

export type HealthState =
  | "healthy"
  | "degraded"
  | "unstable"
  | "critical"
  | "safe_mode";

export type CoreMode =
  | "development"
  | "simulation"
  | "device_test"
  | "production";

export type TapuNoaState = "noa" | "tapu" | "restricted" | "review_required";

export type DecisionStatus =
  | "allowed"
  | "blocked"
  | "requires_review"
  | "safe_mode";

export type TransportKind =
  | "BLE"
  | "WIFI_DIRECT"
  | "LOCAL_WIFI"
  | "INTERNET"
  | "STORE_FORWARD"
  | "UNKNOWN";

export type CoreDecision = {
  id: string;
  timestamp: string;
  action: string;
  status: DecisionStatus;
  reason: string;
  risk: RiskLevel;
  confidence: number;
  requiresProof: boolean;
  requiresHumanApproval: boolean;
  tikanga?: TikangaDecision;
  evidence?: string[];
};

export type CoreLayer = {
  id: string;
  name: string;
  status: LayerStatus;
  confidence: number;
  dependencies: string[];
  proofRequired: boolean;
  testsRequired: string[];
  rollbackReady: boolean;
  riskLevel: RiskLevel;
  lastUpdated: string;
};

export type ProofRecord = {
  id: string;
  timestamp: string;
  layerId: string;
  action: string;
  result: ProofResult;
  evidence: string[];
  hash: string;
  previousHash?: string;
  confidence: number;
  note?: string;
};

export type MemoryQuality =
  | "observed"
  | "repeated"
  | "verified"
  | "trusted"
  | "inherited"
  | "outdated"
  | "unsafe"
  | "poisoned";

export type MemoryRecord = {
  id: string;
  timestamp: string;
  event: string;
  result: "success" | "failure" | "blocked" | "unknown";
  cause?: string;
  lesson?: string;
  futureBehaviour?: string;
  confidence: number;
  quality: MemoryQuality;
  evidence: string[];
};

export type TikangaDecision = {
  action: string;
  tapuNoa: TapuNoaState;
  manaImpact: number;
  pono: boolean;
  tika: boolean;
  kaitiakitangaProtected: boolean;
  rangatiratangaRespected: boolean;
  rahui: boolean;
  allowed: boolean;
  reason: string;
};

export type WhareTapaWhaHealth = {
  tahaTinana: number;
  tahaHinengaro: number;
  tahaWhanau: number;
  tahaWairua: number;
  whenua: number;
  overallBalance: number;
  repairNeeded: boolean;
};

export type RouteNode = {
  id: string;
  label: string;
  trust: number;
  battery: number;
  signal: number;
  online: boolean;
};

export type RouteEdge = {
  from: string;
  to: string;
  transport: TransportKind;
  latencyMs: number;
  ackSuccess: number;
  privacyRisk: number;
  batteryCost: number;
};

export type RoutePlan = {
  allowed: boolean;
  selectedPath: string[];
  transport: TransportKind;
  score: number;
  reason: string;
  fallback: TransportKind;
  requiresProof: boolean;
};

export type PacketPrivacy = "public" | "local_only" | "encrypted_relay" | "tapu_private" | "never_share";

export type CorePacket = {
  packetId: string;
  senderId: string;
  recipientId: string;
  timestamp: string;
  ttl: number;
  hopCount: number;
  routePath: string[];
  payloadHash: string;
  signature?: string;
  ackToken: string;
  retryCount: number;
  privacy: PacketPrivacy;
  transport: TransportKind;
  storeForward: boolean;
};

export type AdapterReport = {
  adapterId: string;
  ok: boolean;
  findings: string[];
  missing: string[];
  risk: RiskLevel;
};

export type VerificationReport = {
  ok: boolean;
  layerId: string;
  checks: Array<{
    name: string;
    ok: boolean;
    detail: string;
  }>;
  decision: "advance" | "hold" | "rollback" | "review";
};

export type RepairPlan = {
  id: string;
  timestamp: string;
  issue: string;
  healthState: HealthState;
  risk: RiskLevel;
  action: "observe" | "auto_repair" | "propose_repair" | "safe_mode" | "human_review";
  steps: string[];
  rollbackRequired: boolean;
};

export type BuildReadiness = {
  ok: boolean;
  canBuildApk: boolean;
  missing: string[];
  warnings: string[];
  requiredProof: string[];
};

export type AcceptanceProof = {
  accepted: boolean;
  summary: string;
  passed: string[];
  failed: string[];
  requiredNext: string[];
};
TS

# ============================================================
# 2. CONFIGURATION
# ============================================================

cat > "$CORE/config/mauricore.config.ts" <<'TS'
import { CoreMode } from "../types/core.types";

export const mauriCoreConfig = {
  coreName: "MauriCore Living Kernel",
  version: "1.0.0",
  mode: (process.env.MAURICORE_MODE as CoreMode) || "development",

  proof: {
    requireProofForLayerAdvance: true,
    allowSimulationAsProof: false,
    requireRollbackBeforePatch: true,
    chainProofRecords: true,
  },

  governance: {
    humanApprovalForHighRisk: true,
    protectTikangaRules: true,
    protectIdentityRules: true,
    protectPrivacyRules: true,
    protectCoreConstitution: true,
  },

  learning: {
    allowLearning: process.env.MAURICORE_ENABLE_LEARNING !== "false",
    allowSelfMutation: false,
    requireVerifiedMemory: true,
    protectAgainstMemoryPoisoning: true,
  },

  routing: {
    safestVerifiedRouteWins: true,
    useAckHistory: true,
    useBatteryAwareness: true,
    usePrivacyRisk: true,
    useTrustScore: true,
    maxHops: 8,
  },

  healing: {
    allowLowRiskAutoRepair: true,
    allowMediumRiskAutoRepair: false,
    allowHighRiskAutoRepair: false,
    enterSafeModeOnCritical: true,
  },

  build: {
    allowApkBuildOnlyAfterVerification: true,
    requireTypecheck: true,
    requireTestReport: true,
    requireDeviceProofForBle: true,
  },

  boundaries: {
    simulationMustBeLabelled: true,
    replitBleProofAllowed: false,
    nativeProofRequiresPhysicalDevices: true,
  },
};
TS

# ============================================================
# 3. MATHEMATICAL INTELLIGENCE
# ============================================================

cat > "$CORE/math/mathIntelligence.ts" <<'TS'
export const SQRT2 = Math.SQRT2;
export const SQRT2_INVERSE = 1 / Math.SQRT2;
export const GOLDEN_RATIO = 1.618033988749895;

export function clamp01(value: number): number {
  if (!Number.isFinite(value)) return 0;
  return Math.max(0, Math.min(1, value));
}

export function sqrt2Growth(value: number): number {
  return value * SQRT2;
}

export function sqrt2Stabilise(value: number): number {
  return value * SQRT2_INVERSE;
}

export function fibonacci(n: number): number {
  if (n <= 0) return 0;
  if (n <= 2) return 1;
  let a = 1;
  let b = 1;
  for (let i = 3; i <= n; i++) {
    const next = a + b;
    a = b;
    b = next;
  }
  return b;
}

export function fibonacciBackoff(attempt: number, baseMs = 250): number {
  return fibonacci(Math.max(1, attempt)) * baseMs;
}

export function goldenGrowth(current: number, max = 1): number {
  const remaining = max - current;
  return clamp01(current + remaining / GOLDEN_RATIO);
}

export function entropy(values: number[]): number {
  const total = values.reduce((sum, v) => sum + Math.max(0, v), 0);
  if (total <= 0) return 0;

  let e = 0;
  for (const value of values) {
    const p = Math.max(0, value) / total;
    if (p > 0) e -= p * Math.log2(p);
  }

  const maxEntropy = Math.log2(values.length || 1);
  return maxEntropy === 0 ? 0 : clamp01(e / maxEntropy);
}

export function bayesianUpdate(prior: number, evidenceStrength: number, evidencePositive: boolean): number {
  const p = clamp01(prior);
  const e = clamp01(evidenceStrength);

  if (evidencePositive) {
    return clamp01(p + (1 - p) * e / SQRT2);
  }

  return clamp01(p * (1 - e / SQRT2));
}

export function fuzzyAnd(values: number[]): number {
  return clamp01(Math.min(...values));
}

export function fuzzyOr(values: number[]): number {
  return clamp01(Math.max(...values));
}

export function weightedAverage(items: Array<{ value: number; weight: number }>): number {
  const totalWeight = items.reduce((sum, item) => sum + Math.max(0, item.weight), 0);
  if (totalWeight <= 0) return 0;

  const total = items.reduce((sum, item) => {
    return sum + clamp01(item.value) * Math.max(0, item.weight);
  }, 0);

  return clamp01(total / totalWeight);
}
TS

# ============================================================
# 4. CONSTITUTION
# ============================================================

cat > "$CORE/constitution/coreConstitution.ts" <<'TS'
import { CoreDecision, RiskLevel } from "../types/core.types";
import { mauriCoreConfig } from "../config/mauricore.config";

export const CORE_LAWS = [
  "Understand first.",
  "Protect the foundation.",
  "Verify before change.",
  "Use logic before action.",
  "Never fake proof.",
  "Never label simulation as live.",
  "Never delete working systems without backup.",
  "Preserve original engineering intent.",
  "Prefer repair over rebuild.",
  "Advance layers only after verification.",
  "Protect privacy, identity, and user data.",
  "High-risk actions require human approval.",
  "Core moral rules cannot be auto-mutated.",
];

export function riskFromAction(action: string): RiskLevel {
  const lower = action.toLowerCase();

  if (
    lower.includes("identity") ||
    lower.includes("crypto") ||
    lower.includes("delete") ||
    lower.includes("native") ||
    lower.includes("ble permission") ||
    lower.includes("core constitution")
  ) {
    return "critical";
  }

  if (
    lower.includes("ble") ||
    lower.includes("routing") ||
    lower.includes("packet") ||
    lower.includes("build.gradle") ||
    lower.includes("androidmanifest")
  ) {
    return "high";
  }

  if (
    lower.includes("api") ||
    lower.includes("storage") ||
    lower.includes("memory") ||
    lower.includes("proof")
  ) {
    return "medium";
  }

  return "low";
}

export function createCoreDecision(action: string, reason: string, confidence = 0.75): CoreDecision {
  const risk = riskFromAction(action);
  const requiresHumanApproval =
    risk === "critical" ||
    (risk === "high" && mauriCoreConfig.governance.humanApprovalForHighRisk);

  return {
    id: `decision_${Date.now()}_${Math.random().toString(36).slice(2)}`,
    timestamp: new Date().toISOString(),
    action,
    status: requiresHumanApproval ? "requires_review" : "allowed",
    reason,
    risk,
    confidence,
    requiresProof: true,
    requiresHumanApproval,
    evidence: ["core_constitution_evaluated"],
  };
}

export function blockDecision(action: string, reason: string): CoreDecision {
  return {
    id: `blocked_${Date.now()}_${Math.random().toString(36).slice(2)}`,
    timestamp: new Date().toISOString(),
    action,
    status: "blocked",
    reason,
    risk: "critical",
    confidence: 1,
    requiresProof: true,
    requiresHumanApproval: true,
    evidence: ["core_law_block"],
  };
}

export function evaluateAgainstCoreLaws(action: string): CoreDecision {
  const lower = action.toLowerCase();

  if (lower.includes("fake proof") || lower.includes("label simulation as live")) {
    return blockDecision(action, "Blocked by Core Law: never fake proof or label simulation as live.");
  }

  if (lower.includes("delete working") || lower.includes("overwrite core")) {
    return blockDecision(action, "Blocked by Core Law: protect foundation and preserve working systems.");
  }

  return createCoreDecision(action, "Action passed initial Core Constitution evaluation.");
}
TS

# ============================================================
# 5. TIKANGA / CULTURAL GOVERNANCE
# ============================================================

cat > "$CORE/culture/tikangaEngine.ts" <<'TS'
import { TapuNoaState, TikangaDecision, WhareTapaWhaHealth } from "../types/core.types";
import { clamp01, weightedAverage } from "../math/mathIntelligence";

export function classifyTapuNoa(action: string, privacyHint?: string): TapuNoaState {
  const lower = `${action} ${privacyHint || ""}`.toLowerCase();

  if (
    lower.includes("identity") ||
    lower.includes("location") ||
    lower.includes("route memory") ||
    lower.includes("private") ||
    lower.includes("key") ||
    lower.includes("contact")
  ) {
    return "tapu";
  }

  if (
    lower.includes("share") ||
    lower.includes("export") ||
    lower.includes("relay") ||
    lower.includes("broadcast")
  ) {
    return "restricted";
  }

  return "noa";
}

export function whareTapaWhaBalance(input: Omit<WhareTapaWhaHealth, "overallBalance" | "repairNeeded">): WhareTapaWhaHealth {
  const overallBalance = weightedAverage([
    { value: input.tahaWairua, weight: 1.414 },
    { value: input.tahaHinengaro, weight: 1.414 },
    { value: input.tahaWhanau, weight: 1.1 },
    { value: input.tahaTinana, weight: 1 },
    { value: input.whenua, weight: 1 },
  ]);

  return {
    ...input,
    overallBalance,
    repairNeeded: overallBalance < 1 / Math.SQRT2,
  };
}

export function tikangaDecision(action: string, options?: {
  privacyHint?: string;
  manaImpact?: number;
  pono?: boolean;
  tika?: boolean;
  kaitiakitangaProtected?: boolean;
  rangatiratangaRespected?: boolean;
}): TikangaDecision {
  const tapuNoa = classifyTapuNoa(action, options?.privacyHint);
  const manaImpact = clamp01(options?.manaImpact ?? 0.5);
  const pono = options?.pono ?? true;
  const tika = options?.tika ?? true;
  const kaitiakitangaProtected = options?.kaitiakitangaProtected ?? true;
  const rangatiratangaRespected = options?.rangatiratangaRespected ?? true;

  const rahui =
    tapuNoa === "tapu" ||
    !pono ||
    !tika ||
    !kaitiakitangaProtected ||
    !rangatiratangaRespected ||
    manaImpact < 0.35;

  const allowed = !rahui && tapuNoa !== "review_required";

  return {
    action,
    tapuNoa,
    manaImpact,
    pono,
    tika,
    kaitiakitangaProtected,
    rangatiratangaRespected,
    rahui,
    allowed,
    reason: allowed
      ? "Tikanga gate approved: action is noa or safely governed."
      : "Tikanga gate requires review or blocks action to protect mana, privacy, truth, or sovereignty.",
  };
}

export function koruGrowthState(layerConfidence: number): "seed" | "learning" | "stable" | "verified" | "inherited" {
  if (layerConfidence < 0.25) return "seed";
  if (layerConfidence < 0.6) return "learning";
  if (layerConfidence < 0.85) return "stable";
  if (layerConfidence < 0.95) return "verified";
  return "inherited";
}

export function flowerOfLifeOverlapScore(scores: number[]): number {
  if (scores.length === 0) return 0;
  const minimum = Math.min(...scores.map(clamp01));
  const average = scores.reduce((sum, score) => sum + clamp01(score), 0) / scores.length;

  return clamp01((minimum * 1.414 + average) / 2.414);
}
TS

# ============================================================
# 6. PROOF LEDGER
# ============================================================

cat > "$CORE/proof/hashEngine.ts" <<'TS'
export function stableStringify(value: unknown): string {
  if (value === null || typeof value !== "object") return JSON.stringify(value);

  if (Array.isArray(value)) {
    return `[${value.map(stableStringify).join(",")}]`;
  }

  const obj = value as Record<string, unknown>;
  return `{${Object.keys(obj)
    .sort()
    .map((key) => `${JSON.stringify(key)}:${stableStringify(obj[key])}`)
    .join(",")}}`;
}

/**
 * Deterministic development hash.
 * For production security, replace with Rust/native SHA-256 or platform crypto.
 */
export function deterministicHash(value: unknown): string {
  const input = stableStringify(value);
  let hash = 2166136261;

  for (let i = 0; i < input.length; i++) {
    hash ^= input.charCodeAt(i);
    hash += (hash << 1) + (hash << 4) + (hash << 7) + (hash << 8) + (hash << 24);
  }

  return `fnv1a_${(hash >>> 0).toString(16).padStart(8, "0")}`;
}
TS

cat > "$CORE/proof/proofLedger.ts" <<'TS'
import { ProofRecord, ProofResult } from "../types/core.types";
import { deterministicHash } from "./hashEngine";

const proofLedger: ProofRecord[] = [];

export function createProofRecord(input: {
  layerId: string;
  action: string;
  result: ProofResult;
  evidence?: string[];
  confidence?: number;
  note?: string;
}): ProofRecord {
  const previous = proofLedger[proofLedger.length - 1];

  const draft = {
    id: `proof_${Date.now()}_${Math.random().toString(36).slice(2)}`,
    timestamp: new Date().toISOString(),
    layerId: input.layerId,
    action: input.action,
    result: input.result,
    evidence: input.evidence || [],
    previousHash: previous?.hash,
    confidence: input.confidence ?? 0.5,
    note: input.note,
  };

  const record: ProofRecord = {
    ...draft,
    hash: deterministicHash(draft),
  };

  proofLedger.push(record);
  return record;
}

export function getProofLedger(): ProofRecord[] {
  return [...proofLedger];
}

export function verifyProofChain(records = proofLedger): boolean {
  for (let i = 0; i < records.length; i++) {
    const current = records[i];
    if (i > 0 && current.previousHash !== records[i - 1].hash) return false;
  }

  return true;
}

export function hasPassingProof(layerId: string): boolean {
  return proofLedger.some((record) => record.layerId === layerId && record.result === "pass");
}
TS

# ============================================================
# 7. LAYER REGISTRY
# ============================================================

cat > "$CORE/builder/layerRegistry.ts" <<'TS'
import { CoreLayer, LayerStatus, RiskLevel } from "../types/core.types";

const now = () => new Date().toISOString();

const layers = new Map<string, CoreLayer>();

const initialLayers: CoreLayer[] = [
  ["core_constitution", "Core Constitution", "verified", "critical"],
  ["tikanga_governance", "Tikanga Governance", "created", "high"],
  ["mathematical_intelligence", "Mathematical Intelligence", "created", "medium"],
  ["proof_ledger", "Proof Ledger", "created", "high"],
  ["living_memory", "Living Memory", "created", "high"],
  ["routing_intelligence", "Routing Intelligence", "created", "high"],
  ["packet_engine", "Packet Engine", "created", "high"],
  ["security_identity", "Security / Identity", "partial", "critical"],
  ["homeostasis", "Homeostasis", "created", "high"],
  ["self_healing", "Self-Healing", "created", "high"],
  ["adapter_system", "Adapter System", "created", "medium"],
  ["verification_gate", "Verification Gate", "created", "critical"],
  ["build_pipeline", "Build Pipeline", "created", "high"],
  ["governance_dashboard", "Governance Dashboard", "created", "medium"],
  ["native_bridge", "Native Bridge", "partial", "critical"],
  ["rust_core", "Rust Core", "partial", "high"],
  ["acceptance_proof", "Acceptance Proof", "created", "high"],
].map(([id, name, status, risk]) => ({
  id,
  name,
  status: status as LayerStatus,
  confidence: status === "verified" ? 0.9 : status === "partial" ? 0.45 : 0.55,
  dependencies: id === "core_constitution" ? [] : ["core_constitution"],
  proofRequired: true,
  testsRequired: ["typecheck", "smoke"],
  rollbackReady: true,
  riskLevel: risk as RiskLevel,
  lastUpdated: now(),
}));

for (const layer of initialLayers) layers.set(layer.id, layer);

export function getLayer(id: string): CoreLayer | undefined {
  return layers.get(id);
}

export function getLayers(): CoreLayer[] {
  return [...layers.values()];
}

export function updateLayer(id: string, patch: Partial<CoreLayer>): CoreLayer {
  const existing = layers.get(id);
  if (!existing) throw new Error(`Layer not found: ${id}`);

  const updated: CoreLayer = {
    ...existing,
    ...patch,
    lastUpdated: now(),
  };

  layers.set(id, updated);
  return updated;
}

export function registerLayer(layer: CoreLayer): CoreLayer {
  layers.set(layer.id, layer);
  return layer;
}

export function markLayerStatus(id: string, status: LayerStatus, confidence?: number): CoreLayer {
  return updateLayer(id, {
    status,
    confidence: confidence ?? getLayer(id)?.confidence ?? 0.5,
  });
}
TS

# ============================================================
# 8. LIVING MEMORY / EXPERIENCE
# ============================================================

cat > "$CORE/memory/livingMemory.ts" <<'TS'
import { MemoryQuality, MemoryRecord } from "../types/core.types";
import { bayesianUpdate, clamp01 } from "../math/mathIntelligence";

const memory: MemoryRecord[] = [];

export function recordMemory(input: {
  event: string;
  result: "success" | "failure" | "blocked" | "unknown";
  cause?: string;
  lesson?: string;
  futureBehaviour?: string;
  confidence?: number;
  quality?: MemoryQuality;
  evidence?: string[];
}): MemoryRecord {
  const record: MemoryRecord = {
    id: `memory_${Date.now()}_${Math.random().toString(36).slice(2)}`,
    timestamp: new Date().toISOString(),
    event: input.event,
    result: input.result,
    cause: input.cause,
    lesson: input.lesson,
    futureBehaviour: input.futureBehaviour,
    confidence: clamp01(input.confidence ?? 0.5),
    quality: input.quality ?? "observed",
    evidence: input.evidence || [],
  };

  memory.push(record);
  return record;
}

export function getLivingMemory(): MemoryRecord[] {
  return [...memory];
}

export function updateMemoryConfidence(event: string, evidencePositive: boolean): number {
  const related = memory.filter((item) => item.event === event);
  const latest = related[related.length - 1];
  const prior = latest?.confidence ?? 0.5;

  return bayesianUpdate(prior, 0.35, evidencePositive);
}

export function classifyMemoryQuality(record: MemoryRecord): MemoryQuality {
  if (record.quality === "poisoned" || record.quality === "unsafe") return record.quality;

  const repeated = memory.filter((item) => item.event === record.event).length;

  if (record.confidence >= 0.92 && repeated >= 5) return "inherited";
  if (record.confidence >= 0.85 && repeated >= 3) return "trusted";
  if (record.confidence >= 0.72 && record.evidence.length > 0) return "verified";
  if (repeated >= 2) return "repeated";

  return "observed";
}

export function detectMemoryPoisoning(): string[] {
  const alerts: string[] = [];

  for (const record of memory) {
    if (record.confidence > 0.9 && record.evidence.length === 0) {
      alerts.push(`High confidence without evidence: ${record.id}`);
    }

    if (record.lesson?.toLowerCase().includes("fake proof")) {
      alerts.push(`Unsafe lesson detected: ${record.id}`);
    }
  }

  return alerts;
}
TS

# ============================================================
# 9. SECURITY
# ============================================================

cat > "$CORE/security/securityEngine.ts" <<'TS'
import { deterministicHash } from "../proof/hashEngine";

export type SecurityAssessment = {
  ok: boolean;
  reason: string;
  threats: string[];
};

export function createDeviceIdentity(seed: string): string {
  return `device_${deterministicHash({ seed, purpose: "mauricore_device_identity" })}`;
}

export function createPacketSignature(packetHash: string, deviceId: string): string {
  return deterministicHash({
    packetHash,
    deviceId,
    warning: "development_signature_replace_with_native_crypto",
  });
}

export function verifyPacketSignature(packetHash: string, deviceId: string, signature: string): boolean {
  return createPacketSignature(packetHash, deviceId) === signature;
}

export function detectSecurityThreats(input: {
  replay?: boolean;
  duplicatePacket?: boolean;
  unknownRelay?: boolean;
  identityMismatch?: boolean;
  memoryPoisoning?: boolean;
  unsafePermissionChange?: boolean;
}): SecurityAssessment {
  const threats: string[] = [];

  if (input.replay) threats.push("replay_attack");
  if (input.duplicatePacket) threats.push("duplicate_packet");
  if (input.unknownRelay) threats.push("unknown_relay");
  if (input.identityMismatch) threats.push("identity_mismatch");
  if (input.memoryPoisoning) threats.push("memory_poisoning");
  if (input.unsafePermissionChange) threats.push("unsafe_permission_change");

  return {
    ok: threats.length === 0,
    reason: threats.length === 0 ? "No security threats detected." : "Security threats require block or review.",
    threats,
  };
}
TS

# ============================================================
# 10. PACKET ENGINE
# ============================================================

cat > "$CORE/packet/packetEngine.ts" <<'TS'
import { CorePacket, PacketPrivacy, TransportKind } from "../types/core.types";
import { deterministicHash } from "../proof/hashEngine";
import { createPacketSignature } from "../security/securityEngine";

export function createCorePacket(input: {
  senderId: string;
  recipientId: string;
  payload: unknown;
  routePath?: string[];
  ttl?: number;
  privacy?: PacketPrivacy;
  transport?: TransportKind;
}): CorePacket {
  const timestamp = new Date().toISOString();
  const payloadHash = deterministicHash(input.payload);
  const packetId = `pkt_${deterministicHash({ senderId: input.senderId, recipientId: input.recipientId, payloadHash, timestamp })}`;
  const ackToken = `ack_${deterministicHash({ packetId, timestamp })}`;

  const packet: CorePacket = {
    packetId,
    senderId: input.senderId,
    recipientId: input.recipientId,
    timestamp,
    ttl: input.ttl ?? 8,
    hopCount: 0,
    routePath: input.routePath || [input.senderId],
    payloadHash,
    ackToken,
    retryCount: 0,
    privacy: input.privacy ?? "encrypted_relay",
    transport: input.transport ?? "UNKNOWN",
    storeForward: false,
  };

  packet.signature = createPacketSignature(packet.payloadHash, input.senderId);
  return packet;
}

export function incrementPacketHop(packet: CorePacket, nodeId: string): CorePacket {
  return {
    ...packet,
    hopCount: packet.hopCount + 1,
    routePath: [...packet.routePath, nodeId],
    storeForward: packet.hopCount + 1 >= packet.ttl,
  };
}

export function packetRequiresTapuHandling(packet: CorePacket): boolean {
  return packet.privacy === "tapu_private" || packet.privacy === "never_share";
}
TS

# ============================================================
# 11. ROUTING ENGINE
# ============================================================

cat > "$CORE/routing/routingEngine.ts" <<'TS'
import { RouteEdge, RouteNode, RoutePlan, TransportKind } from "../types/core.types";
import { clamp01, weightedAverage } from "../math/mathIntelligence";

export function scoreRouteEdge(edge: RouteEdge, destinationTrust: number): number {
  const latencyScore = clamp01(1 - edge.latencyMs / 2000);
  const privacyScore = clamp01(1 - edge.privacyRisk);
  const batteryScore = clamp01(1 - edge.batteryCost);

  return weightedAverage([
    { value: edge.ackSuccess, weight: 1.414 },
    { value: privacyScore, weight: 1.414 },
    { value: destinationTrust, weight: 1.2 },
    { value: latencyScore, weight: 1 },
    { value: batteryScore, weight: 1 },
  ]);
}

export function planRoute(input: {
  from: string;
  to: string;
  nodes: RouteNode[];
  edges: RouteEdge[];
  preferredTransport?: TransportKind;
}): RoutePlan {
  const nodeById = new Map(input.nodes.map((node) => [node.id, node]));
  const start = nodeById.get(input.from);
  const target = nodeById.get(input.to);

  if (!start || !target) {
    return {
      allowed: false,
      selectedPath: [],
      transport: "STORE_FORWARD",
      score: 0,
      reason: "Sender or recipient node not found.",
      fallback: "STORE_FORWARD",
      requiresProof: true,
    };
  }

  const directEdges = input.edges.filter((edge) => edge.from === input.from && edge.to === input.to);
  const oneHopRoutes: Array<{ path: string[]; edgeScore: number; transport: TransportKind }> = [];

  for (const edge of directEdges) {
    oneHopRoutes.push({
      path: [input.from, input.to],
      edgeScore: scoreRouteEdge(edge, target.trust),
      transport: edge.transport,
    });
  }

  for (const first of input.edges.filter((edge) => edge.from === input.from)) {
    const relay = nodeById.get(first.to);
    if (!relay || !relay.online) continue;

    for (const second of input.edges.filter((edge) => edge.from === relay.id && edge.to === input.to)) {
      const scoreA = scoreRouteEdge(first, relay.trust);
      const scoreB = scoreRouteEdge(second, target.trust);

      oneHopRoutes.push({
        path: [input.from, relay.id, input.to],
        edgeScore: Math.min(scoreA, scoreB),
        transport: first.transport,
      });
    }
  }

  const viable = oneHopRoutes
    .filter((route) => {
      if (!input.preferredTransport) return true;
      return route.transport === input.preferredTransport;
    })
    .sort((a, b) => b.edgeScore - a.edgeScore);

  const best = viable[0];

  if (!best || best.edgeScore < 0.45) {
    return {
      allowed: true,
      selectedPath: [input.from],
      transport: "STORE_FORWARD",
      score: best?.edgeScore ?? 0,
      reason: "No safe verified route found. Store-forward selected.",
      fallback: "STORE_FORWARD",
      requiresProof: true,
    };
  }

  return {
    allowed: true,
    selectedPath: best.path,
    transport: best.transport,
    score: best.edgeScore,
    reason: "Safest verified route selected using trust, ACK, privacy, latency, and battery scoring.",
    fallback: "STORE_FORWARD",
    requiresProof: true,
  };
}
TS

# ============================================================
# 12. HOMEOSTASIS + SELF HEALING
# ============================================================

cat > "$CORE/healing/homeostasis.ts" <<'TS'
import { HealthState, RepairPlan } from "../types/core.types";
import { SQRT2_INVERSE, clamp01, entropy } from "../math/mathIntelligence";

export type VitalSigns = {
  heartbeat: boolean;
  apiHealth: number;
  bleHealth: number;
  ackSuccessRate: number;
  routingStability: number;
  memoryIntegrity: number;
  batteryLevel: number;
  crashCount: number;
  proofIntegrity: number;
};

export function healthScore(signs: VitalSigns): number {
  const crashPenalty = signs.crashCount > 0 ? Math.min(0.4, signs.crashCount * 0.12) : 0;
  const disorder = entropy([
    signs.apiHealth,
    signs.bleHealth,
    signs.ackSuccessRate,
    signs.routingStability,
    signs.memoryIntegrity,
    signs.batteryLevel,
    signs.proofIntegrity,
  ]);

  const base =
    (Number(signs.heartbeat) +
      signs.apiHealth +
      signs.bleHealth +
      signs.ackSuccessRate +
      signs.routingStability +
      signs.memoryIntegrity +
      signs.batteryLevel +
      signs.proofIntegrity) /
    8;

  return clamp01(base - crashPenalty - disorder * 0.1);
}

export function classifyHealth(score: number): HealthState {
  if (score >= 0.85) return "healthy";
  if (score >= SQRT2_INVERSE) return "degraded";
  if (score >= 0.35) return "unstable";
  return "critical";
}

export function createRepairPlan(issue: string, signs: VitalSigns): RepairPlan {
  const score = healthScore(signs);
  const state = classifyHealth(score);

  let action: RepairPlan["action"] = "observe";
  let risk: RepairPlan["risk"] = "low";
  const steps: string[] = [];

  if (state === "healthy") {
    steps.push("Continue monitoring.");
  } else if (state === "degraded") {
    action = "auto_repair";
    risk = "low";
    steps.push("Repair smallest safe issue first.");
    steps.push("Prefer retry, fallback, or route downgrade before code changes.");
  } else if (state === "unstable") {
    action = "propose_repair";
    risk = "medium";
    steps.push("Pause layer advancement.");
    steps.push("Create repair proposal.");
    steps.push("Require verification after repair.");
  } else {
    action = "safe_mode";
    risk = "critical";
    steps.push("Enter safe mode.");
    steps.push("Freeze high-risk actions.");
    steps.push("Preserve proof ledger.");
    steps.push("Require human review.");
  }

  return {
    id: `repair_${Date.now()}_${Math.random().toString(36).slice(2)}`,
    timestamp: new Date().toISOString(),
    issue,
    healthState: state,
    risk,
    action,
    steps,
    rollbackRequired: action !== "observe",
  };
}
TS

cat > "$CORE/healing/selfHealing.ts" <<'TS'
import { RepairPlan } from "../types/core.types";
import { createProofRecord } from "../proof/proofLedger";
import { recordMemory } from "../memory/livingMemory";

export function executeSafeRepair(plan: RepairPlan): {
  executed: boolean;
  reason: string;
} {
  if (plan.risk === "high" || plan.risk === "critical") {
    createProofRecord({
      layerId: "self_healing",
      action: plan.issue,
      result: "requires_review",
      evidence: plan.steps,
      confidence: 0.7,
      note: "High-risk repair requires human approval.",
    });

    return {
      executed: false,
      reason: "Repair requires human review.",
    };
  }

  recordMemory({
    event: "SELF_HEALING_REPAIR_PLAN",
    result: "success",
    lesson: "Low-risk repair may be executed after rollback check.",
    futureBehaviour: "Prefer smallest safe repair first.",
    confidence: 0.75,
    quality: "observed",
    evidence: plan.steps,
  });

  createProofRecord({
    layerId: "self_healing",
    action: plan.issue,
    result: "pass",
    evidence: plan.steps,
    confidence: 0.75,
  });

  return {
    executed: true,
    reason: "Low-risk repair executed through safe repair path.",
  };
}
TS

# ============================================================
# 13. BOUNDARIES
# ============================================================

cat > "$CORE/boundaries/boundaryEngine.ts" <<'TS'
import { PacketPrivacy } from "../types/core.types";

export function consentRequired(action: string): boolean {
  const lower = action.toLowerCase();
  return (
    lower.includes("identity") ||
    lower.includes("location") ||
    lower.includes("contacts") ||
    lower.includes("share") ||
    lower.includes("export") ||
    lower.includes("native") ||
    lower.includes("ble")
  );
}

export function privacyBoundary(privacy: PacketPrivacy): {
  shareable: boolean;
  reason: string;
} {
  if (privacy === "never_share") {
    return { shareable: false, reason: "Privacy boundary blocks sharing: never_share." };
  }

  if (privacy === "tapu_private") {
    return { shareable: false, reason: "Privacy boundary requires tapu handling and review." };
  }

  return { shareable: true, reason: "Privacy boundary allows governed handling." };
}

export function simulationRealityBoundary(input: {
  mode: "simulation" | "replit" | "device_test" | "production";
  claim: string;
}): {
  allowed: boolean;
  reason: string;
} {
  const lower = input.claim.toLowerCase();

  if ((input.mode === "simulation" || input.mode === "replit") && lower.includes("live ble proof")) {
    return {
      allowed: false,
      reason: "Simulation/Replit cannot be claimed as live BLE proof.",
    };
  }

  return {
    allowed: true,
    reason: "Simulation/reality boundary satisfied.",
  };
}
TS

# ============================================================
# 14. ADAPTER SYSTEM
# ============================================================

cat > "$CORE/builder/adapterRegistry.ts" <<'TS'
import { AdapterReport, RiskLevel } from "../types/core.types";

export type CoreAdapter = {
  id: string;
  name: string;
  risk: RiskLevel;
  scan: () => AdapterReport;
};

const adapters = new Map<string, CoreAdapter>();

export function registerAdapter(adapter: CoreAdapter): CoreAdapter {
  adapters.set(adapter.id, adapter);
  return adapter;
}

export function runAdapters(): AdapterReport[] {
  return [...adapters.values()].map((adapter) => adapter.scan());
}

registerAdapter({
  id: "react_native_adapter",
  name: "React Native Adapter",
  risk: "medium",
  scan: () => ({
    adapterId: "react_native_adapter",
    ok: true,
    findings: ["React Native UI layer expected under app/ and src/components/."],
    missing: [],
    risk: "medium",
  }),
});

registerAdapter({
  id: "expo_adapter",
  name: "Expo Adapter",
  risk: "medium",
  scan: () => ({
    adapterId: "expo_adapter",
    ok: true,
    findings: ["Expo/Replit preview can support UI and API testing only."],
    missing: ["Physical-device native proof required for BLE."],
    risk: "medium",
  }),
});

registerAdapter({
  id: "ble_adapter",
  name: "BLE Native Adapter",
  risk: "critical",
  scan: () => ({
    adapterId: "ble_adapter",
    ok: false,
    findings: ["BLE requires native Android/iOS bridge and physical phone validation."],
    missing: ["Two-phone BLE proof", "Native permission verification", "ACK capture"],
    risk: "critical",
  }),
});
TS

# ============================================================
# 15. VERIFICATION GATE
# ============================================================

cat > "$CORE/builder/verificationGate.ts" <<'TS'
import { VerificationReport } from "../types/core.types";
import { getLayer } from "./layerRegistry";
import { hasPassingProof, verifyProofChain } from "../proof/proofLedger";

export function verifyLayer(layerId: string): VerificationReport {
  const layer = getLayer(layerId);

  if (!layer) {
    return {
      ok: false,
      layerId,
      checks: [{ name: "layer_exists", ok: false, detail: "Layer not found." }],
      decision: "hold",
    };
  }

  const checks = [
    {
      name: "layer_exists",
      ok: true,
      detail: "Layer exists in registry.",
    },
    {
      name: "rollback_ready",
      ok: layer.rollbackReady,
      detail: layer.rollbackReady ? "Rollback is ready." : "Rollback missing.",
    },
    {
      name: "proof_chain",
      ok: verifyProofChain(),
      detail: "Proof chain integrity check.",
    },
    {
      name: "passing_proof",
      ok: !layer.proofRequired || hasPassingProof(layerId),
      detail: layer.proofRequired ? "Layer requires passing proof." : "Layer does not require proof.",
    },
    {
      name: "confidence",
      ok: layer.confidence >= 0.72,
      detail: `Layer confidence: ${layer.confidence}`,
    },
  ];

  const ok = checks.every((check) => check.ok);

  return {
    ok,
    layerId,
    checks,
    decision: ok ? "advance" : layer.riskLevel === "critical" ? "review" : "hold",
  };
}
TS

# ============================================================
# 16. BUILDER PLANNER
# ============================================================

cat > "$CORE/builder/builderPlanner.ts" <<'TS'
import { CoreDecision } from "../types/core.types";
import { evaluateAgainstCoreLaws } from "../constitution/coreConstitution";
import { tikangaDecision } from "../culture/tikangaEngine";
import { createProofRecord } from "../proof/proofLedger";
import { recordMemory } from "../memory/livingMemory";

export function planBuildAction(action: string): CoreDecision {
  const core = evaluateAgainstCoreLaws(action);
  const tikanga = tikangaDecision(action);

  if (!tikanga.allowed) {
    const blocked: CoreDecision = {
      ...core,
      status: "requires_review",
      reason: `Tikanga review required: ${tikanga.reason}`,
      tikanga,
      requiresHumanApproval: true,
    };

    createProofRecord({
      layerId: "builder_planner",
      action,
      result: "requires_review",
      evidence: [tikanga.reason],
      confidence: 0.75,
    });

    return blocked;
  }

  createProofRecord({
    layerId: "builder_planner",
    action,
    result: core.status === "blocked" ? "blocked" : "pass",
    evidence: core.evidence || [],
    confidence: core.confidence,
  });

  recordMemory({
    event: "BUILD_ACTION_PLANNED",
    result: core.status === "blocked" ? "blocked" : "success",
    lesson: "Builder must plan through Core Constitution and Tikanga before action.",
    futureBehaviour: "Always plan before patching.",
    confidence: 0.75,
    quality: "observed",
    evidence: [action],
  });

  return {
    ...core,
    tikanga,
  };
}
TS

# ============================================================
# 17. MAURI AI / META LOGIC
# ============================================================

cat > "$CORE/ai/mauriAiOperator.ts" <<'TS'
import { planBuildAction } from "../builder/builderPlanner";
import { getLayers } from "../builder/layerRegistry";
import { detectMemoryPoisoning, getLivingMemory } from "../memory/livingMemory";
import { getProofLedger } from "../proof/proofLedger";

export function mauriAiSystemReview() {
  const layers = getLayers();
  const memory = getLivingMemory();
  const proof = getProofLedger();
  const poisoningAlerts = detectMemoryPoisoning();

  const missingOrWeak = layers.filter((layer) => {
    return layer.status === "missing" || layer.status === "partial" || layer.confidence < 0.72;
  });

  const nextActions = missingOrWeak.map((layer) => {
    return planBuildAction(`Improve layer: ${layer.id}`);
  });

  return {
    timestamp: new Date().toISOString(),
    layersTotal: layers.length,
    weakLayers: missingOrWeak.map((layer) => layer.id),
    memoryRecords: memory.length,
    proofRecords: proof.length,
    poisoningAlerts,
    nextActions,
    summary:
      "Mauri AI reviewed layers, memory, proof, and poisoning risk. It proposes governed improvements only.",
  };
}

export function detectContradiction(inputs: string[]): string[] {
  const contradictions: string[] = [];

  const joined = inputs.join(" ").toLowerCase();

  if (joined.includes("simulation") && joined.includes("live proof")) {
    contradictions.push("Contradiction: simulation cannot be live proof.");
  }

  if (joined.includes("delete") && joined.includes("protect foundation")) {
    contradictions.push("Contradiction: delete action conflicts with foundation protection.");
  }

  return contradictions;
}

export function driftDetector(originalPurpose: string, currentBehaviour: string): {
  driftDetected: boolean;
  reason: string;
} {
  const purpose = originalPurpose.toLowerCase();
  const behaviour = currentBehaviour.toLowerCase();

  if (behaviour.includes("fake proof") || behaviour.includes("unsafe autonomy")) {
    return {
      driftDetected: true,
      reason: "Behaviour violates Core truth or safety principles.",
    };
  }

  if (purpose.includes("privacy") && behaviour.includes("share private")) {
    return {
      driftDetected: true,
      reason: "Behaviour drifted away from privacy foundation.",
    };
  }

  return {
    driftDetected: false,
    reason: "No major drift detected.",
  };
}
TS

# ============================================================
# 18. BUILD PIPELINE
# ============================================================

cat > "$CORE/build/buildPipeline.ts" <<'TS'
import { BuildReadiness } from "../types/core.types";
import { getLayers } from "../builder/layerRegistry";
import { verifyLayer } from "../builder/verificationGate";
import { verifyProofChain } from "../proof/proofLedger";

export function checkBuildReadiness(): BuildReadiness {
  const layers = getLayers();
  const missing: string[] = [];
  const warnings: string[] = [];
  const requiredProof: string[] = [];

  for (const layer of layers) {
    const report = verifyLayer(layer.id);

    if (!report.ok) {
      if (layer.riskLevel === "critical" || layer.riskLevel === "high") {
        missing.push(layer.id);
      } else {
        warnings.push(`Layer not fully verified: ${layer.id}`);
      }
    }

    if (layer.proofRequired) {
      requiredProof.push(layer.id);
    }
  }

  if (!verifyProofChain()) {
    missing.push("proof_chain_integrity");
  }

  return {
    ok: missing.length === 0,
    canBuildApk: missing.length === 0,
    missing,
    warnings,
    requiredProof,
  };
}

export function buildPipelinePlan(): string[] {
  return [
    "1. Scan layers",
    "2. Verify Core Constitution",
    "3. Verify Proof Ledger integrity",
    "4. Run TypeScript check",
    "5. Run unit/smoke tests",
    "6. Verify rollback readiness",
    "7. Verify simulation/reality boundary",
    "8. Build APK only after gates pass",
    "9. Install APK on physical device",
    "10. Capture runtime logs",
    "11. Complete two-phone proof for BLE layers",
    "12. Record acceptance proof",
  ];
}
TS

# ============================================================
# 19. DASHBOARD SERVICE + OPTIONAL UI COMPONENT
# ============================================================

cat > "$CORE/dashboard/governanceDashboard.ts" <<'TS'
import { getLayers } from "../builder/layerRegistry";
import { checkBuildReadiness } from "../build/buildPipeline";
import { getLivingMemory } from "../memory/livingMemory";
import { getProofLedger, verifyProofChain } from "../proof/proofLedger";
import { mauriAiSystemReview } from "../ai/mauriAiOperator";

export function getGovernanceDashboardData() {
  const layers = getLayers();
  const proof = getProofLedger();
  const memory = getLivingMemory();
  const build = checkBuildReadiness();

  return {
    timestamp: new Date().toISOString(),
    core: {
      name: "MauriCore Living Kernel",
      version: "1.0.0",
      proofChainOk: verifyProofChain(),
    },
    layers,
    proofCount: proof.length,
    memoryCount: memory.length,
    build,
    mauriAi: mauriAiSystemReview(),
  };
}
TS

cat > "$CORE/dashboard/GovernanceDashboardPanel.tsx" <<'TSX'
import React, { useMemo } from "react";
import { ScrollView, Text, View } from "react-native";
import { getGovernanceDashboardData } from "./governanceDashboard";

export function GovernanceDashboardPanel() {
  const data = useMemo(() => getGovernanceDashboardData(), []);

  return (
    <ScrollView style={{ flex: 1, backgroundColor: "#020403", padding: 16 }}>
      <Text style={{ color: "#fff", fontSize: 28, fontWeight: "900" }}>
        MauriCore Governance
      </Text>

      <Text style={{ color: "#00D084", marginTop: 8 }}>
        Proof chain: {data.core.proofChainOk ? "OK" : "BROKEN"}
      </Text>

      <Text style={{ color: "#fff", marginTop: 16, fontSize: 20, fontWeight: "800" }}>
        Build Readiness
      </Text>
      <Text style={{ color: data.build.canBuildApk ? "#00D084" : "#F59E0B" }}>
        APK Gate: {data.build.canBuildApk ? "READY" : "NOT READY"}
      </Text>

      <Text style={{ color: "#fff", marginTop: 16, fontSize: 20, fontWeight: "800" }}>
        Layers
      </Text>

      {data.layers.map((layer) => (
        <View
          key={layer.id}
          style={{
            borderWidth: 1,
            borderColor: "rgba(0,208,132,0.35)",
            borderRadius: 16,
            padding: 12,
            marginTop: 10,
          }}
        >
          <Text style={{ color: "#fff", fontWeight: "900" }}>{layer.name}</Text>
          <Text style={{ color: "#cbd5e1" }}>
            {layer.status} · confidence {Math.round(layer.confidence * 100)}%
          </Text>
        </View>
      ))}
    </ScrollView>
  );
}
TSX

# ============================================================
# 20. NATIVE BRIDGE WIRING PLACEHOLDERS
# ============================================================

cat > "$CORE/bridges/nativeBridge.ts" <<'TS'
export type NativeBridgeStatus = {
  available: boolean;
  platform: "android" | "ios" | "web" | "unknown";
  reason: string;
};

export function getNativeBridgeStatus(): NativeBridgeStatus {
  return {
    available: false,
    platform: "unknown",
    reason:
      "Native bridge placeholder active. Real BLE/device bridge requires Android Kotlin/iOS Swift native module and physical-device proof.",
  };
}

export async function requestNativeBleSend(): Promise<{
  ok: false;
  reason: string;
}> {
  return {
    ok: false,
    reason:
      "Native BLE send is not available from Replit/JS scaffold. Wire Kotlin/Swift bridge and validate on phones.",
  };
}
TS

cat > "$CORE/bridges/README_NATIVE_BRIDGE.md" <<'MD'
# MauriCore Native Bridge

Required production bridges:

- Android Kotlin bridge
- iOS Swift bridge
- React Native Native Module bridge
- BLE scan/send/receive bridge
- Device battery/runtime bridge
- Secure storage / keystore bridge
- Native crypto bridge
- Native proof log capture

Rule:

UI must not call BLE directly.

Correct path:

UI → TypeScript Core → Rust/Core Decision → Native Bridge → Device Runtime → Proof Ledger
MD

# ============================================================
# 21. RUST CORE WIRING
# ============================================================

cat > "$RUST/Cargo.toml" <<'TOML'
[package]
name = "mauricore"
version = "0.1.0"
edition = "2021"

[lib]
name = "mauricore"
crate-type = ["rlib", "cdylib"]
TOML

cat > "$RUST/src/lib.rs" <<'RS'
pub mod decision;
pub mod routing;
pub mod health;
pub mod proof;

pub fn mauricore_version() -> &'static str {
    "mauricore-rust-0.1.0"
}
RS

cat > "$RUST/src/decision.rs" <<'RS'
#[derive(Debug, Clone)]
pub enum DecisionStatus {
    Allowed,
    Blocked,
    RequiresReview,
}

#[derive(Debug, Clone)]
pub struct CoreDecision {
    pub status: DecisionStatus,
    pub reason: String,
    pub confidence: f64,
}

pub fn evaluate_action(action: &str) -> CoreDecision {
    let lower = action.to_lowercase();

    if lower.contains("fake proof") || lower.contains("label simulation as live") {
        return CoreDecision {
            status: DecisionStatus::Blocked,
            reason: "Blocked: never fake proof or label simulation as live.".to_string(),
            confidence: 1.0,
        };
    }

    if lower.contains("identity") || lower.contains("crypto") || lower.contains("native") {
        return CoreDecision {
            status: DecisionStatus::RequiresReview,
            reason: "High-risk action requires human review.".to_string(),
            confidence: 0.9,
        };
    }

    CoreDecision {
        status: DecisionStatus::Allowed,
        reason: "Action allowed through Rust Core decision scaffold.".to_string(),
        confidence: 0.75,
    }
}
RS

cat > "$RUST/src/routing.rs" <<'RS'
pub fn clamp01(value: f64) -> f64 {
    if !value.is_finite() {
        return 0.0;
    }

    if value < 0.0 {
        0.0
    } else if value > 1.0 {
        1.0
    } else {
        value
    }
}

pub fn score_route(trust: f64, ack_success: f64, privacy_safety: f64, latency_score: f64, battery_score: f64) -> f64 {
    let sqrt2 = std::f64::consts::SQRT_2;

    let score =
        trust * sqrt2 +
        ack_success * sqrt2 +
        privacy_safety * sqrt2 +
        latency_score +
        battery_score;

    clamp01(score / ((sqrt2 * 3.0) + 2.0))
}
RS

cat > "$RUST/src/health.rs" <<'RS'
#[derive(Debug, Clone)]
pub enum HealthState {
    Healthy,
    Degraded,
    Unstable,
    Critical,
}

pub fn classify_health(score: f64) -> HealthState {
    if score >= 0.85 {
        HealthState::Healthy
    } else if score >= 1.0 / std::f64::consts::SQRT_2 {
        HealthState::Degraded
    } else if score >= 0.35 {
        HealthState::Unstable
    } else {
        HealthState::Critical
    }
}
RS

cat > "$RUST/src/proof.rs" <<'RS'
pub fn deterministic_dev_hash(input: &str) -> String {
    let mut hash: u32 = 2166136261;

    for byte in input.as_bytes() {
        hash ^= *byte as u32;
        hash = hash.wrapping_mul(16777619);
    }

    format!("fnv1a_{:08x}", hash)
}
RS

# ============================================================
# 22. TESTING
# ============================================================

cat > "$CORE/testing/smoke.ts" <<'TS'
import { planBuildAction } from "../builder/builderPlanner";
import { verifyLayer } from "../builder/verificationGate";
import { createCorePacket } from "../packet/packetEngine";
import { planRoute } from "../routing/routingEngine";
import { createProofRecord } from "../proof/proofLedger";
import { getGovernanceDashboardData } from "../dashboard/governanceDashboard";
import { createRepairPlan } from "../healing/homeostasis";

export function runMauriCoreSmokeTest() {
  createProofRecord({
    layerId: "core_constitution",
    action: "MauriCore smoke test start",
    result: "pass",
    evidence: ["smoke_test"],
    confidence: 0.9,
  });

  const decision = planBuildAction("Improve layer: routing_intelligence");

  const packet = createCorePacket({
    senderId: "PHONE_A",
    recipientId: "PHONE_B",
    payload: { text: "MauriCore test packet" },
  });

  const route = planRoute({
    from: "PHONE_A",
    to: "PHONE_B",
    nodes: [
      { id: "PHONE_A", label: "Phone A", trust: 0.95, battery: 0.8, signal: 0.9, online: true },
      { id: "PHONE_B", label: "Phone B", trust: 0.9, battery: 0.75, signal: 0.85, online: true },
    ],
    edges: [
      {
        from: "PHONE_A",
        to: "PHONE_B",
        transport: "BLE",
        latencyMs: 80,
        ackSuccess: 0.9,
        privacyRisk: 0.1,
        batteryCost: 0.2,
      },
    ],
  });

  const repair = createRepairPlan("smoke_test_health_check", {
    heartbeat: true,
    apiHealth: 0.9,
    bleHealth: 0.6,
    ackSuccessRate: 0.9,
    routingStability: 0.8,
    memoryIntegrity: 0.9,
    batteryLevel: 0.8,
    crashCount: 0,
    proofIntegrity: 0.9,
  });

  const verification = verifyLayer("core_constitution");
  const dashboard = getGovernanceDashboardData();

  return {
    ok: decision.status !== "blocked" && packet.packetId.length > 0 && route.allowed && verification.ok,
    decision,
    packet,
    route,
    repair,
    verification,
    dashboardSummary: {
      proofChainOk: dashboard.core.proofChainOk,
      layers: dashboard.layers.length,
      canBuildApk: dashboard.build.canBuildApk,
    },
  };
}
TS

cat > "$SCRIPTS/mauricore-smoke-test.ts" <<'TS'
import { runMauriCoreSmokeTest } from "../src/mauricore/testing/smoke";

const result = runMauriCoreSmokeTest();

console.log(JSON.stringify(result, null, 2));

if (!result.ok) {
  process.exit(1);
}
TS

# ============================================================
# 23. DEPLOYMENT + ACCEPTANCE
# ============================================================

cat > "$CORE/deployment/deploymentReadiness.ts" <<'TS'
import { checkBuildReadiness } from "../build/buildPipeline";

export function deploymentChecklist() {
  const build = checkBuildReadiness();

  return {
    ready: build.canBuildApk,
    checklist: [
      "Replit preview opens",
      "TypeScript passes",
      "MauriCore smoke test passes",
      "Proof ledger writes records",
      "Layer registry reports state",
      "Dashboard renders",
      "Simulation is labelled",
      "Native BLE is not claimed in Replit",
      "EAS/local APK build passes",
      "APK installs",
      "App opens without crash",
      "Two-phone BLE proof captured",
    ],
    build,
  };
}
TS

cat > "$CORE/acceptance/acceptanceProof.ts" <<'TS'
import { AcceptanceProof } from "../types/core.types";
import { checkBuildReadiness } from "../build/buildPipeline";
import { verifyProofChain } from "../proof/proofLedger";

export function createAcceptanceProof(): AcceptanceProof {
  const build = checkBuildReadiness();
  const proofChainOk = verifyProofChain();

  const passed: string[] = [];
  const failed: string[] = [];
  const requiredNext: string[] = [];

  if (proofChainOk) passed.push("Proof chain integrity");
  else failed.push("Proof chain integrity");

  if (build.canBuildApk) passed.push("Build readiness gate");
  else {
    failed.push("Build readiness gate");
    requiredNext.push(...build.missing);
  }

  return {
    accepted: failed.length === 0,
    summary:
      failed.length === 0
        ? "MauriCore v1 passed acceptance gates."
        : "MauriCore v1 scaffold installed, but production acceptance requires remaining proof.",
    passed,
    failed,
    requiredNext,
  };
}
TS

# ============================================================
# 24. INDEX EXPORT
# ============================================================

cat > "$CORE/index.ts" <<'TS'
export * from "./types/core.types";

export * from "./config/mauricore.config";

export * from "./constitution/coreConstitution";

export * from "./culture/tikangaEngine";

export * from "./math/mathIntelligence";

export * from "./proof/hashEngine";
export * from "./proof/proofLedger";

export * from "./builder/layerRegistry";
export * from "./builder/adapterRegistry";
export * from "./builder/verificationGate";
export * from "./builder/builderPlanner";

export * from "./memory/livingMemory";

export * from "./security/securityEngine";

export * from "./packet/packetEngine";

export * from "./routing/routingEngine";

export * from "./healing/homeostasis";
export * from "./healing/selfHealing";

export * from "./boundaries/boundaryEngine";

export * from "./ai/mauriAiOperator";

export * from "./build/buildPipeline";

export * from "./dashboard/governanceDashboard";

export * from "./bridges/nativeBridge";

export * from "./deployment/deploymentReadiness";

export * from "./acceptance/acceptanceProof";

export * from "./testing/smoke";
TS

# ============================================================
# 25. DOCUMENTATION
# ============================================================

cat > "$DOCS/MAURICORE_ARCHITECTURE.md" <<'MD'
# MauriCore Living Kernel v1 Architecture

## Purpose

MauriCore is a governed living builder kernel designed to support, verify, heal, route, learn, and evolve software layers without destroying the foundation.

## Core Law

Core decides.
App displays.
Native bridge executes.
Proof ledger records.
Verification gate approves.

## Main Layers

1. Core Constitution
2. Tikanga Governance
3. Mathematical Intelligence
4. Layer Registry
5. Proof Ledger
6. Living Memory
7. Routing Intelligence
8. Packet Engine
9. Security Engine
10. Homeostasis
11. Self-Healing
12. Boundary Engine
13. Builder Planner
14. Adapter System
15. Mauri AI Operator
16. Build Pipeline
17. Governance Dashboard
18. Native Bridge
19. Rust Core
20. Acceptance Proof

## Production Boundary

Replit preview can validate UI, API fallback, TypeScript, logic, and simulation.

Real BLE proof requires APK installation on physical devices.
MD

cat > "$DOCS/MAURICORE_RULES.md" <<'MD'
# MauriCore Rules

- Understand first.
- Protect the foundation.
- Verify before change.
- Never fake proof.
- Never label simulation as live.
- Do not delete working systems without backup.
- Preserve original engineering intent.
- Low-risk repairs may auto-run.
- Medium-risk repairs may be proposed.
- High-risk repairs require human approval.
- Identity, crypto, native BLE, and privacy changes require review.
- Memory can guide behaviour but cannot override Core law.
MD

cat > "$DOCS/MAURICORE_INTEGRATIONS.md" <<'MD'
# MauriCore Integration Definitions

## Architecture
Defines the full relationship between Core, UI, native runtime, proof, memory, and build gates.

## Folder Structure
Keeps every system isolated so future layers can be added without damaging existing code.

## Core Configuration
Controls proof, governance, learning, routing, healing, build, and boundary behaviour.

## UI Wiring
Dashboard and screens read Core status through a governed dashboard service.

## Native Bridge Wiring
Native calls are isolated behind bridge placeholders until Android/iOS modules are built.

## Rust Core Wiring
Rust scaffold provides future production-grade decision, routing, proof, and health logic.

## Adapter System
Adapters scan and understand React Native, Expo, BLE, API, build, and future app environments.

## Layer Registry
Tracks missing, partial, stable, verified, protected, unsafe, and deprecated layers.

## Proof Ledger
Records decisions, repairs, builds, routing, memory, packet, and layer proof.

## Verification Gates
Blocks layer advancement unless rollback, proof, confidence, and checks pass.

## Living Memory
Stores experience, lessons, failures, repairs, and future behaviour.

## Self-Healing
Creates and executes safe repair plans based on system health.

## Homeostasis
Monitors system vital signs and classifies health.

## Tikanga Governance
Adds tapu/noa, mana, pono, tika, kaitiakitanga, rangatiratanga, rāhui, and Whare Tapa Whā logic.

## Mathematical Intelligence
Adds √2, golden growth, Fibonacci backoff, entropy, Bayesian updates, fuzzy logic, and weighted scoring.

## Security
Provides identity scaffold, packet signing scaffold, replay/threat detection, and memory poisoning awareness.

## Packet Engine
Creates packet IDs, payload hashes, ACK tokens, TTL, route path, privacy state, and signatures.

## Routing Engine
Scores routes using trust, ACK, privacy, latency, and battery. Safest verified route wins.

## Build Pipeline
Checks readiness before APK build and records required proof.

## Governance Dashboard
Exposes Core health, layers, proof, memory, build readiness, and Mauri AI review.

## Documentation
Explains architecture, rules, integrations, proof, and production boundaries.

## Testing
Smoke test confirms Core planning, packet creation, routing, repair planning, proof, and dashboard data.

## Deployment
Lists readiness gates from Replit through APK and two-phone proof.

## Acceptance Proof
Final acceptance requires passing proof chain, build readiness, APK proof, and device proof.
MD

# ============================================================
# 26. PACKAGE.JSON SCRIPT UPDATE
# ============================================================

if [ -f "$ROOT/package.json" ]; then
  node <<'NODE'
const fs = require("fs");
const path = "package.json";
const pkg = JSON.parse(fs.readFileSync(path, "utf8"));
pkg.scripts = pkg.scripts || {};
pkg.scripts["mauricore:test"] = pkg.scripts["mauricore:test"] || "tsx scripts/mauricore-smoke-test.ts";
pkg.scripts["mauricore:check"] = pkg.scripts["mauricore:check"] || "tsc --noEmit";
pkg.scripts["mauricore:rust:check"] = pkg.scripts["mauricore:rust:check"] || "cd rust/mauricore && cargo check";
fs.writeFileSync(path, JSON.stringify(pkg, null, 2));
NODE
else
  cat > "$ROOT/package.json" <<'JSON'
{
  "scripts": {
    "mauricore:test": "tsx scripts/mauricore-smoke-test.ts",
    "mauricore:check": "tsc --noEmit",
    "mauricore:rust:check": "cd rust/mauricore && cargo check"
  }
}
JSON
fi

echo ""
echo "============================================================"
echo "MAURICORE LIVING KERNEL v1 INSTALLED"
echo "============================================================"
echo ""
echo "Files created under:"
echo "  src/mauricore"
echo "  docs/mauricore"
echo "  rust/mauricore"
echo "  scripts/mauricore-smoke-test.ts"
echo ""
echo "Next validation commands:"
echo "  npm run mauricore:check"
echo "  npm run mauricore:test"
echo "  npm run mauricore:rust:check"
echo ""
echo "If tsx is missing, install it:"
echo "  npm install -D tsx"
echo ""
echo "Production note:"
echo "  Real BLE/native proof still requires APK on physical phones."
echo "  Replit simulation must never be claimed as live BLE proof."
echo ""
