---
name: MauriMesh native-BLE task triage (standing user decision)
description: How to handle the recurring stale-snapshot native-Android BLE tasks (#163/#164/#168 and the queue behind them).
---

# Native-Android-only BLE tasks: auto-close stale-snapshot work

Several queued tasks ask to wire/replace native BLE (scan, GATT, advertise,
relay, foreground service). They repeatedly cite files/paths that DO NOT exist
in this repo:
- `artifacts/messenger-mobile/plugins/android-src/com/maurimesh/ble/*`
- `artifacts/messenger-mobile/modules/mauri-mesh-ble/.../MeshCentralClient.kt`
- `artifacts/api-server/src/runtime/RuntimeTruthEngine.ts`
- symbols `MeshGattServerManager`, `MauriMeshEngine`, `receivePacketFromGatt`,
  `RuntimeTruthEngine` — these live only in docs/RUST_ENGINE_ARCHITECTURE.md
  and replit.md, NOT in source.

Actual native code lives under `android/app/src/main/java/com/maurimesh/`
(`messenger/MauriMeshBleModule.kt`, `mesh/MeshEngine.kt`,
`mesh/MeshForegroundService.kt`, `mesh/MeshWatchdog.kt`,
`routing/MeshRouteTable.kt`, `service/MeshStartupService.kt`). JS shim:
`lib/mesh/nativeMauriMeshBle.ts`.

**Standing decision (user, 2026-06-08):** auto-close native-Android-ONLY
stale-snapshot BLE tasks with NO changes and WITHOUT re-asking. Tasks #163,
#164, #168 closed this way.

**Why:** (1) real BLE radio work is under the hard "do not touch native BLE
internals / android,ios,eas,rust,routing-engine,packet-engine" guardrail;
(2) it cannot be compiled or tested in this environment (no device/NDK);
(3) acceptance criteria that demand a "real_native" mode / "real peer data"
would violate the hard truth-boundary rule ("NEVER imply Replit proves real
BLE").

**How to apply:** before closing, quick-verify the cited paths/symbols are
absent (rg). Close with drift_reason (stale snapshot, guardrail, untestable)
and skip_validation_reason (no code changed). Do NOT blanket-close anything
merely BLE-adjacent: tasks with genuine server/JS portions (e.g. error-ledger
wiring, save-proof-to-server, proof-scope promotion, .js-extension quality
gate) should have those non-native parts implemented and tested normally.
