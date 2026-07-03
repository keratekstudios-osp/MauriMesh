# MauriMesh Proof Vault Health + Export v1

Generated: 20260614-045027

## Added

- app/proof-vault-health.tsx
- Dashboard button: Proof Vault Health

## Capabilities

- Reads MauriMesh AsyncStorage vault keys
- Counts entries
- Counts proof entries
- Totals stored bytes
- Groups by proof type
- Lists packet IDs
- Creates export JSON
- Creates simple integrity checksum
- Saves health report back into vault

## Truth

This audits local proof storage.
It does not claim native BLE/GATT packet-bound PASS.

Native BLE/GATT PASS still requires the same packetId inside native BLE/GATT transport logs.
