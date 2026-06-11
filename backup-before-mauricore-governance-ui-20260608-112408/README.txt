Backup marker before wiring MauriCore Governance Dashboard UI.
This script creates/updates:
- app/mauricore-governance.tsx
- src/mauricore/dashboard/MauriCoreGovernanceScreen.tsx
- attempts safe dashboard button injection only if a known dashboard file is found.

It does not delete BLE/router/ACK/store-forward/native files.
