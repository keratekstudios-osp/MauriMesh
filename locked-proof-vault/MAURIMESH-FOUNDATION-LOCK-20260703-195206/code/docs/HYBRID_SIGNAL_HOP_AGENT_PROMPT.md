# MauriMesh Hybrid Signal Hop Engine — Architecture & Wiring Guide

## Architecture

```
PHONE_A
  ↓ BLE discovery
PHONE_B found
  ↓ exchange capability beacon
PHONE_B says: Wi-Fi available / local IP / Wi-Fi Direct candidate
  ↓ upgrade path
PHONE_A sends larger payload through Wi-Fi path
  ↓ if Wi-Fi fails
fallback to BLE fragments / store-forward
  ↓ if internet gateway discovered
complete delivery through internet gateway
  ↓ ACK travels reverse path
proof ledger records BLE_DISCOVERY → WIFI_UPGRADE → INTERNET_GATEWAY → DELIVERED
```

## Core engines

| File | Responsibility |
|---|---|
| `HybridSignalHopEngine.ts` | Orchestrator — drives the full hop sequence |
| `HybridRouteEngine.ts` | Scores and ranks transport candidates |
| `HybridLearningEngine.ts` | Self-healing memory — bias future scores from past success/failure |
| `HybridProofLedger.ts` | Records every stage transition with proof events |
| `HybridCapabilityExchangeEngine.ts` | Builds and parses peer capability beacons |
| `HybridTransportAdapter.ts` | Adapter boundary — wire to real transports here |
| `HybridSimulationEngine.ts` | Simulation-only runners (labelled `simulation: true`) |

## Absolute rules

1. **BLE is the discovery layer** — always used to find peers first.
2. **Wi-Fi is the preferred delivery layer** when discovered (LOCAL_WIFI score 95, WIFI_DIRECT score 90 vs BLE 45).
3. **Internet is used only when a gateway is discovered** — never the default.
4. **Store-forward must catch failure** — never drop a packet when all live routes fail.
5. **Simulation events must be labelled `simulation: true`** — NEVER mark them as physical proof.
6. **Physical proof requires**: two real phones, real BLE discovery, real Wi-Fi or gateway delivery, real ACK.
7. **Do not delete existing BLE, Rust core, proof ledger, offline save, routing, API, or UI files.**

## Installed location

```
artifacts/messenger-mobile/src/maurimesh/hybrid-hop/
  types.ts
  hash.ts
  HybridLearningEngine.ts
  HybridProofLedger.ts
  HybridCapabilityExchangeEngine.ts
  HybridRouteEngine.ts
  HybridTransportAdapter.ts
  HybridSignalHopEngine.ts
  HybridSimulationEngine.ts
  index.ts
  ui/HybridSignalHopPanel.tsx
```

## Wiring points

### 1. BLE discovery path
- Location: `artifacts/messenger-mobile/lib/mesh/nativeMauriMeshBle.ts` (or wherever BLE scan events fire)
- When a peer is found via BLE, build a `HybridPeerCapabilities` object from the capability beacon
- Feed it to `hybridSignalHopEngine.deliver(packet, peer)`

### 2. Capability beacon exchange
- Over BLE, exchange a JSON beacon with:
  - `peerId`, `bleAvailable`, `wifiDirectAvailable`, `localWifiAvailable`, `internetAvailable`
  - `localIp`, `wifiDirectServiceName`, `internetGatewayUrl`, `batteryPercent`, `trustScore`
- Parse remote beacons with `hybridCapabilityExchangeEngine.parseRemoteCapability(raw)`

### 3. Wi-Fi upgrade path
- Wire `HybridTransportAdapter.sendViaWifi` to the Wi-Fi Direct or local network send path
- Return `true` only after confirmed delivery/ACK

### 4. Internet gateway path
- Wire `HybridTransportAdapter.sendViaInternet` to an authenticated POST to the gateway URL
- The gateway relays the packet to the destination node
- Return `true` only after HTTP 200/201 and ACK confirmation

### 5. Store-forward fallback
- Wire `HybridTransportAdapter.queueStoreForward` to the offline queue (offlineStore)
- Packet is retried when the next live path becomes available

### 6. Rust core enhancement
- Before calling `hybridSignalHopEngine.deliver()`, optionally run:
  - `buildMauriMeshPacketWithRustCore` for FNV-1a hash chain
  - `scoreMauriMeshRouteWithRustCore` for additional risk scoring
- TypeScript fallback always active

### 7. Proof ledger stages to record
```
BLE_DISCOVERY → BLE_PEER_FOUND → CAPABILITY_EXCHANGE → ROUTE_SCORE
→ WIFI_CANDIDATE_FOUND → WIFI_UPGRADE_ATTEMPT → WIFI_DELIVERY
→ INTERNET_GATEWAY_FOUND → INTERNET_DELIVERY
→ ACK_RECEIVED → DELIVERED
(failure path): FAILED → SELF_HEALED → STORE_FORWARD_QUEUED
```

### 8. UI
```tsx
import HybridSignalHopPanel from "@/src/maurimesh/hybrid-hop/ui/HybridSignalHopPanel";
// Add to device-proof.tsx after RustCoreStatusPanel
```

## Test

```bash
node scripts/test-hybrid-signal-hop-engine.mjs
```

## Physical proof (future)

Physical proof requires:
- Two Android phones on the same BLE/Wi-Fi network
- Real BLE peer discovery with capability beacon exchange
- Real Wi-Fi upgrade or internet gateway delivery
- Real ACK returned on reverse path
- ADB logs showing TX → RX → ACK chain
