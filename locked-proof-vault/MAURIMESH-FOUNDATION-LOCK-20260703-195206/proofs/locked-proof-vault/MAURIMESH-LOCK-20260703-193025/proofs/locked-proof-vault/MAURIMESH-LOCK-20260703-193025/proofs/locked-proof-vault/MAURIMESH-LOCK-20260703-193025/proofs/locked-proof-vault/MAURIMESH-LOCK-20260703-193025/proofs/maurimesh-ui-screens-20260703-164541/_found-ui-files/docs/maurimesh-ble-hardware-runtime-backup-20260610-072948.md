# MauriMesh BLE Hardware Runtime Backup Wiring

Generated: 20260610-072948

## Added

- BleHardwareBackupPolicy.ts
- BleHardwareRuntimeAdapter.ts
- BleHardwareRuntimePanel.tsx
- /ble-hardware-runtime route
- Dashboard button
- Backup route registry entry
- Optional MauriCore BLE Runtime panel embed
- Checker

## Runtime protection

- Hardware-aware BLE scan control
- BLE advertise control
- Scan window tuning
- Scan cooldown tuning
- Retry limit tuning
- Proof hashing throttling
- Animation reduction
- Store-forward flag
- Backup failover policy

## Final Truth

This controls MauriMesh BLE behaviour.
It does not prove BLE delivery.
Real BLE proof still requires APK device TX/RX/ACK logcat evidence.
