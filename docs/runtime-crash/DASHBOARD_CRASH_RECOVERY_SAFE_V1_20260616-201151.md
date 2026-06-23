# MauriMesh Dashboard Crash Recovery Safe v1

Generated: 20260616-201151

## Result

Safe dashboard replaced app/dashboard.tsx.

## Why

The APK crashed after opening dashboard after dashboard route patching.

## Recovery Action

Dashboard was replaced with a dependency-light React Native screen:
- no custom component imports
- no proof logic imports
- no vault logic imports
- no native BLE imports
- route cards only
- truth labels preserved

## Routes Included

- /maurimesh-spine-exam
- /proof-2-hop
- /3-device-proof
- /ble-3-device-proof
- /store-forward-proof
- /native-ble-gatt-proof
- /locked-proof-vault
- /proof-vault-health
- /learner-core

## Truth

Native BLE/GATT packet-bound PASS is not claimed.

## Backup

/home/runner/workspace/backup-before-dashboard-crash-recovery-safe-v1-20260616-201151
