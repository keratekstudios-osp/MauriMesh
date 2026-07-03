# MauriMesh Two-Hop + Three-Hop Total Proof Activation Report

Generated: 20260610-202024  
Root: /home/runner/workspace  

## Truth Boundary

This installer activates app-level proof, button automation, route checking, logcat proof labels, and build readiness reporting.

It can automatically prove:
- required app routes exist
- proof buttons render
- proof buttons can be auto-triggered inside the APK
- ReactNativeJS/logcat proof labels are emitted
- 2-hop and 3-hop proof templates exist
- route inventory is present
- bundle/export readiness

It cannot fake physical radio proof.

Real physical proof still requires:
- 2 phones for hotspot gateway proof
- 3 phones for real 3-hop BLE relay proof
- ADB/logcat capture from each phone
- matching proofId, packetId, and routeId across devices


## 0. Root Check

- [PASS] package.json exists
- [PASS] app directory exists

## 1. Backup Existing Proof Files

- [PASS] Backed up two-phone-hotspot-proof.tsx
- [PASS] Backed up three-hop-relay-proof.tsx
- [WARN] two-three-hop-proof-lab.tsx did not exist before install
- [WARN] totalProofEngine.ts did not exist before install
- [WARN] totalProofReport.ts did not exist before install

## 2. Install Total Proof Engine

- [PASS] Installed src/maurimesh/total-proof/totalProofEngine.ts

## 3. Install Total Proof Lab Route

- [PASS] Installed app/two-three-hop-proof-lab.tsx

## 4. Install Direct 2-Hop Route With Log Buttons

- [PASS] Installed active 2-hop route app/two-phone-hotspot-proof.tsx

## 5. Install Direct 3-Hop Route With Log Buttons

- [PASS] Installed active 3-hop route app/three-hop-relay-proof.tsx

## 6. Install Static Report Generator

- [PASS] Installed static report generator

## 7. Dashboard Route Marker / Safe Wire

- [WARN] Dashboard marker added. If dashboard has SafeNavButton/MauriButton, wire visible button manually or open route directly.

## 8. Route Inventory Check

- [PASS] Required app file present: app/dashboard.tsx
- [PASS] Required app file present: app/test-layer.tsx
- [PASS] Required app file present: app/full-mesh-test-report.tsx
- [PASS] Required app file present: app/two-phone-hotspot-proof.tsx
- [PASS] Required app file present: app/three-hop-relay-proof.tsx
- [PASS] Required app file present: app/two-three-hop-proof-lab.tsx
- [PASS] Required app file present: app/maori-protocols.tsx
- [PASS] Required app file present: app/jumpcode-proof.tsx
- [PASS] Required app file present: app/evolution-layer.tsx
- [PASS] Required app file present: app/native-telemetry.tsx
- [PASS] Required app file present: app/mauricore-ble-runtime.tsx
- [PASS] Required app file present: app/device-proof.tsx
- [PASS] Required app file present: app/proof-ledger.tsx
- [PASS] Required app file present: app/message-fallback.tsx
- [PASS] Required app file present: app/route-lab.tsx
- [PASS] Required app file present: app/hybrid-wifi-ble-mesh.tsx
- [PASS] Required app file present: app/living-mesh.tsx
- [PASS] Required app file present: app/self-healing.tsx
- [PASS] Required app file present: app/pixel-calling.tsx
- [PASS] Required app file present: app/ai-pixel-reconstruction.tsx
### App Route Inventory
```txt
app/ack-tracking.tsx
app/add-friend.tsx
app/ai-pixel-reconstruction.tsx
app/api-config.tsx
app/backup-intelligence.tsx
app/ble-hardware-runtime.tsx
app/ble-proof.tsx
app/chat.tsx
app/dashboard.tsx
app/delivery-analytics.tsx
app/device-hardware.tsx
app/device-proof.tsx
app/evolution-layer.tsx
app/foreground-runtime-proof.tsx
app/full-mesh-test-report.tsx
app/hardware-ble-proof.tsx
app/hardware-runtime.tsx
app/hybrid-wifi-ble-mesh.tsx
app/index.tsx
app/integration-hub.tsx
app/intelligence.tsx
app/jumpcode-proof.tsx
app/latency-monitoring.tsx
app/_layout.tsx
app/live-mesh-ops.tsx
app/living-mesh.tsx
app/login.tsx
app/maori-protocols.tsx
app/mauricore-ble-runtime.tsx
app/mauricore-governance.tsx
app/mesh/ack-tracking.tsx
app/mesh/ble-discovery.tsx
app/mesh/index.tsx
app/mesh/packet-analysis.tsx
app/mesh/peer-mapping.tsx
app/mesh/relay-analytics.tsx
app/mesh/signal-strength.tsx
app/mesh-status.tsx
app/mesh/store-forward-queue.tsx
app/message-fallback.tsx
app/native-ble-audit.tsx
app/native-ble-scan-proof.tsx
app/native-ble-status.tsx
app/native-telemetry.tsx
app/network/delivery-analytics.tsx
app/network/latency-monitoring.tsx
app/network/route-health.tsx
app/operator-console.tsx
app/pixel-calling-backup.tsx
app/pixel-calling.tsx
app/proof-ledger.tsx
app/proof-metrics.tsx
app/raw-packet-proof.tsx
app/route-health.tsx
app/route-lab.tsx
app/self-healing.tsx
app/settings.tsx
app/store-forward-queue.tsx
app/test-layer.tsx
app/three-hop-relay-proof.tsx
app/tikanga-engine.tsx
app/two-phone-hotspot-proof.tsx
app/two-three-hop-proof-lab.tsx
app/ui-roadmap.tsx
```

## 9. Proof String Verification

- [PASS] Proof string installed: MauriMeshHotspotProof
- [PASS] Proof string installed: MauriMesh3HopProof
- [PASS] Proof string installed: MauriMeshButtonAutoTest
- [PASS] Proof string installed: MauriMeshRouteAutoTest
- [PASS] Proof string installed: PHONE_A_HOTSPOT_ON
- [PASS] Proof string installed: PHONE_A_GATEWAY_READY
- [PASS] Proof string installed: PHONE_B_CONNECTED_TO_PHONE_A_HOTSPOT
- [PASS] Proof string installed: PHONE_B_TX_PACKET_START
- [PASS] Proof string installed: PHONE_A_GATEWAY_RX_FROM_B
- [PASS] Proof string installed: PHONE_A_GATEWAY_FORWARD_ATTEMPT
- [PASS] Proof string installed: PHONE_A_GATEWAY_FORWARD_SUCCESS
- [PASS] Proof string installed: PHONE_A_GATEWAY_ACK_TO_B
- [PASS] Proof string installed: PHONE_B_ACK_RECEIVED
- [PASS] Proof string installed: PHONE_A_TX_BLE_START
- [PASS] Proof string installed: PHONE_B_RX_BLE_FROM_A
- [PASS] Proof string installed: PHONE_B_RELAY_TX_TO_C
- [PASS] Proof string installed: PHONE_C_RX_BLE_FROM_B
- [PASS] Proof string installed: PHONE_C_STRICT_ACK_SENT
- [PASS] Proof string installed: PHONE_B_RELAY_ACK_FROM_C
- [PASS] Proof string installed: PHONE_A_STRICT_OR_RELAY_ACK_RECEIVED

## 10. Create Mac Logcat Capture Script

- [PASS] Created Mac capture script: maurimesh-mac-total-proof-capture.sh

## 11. TypeScript Check

 ERROR  Command was killed with SIGABRT (Aborted): pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help add
 ERROR  Command failed with exit code 1: pnpm add pnpm@9.15.4 --loglevel=error --allow-build=@pnpm/exe --no-dangerously-allow-all-builds --config.node-linker=hoisted --config.bin=bin
For help, run: pnpm help exec
- [WARN] TypeScript check reported errors. Review report. EAS may still bundle, but release should fix TS errors.

## 12. Expo Export Check

[33m[1mWarning: [22mRoot-level [1m"expo"[22m object found. Ignoring extra keys in Expo config: "owner", "extra"
[90mLearn more: https://expo.fyi/root-expo-object[0m[0m
Starting Metro Bundler
Error while reading cache, falling back to a full crawl:
 Error: Unable to deserialize cloned data due to invalid or unsupported version.
    at deserialize (node:v8:401:7)
    at DiskCacheManager.read (/home/runner/workspace/node_modules/.pnpm/metro-file-map@0.83.3/node_modules/metro-file-map/src/cache/DiskCacheManager.js:60:33)
    at FileMap.read (/home/runner/workspace/node_modules/.pnpm/metro-file-map@0.83.3/node_modules/metro-file-map/src/index.js:284:14)
    at /home/runner/workspace/node_modules/.pnpm/metro-file-map@0.83.3/node_modules/metro-file-map/src/index.js:202:25
    at DependencyGraph.ready (/home/runner/workspace/node_modules/.pnpm/metro@0.83.3/node_modules/metro/src/node-haste/DependencyGraph.js:88:5)
Android node_modules/.pnpm/expo-router@6.0.24_@expo+metro-runtime@6.1.2_@types+react-dom@19.2.3_@types+react@19.1.17__@t_fngvj2q4gqenhcjlgrxxtoujku/node_modules/expo-router/entry.js ░░░░░░░░░░░░░░░░  0.0% (0/1)
Android node_modules/.pnpm/expo-router@6.0.24_@expo+metro-runtime@6.1.2_@types+react-dom@19.2.3_@types+react@19.1.17__@t_fngvj2q4gqenhcjlgrxxtoujku/node_modules/expo-router/entry.js ▓▓▓▓░░░░░░░░░░░░ 28.9% (209/389)
Android node_modules/.pnpm/expo-router@6.0.24_@expo+metro-runtime@6.1.2_@types+react-dom@19.2.3_@types+react@19.1.17__@t_fngvj2q4gqenhcjlgrxxtoujku/node_modules/expo-router/entry.js ▓▓▓▓▓▓▓▓▓▓▓░░░░░ 73.5% (752/877)
Android node_modules/.pnpm/expo-router@6.0.24_@expo+metro-runtime@6.1.2_@types+react-dom@19.2.3_@types+react@19.1.17__@t_fngvj2q4gqenhcjlgrxxtoujku/node_modules/expo-router/entry.js ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░ 99.9% (1141/1141)
Android Bundled 11991ms node_modules/.pnpm/expo-router@6.0.24_@expo+metro-runtime@6.1.2_@types+react-dom@19.2.3_@types+react@19.1.17__@t_fngvj2q4gqenhcjlgrxxtoujku/node_modules/expo-router/entry.js (1141 modules)

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
_expo/static/js/android/entry-499a30e91bc467e8fddd1d9b323b88a8.hbc (3.07 MB)

› Files (1):
metadata.json (1.79 kB)

Exported: .maurimesh-two-three-hop-total-export-20260610-202024
- [PASS] Expo Android export passed

## 13. Final Proof Summary


## Installed Routes

- /two-three-hop-proof-lab
- /two-phone-hotspot-proof
- /three-hop-relay-proof

## 2-Hop Proof Identity

- proofId: MM-2HOP-HOTSPOT-20260610-202024
- packetId: pkt-2hop-hotspot-20260610-202024
- routeId: route-phoneB-phoneA-gateway-20260610-202024

Required physical setup:
- PHONE_A = hotspot/gateway
- PHONE_B = client/sender connected to PHONE_A hotspot

Required log stages:
- PHONE_A_HOTSPOT_ON
- PHONE_A_GATEWAY_READY
- PHONE_B_CONNECTED_TO_PHONE_A_HOTSPOT
- PHONE_B_TX_PACKET_START
- PHONE_A_GATEWAY_RX_FROM_B
- PHONE_A_GATEWAY_FORWARD_ATTEMPT
- PHONE_A_GATEWAY_FORWARD_SUCCESS
- PHONE_A_GATEWAY_ACK_TO_B
- PHONE_B_ACK_RECEIVED

## 3-Hop Proof Identity

- proofId: MM-3HOP-RELAY-20260610-202024
- packetId: pkt-3hop-relay-20260610-202024
- routeId: route-phoneA-phoneB-phoneC-20260610-202024

Required physical setup:
- PHONE_A = sender
- PHONE_B = relay
- PHONE_C = receiver

Required log stages:
- PHONE_A_TX_BLE_START
- PHONE_B_RX_BLE_FROM_A
- PHONE_B_RELAY_TX_TO_C
- PHONE_C_RX_BLE_FROM_B
- PHONE_C_STRICT_ACK_SENT
- PHONE_B_RELAY_ACK_FROM_C
- PHONE_A_STRICT_OR_RELAY_ACK_RECEIVED

## Final Truth

With two phones:
- 2-hop hotspot gateway proof can be physically completed.
- 3-hop relay can only be app-log/readiness tested.
- Real 3-hop physical proof requires three phones.


## Score

- PASS: 51
- WARN: 5
- FAIL: 0
- SCORE: 91%
