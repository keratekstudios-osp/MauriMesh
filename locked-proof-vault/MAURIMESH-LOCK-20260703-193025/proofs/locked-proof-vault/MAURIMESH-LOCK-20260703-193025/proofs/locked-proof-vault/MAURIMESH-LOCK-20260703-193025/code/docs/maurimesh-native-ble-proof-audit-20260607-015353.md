# MauriMesh Native BLE Proof Audit

Generated: 20260607-015353

Purpose: identify existing BLE/native/proof files before restoring real wiring.
No files modified. No EAS build used.


## 1. Package Identity

```txt
    namespace 'com.maurimesh.messenger'
        applicationId 'com.maurimesh.messenger'
android/app/src/main/java/com/maurimesh/messenger/MainActivity.kt:package com.maurimesh.messenger
android/app/src/main/java/com/maurimesh/messenger/MainApplication.kt:package com.maurimesh.messenger
  name: [32m'MauriMesh'[39m,
  slug: [32m'MauriMesh'[39m,
  scheme: [32m'maurimesh'[39m,
    bundleIdentifier: [32m'com.maurimesh.messenger'[39m
    package: [32m'com.maurimesh.messenger'[39m,
```

## 2. Android Manifest BLE Permissions

```txt
```

## 3. Native Android BLE / Proof Files

```txt
android/app/src/main/java/com/maurimesh/mesh/MeshEngine.kt
android/app/src/main/java/com/maurimesh/mesh/MeshEngine.kt
android/app/src/main/java/com/maurimesh/mesh/MeshForegroundService.kt
android/app/src/main/java/com/maurimesh/mesh/MeshForegroundService.kt
android/app/src/main/java/com/maurimesh/mesh/MeshWatchdog.kt
android/app/src/main/java/com/maurimesh/mesh/MeshWatchdog.kt
android/app/src/main/java/com/maurimesh/messenger/MainActivity.kt
android/app/src/main/java/com/maurimesh/messenger/MainActivity.kt
android/app/src/main/java/com/maurimesh/messenger/MainApplication.kt
android/app/src/main/java/com/maurimesh/messenger/MainApplication.kt
android/app/src/main/java/com/maurimesh/routing/MeshRouteTable.kt
android/app/src/main/java/com/maurimesh/routing/MeshRouteTable.kt
android/app/src/main/java/com/maurimesh/service/MeshStartupService.kt
android/app/src/main/java/com/maurimesh/service/MeshStartupService.kt
android/app/src/main/res/drawable-hdpi/splashscreen_logo.png
android/app/src/main/res/drawable/ic_launcher_background.xml
android/app/src/main/res/drawable-mdpi/splashscreen_logo.png
android/app/src/main/res/drawable/rn_edit_text_material.xml
android/app/src/main/res/drawable-xhdpi/splashscreen_logo.png
android/app/src/main/res/drawable-xxhdpi/splashscreen_logo.png
android/app/src/main/res/drawable-xxxhdpi/splashscreen_logo.png
android/build/generated/autolinking/package.json.sha
android/build/reports/problems/problems-report.html
```

## 4. TypeScript BLE / Mesh / Proof Files

```txt
app/ble-proof.tsx
app/living-mesh.tsx
app/mesh-status.tsx
app/proof-ledger.tsx
docs/ANDROID_BACKGROUND_RUNTIME_PLAN.md
docs/maurimesh-native-ble-proof-audit-20260607-015353.md
docs/MAURIMESH_PACKET_FORMAT.md
docs/TWO_PHONE_PROOF_EVIDENCE.md
docs/TWO_PHONE_PROOF_PROTOCOL.md
scripts/adb-ble-runtime-proof.sh
scripts/find-ble-mesh-runtime.sh
scripts/maurimesh-completion-status-auditor.mjs
scripts/package.json
scripts/src/rollback.ts
scripts/test-maurimesh-api-url.sh
server/maurimeshIntelligentApiDriver.cjs
server/maurimeshPublicIntelligenceRoutes.cjs
src/components/ChatBubble.tsx
src/components/DeliveryLedgerPanel.tsx
src/components/LivingMeshCanvas.tsx
src/components/mesh/AckPathView.tsx
src/components/mesh/BleReadinessCard.tsx
src/components/mesh/BleScanProof.tsx
src/components/mesh/MeshTopologyView.tsx
src/components/mesh/NodeCard.tsx
src/components/mesh/PacketFlowView.tsx
src/components/mesh/PeerList.tsx
src/components/mesh/QueueVisualizer.tsx
src/components/mesh/RouteBeam.tsx
src/components/mesh/RouteHealthCard.tsx
src/components/MeshSignalCard.tsx
src/components/mesh/SignalMeter.tsx
src/components/RoutePlanPanel.tsx
src/components/ui/MeshBadge.tsx
src/components/ui/MeshButton.tsx
src/components/ui/MeshCard.tsx
src/components/ui/MeshHeader.tsx
src/components/ui/MeshInput.tsx
src/components/ui/MeshStatusPill.tsx
src/integration/MAURIMESH_155_INTEGRATION_POINTS.md
src/lib/bluetoothMeshClient.ts
src/lib/meshClient.ts
src/lib/proofLogger.ts
src/lib/proofSimulation.ts
src/maurimesh/api/intelligentApiDriver.ts
src/maurimesh/api/intelligentApiDriver.ts.bak-api-base-fix-20260603-142044
src/maurimesh/api/intelligentApiDriver.ts.bak-public-mesh-api-20260603-145405
src/maurimesh/api/publicIntelligenceClient.ts
src/maurimesh/api/publicIntelligenceClient.ts.bak-public-mesh-api-20260603-145405
src/maurimesh/config/apiBaseUrl.ts
src/maurimesh/invention-engine/cleoChanelleSynthFederation.ts
src/maurimesh/invention-engine/communityInfrastructure.ts
src/maurimesh/invention-engine/decentralisedTrustMemory.ts
src/maurimesh/invention-engine/demo.ts
src/maurimesh/invention-engine/hybridHumanAiNetworkProtocol.ts
src/maurimesh/invention-engine/index.ts
src/maurimesh/invention-engine/kiaKahaEmergencyRouting.ts
src/maurimesh/invention-engine/livingMeshVisualProof.ts
src/maurimesh/invention-engine/livingRouteMemory.ts
src/maurimesh/invention-engine/livingSelfGovernedAiMesh.ts
src/maurimesh/invention-engine/mauriAiRoutingConscience.ts
src/maurimesh/invention-engine/offlineIdentityMesh.ts
src/maurimesh/invention-engine/pathwayPipelineArchitecture.ts
src/maurimesh/invention-engine/selfHealingRuntime.ts
src/maurimesh/invention-engine/storeAndForwardSocialMesh.ts
src/maurimesh/invention-engine/tapuNoaPrivacyStates.ts
src/maurimesh/invention-engine/tikangaGovernance.ts
src/maurimesh/invention-engine/types.ts
src/maurimesh/invention-engine/utils.ts
src/maurimesh/system-brain/buttonDecisionRouter.ts
src/maurimesh/system-brain/layerRegistry.ts
src/maurimesh/system-brain/systemBrain.ts
src/maurimesh/system-brain/systemTypes.ts
src/maurimesh/ui/mauriUiEngine.ts
src/mesh/bluetoothMeshSuperEngine.ts
src/mesh/validateBluetoothMeshSuperEngine.ts
src/operating/MAURIMESH_155_OPERATING_STRUCTURE.md
```

## 5. BLE Imports And Native Module References

```txt
app/_layout.tsx:2:import { Stack } from "expo-router";
app/_layout.tsx:6:    <Stack
app/_layout.tsx:9:        contentStyle: { backgroundColor: "#020617" },
app/index.tsx:2:import { Pressable, StyleSheet, Text, View } from "react-native";
app/index.tsx:16:        Native APK shell, package identity, and safe Expo Router navigation are working.
app/index.tsx:19:      <Pressable style={styles.button} onPress={() => router.push("/dashboard")}>
app/index.tsx:21:      </Pressable>
app/index.tsx:29:    backgroundColor: "#020617",
app/index.tsx:61:    backgroundColor: "#00D084",
app/dashboard.tsx:2:import { Pressable, ScrollView, StyleSheet, Text, View } from "react-native";
app/dashboard.tsx:14:  { title: "BLE Proof UI", route: "/ble-proof" },
app/dashboard.tsx:30:        <Text style={styles.cardText}>Package: com.maurimesh.messenger</Text>
app/dashboard.tsx:31:        <Text style={styles.cardText}>Router: safe Stack only</Text>
app/dashboard.tsx:32:        <Text style={styles.cardText}>BLE/runtime UI: safe proof shell only</Text>
app/dashboard.tsx:36:        <Pressable
app/dashboard.tsx:42:        </Pressable>
app/dashboard.tsx:45:      <Pressable style={styles.homeButton} onPress={() => router.back()}>
app/dashboard.tsx:46:        <Text style={styles.homeButtonText}>Back Home</Text>
app/dashboard.tsx:47:      </Pressable>
app/dashboard.tsx:53:  screen: { flex: 1, backgroundColor: "#020617" },
app/dashboard.tsx:59:    backgroundColor: "rgba(255,255,255,0.06)",
app/dashboard.tsx:69:    backgroundColor: "rgba(0,208,132,0.14)",
app/dashboard.tsx:79:    backgroundColor: "#00D084",
app/settings.tsx:14:        <Text style={styles.cardText}>Safe UI shell only. BLE/runtime engines still isolated until stable route proof.</Text>
app/settings.tsx:17:        <Text style={styles.cardTitle}>Package</Text>
app/settings.tsx:25:  screen: { flex: 1, backgroundColor: "#020617" },
app/settings.tsx:30:  card: { backgroundColor: "rgba(255,255,255,0.06)", borderColor: "rgba(0,208,132,0.28)", borderWidth: 1, borderRadius: 22, padding: 18, marginBottom: 16 },
app/chat.tsx:12:      <View style={styles.bubbleLeft}><Text style={styles.text}>Safe chat UI loaded.</Text></View>
app/chat.tsx:13:      <View style={styles.bubbleRight}><Text style={styles.text}>BLE send/receive remains isolated until native proof is restored.</Text></View>
app/chat.tsx:19:  screen: { flex: 1, backgroundColor: "#020617" },
app/chat.tsx:24:  bubbleLeft: { alignSelf: "flex-start", maxWidth: "86%", backgroundColor: "rgba(255,255,255,0.06)", borderColor: "rgba(0,208,132,0.28)", borderWidth: 1, borderRadius: 18, padding: 16, marginBottom: 12 },
app/chat.tsx:25:  bubbleRight: { alignSelf: "flex-end", maxWidth: "86%", backgroundColor: "rgba(0,208,132,0.18)", borderColor: "#00D084", borderWidth: 1, borderRadius: 18, padding: 16, marginBottom: 12 },
app/living-mesh.tsx:17:      <Text style={styles.note}>Safe visual shell only. Live BLE topology remains isolated.</Text>
app/living-mesh.tsx:23:  screen: { flex: 1, backgroundColor: "#020617" },
app/living-mesh.tsx:28:  canvas: { height: 330, backgroundColor: "rgba(255,255,255,0.04)", borderColor: "rgba(0,208,132,0.28)", borderWidth: 1, borderRadius: 24, position: "relative" },
app/living-mesh.tsx:29:  node: { position: "absolute", width: 58, height: 58, marginLeft: -29, marginTop: -29, borderRadius: 29, backgroundColor: "rgba(0,208,132,0.18)", borderColor: "#00D084", borderWidth: 1, alignItems: "center", justifyContent: "center" },
app/mesh-status.tsx:5:const MARKER = "API_FALLBACK_MESH_STATUS_20260607_A";
app/mesh-status.tsx:19:            mode: "UNAVAILABLE",
app/mesh-status.tsx:31:  const mode = mesh?.mode || "UNAVAILABLE";
app/mesh-status.tsx:50:        <Text style={styles.cardTitle}>API Fallback</Text>
app/mesh-status.tsx:52:          {mesh?.message || "Checking mesh fallback status..."}
app/mesh-status.tsx:57:        <Text style={styles.cardTitle}>Nodes Visible</Text>
app/mesh-status.tsx:62:        <Text style={styles.cardTitle}>Routes Visible</Text>
app/mesh-status.tsx:70:          Otherwise it shows labelled simulation. It does not claim live BLE.
app/mesh-status.tsx:78:  screen: { flex: 1, backgroundColor: "#020617" },
app/mesh-status.tsx:90:    backgroundColor: "rgba(255,255,255,0.04)",
app/mesh-status.tsx:94:    backgroundColor: "rgba(255,255,255,0.06)",
app/add-friend.tsx:13:      <Text style={styles.note}>Camera and BLE nearby discovery are isolated until native proof restore.</Text>
app/add-friend.tsx:19:  screen: { flex: 1, backgroundColor: "#020617" },
app/add-friend.tsx:24:  qr: { height: 260, borderRadius: 24, borderWidth: 1, borderColor: "rgba(0,208,132,0.28)", backgroundColor: "rgba(255,255,255,0.06)", alignItems: "center", justifyContent: "center" },
app/pixel-calling.tsx:19:  screen: { flex: 1, backgroundColor: "#020617" },
app/pixel-calling.tsx:24:  video: { height: 360, borderRadius: 24, borderWidth: 1, borderColor: "rgba(0,208,132,0.28)", backgroundColor: "rgba(255,255,255,0.04)", alignItems: "center", justifyContent: "center" },
app/ble-proof.tsx:5:const MARKER = "SAFE_BLE_PROOF_UI_20260607_A";
app/ble-proof.tsx:7:export default function BleProofScreen() {
app/ble-proof.tsx:11:      <Text style={styles.title}>BLE Proof UI</Text>
app/ble-proof.tsx:17:          This is a safe APK UI layer. It does not claim live BLE. Real BLE proof requires
app/ble-proof.tsx:18:          physical phones, permissions, native logs, TX/RX/ACK events, and two-phone validation.
app/ble-proof.tsx:34:  screen: { flex: 1, backgroundColor: "#020617" },
app/ble-proof.tsx:40:    backgroundColor: "rgba(245,158,11,0.10)",
app/ble-proof.tsx:48:    backgroundColor: "rgba(255,255,255,0.06)",
app/proof-ledger.tsx:17:        <Text style={styles.cardText}>Package identity: com.maurimesh.messenger</Text>
app/proof-ledger.tsx:37:  screen: { flex: 1, backgroundColor: "#020617" },
app/proof-ledger.tsx:43:    backgroundColor: "rgba(255,255,255,0.06)",
app/proof-ledger.tsx:55:    backgroundColor: "rgba(255,255,255,0.05)",
src/lib/meshClient.ts:5:  mode: "LIVE" | "SIMULATION" | "UNAVAILABLE";
src/lib/meshClient.ts:29:      "Mesh API unavailable in APK/Replit preview. Showing labelled simulation only. This is not live BLE.",
src/lib/proofLogger.ts:1:export function logBleScanStarted() {
src/lib/proofLogger.ts:9:export function logPacketSent(_packet?: any) {
src/lib/proofLogger.ts:13:export function logPacketReceived(_packet?: any) {
src/lib/bluetoothMeshClient.ts:2:  bluetoothMeshSuperEngine,
src/lib/bluetoothMeshClient.ts:3:  BluetoothMode,
src/lib/bluetoothMeshClient.ts:5:} from "../mesh/bluetoothMeshSuperEngine";
src/lib/bluetoothMeshClient.ts:7:export function startBluetoothMeshRuntime() {
src/lib/bluetoothMeshClient.ts:8:  bluetoothMeshSuperEngine.startRuntimeLoop();
src/lib/bluetoothMeshClient.ts:9:  return bluetoothMeshSuperEngine.getSnapshot();
src/lib/bluetoothMeshClient.ts:12:export function stopBluetoothMeshRuntime() {
src/lib/bluetoothMeshClient.ts:13:  bluetoothMeshSuperEngine.stopRuntimeLoop();
src/lib/bluetoothMeshClient.ts:14:  return bluetoothMeshSuperEngine.getSnapshot();
src/lib/bluetoothMeshClient.ts:17:export function ingestBluetoothPeer(input: {
src/lib/bluetoothMeshClient.ts:22:  mode?: BluetoothMode;
src/lib/bluetoothMeshClient.ts:25:  bluetoothMeshSuperEngine.ingestBluetoothPeer({
src/lib/bluetoothMeshClient.ts:30:    mode: input.mode || "BLE_SCAN",
src/lib/bluetoothMeshClient.ts:34:  return bluetoothMeshSuperEngine.getSnapshot();
src/lib/bluetoothMeshClient.ts:37:export async function sendBluetoothMeshMessage(to: string, text: string) {
src/lib/bluetoothMeshClient.ts:38:  return bluetoothMeshSuperEngine.sendPacket(to, {
src/lib/bluetoothMeshClient.ts:44:export function receiveBluetoothMeshPacket(packet: any) {
src/lib/bluetoothMeshClient.ts:45:  return bluetoothMeshSuperEngine.receivePacket(packet);
src/lib/bluetoothMeshClient.ts:48:export function learnBluetoothMeshRoute(input: {
src/lib/bluetoothMeshClient.ts:49:  packetId: string;
src/lib/bluetoothMeshClient.ts:55:  bluetoothMeshSuperEngine.learn({
src/lib/bluetoothMeshClient.ts:60:  return bluetoothMeshSuperEngine.getSnapshot();
src/lib/bluetoothMeshClient.ts:63:export function getBluetoothMeshSnapshot() {
src/lib/bluetoothMeshClient.ts:64:  return bluetoothMeshSuperEngine.getSnapshot();
src/lib/bluetoothMeshClient.ts:67:export function seedBluetoothMeshDemo() {
src/lib/bluetoothMeshClient.ts:68:  bluetoothMeshSuperEngine.ingestBluetoothPeer({
src/lib/bluetoothMeshClient.ts:70:    name: "Phone A BLE GATT",
src/lib/bluetoothMeshClient.ts:72:    mode: "BLE_GATT",
src/lib/bluetoothMeshClient.ts:75:  bluetoothMeshSuperEngine.ingestBluetoothPeer({
src/lib/bluetoothMeshClient.ts:77:    name: "Relay B Advertiser",
src/lib/bluetoothMeshClient.ts:79:    mode: "BLE_ADVERTISE",
src/lib/bluetoothMeshClient.ts:84:  bluetoothMeshSuperEngine.ingestBluetoothPeer({
src/lib/bluetoothMeshClient.ts:88:    mode: "BLE_SCAN",
src/lib/bluetoothMeshClient.ts:92:  return bluetoothMeshSuperEngine.getSnapshot();
src/lib/inventionEngineClient.ts:2:  ackLastRoute,
src/lib/inventionEngineClient.ts:27:export async function ackInventionRoute(): Promise<UiEngineSnapshot> {
src/lib/inventionEngineClient.ts:28:  ackLastRoute();
src/lib/mauriEssentials.ts:26:    proofBoundary: "Needs APK and physical phone validation for native BLE identity exchange.",
src/lib/mauriEssentials.ts:34:    proofBoundary: "Needs real packet outcomes from phones to become field-proven.",
src/lib/mauriEssentials.ts:64:    reason: "Detects failed packets, stale nodes, missing ACKs, and recovery actions.",
src/lib/mauriEssentials.ts:66:    proofBoundary: "Needs Android background service integration.",
src/lib/mauriEssentials.ts:72:    reason: "Stores messages when the recipient is unavailable and forwards later.",
src/lib/mauriEssentials.ts:81:    enhances: "Turns invisible routing into visible proof.",
src/lib/mauriEssentials.ts:104:    reason: "Applies contextual privacy states to packets and relay permissions.",
src/lib/mauriEssentials.ts:121:    enhances: "Reduces reliance on unreliable or unsafe relays.",
src/lib/mauriEssentials.ts:166:      detail: `${snapshot.nodes.length} node(s) visible to UI.`,
src/lib/mauriEssentials.ts:171:      detail: `${snapshot.routes.length} route(s) visible to UI.`,
src/lib/mauriEssentials.ts:187:          : "No trust memory yet. Run a demo and ACK/fail route.",
src/lib/mauriEssentials.ts:195:          : "No learned route yet. ACK a route to create memory.",
src/lib/mauriEssentials.ts:198:      name: "Native BLE proof",
src/lib/mauriEssentials.ts:208:      name: "Background runtime proof",
src/lib/mauriSystemBrainClient.ts:3:  status: "READY" | "SIMULATION" | "UNAVAILABLE";
src/lib/mauriSystemBrainClient.ts:23:      { name: "BLE Runtime", status: "pending-native" },
src/lib/mauriSystemBrainClient.ts:24:      { name: "ACK / Routing / Store-Forward", status: "protected" },
src/lib/mauriSystemBrainClient.ts:30:      "This proves the Replit web UI layer. Real BLE, native ACK routing, and offline phone-to-phone proof require APK/device validation."
src/lib/mauriSystemBrainClient.ts:42:export async function ackMauriSystemBrainRoute() {
src/lib/mauriSystemBrainClient.ts:46:    message: "ACK simulated in static preview mode."
src/lib/api.ts.bak-api-base-fix-20260603-142044:5:  | { ok: false; error: string; source: "unavailable" };
src/lib/api.ts.bak-api-base-fix-20260603-142044:15:  // Browser/Replit same-origin fallback.
src/lib/api.ts.bak-api-base-fix-20260603-142044:33:      source: "unavailable",
src/lib/api.ts.bak-api-base-fix-20260603-142044:56:        source: "unavailable",
src/lib/api.ts.bak-api-base-fix-20260603-142044:67:      source: "unavailable",
src/lib/api.ts:5:  | { ok: false; error: string; source: "unavailable" };
src/lib/api.ts:20:      source: "unavailable",
src/lib/api.ts:39:        source: "unavailable",
src/lib/api.ts:50:      source: "unavailable",
src/lib/proofSimulation.ts:16:    id: "router-stack",
src/lib/proofSimulation.ts:19:    detail: "Safe Expo Router Stack opens dashboard and UI screens.",
src/lib/proofSimulation.ts:22:    id: "ble-runtime",
src/lib/proofSimulation.ts:23:    stage: "BLE Runtime",
src/lib/proofSimulation.ts:25:    detail: "Native BLE send/receive proof is protected and not active in this UI shell.",
src/theme/mauriTheme.ts:3:    black: "#020403",
src/theme/mauriTheme.ts:4:    deepBlack: "#000000",
src/design-system/colors.ts:2:  background: "#020617",
src/components/ui/MeshButton.tsx:2:import { Pressable, Text, PressableProps } from "react-native";
src/components/ui/MeshButton.tsx:4:export function MeshButton({ children, ...props }: PressableProps & { children?: React.ReactNode }) {
src/components/ui/MeshButton.tsx:6:    <Pressable {...props}>
src/components/ui/MeshButton.tsx:8:    </Pressable>
src/components/mesh/PacketFlowView.tsx:4:export type Packet = {
src/components/mesh/PacketFlowView.tsx:11:export function PacketFlowView({ packets = [] }: { packets?: Packet[] }) {
src/components/mesh/PacketFlowView.tsx:14:      {packets.map((p) => (
src/components/mesh/PacketFlowView.tsx:21:export default PacketFlowView;
src/components/mesh/AckPathView.tsx:4:export type AckNode = {
src/components/mesh/AckPathView.tsx:10:export function AckPathView({ nodes = [] }: { nodes?: AckNode[] }) {
src/components/mesh/AckPathView.tsx:20:export default AckPathView;
src/components/mesh/BleReadinessCard.tsx:4:export function BleReadinessCard() {
src/components/mesh/BleReadinessCard.tsx:7:      <Text>BLE readiness: offline</Text>
src/components/mesh/BleReadinessCard.tsx:12:export default BleReadinessCard;
src/components/mesh/BleScanProof.tsx:4:export function BleScanProof() {
src/components/mesh/BleScanProof.tsx:7:      <Text>BLE scan proof pending</Text>
src/components/mesh/BleScanProof.tsx:12:export default BleScanProof;
src/components/mesh/RouteHealthCard.tsx:8:  packetLoss?: number;
src/components/LivingMeshCanvas.tsx:64:    backgroundColor: "#020806",
src/components/LivingMeshCanvas.tsx:73:    backgroundColor: mauriTheme.colors.greenstone,
src/components/LivingMeshCanvas.tsx:83:    backgroundColor: "rgba(0,208,132,0.16)",
src/components/ScreenShell.tsx:6:    <SafeAreaView style={{ flex: 1, backgroundColor: "#000" }}>
src/components/AppShell.tsx:24:    backgroundColor: mauriTheme.colors.black
src/components/MauriButton.tsx:2:import { Pressable, StyleSheet, Text } from "react-native";
src/components/MauriButton.tsx:15:    <Pressable
src/components/MauriButton.tsx:26:    </Pressable>
src/components/MauriButton.tsx:40:    backgroundColor: mauriTheme.colors.greenstone,
src/components/MauriButton.tsx:44:    backgroundColor: mauriTheme.colors.panel,
src/components/MauriButton.tsx:48:    backgroundColor: "rgba(239,68,68,0.16)",
src/components/StatusPill.tsx:35:    backgroundColor: "rgba(255,255,255,0.05)"
src/components/MeshSignalCard.tsx:13:  status: "LIVE" | "SIMULATION" | "UNAVAILABLE";
src/components/MeshSignalCard.tsx:31:    backgroundColor: mauriTheme.colors.panel,
src/components/ChatBubble.tsx:5:export function ChatBubble({
src/components/ChatBubble.tsx:32:    backgroundColor: "rgba(0,208,132,0.18)",
src/components/ChatBubble.tsx:37:    backgroundColor: mauriTheme.colors.panel,
src/components/InventionEngineCard.tsx:28:    backgroundColor: mauriTheme.colors.panel,
src/components/SynthPanel.tsx:33:    backgroundColor: mauriTheme.colors.panel,
src/components/SynthPanel.tsx:52:    backgroundColor: "rgba(255,255,255,0.04)",
src/components/RoutePlanPanel.tsx:68:    backgroundColor: mauriTheme.colors.panel,
src/components/RoutePlanPanel.tsx:109:    backgroundColor: "rgba(0,208,132,0.08)",
src/components/DeliveryLedgerPanel.tsx:6:  packetId: string;
src/components/DeliveryLedgerPanel.tsx:16:      <Text style={styles.title}>Delivery Proof + ACK Ledger</Text>
src/components/DeliveryLedgerPanel.tsx:21:          <View key={`${event.packetId}-${event.status}-${index}`} style={styles.event}>
src/components/DeliveryLedgerPanel.tsx:39:    backgroundColor: mauriTheme.colors.panel,
src/components/CompletionAuditPanel.tsx:39:    backgroundColor: mauriTheme.colors.panel,
src/components/SystemBrainPanel.tsx:34:    backgroundColor: mauriTheme.colors.panel,
src/components/ButtonWiringPanel.tsx:36:    backgroundColor: mauriTheme.colors.panel,
src/operating/mauriOperatingTypes.ts:5:  | "packet"
src/operating/mauriOperatingTypes.ts:20:  | "fallback"
src/operating/mauriOperatingTypes.ts:51:    | "ack_received"
src/operating/mauriOperatingTypes.ts:54:    | "fallback_used"
src/operating/mauriOperatingTypes.ts:73:  fallback: number;
src/operating/mauriOperatingTypes.ts:81:  | "fallback_store_forward"
src/operating/mauri155LayerCatalog.ts:8:    "identity, shared types, contracts, configuration, versioning, and stable system law",
src/operating/mauri155LayerCatalog.ts:10:    "device body, Bluetooth permissions, power, foreground runtime, radio health, and hardware proof boundary",
src/operating/mauri155LayerCatalog.ts:12:    "BLE scan, BLE advertise, BLE GATT, peer-to-peer transport, relay transport, and fallback transport",
src/operating/mauri155LayerCatalog.ts:13:  packet:
src/operating/mauri155LayerCatalog.ts:14:    "packet structure, encryption envelope, dedupe, TTL, fragmentation, reassembly, and ACK identity",
src/operating/mauri155LayerCatalog.ts:24:    "peer table, friend graph, trust graph, group resilience, path whakapapa, and relationship memory",
src/operating/mauri155LayerCatalog.ts:41:    "Packet Contract",
src/operating/mauri155LayerCatalog.ts:50:    "Bluetooth Permission Body",
src/operating/mauri155LayerCatalog.ts:51:    "BLE Radio State",
src/operating/mauri155LayerCatalog.ts:55:    "Device Capability Scan",
src/operating/mauri155LayerCatalog.ts:65:    "BLE Scan Loop",
src/operating/mauri155LayerCatalog.ts:66:    "BLE Advertise Loop",
src/operating/mauri155LayerCatalog.ts:67:    "BLE GATT Server",
src/operating/mauri155LayerCatalog.ts:68:    "BLE GATT Client",
src/operating/mauri155LayerCatalog.ts:69:    "BLE Packet Send Shell",
src/operating/mauri155LayerCatalog.ts:70:    "BLE Packet Receive Shell",
src/operating/mauri155LayerCatalog.ts:75:    "Transport Fallback",
src/operating/mauri155LayerCatalog.ts:79:  packet: [
src/operating/mauri155LayerCatalog.ts:80:    "Packet ID",
src/operating/mauri155LayerCatalog.ts:81:    "Packet Envelope",
src/operating/mauri155LayerCatalog.ts:82:    "Packet Encryption",
src/operating/mauri155LayerCatalog.ts:83:    "Packet Signature",
src/operating/mauri155LayerCatalog.ts:84:    "Packet Deduplication",
src/operating/mauri155LayerCatalog.ts:89:    "ACK Packet",
src/operating/mauri155LayerCatalog.ts:90:    "Reverse Path ACK",
src/operating/mauri155LayerCatalog.ts:95:    "Route Table",
src/operating/mauri155LayerCatalog.ts:99:    "ACK Weight",
src/operating/mauri155LayerCatalog.ts:114:    "ACK Lesson",
src/operating/mauri155LayerCatalog.ts:118:    "Fallback Lesson",
src/operating/mauri155LayerCatalog.ts:127:    "Fallback Activator",
src/operating/mauri155LayerCatalog.ts:131:    "Retry Backoff",
src/operating/mauri155LayerCatalog.ts:135:    "ACK Recovery",
src/operating/mauri155LayerCatalog.ts:143:    "No Fake BLE Proof",
src/operating/mauri155LayerCatalog.ts:155:    "Peer Table",
src/operating/mauri155LayerCatalog.ts:205:    "No Fake BLE Claim Proof",
src/operating/mauri155LayerCatalog.ts:208:    "BLE Scan Proof",
src/operating/mauri155LayerCatalog.ts:209:    "BLE Advertise Proof",
src/operating/mauri155LayerCatalog.ts:210:    "GATT Transfer Proof",
src/operating/mauri155OperatingRuntime.ts:73:  teachRouteSuccess(peerId: string, packetId: string): void {
src/operating/mauri155OperatingRuntime.ts:74:    this.boostDomains(["routing", "packet", "learning", "whanau", "observability"], 0.04);
src/operating/mauri155OperatingRuntime.ts:82:        "Route success teaches routing, packet integrity, ACK confidence, whānau trust, and Living Mesh visibility.",
src/operating/mauri155OperatingRuntime.ts:83:      data: { peerId, packetId },
src/operating/mauri155OperatingRuntime.ts:87:  teachRouteFailure(peerId: string, packetId: string): void {
src/operating/mauri155OperatingRuntime.ts:99:      data: { peerId, packetId },
src/operating/mauri155OperatingRuntime.ts:103:  teachAckReceived(peerId: string, packetId: string): void {
src/operating/mauri155OperatingRuntime.ts:104:    this.boostDomains(["packet", "routing", "learning", "whanau"], 0.05);
src/operating/mauri155OperatingRuntime.ts:107:      sourceLayerId: "packet",
src/operating/mauri155OperatingRuntime.ts:108:      type: "ack_received",
src/operating/mauri155OperatingRuntime.ts:112:        "ACK received. The system learns delivery truth, peer trust, latency expectation, and route quality.",
src/operating/mauri155OperatingRuntime.ts:113:      data: { peerId, packetId },
src/operating/mauri155OperatingRuntime.ts:117:  teachPhysicalBleRequired(reason: string): void {
src/operating/mauri155OperatingRuntime.ts:118:    this.setDomainState("proof", "fallback", 0.5);
src/operating/mauri155OperatingRuntime.ts:119:    this.setDomainState("physical", "fallback", 0.5);
src/operating/mauri155OperatingRuntime.ts:127:        "Physical BLE proof is required. Replit can validate logic, but APK plus physical phones prove Bluetooth runtime.",
src/operating/mauri155OperatingRuntime.ts:161:        fallback: group.filter(layer => layer.state === "fallback").length,
src/operating/mauri155OperatingRuntime.ts:181:        "This is the one giant MauriMesh operating runtime. Replit proves logic only. Physical BLE proof requires APK plus physical phones.",
src/operating/mauri155OperatingRuntime.ts:232:        if (layer.score < 0.45) layer.state = "fallback";
src/operating/mauri155OperatingRuntime.ts:250:    if (score >= 0.5) return "fallback_store_forward";
src/operating/validateMauri155OperatingRuntime.ts:9:  runtime.teachRouteSuccess("peer-alpha", "packet-001");
src/operating/validateMauri155OperatingRuntime.ts:10:  runtime.teachAckReceived("peer-alpha", "packet-001");
src/operating/validateMauri155OperatingRuntime.ts:11:  runtime.teachRouteFailure("peer-beta", "packet-002");
src/operating/validateMauri155OperatingRuntime.ts:12:  runtime.teachTikangaWarning("Do not claim live BLE proof inside Replit.");
src/operating/validateMauri155OperatingRuntime.ts:13:  runtime.teachPhysicalBleRequired(
src/operating/validateMauri155OperatingRuntime.ts:14:    "Real BLE proof requires APK, physical phones, and ADB/logcat."
src/operating/MAURIMESH_155_OPERATING_STRUCTURE.md:14:4. Packet
src/operating/MAURIMESH_155_OPERATING_STRUCTURE.md:26:observe -> learn -> score -> balance -> decide -> act -> ACK/fail -> heal -> snapshot -> repeat
src/operating/MAURIMESH_155_OPERATING_STRUCTURE.md:32:- fallback_store_forward
src/operating/MAURIMESH_155_OPERATING_STRUCTURE.md:39:Physical BLE proof requires APK + physical phones + ADB/logcat.
src/integration/mauriRuntimeIntegrationBridge.ts:6: * without deleting or replacing existing BLE, routing, ACK, store-forward, or UI files.
src/integration/mauriRuntimeIntegrationBridge.ts:10: * - Physical BLE proof requires APK + physical phones + ADB/logcat.
src/integration/mauriRuntimeIntegrationBridge.ts:19:      packetId: string;
src/integration/mauriRuntimeIntegrationBridge.ts:24:      packetId: string;
src/integration/mauriRuntimeIntegrationBridge.ts:27:      type: "ack_received";
src/integration/mauriRuntimeIntegrationBridge.ts:29:      packetId: string;
src/integration/mauriRuntimeIntegrationBridge.ts:36:      type: "physical_ble_required";
src/integration/mauriRuntimeIntegrationBridge.ts:69:        this.runtime.teachRouteSuccess(event.peerId, event.packetId);
src/integration/mauriRuntimeIntegrationBridge.ts:73:        this.runtime.teachRouteFailure(event.peerId, event.packetId);
src/integration/mauriRuntimeIntegrationBridge.ts:76:      case "ack_received":
src/integration/mauriRuntimeIntegrationBridge.ts:77:        this.runtime.teachAckReceived(event.peerId, event.packetId);
src/integration/mauriRuntimeIntegrationBridge.ts:84:      case "physical_ble_required":
src/integration/mauriRuntimeIntegrationBridge.ts:85:        this.runtime.teachPhysicalBleRequired(event.reason);
src/integration/validateMauriRuntimeIntegrationBridge.ts:9:    packetId: "packet-001",
src/integration/validateMauriRuntimeIntegrationBridge.ts:13:    type: "ack_received",
src/integration/validateMauriRuntimeIntegrationBridge.ts:15:    packetId: "packet-001",
src/integration/validateMauriRuntimeIntegrationBridge.ts:21:    packetId: "packet-002",
src/integration/validateMauriRuntimeIntegrationBridge.ts:26:    reason: "Do not claim live BLE proof inside Replit.",
src/integration/validateMauriRuntimeIntegrationBridge.ts:30:    type: "physical_ble_required",
src/integration/validateMauriRuntimeIntegrationBridge.ts:31:    reason: "Real BLE proof requires APK, physical phones, and ADB/logcat.",
src/integration/MAURIMESH_155_INTEGRATION_POINTS.md:7:- Existing BLE files
src/integration/MAURIMESH_155_INTEGRATION_POINTS.md:9:- Existing ACK files
src/ai/mauriAiTypes.ts:12:  packetId?: string;
src/ai/mauriAiTypes.ts:15:  ackSuccess?: boolean;
src/ai/mauriAiTypes.ts:22:  physicalBleProven?: boolean;
src/ai/mauriAiTypes.ts:31:  ackRate: number;
src/ai/mauriAiTypes.ts:62:    storedPackets: number;
src/ai/mauriAiTypes.ts:63:    forwardedPackets: number;
src/ai/mauriAiIntelligenceRuntime.ts:21:    storedPackets: 0,
src/ai/mauriAiIntelligenceRuntime.ts:22:    forwardedPackets: 0,
src/ai/mauriAiIntelligenceRuntime.ts:32:    if (signal.ackSuccess) this.memory.routeSuccess += 1;
src/ai/mauriAiIntelligenceRuntime.ts:36:      this.memory.storedPackets += 1;
src/ai/mauriAiIntelligenceRuntime.ts:62:        "Mauri AI routing intelligence is active. Replit validates logic only. Real BLE proof requires APK plus physical phones.",
src/ai/mauriAiIntelligenceRuntime.ts:66:  storePacket(packetId: string, peerId: string, payload: unknown): void {
src/ai/mauriAiIntelligenceRuntime.ts:68:      packetId,
src/ai/mauriAiIntelligenceRuntime.ts:75:    this.memory.storedPackets += 1;
```

## 6. Current Safe UI Route Markers

```txt
app/index.tsx:const MARKER = "SAFE_HOME_DASHBOARD_20260607_A";
app/dashboard.tsx:const MARKER = "SAFE_DASHBOARD_PROOF_BUTTONS_20260607_A";
app/mesh-status.tsx:const MARKER = "API_FALLBACK_MESH_STATUS_20260607_A";
app/ble-proof.tsx:const MARKER = "SAFE_BLE_PROOF_UI_20260607_A";
app/proof-ledger.tsx:const MARKER = "SAFE_PROOF_LEDGER_20260607_A";
```

## 7. Crash-Risk Scan

```txt
PASS: no known risky startup patterns in app.
```

## 8. TypeScript Check

```txt
```

## 9. Clean Export Check

```txt
Starting Metro Bundler
warning: Bundler cache is empty, rebuilding (this may take a minute)
Android node_modules/.pnpm/expo-router@6.0.24_@expo+metro-runtime@6.1.2_@types+react-dom@19.2.3_@types+react@19.1.17__@t_fngvj2q4gqenhcjlgrxxtoujku/node_modules/expo-router/entry.js ░░░░░░░░░░░░░░░░  0.0% (0/1)
Android node_modules/.pnpm/expo-router@6.0.24_@expo+metro-runtime@6.1.2_@types+react-dom@19.2.3_@types+react@19.1.17__@t_fngvj2q4gqenhcjlgrxxtoujku/node_modules/expo-router/entry.js ▓▓▓▓▓░░░░░░░░░░░ 32.9% (278/485)
Android node_modules/.pnpm/expo-router@6.0.24_@expo+metro-runtime@6.1.2_@types+react-dom@19.2.3_@types+react@19.1.17__@t_fngvj2q4gqenhcjlgrxxtoujku/node_modules/expo-router/entry.js ▓▓▓▓▓▓▓▓▓▓▓▓▓░░░ 87.4% (761/814)
Android Bundled 10270ms node_modules/.pnpm/expo-router@6.0.24_@expo+metro-runtime@6.1.2_@types+react-dom@19.2.3_@types+react@19.1.17__@t_fngvj2q4gqenhcjlgrxxtoujku/node_modules/expo-router/entry.js (968 modules)

› Assets (24):
node_modules/.pnpm/@react-navigation+elements@2.9.19_@react-navigation+native@7.2.5_react-native@0.81.5_@babel+c_o5xhxhhziuspmnzkys54devyi4/node_modules/@react-navigation/elements/lib/module/assets/back-icon-mask.png (653 B)
node_modules/.pnpm/@react-navigation+elements@2.9.19_@react-navigation+native@7.2.5_react-native@0.81.5_@babel+c_o5xhxhhziuspmnzkys54devyi4/node_modules/@react-navigation/elements/lib/module/assets/back-icon.png (4 variations | 152 B)
node_modules/.pnpm/@react-navigation+elements@2.9.19_@react-navigation+native@7.2.5_react-native@0.81.5_@babel+c_o5xhxhhziuspmnzkys54devyi4/node_modules/@react-navigation/elements/lib/module/assets/clear-icon.png (4 variations | 425 B)
node_modules/.pnpm/@react-navigation+elements@2.9.19_@react-navigation+native@7.2.5_react-native@0.81.5_@babel+c_o5xhxhhziuspmnzkys54devyi4/node_modules/@react-navigation/elements/lib/module/assets/close-icon.png (4 variations | 235 B)
node_modules/.pnpm/@react-navigation+elements@2.9.19_@react-navigation+native@7.2.5_react-native@0.81.5_@babel+c_o5xhxhhziuspmnzkys54devyi4/node_modules/@react-navigation/elements/lib/module/assets/search-icon.png (4 variations | 599 B)
node_modules/.pnpm/expo-router@6.0.24_@expo+metro-runtime@6.1.2_@types+react-dom@19.2.3_@types+react@19.1.17__@t_fngvj2q4gqenhcjlgrxxtoujku/node_modules/expo-router/assets/arrow_down.png (9.46 kB)
node_modules/.pnpm/expo-router@6.0.24_@expo+metro-runtime@6.1.2_@types+react-dom@19.2.3_@types+react@19.1.17__@t_fngvj2q4gqenhcjlgrxxtoujku/node_modules/expo-router/assets/error.png (469 B)
node_modules/.pnpm/expo-router@6.0.24_@expo+metro-runtime@6.1.2_@types+react-dom@19.2.3_@types+react@19.1.17__@t_fngvj2q4gqenhcjlgrxxtoujku/node_modules/expo-router/assets/file.png (138 B)
node_modules/.pnpm/expo-router@6.0.24_@expo+metro-runtime@6.1.2_@types+react-dom@19.2.3_@types+react@19.1.17__@t_fngvj2q4gqenhcjlgrxxtoujku/node_modules/expo-router/assets/forward.png (188 B)
node_modules/.pnpm/expo-router@6.0.24_@expo+metro-runtime@6.1.2_@types+react-dom@19.2.3_@types+react@19.1.17__@t_fngvj2q4gqenhcjlgrxxtoujku/node_modules/expo-router/assets/pkg.png (364 B)
node_modules/.pnpm/expo-router@6.0.24_@expo+metro-runtime@6.1.2_@types+react-dom@19.2.3_@types+react@19.1.17__@t_fngvj2q4gqenhcjlgrxxtoujku/node_modules/expo-router/assets/sitemap.png (465 B)
node_modules/.pnpm/expo-router@6.0.24_@expo+metro-runtime@6.1.2_@types+react-dom@19.2.3_@types+react@19.1.17__@t_fngvj2q4gqenhcjlgrxxtoujku/node_modules/expo-router/assets/unmatched.png (4.75 kB)

› android bundles (1):
_expo/static/js/android/entry-bb2811e6045cbd877e97878673eb8f4d.hbc (2.51 MB)

› Files (1):
metadata.json (1.79 kB)

Exported: dist
```
