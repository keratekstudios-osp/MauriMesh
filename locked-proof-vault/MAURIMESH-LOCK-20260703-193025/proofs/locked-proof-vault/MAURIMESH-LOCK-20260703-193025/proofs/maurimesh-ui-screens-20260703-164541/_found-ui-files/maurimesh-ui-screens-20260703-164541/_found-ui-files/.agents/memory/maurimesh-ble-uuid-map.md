---
name: MauriMesh BLE service UUID map & stale task paths
description: Where BLE UUIDs really live, the three divergent families, and that some task specs cite a non-existent artifacts/* native tree.
---

# MauriMesh BLE service UUIDs — real locations & divergence

Some assigned tasks (e.g. the "unify BLE service UUIDs" task) reference a
native source tree that **does not exist**:
`artifacts/messenger-mobile/plugins/android-src/com/maurimesh/ble/*.kt`
(`MeshBleUuids.kt`, `MeshGattServerManager.kt`, `MeshAdvertiser.kt`,
`MeshCentralClient.kt`) and `artifacts/mesh-daemon/src/ble.rs`. None of
these files are in the repo. **Verify paths before acting on BLE tasks.**

Real UUID definitions (three divergent families, no single source of truth):
- Native Kotlin radio — `android/app/src/main/java/com/maurimesh/mesh/MeshEngine.kt`:
  SERVICE `7c9a0001-…`, TX `7c9a0002-…`, RX `7c9a0003-…` (also mirrored in
  `fix-maurimesh-release-kotlin-native-layer.sh`).
- JS/TS BLE transport — `lib/lib/mesh/useBleTransport.ts`:
  `MESH_SERVICE_UUID = 7f9a0001-…`, TX `7f9a0002-…`, RX `7f9a0003-…`.
- Docs only — `docs/RUST_ENGINE_ARCHITECTURE.md` table: `4d617572-…0001/0002`.

The Rust core (`rust/maurimesh-core/src/`) defines **no BLE UUIDs at all**
(it is simulation/FFI/packet/route logic, not radio). So any task premise
that "Rust defines the canonical UUID" is false.

**Why:** the Kotlin (`7c9a`) and JS (`7f9a`) families differ, so on real
hardware the native radio and the JS transport would not interoperate. As of
the close of the unify-UUIDs task the user chose to **leave them divergent**
(make no change), because the genuine fix requires editing `android/` native
Kotlin which is under the standing "do not touch native BLE radio internals"
guardrail and is untestable here.

**How to apply:** if a future task asks to align/advertise/scan BLE UUIDs,
do not trust the artifacts/* paths; the live values are in MeshEngine.kt and
useBleTransport.ts. Confirm with the user which family is canonical before
changing native code, since there is no authoritative definition.
