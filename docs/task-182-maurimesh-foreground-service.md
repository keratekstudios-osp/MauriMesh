# Task #182 — MauriMesh Foreground Service

Marker: `TASK_182_MAURIMESH_FOREGROUND_SERVICE_20260608_A`

## Installed

- `MauriMeshForegroundService.kt`
- `MauriMeshBackgroundRuntimeModule.kt`
- `MauriMeshBackgroundRuntimePackage.kt`
- Android manifest service declaration
- Foreground permissions
- JS client: `src/maurimesh/background/foregroundRuntimeClient.ts`
- Proof screen: `/foreground-runtime-proof`
- Permission helper: `scripts/grant-task-182-background-permissions.sh`
- Logcat proof helper: `scripts/task-182-screen-lock-proof-logcat.sh`

## Native behavior

- Calls `startForeground()`
- Persistent notification: `MauriMesh Mesh Active`
- Returns `START_STICKY`
- Writes heartbeat every 2 minutes
- Exposes status through React Native bridge

## Truth boundary

This installs the native foreground runtime layer.

Real completion requires physical proof:

1. Build and install APK.
2. Open Dashboard → Foreground Runtime Proof.
3. Press Start Mesh Foreground Service.
4. Confirm Android notification is visible.
5. Lock phone screen for 10+ minutes.
6. Unlock.
7. Confirm heartbeat advanced.
8. Confirm BLE scan still starts after screen lock.
9. Run two-phone screen-off discovery/ACK proof after advertise/connect phases exist.
