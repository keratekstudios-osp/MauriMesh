# MauriMesh App/Runtime Risk File List

## Time

20260613-203925

## Purpose

This report lists app/runtime/build-related files currently modified or untracked before the next APK build.

## Protection

This command did not push, commit, stage, delete, or edit app code.

## Risk File Count

`23`

## Files

```text
 M app/_layout.tsx
 M app/dashboard.tsx
 M app/login.tsx
 M app/store-forward-proof.tsx
 M src/components/AiPixelReconstructionPanel.tsx
 M src/components/BackupIntelligencePanel.tsx
 M src/components/BleHardwareRuntimePanel.tsx
 M src/components/DeviceHardwarePanel.tsx
 M src/components/HardwareRuntimeControllerPanel.tsx
 M src/components/HybridWifiBleMeshPanel.tsx
 M src/components/IntelligencePanel.tsx
 M src/components/MauriButton.tsx
 M src/components/MauriPanel.tsx
 M src/components/MessageFallbackPanel.tsx
 M src/components/NativeTelemetryPanel.tsx
 M src/components/PixelCallingBackupFallbackPanel.tsx
 M src/components/PixelCallingRuntimePanel.tsx
?? app/locked-proof-vault.tsx
?? app/locked-proofs.tsx
?? app/runtime-logs.tsx
?? src/maurimesh/proof/lockedProofVault.ts
?? src/maurimesh/proofs/
?? src/maurimesh/runtime/runtimeLog.ts
```

## Next Action

Review these files before building another APK. Do not run EAS/APK build until the dashboard, proof screens, runtime logging, and package/build config changes are understood.
