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
