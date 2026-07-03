# MauriMesh Hardware Runtime Controller

Generated: 20260610-072645

## Added

- HardwareRuntimeController.ts
- useHardwareRuntimeController hook
- HardwareRuntimeControllerPanel
- /hardware-runtime route
- Dashboard button
- Backup route registry entry
- Checker

## Controls

- BLE scan window
- BLE cooldown
- BLE retry count
- BLE advertise permission
- Proof hashing permission
- Proof ledger batch size
- Animation reduction flag
- Store-forward routing flag
- Safe mode state
- Operator alert

## Final Truth

This layer lets MauriMesh adapt its own runtime behaviour from native telemetry.
It does not repair physical hardware.
It does not bypass Android restrictions.
It does not prove BLE delivery without device TX/RX/ACK logs.
