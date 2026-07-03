# MauriMesh Hybrid Wi-Fi BLE Mesh

Generated: 20260610-080330

## Added

- HybridWifiBleMeshTypes.ts
- BackupHybridWifiBleMeshEngine.ts
- HybridWifiBleMeshPanel.tsx
- /hybrid-wifi-ble-mesh route
- Dashboard button
- Backup route registry entry
- Embedded panel in MauriCore BLE Runtime
- Embedded panel in BLE Hardware Runtime
- Embedded panel in Device Proof
- Checker

## Transport fallback order

- BLE_DIRECT
- BLE_RELAY
- STORE_FORWARD
- WIFI_LOCAL
- WIFI_DIRECT_READY
- INTERNET_GATEWAY
- OFFLINE_HOLD

## Proof events

- HYBRID_ROUTE_DECISION
- HYBRID_FAILOVER
- HYBRID_STORE_FORWARD
- HYBRID_GATEWAY_READY
- HYBRID_OFFLINE_HOLD

## Final Truth

This is a routing and failover decision layer.
Real BLE/Wi-Fi delivery still requires installed APK device proof.
Real BLE delivery requires TX/RX/ACK logcat evidence.
