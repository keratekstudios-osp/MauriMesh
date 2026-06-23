# MauriMesh Safe Dashboard Entry v2

Generated: 20260614-045518

## Problem

Last APK crashed when pressing Open Dashboard.

## Patch

Replaced app/dashboard.tsx with a dependency-light Safe Dashboard using only:

- React
- React Native primitives
- expo-router

Removed risk from:

- custom panels
- heavy visual wrappers
- experimental imports
- native module access on dashboard open
- animation dependencies

## Preserved routes

- /ble-2-hop-proof
- /3-device-proof
- /ble-3-device-proof
- /store-forward-proof
- /locked-proof-vault
- /proof-vault-health
- /learner-core

## Truth

This patch hardens dashboard entry.

It does not claim native BLE/GATT packet-bound PASS.

Native BLE/GATT PASS still requires the same packetId inside native BLE/GATT transport logs.
