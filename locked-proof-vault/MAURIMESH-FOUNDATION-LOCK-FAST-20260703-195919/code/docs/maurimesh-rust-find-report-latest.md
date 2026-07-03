# MauriMesh Rust Find Report

Generated: 20260610-112844

## 1. Rust Cargo Projects

- [x] Cargo.toml files found
  - rust/maurimesh-core/Cargo.toml
  - rust/mauricore/Cargo.toml

## 2. Rust Source Files

- [x] Rust .rs files found
  - rust/maurimesh-core/src/types.rs
  - rust/maurimesh-core/src/hash.rs
  - rust/maurimesh-core/src/packet.rs
  - rust/maurimesh-core/src/route.rs
  - rust/maurimesh-core/src/ack.rs
  - rust/maurimesh-core/src/queue.rs
  - rust/maurimesh-core/src/proof.rs
  - rust/maurimesh-core/src/simulation.rs
  - rust/maurimesh-core/src/truth.rs
  - rust/maurimesh-core/src/ffi.rs
  - rust/maurimesh-core/src/lib.rs
  - rust/maurimesh-core/src/main.rs
  - rust/mauricore/src/lib.rs
  - rust/mauricore/src/decision.rs
  - rust/mauricore/src/routing.rs
  - rust/mauricore/src/health.rs
  - rust/mauricore/src/proof.rs

## 3. Rust Directory Summary

  - src/mauricore
  - backup-before-agentless-20260530-063813/app/trust
  - docs/mauricore
  - rust
  - rust/maurimesh-core
  - rust/mauricore
  - reports/mauricore
  - backup-before-isolating-router-layouts-20260606-165327/app/trust
  - backup-before-mauricore-v1-20260608-095016
  - backup-before-mauricore-governance-ui-20260608-112408
  - backup-before-mauricore-build-test-all-20260608-112755
  - backup-before-force-mauricore-button-20260608-115007
  - dist-mauricore-button-check
  - backup-before-mauricore-android-ble-bridge-20260608-120005
  - dist-mauricore-ble-runtime-bridge
  - backup-before-mauricore-ble-runtime-button-20260608-120136
  - dist-mauricore-ble-runtime-button
  - backup-before-mauricore-build-test-all-20260608-120332
  - dist-mauricore-check

## 4. Package.json Rust Scripts

24:    "mauricore:test": "tsx scripts/mauricore-smoke-test.ts",
25:    "mauricore:check": "tsc --noEmit",
26:    "mauricore:rust:check": "cd rust/mauricore && cargo check"
- [x] Rust/Cargo scripts found in package.json

## 5. Cargo Check

- [ ] cargo not found in this environment

## 6. Android JNI / Native Library Wiring

### Android .so files
- [ ] No .so files found under android/src/app

### jniLibs references
/home/runner/workspace/android/app/build.gradle:125:        jniLibs {
- [x] jniLibs reference found

### System.loadLibrary / loadLibrary references
- [ ] No loadLibrary reference found

### JNI / UniFFI / FFI references
/home/runner/workspace/rust/maurimesh-core/src/ffi.rs:1:use std::ffi::{CStr, CString};
/home/runner/workspace/rust/maurimesh-core/src/lib.rs:10:pub mod ffi;
/home/runner/workspace/rust/maurimesh-core/Cargo.toml:11:crate-type = ["rlib", "cdylib", "staticlib"]
/home/runner/workspace/rust/mauricore/Cargo.toml:8:crate-type = ["rlib", "cdylib"]
/home/runner/workspace/android/gradlew:38:#           «${var#prefix}», «${var%suffix}», and «$( cmd )»;
/home/runner/workspace/android/app/build.gradle:125:        jniLibs {
/home/runner/workspace/android/app/src/debug/AndroidManifest.xml:6:    <application android:usesCleartextTraffic="true" tools:targetApi="28" tools:ignore="GoogleAppIndexingWarning" tools:replace="android:usesCleartextTraffic" />
/home/runner/workspace/android/app/src/debugOptimized/AndroidManifest.xml:6:    <application android:usesCleartextTraffic="true" tools:targetApi="28" tools:ignore="GoogleAppIndexingWarning" tools:replace="android:usesCleartextTraffic" />
/home/runner/workspace/src/lib/meshGovernanceSim.ts:5:  trafficShapedRoutes: number;
/home/runner/workspace/src/lib/meshGovernanceSim.ts:17:// engine so the dashboard can show the self-healing and traffic-control layers
/home/runner/workspace/src/lib/meshGovernanceSim.ts:54:      trafficShapedRoutes: stats.trafficShapedRoutes,
/home/runner/workspace/src/lib/governanceHistory.ts:41:      trafficShapedRoutes: counters.trafficShapedRoutes,
/home/runner/workspace/src/lib/meshClient.ts:11:  // Self-healing / traffic-control counters from the shared server-side engine.
/home/runner/workspace/src/components/SystemBrainPanel.tsx:11:      <Text style={styles.title}>Self-Efficient System Score</Text>
/home/runner/workspace/src/maurimesh/live/meshCharts.tsx:86:  const suffix = unit ? ` ${unit}` : "";
/home/runner/workspace/src/maurimesh/live/meshCharts.tsx:91:        {suffix}
/home/runner/workspace/src/maurimesh/live/meshCharts.tsx:94:        0{suffix}
/home/runner/workspace/app/mesh-status.tsx:146:        <Text style={styles.cardTitle}>Self-Healing & Traffic Control</Text>
/home/runner/workspace/app/mesh-status.tsx:156:          <Text style={styles.govLabel}>Traffic-shaped routes</Text>
/home/runner/workspace/app/mesh-status.tsx:158:            {governance?.trafficShapedRoutes ?? 0}
/home/runner/workspace/app/mesh-status.tsx:176:          traffic-control layers, updating every {GOVERNANCE_TICK_MS / 1000}s as
/home/runner/workspace/app/mesh-status.tsx:207:              Traffic-shaped
/home/runner/workspace/app/mesh-status.tsx:210:              {governance?.trafficShapedRoutes ?? 0}
/home/runner/workspace/app/mesh-status.tsx:215:            values={history.map((h) => h.trafficShapedRoutes)}
/home/runner/workspace/app/mesh/store-forward-queue.tsx:52:          <EmptyNote text="The store-forward queue is empty. Messages that can't be delivered immediately are held here and relayed once a peer becomes reachable. Queued traffic appears here as soon as mesh delivery is exercised." />
- [x] JNI/FFI style reference found

## 7. Android Gradle Rust/Cargo Hooks

/home/runner/workspace/android/app/build.gradle:125:        jniLibs {
- [x] Android Gradle/native Rust-related reference found

## 8. Runtime Bridge Search

/home/runner/workspace/src/lib/mauriEssentials.ts:25:    enhances: "Allows MauriMesh to act as a trusted local messenger during weak or failed connectivity.",
/home/runner/workspace/src/lib/mauriEssentials.ts:32:    reason: "Records route success, failure, latency, and trust change.",
/home/runner/workspace/src/lib/mauriEssentials.ts:48:    reason: "Balances signal, battery, trust, urgency, privacy, and delivery chance.",
/home/runner/workspace/src/lib/mauriEssentials.ts:118:    name: "Decentralised Trust Memory",
/home/runner/workspace/src/lib/mauriEssentials.ts:120:    reason: "Lets node trust rise or fall based on behaviour.",
/home/runner/workspace/src/lib/mauriEssentials.ts:182:      name: "Trust memory",
/home/runner/workspace/src/lib/mauriEssentials.ts:183:      status: snapshot.trustCount > 0 ? "PASS" : "WARN",
/home/runner/workspace/src/lib/mauriEssentials.ts:185:        snapshot.trustCount > 0
/home/runner/workspace/src/lib/mauriEssentials.ts:186:          ? `${snapshot.trustCount} trust record(s) active.`
/home/runner/workspace/src/lib/mauriEssentials.ts:187:          : "No trust memory yet. Run a demo and ACK/fail route.",
/home/runner/workspace/src/lib/meshGovernanceSim.ts:32:    trustBlockThreshold: 35,
/home/runner/workspace/src/lib/meshGovernanceSim.ts:45:    engine.upsertPeer({ id: "RELAY_1", label: "Relay 1", transport: "simulation", signal: 88, trust: 80 });
/home/runner/workspace/src/lib/meshGovernanceSim.ts:46:    engine.upsertPeer({ id: "RELAY_2", label: "Relay 2", transport: "simulation", signal: 82, trust: 76 });
/home/runner/workspace/src/lib/meshGovernanceSim.ts:47:    engine.upsertPeer({ id: "FLAKY_X", label: "Flaky X", transport: "simulation", signal: 60, trust: 40 });
/home/runner/workspace/src/lib/meshGovernanceSim.ts:63:    engine.upsertPeer({ id: "RELAY_1", transport: "simulation", signal: 88, trust: 80, lastSeen: now });
/home/runner/workspace/src/lib/meshGovernanceSim.ts:64:    engine.upsertPeer({ id: "RELAY_2", transport: "simulation", signal: 82, trust: 76, lastSeen: now });
/home/runner/workspace/src/lib/meshClient.ts:34:    // trusted native/live transport proof. Always label this data as
/home/runner/workspace/src/lib/uiRemainder.ts:39:    why: "You need a UI where routing decisions are visible: BLE, Wi-Fi, relay, internet fallback, TTL, trust, and path score.",
/home/runner/workspace/src/lib/uiRemainder.ts:137:    title: "MauriCore Status Panel",
/home/runner/workspace/src/lib/uiRemainder.ts:141:    why: "MauriCore needs a compact reusable panel for living memory, governance, BLE runtime, and routing state.",
/home/runner/workspace/src/lib/uiRemainder.ts:143:      "Create src/components/MauriCoreStatusPanel.tsx",
/home/runner/workspace/src/lib/uiBackupRoutes.ts:129:    fallbackRoute: "/mauricore-governance",
/home/runner/workspace/src/lib/uiBackupRoutes.ts:159:    title: "MauriCore Governance",
/home/runner/workspace/src/lib/uiBackupRoutes.ts:160:    route: "/mauricore-governance",
/home/runner/workspace/src/lib/uiBackupRoutes.ts:163:    purpose: "MauriCore governance view.",
/home/runner/workspace/src/lib/uiBackupRoutes.ts:167:    title: "MauriCore BLE Runtime",
/home/runner/workspace/src/lib/uiBackupRoutes.ts:168:    route: "/mauricore-ble-runtime",
/home/runner/workspace/src/components/RouteDecisionPanel.tsx:18:        Visual decision layer for BLE, relay, Wi-Fi, internet fallback, trust score, TTL, and path selection.
/home/runner/workspace/src/components/SelfHealingPanel.tsx:9:    "Lower trust on failed relay",
/home/runner/workspace/src/components/MauriCoreStatusPanel.tsx:6:export function MauriCoreStatusPanel() {
/home/runner/workspace/src/components/MauriCoreStatusPanel.tsx:18:      <Text style={styles.title}>MauriCore</Text>
/home/runner/workspace/src/components/HybridWifiBleMeshPanel.tsx:45:        peerTrustScore: 62,
/home/runner/workspace/src/components/HybridWifiBleMeshPanel.tsx:62:        peerTrustScore: 86,
/home/runner/workspace/src/components/HybridWifiBleMeshPanel.tsx:78:      peerTrustScore: 91,
/home/runner/workspace/src/operating/mauri155LayerCatalog.ts:24:    "peer table, friend graph, trust graph, group resilience, path whakapapa, and relationship memory",
/home/runner/workspace/src/operating/mauri155LayerCatalog.ts:156:    "Trusted Peer Memory",
/home/runner/workspace/src/operating/mauri155OperatingRuntime.ts:82:        "Route success teaches routing, packet integrity, ACK confidence, whānau trust, and Living Mesh visibility.",
/home/runner/workspace/src/operating/mauri155OperatingRuntime.ts:112:        "ACK received. The system learns delivery truth, peer trust, latency expectation, and route quality.",
/home/runner/workspace/src/ai/mauriAiTypes.ts:17:  peerTrusted?: boolean;
/home/runner/workspace/src/ai/mauriAiTypes.ts:32:  trustScore: number;
/home/runner/workspace/src/ai/validateMauriAiIntelligenceRuntime.ts:15:      trustScore: 0.9,
/home/runner/workspace/src/ai/validateMauriAiIntelligenceRuntime.ts:26:      trustScore: 0.72,
/home/runner/workspace/src/ai/validateMauriAiIntelligenceRuntime.ts:37:      trustScore: 0.6,
/home/runner/workspace/src/ai/validateMauriAiIntelligenceRuntime.ts:48:    peerTrusted: true,
/home/runner/workspace/src/ai/validateMauriAiIntelligenceRuntime.ts:58:    peerTrusted: true,
/home/runner/workspace/src/routing/mauriAiRoutingIntelligence.ts:17:    const trustScore = clamp01(candidate.trustScore);
/home/runner/workspace/src/routing/mauriAiRoutingIntelligence.ts:26:        trustScore * 0.18 +
/home/runner/workspace/src/routing/mauriAiRoutingIntelligence.ts:36:      `trust=${trustScore.toFixed(2)}`,
/home/runner/workspace/src/routing/mauriAiRoutingIntelligence.ts:57:    if (signal.ackSuccess) return "ACK success strengthens route trust and future selection.";
/home/runner/workspace/src/routing/jumpCodeEngine.ts:25:      .sort((a, b) => b.ackRate + b.trustScore - (a.ackRate + a.trustScore))
/home/runner/workspace/src/routing/jumpCodeEngine.ts:31:        : relays.reduce((sum, relay) => sum + relay.ackRate + relay.trustScore, 0) /
/home/runner/workspace/src/routing/jumpCodeEngine.ts:44:        `avgRelayTrustAck=${avgRelay.toFixed(2)}`,
/home/runner/workspace/src/governance/aiGovernanceIntelligence.ts:28:    if (signal.peerTrusted === false) {
/home/runner/workspace/src/governance/aiGovernanceIntelligence.ts:30:      warnings.push("Peer is not trusted.");
/home/runner/workspace/src/mesh/bluetoothMeshSuperEngine.ts:52:  trust: number;
/home/runner/workspace/src/mesh/bluetoothMeshSuperEngine.ts:277:      trust: existing?.trust ?? 70,
/home/runner/workspace/src/mesh/bluetoothMeshSuperEngine.ts:585:      peer.trust = clamp(peer.trust + 2);
/home/runner/workspace/src/mesh/bluetoothMeshSuperEngine.ts:593:      peer.trust = clamp(peer.trust - 6);
/home/runner/workspace/src/mesh/bluetoothMeshSuperEngine.ts:599:      if (peer.health < 20 || peer.trust < 20) {
/home/runner/workspace/src/mesh/bluetoothMeshSuperEngine.ts:631:      if (peer.state === "recovering" && peer.health >= 60 && peer.trust >= 50) {
/home/runner/workspace/src/mesh/bluetoothMeshSuperEngine.ts:727:    score += (peer.trust - 70) * 0.25;
/home/runner/workspace/src/mesh/bluetoothMeshSuperEngine.ts:741:    const trust = peer.trust / 100;
/home/runner/workspace/src/mesh/bluetoothMeshSuperEngine.ts:750:      trust * 0.2 +
/home/runner/workspace/src/mesh/bluetoothMeshSuperEngine.ts:757:      trust * 0.18 +
/home/runner/workspace/src/mesh/bluetoothMeshSuperEngine.ts:764:    const weakestSafeFactor = Math.min(signal, trust, health, reliability);
/home/runner/workspace/src/mesh/bluetoothMeshSuperEngine.ts:784:      (peer.trust / 100) * 0.11 +
/home/runner/workspace/src/maurimesh/invention-engine/types.ts:17:export type TrustLevel =
/home/runner/workspace/src/maurimesh/invention-engine/types.ts:50:  trust: TrustLevel;
/home/runner/workspace/src/maurimesh/invention-engine/types.ts:103:  trustDelta: number;
/home/runner/workspace/src/maurimesh/invention-engine/offlineIdentityMesh.ts:1:import { MeshNode, TrustLevel } from "./types";
/home/runner/workspace/src/maurimesh/invention-engine/offlineIdentityMesh.ts:8:  trust: TrustLevel;
/home/runner/workspace/src/maurimesh/invention-engine/offlineIdentityMesh.ts:22:      trust: "OBSERVED",
/home/runner/workspace/src/maurimesh/invention-engine/offlineIdentityMesh.ts:38:      trust: node.trust,
/home/runner/workspace/src/maurimesh/invention-engine/offlineIdentityMesh.ts:49:    return Boolean(identity && identity.trust !== "BLOCKED");
/home/runner/workspace/src/maurimesh/invention-engine/offlineIdentityMesh.ts:52:  promoteTrust(deviceId: string, trust: TrustLevel): void {
/home/runner/workspace/src/maurimesh/invention-engine/offlineIdentityMesh.ts:55:    identity.trust = trust;
/home/runner/workspace/src/maurimesh/invention-engine/livingRouteMemory.ts:14:      trustDelta: 0,
/home/runner/workspace/src/maurimesh/invention-engine/livingRouteMemory.ts:22:    existing.trustDelta += 0.03;
/home/runner/workspace/src/maurimesh/invention-engine/livingRouteMemory.ts:36:      trustDelta: 0,
/home/runner/workspace/src/maurimesh/invention-engine/livingRouteMemory.ts:41:    existing.trustDelta -= 0.05;
/home/runner/workspace/src/maurimesh/invention-engine/livingRouteMemory.ts:56:    const trustScore = Math.max(0, Math.min(1, 0.5 + mem.trustDelta));
/home/runner/workspace/src/maurimesh/invention-engine/livingRouteMemory.ts:58:    return successRatio * 0.5 + latencyScore * 0.25 + trustScore * 0.25;
/home/runner/workspace/src/maurimesh/invention-engine/tikangaGovernance.ts:11:    if (fromNode?.trust === "BLOCKED") {
/home/runner/workspace/src/maurimesh/invention-engine/tikangaGovernance.ts:14:        reason: "Sender is blocked by trust policy.",
/home/runner/workspace/src/maurimesh/invention-engine/tikangaGovernance.ts:20:    if (toNode?.trust === "BLOCKED") {
/home/runner/workspace/src/maurimesh/invention-engine/tikangaGovernance.ts:23:        reason: "Recipient is blocked by trust policy.",
/home/runner/workspace/src/maurimesh/invention-engine/tikangaGovernance.ts:30:      restrictions.push("Only trusted or verified routes may carry protected packet.");
/home/runner/workspace/src/maurimesh/invention-engine/mauriAiRoutingConscience.ts:27:    const onlineTrusted = nodes.filter(
/home/runner/workspace/src/maurimesh/invention-engine/mauriAiRoutingConscience.ts:30:        n.trust !== "BLOCKED" &&
/home/runner/workspace/src/maurimesh/invention-engine/mauriAiRoutingConscience.ts:58:    const relays = onlineTrusted
/home/runner/workspace/src/maurimesh/invention-engine/mauriAiRoutingConscience.ts:64:          packet.culturalState === "TAPU_PROTECTED" && n.trust !== "VERIFIED" && n.trust !== "GUARDIAN"
/home/runner/workspace/src/maurimesh/invention-engine/mauriAiRoutingConscience.ts:102:          reason: "Best available trusted relay selected.",
/home/runner/workspace/src/maurimesh/invention-engine/mauriAiRoutingConscience.ts:116:    const trust =
/home/runner/workspace/src/maurimesh/invention-engine/mauriAiRoutingConscience.ts:117:      node.trust === "GUARDIAN" ? 1 :
/home/runner/workspace/src/maurimesh/invention-engine/mauriAiRoutingConscience.ts:118:      node.trust === "VERIFIED" ? 0.9 :
/home/runner/workspace/src/maurimesh/invention-engine/mauriAiRoutingConscience.ts:119:      node.trust === "TRUSTED" ? 0.75 :
/home/runner/workspace/src/maurimesh/invention-engine/mauriAiRoutingConscience.ts:120:      node.trust === "OBSERVED" ? 0.55 :
/home/runner/workspace/src/maurimesh/invention-engine/mauriAiRoutingConscience.ts:121:      node.trust === "UNKNOWN" ? 0.35 : 0;
/home/runner/workspace/src/maurimesh/invention-engine/mauriAiRoutingConscience.ts:134:        [trust, 0.35],
/home/runner/workspace/src/maurimesh/invention-engine/cleoChanelleSynthFederation.ts:17:        ? "The message can be safely stored and forwarded when the next trusted path appears."
/home/runner/workspace/src/maurimesh/invention-engine/storeAndForwardSocialMesh.ts:13:      reason: "Packet stored for future trusted delivery path.",
/home/runner/workspace/src/maurimesh/invention-engine/livingMeshVisualProof.ts:7:  trust: string;
/home/runner/workspace/src/maurimesh/invention-engine/livingMeshVisualProof.ts:39:        trust: n.trust,
/home/runner/workspace/src/maurimesh/invention-engine/tapuNoaPrivacyStates.ts:5:    if (packet.culturalState === "NOA_OPEN") return node.trust !== "BLOCKED";
/home/runner/workspace/src/maurimesh/invention-engine/tapuNoaPrivacyStates.ts:8:      return node.trust === "VERIFIED" || node.trust === "GUARDIAN";
/home/runner/workspace/src/maurimesh/invention-engine/tapuNoaPrivacyStates.ts:12:      return node.trust !== "BLOCKED" && node.batteryPct > 5;
/home/runner/workspace/src/maurimesh/invention-engine/tapuNoaPrivacyStates.ts:15:    return node.trust === "TRUSTED" || node.trust === "VERIFIED" || node.trust === "GUARDIAN";
/home/runner/workspace/src/maurimesh/invention-engine/tapuNoaPrivacyStates.ts:45:        return "Whanaungatanga / Trusted relationship";
/home/runner/workspace/src/maurimesh/invention-engine/decentralisedTrustMemory.ts:1:import { MeshNode, TrustLevel } from "./types";
/home/runner/workspace/src/maurimesh/invention-engine/decentralisedTrustMemory.ts:4:export type TrustRecord = {
/home/runner/workspace/src/maurimesh/invention-engine/decentralisedTrustMemory.ts:12:export class DecentralisedTrustMemory {
/home/runner/workspace/src/maurimesh/invention-engine/decentralisedTrustMemory.ts:13:  private trust = new Map<string, TrustRecord>();
/home/runner/workspace/src/maurimesh/invention-engine/decentralisedTrustMemory.ts:15:  observeSuccess(nodeId: string, reason = "Successful relay or ACK."): TrustRecord {
/home/runner/workspace/src/maurimesh/invention-engine/decentralisedTrustMemory.ts:20:    this.trust.set(nodeId, record);
/home/runner/workspace/src/maurimesh/invention-engine/decentralisedTrustMemory.ts:24:  observeFailure(nodeId: string, reason = "Failed relay or missing ACK."): TrustRecord {
/home/runner/workspace/src/maurimesh/invention-engine/decentralisedTrustMemory.ts:29:    this.trust.set(nodeId, record);
/home/runner/workspace/src/maurimesh/invention-engine/decentralisedTrustMemory.ts:34:    const record = this.trust.get(node.id);
/home/runner/workspace/src/maurimesh/invention-engine/decentralisedTrustMemory.ts:39:      trust: this.scoreToTrust(record.score),
/home/runner/workspace/src/maurimesh/invention-engine/decentralisedTrustMemory.ts:43:  scoreToTrust(score: number): TrustLevel {
/home/runner/workspace/src/maurimesh/invention-engine/decentralisedTrustMemory.ts:52:  exportTrust(): TrustRecord[] {
/home/runner/workspace/src/maurimesh/invention-engine/decentralisedTrustMemory.ts:53:    return Array.from(this.trust.values());
/home/runner/workspace/src/maurimesh/invention-engine/decentralisedTrustMemory.ts:56:  private getOrCreate(nodeId: string): TrustRecord {
/home/runner/workspace/src/maurimesh/invention-engine/decentralisedTrustMemory.ts:58:      this.trust.get(nodeId) || {
/home/runner/workspace/src/maurimesh/invention-engine/communityInfrastructure.ts:31:    if (node.trust === "BLOCKED") return false;
/home/runner/workspace/src/maurimesh/invention-engine/livingSelfGovernedAiMesh.ts:20:import { DecentralisedTrustMemory } from "./decentralisedTrustMemory";
/home/runner/workspace/src/maurimesh/invention-engine/livingSelfGovernedAiMesh.ts:37:  readonly trustMemory = new DecentralisedTrustMemory();
/home/runner/workspace/src/maurimesh/invention-engine/livingSelfGovernedAiMesh.ts:47:      return this.trustMemory.applyToNode(n);
/home/runner/workspace/src/maurimesh/invention-engine/livingSelfGovernedAiMesh.ts:122:        this.trustMemory.observeSuccess(hop.nodeId, "Selected as healthy route candidate.");
/home/runner/workspace/src/maurimesh/invention-engine/livingSelfGovernedAiMesh.ts:166:      this.trustMemory.observeSuccess(nodeId, "ACK confirmed route trust.");
/home/runner/workspace/src/maurimesh/invention-engine/livingSelfGovernedAiMesh.ts:182:      this.trustMemory.observeFailure(nodeId, reason);
/home/runner/workspace/src/maurimesh/invention-engine/livingSelfGovernedAiMesh.ts:198:  trustMemoryExport() {
/home/runner/workspace/src/maurimesh/invention-engine/livingSelfGovernedAiMesh.ts:199:    return this.trustMemory.exportTrust();
/home/runner/workspace/src/maurimesh/invention-engine/index.ts:14:export * from "./decentralisedTrustMemory";
/home/runner/workspace/src/maurimesh/invention-engine/demo.ts:10:    trust: "VERIFIED",
/home/runner/workspace/src/maurimesh/invention-engine/demo.ts:22:    trust: "TRUSTED",
/home/runner/workspace/src/maurimesh/invention-engine/demo.ts:33:    trust: "OBSERVED",
/home/runner/workspace/src/maurimesh/ui/mauriUiEngine.ts:28:  trustCount: number;
/home/runner/workspace/src/maurimesh/ui/mauriUiEngine.ts:43:    trust: "VERIFIED",
/home/runner/workspace/src/maurimesh/ui/mauriUiEngine.ts:55:    trust: "TRUSTED",
/home/runner/workspace/src/maurimesh/ui/mauriUiEngine.ts:66:    trust: "OBSERVED",
/home/runner/workspace/src/maurimesh/ui/mauriUiEngine.ts:77:    trust: "VERIFIED",
/home/runner/workspace/src/maurimesh/ui/mauriUiEngine.ts:214:    trustCount: engine.trustMemoryExport().length,
/home/runner/workspace/src/maurimesh/system-brain/layerRegistry.ts:10:    optimises: ["identity", "offline messaging", "trust", "local-first startup"],
/home/runner/workspace/src/maurimesh/system-brain/layerRegistry.ts:21:    dependencies: ["delivery_ledger", "decentralised_trust_memory"],
/home/runner/workspace/src/maurimesh/system-brain/layerRegistry.ts:40:    optimises: ["safety", "abuse prevention", "policy control", "trusted routing"],
/home/runner/workspace/src/maurimesh/system-brain/layerRegistry.ts:41:    dependencies: ["tikanga_governance", "trust_memory"],
/home/runner/workspace/src/maurimesh/system-brain/layerRegistry.ts:48:    purpose: "Balances route score, trust, battery, privacy, urgency, and delivery likelihood.",
/home/runner/workspace/src/maurimesh/system-brain/layerRegistry.ts:78:    purpose: "Stores packets until a trusted route appears.",
/home/runner/workspace/src/maurimesh/system-brain/layerRegistry.ts:100:    optimises: ["proof", "debugging", "learning", "trust scoring"],
/home/runner/workspace/src/maurimesh/system-brain/layerRegistry.ts:105:    id: "decentralised_trust_memory",
/home/runner/workspace/src/maurimesh/system-brain/layerRegistry.ts:106:    name: "Decentralised Trust Memory",
/home/runner/workspace/src/maurimesh/system-brain/layerRegistry.ts:108:    purpose: "Raises or lowers node trust through behaviour.",
/home/runner/workspace/src/maurimesh/system-brain/layerRegistry.ts:109:    belongsBecause: "Relay trust must be earned, not assumed.",
/home/runner/workspace/src/maurimesh/system-brain/layerRegistry.ts:138:    purpose: "Shows nodes, routes, trust, ledger, and route quality.",
/home/runner/workspace/src/maurimesh/system-brain/layerRegistry.ts:139:    belongsBecause: "Visible proof builds trust and speeds debugging.",
/home/runner/workspace/src/maurimesh/system-brain/buttonDecisionRouter.ts:35:    reason: "Tests route choice, ACK learning, failure learning, and trust updates.",
/home/runner/workspace/src/maurimesh/system-brain/buttonDecisionRouter.ts:67:    reason: "Shows ledger, trust memory, route memory, and synth state.",
/home/runner/workspace/src/maurimesh/system-brain/systemBrain.ts:38:  const trustScore = engine.trustCount > 0 ? 100 : 60;
/home/runner/workspace/src/maurimesh/system-brain/systemBrain.ts:45:      trustScore * 0.15 +
/home/runner/workspace/src/maurimesh/system-brain/systemBrain.ts:53:  if (engine.trustCount === 0) recommendations.push("Run ACK/fail route tests to create trust evolution.");
/home/runner/workspace/src/maurimesh/system-brain/systemBrain.ts:95:  runDemoMessage("Private tapu route test for trusted delivery only.");
/home/runner/workspace/src/maurimesh/intelligence/types.ts:16:  trust: number;
/home/runner/workspace/src/maurimesh/intelligence/RouteIntelligence.ts:15:      route.trust * 0.28 +
/home/runner/workspace/src/maurimesh/intelligence/RouteIntelligence.ts:40:        ? "Hybrid path selected because it balances delivery confidence, trust, latency, and energy."
/home/runner/workspace/src/maurimesh/intelligence/RouteIntelligence.ts:51:    trust: 78,
/home/runner/workspace/src/maurimesh/intelligence/RouteIntelligence.ts:61:    trust: 88,
/home/runner/workspace/src/maurimesh/intelligence/RouteIntelligence.ts:71:    trust: 83,
/home/runner/workspace/src/maurimesh/intelligence/RouteIntelligence.ts:81:    trust: 70,
/home/runner/workspace/src/maurimesh/intelligence/BackupIntelligence.ts:56:    trust: 80,
/home/runner/workspace/src/maurimesh/hybrid-wifi-ble-mesh/HybridWifiBleMeshTypes.ts:16:  peerTrustScore: number;
/home/runner/workspace/src/maurimesh/hybrid-wifi-ble-mesh/BackupHybridWifiBleMeshEngine.ts:166:  const highTrust = link.peerTrustScore >= 80;
/home/runner/workspace/src/maurimesh/hybrid-wifi-ble-mesh/BackupHybridWifiBleMeshEngine.ts:173:        (highTrust ? 15 : 0) +
/home/runner/workspace/src/maurimesh/hybrid-wifi-ble-mesh/BackupHybridWifiBleMeshEngine.ts:239:      peerTrustScore: 91,
/home/runner/workspace/src/maurimesh/test-layer/MauriMeshFullTestEngine.ts:25:  "/mauricore-governance",
/home/runner/workspace/src/maurimesh/test-layer/MauriMeshFullTestEngine.ts:26:  "/mauricore-ble-runtime",
/home/runner/workspace/src/mauricore/types/core.types.ts:89:  | "trusted"
/home/runner/workspace/src/mauricore/types/core.types.ts:134:  trust: number;
/home/runner/workspace/src/mauricore/config/mauricore.config.ts:4:  coreName: "MauriCore Living Kernel",
/home/runner/workspace/src/mauricore/config/mauricore.config.ts:35:    useTrustScore: true,
/home/runner/workspace/src/mauricore/constitution/coreConstitution.ts:2:import { mauriCoreConfig } from "../config/mauricore.config";
/home/runner/workspace/src/mauricore/routing/routingEngine.ts:4:export function scoreRouteEdge(edge: RouteEdge, destinationTrust: number): number {
/home/runner/workspace/src/mauricore/routing/routingEngine.ts:12:    { value: destinationTrust, weight: 1.2 },
/home/runner/workspace/src/mauricore/routing/routingEngine.ts:47:      edgeScore: scoreRouteEdge(edge, target.trust),
/home/runner/workspace/src/mauricore/routing/routingEngine.ts:57:      const scoreA = scoreRouteEdge(first, relay.trust);
/home/runner/workspace/src/mauricore/routing/routingEngine.ts:58:      const scoreB = scoreRouteEdge(second, target.trust);
/home/runner/workspace/src/mauricore/routing/routingEngine.ts:94:    reason: "Safest verified route selected using trust, ACK, privacy, latency, and battery scoring.",
/home/runner/workspace/src/mauricore/memory/livingMemory.ts:51:  if (record.confidence >= 0.85 && repeated >= 3) return "trusted";
/home/runner/workspace/src/mauricore/proof/hashEngine.ts:17: * For production security, replace with Rust/native SHA-256 or platform crypto.
/home/runner/workspace/src/mauricore/builder/layerRegistry.ts:23:  ["rust_core", "Rust Core", "partial", "high"],
/home/runner/workspace/src/mauricore/security/securityEngine.ts:10:  return `device_${deterministicHash({ seed, purpose: "mauricore_device_identity" })}`;
/home/runner/workspace/src/mauricore/bridges/README_NATIVE_BRIDGE.md:1:# MauriCore Native Bridge
/home/runner/workspace/src/mauricore/bridges/README_NATIVE_BRIDGE.md:20:UI → TypeScript Core → Rust/Core Decision → Native Bridge → Device Runtime → Proof Ledger
/home/runner/workspace/src/mauricore/dashboard/governanceDashboard.ts:16:      name: "MauriCore Living Kernel",
/home/runner/workspace/src/mauricore/dashboard/GovernanceDashboardPanel.tsx:11:        MauriCore Governance
/home/runner/workspace/src/mauricore/dashboard/MauriCoreGovernanceScreen.tsx:51:export default function MauriCoreGovernanceScreen() {
/home/runner/workspace/src/mauricore/dashboard/MauriCoreGovernanceScreen.tsx:71:      <Text style={styles.title}>MauriCore Governance</Text>
/home/runner/workspace/src/mauricore/dashboard/mauriCoreGovernanceRoute.ts:1:export const MAURICORE_GOVERNANCE_ROUTE = "/mauricore-governance";
/home/runner/workspace/src/mauricore/dashboard/MauriCoreBleRuntimeScreen.tsx:17:export default function MauriCoreBleRuntimeScreen() {
/home/runner/workspace/src/mauricore/dashboard/MauriCoreBleRuntimeScreen.tsx:33:      <Text style={styles.title}>MauriCore Android BLE Runtime</Text>
/home/runner/workspace/src/mauricore/deployment/deploymentReadiness.ts:11:      "MauriCore smoke test passes",
/home/runner/workspace/src/mauricore/acceptance/acceptanceProof.ts:26:        ? "MauriCore v1 passed acceptance gates."
/home/runner/workspace/src/mauricore/acceptance/acceptanceProof.ts:27:        : "MauriCore v1 scaffold installed, but production acceptance requires remaining proof.",
/home/runner/workspace/src/mauricore/testing/smoke.ts:9:export function runMauriCoreSmokeTest() {
/home/runner/workspace/src/mauricore/testing/smoke.ts:12:    action: "MauriCore smoke test start",
/home/runner/workspace/src/mauricore/testing/smoke.ts:23:    payload: { text: "MauriCore test packet" },
/home/runner/workspace/src/mauricore/testing/smoke.ts:30:      { id: "PHONE_A", label: "Phone A", trust: 0.95, battery: 0.8, signal: 0.9, online: true },
/home/runner/workspace/src/mauricore/testing/smoke.ts:31:      { id: "PHONE_B", label: "Phone B", trust: 0.9, battery: 0.75, signal: 0.85, online: true },
/home/runner/workspace/src/mauricore/index.ts:3:export * from "./config/mauricore.config";
/home/runner/workspace/app/dashboard.tsx:10:import { MauriCoreStatusPanel } from "../src/components/MauriCoreStatusPanel";
/home/runner/workspace/app/dashboard.tsx:54:      <MauriCoreStatusPanel />
/home/runner/workspace/app/dashboard.tsx:93:        <Text style={styles.sectionTitle}>MauriCore</Text>
/home/runner/workspace/app/dashboard.tsx:95:          <MauriButton title="MauriCore Governance" onPress={() => router.push("/mauricore-governance")} />
/home/runner/workspace/app/dashboard.tsx:96:          <MauriButton title="MauriCore BLE Runtime" onPress={() => router.push("/mauricore-ble-runtime")} />
/home/runner/workspace/app/mauricore-governance.tsx:5:import { MauriCoreStatusPanel } from "../src/components/MauriCoreStatusPanel";
/home/runner/workspace/app/mauricore-governance.tsx:8:export default function MauriCoreGovernanceScreen() {
/home/runner/workspace/app/mauricore-governance.tsx:11:      <Text style={styles.title}>MauriCore Governance</Text>
/home/runner/workspace/app/mauricore-governance.tsx:13:        Governance dashboard for MauriCore, Tikanga decision state, audit visibility, and safe UI proof.
/home/runner/workspace/app/mauricore-governance.tsx:15:      <MauriCoreStatusPanel />
/home/runner/workspace/app/mauricore-ble-runtime.tsx:7:import { MauriCoreStatusPanel } from "../src/components/MauriCoreStatusPanel";
/home/runner/workspace/app/mauricore-ble-runtime.tsx:11:export default function MauriCoreBleRuntimeScreen() {
/home/runner/workspace/app/mauricore-ble-runtime.tsx:15:      <Text style={styles.title}>MauriCore BLE Runtime</Text>
/home/runner/workspace/app/mauricore-ble-runtime.tsx:20:      <MauriCoreStatusPanel />
/home/runner/workspace/app/route-lab.tsx:12:        SIMULATION route design for BLE, relay, Wi-Fi, internet fallback, trust, TTL, and path selection.
/home/runner/workspace/app/operator-console.tsx:4:import { MauriCoreStatusPanel } from "../src/components/MauriCoreStatusPanel";
/home/runner/workspace/app/operator-console.tsx:17:      <MauriCoreStatusPanel />
- [x] Runtime bridge/reference strings found

## 9. Final Rust Status

- Cargo.toml count: 2
- Rust .rs count: 17
- Android/native .so count: 0
- Mauri-related loadLibrary count: 0
- Android Gradle Cargo/Rust hook count: 0

- Rust source status: PRESENT
- Rust APK integration status: SOURCE PRESENT, APK INTEGRATION NOT PROVEN

## Truth Boundary

Rust source files prove Rust exists in the repo.
They do not prove Rust is inside the APK.
APK Rust proof requires compiled .so files, Gradle wiring, Kotlin loadLibrary/JNI or UniFFI bridge, and runtime call proof.
