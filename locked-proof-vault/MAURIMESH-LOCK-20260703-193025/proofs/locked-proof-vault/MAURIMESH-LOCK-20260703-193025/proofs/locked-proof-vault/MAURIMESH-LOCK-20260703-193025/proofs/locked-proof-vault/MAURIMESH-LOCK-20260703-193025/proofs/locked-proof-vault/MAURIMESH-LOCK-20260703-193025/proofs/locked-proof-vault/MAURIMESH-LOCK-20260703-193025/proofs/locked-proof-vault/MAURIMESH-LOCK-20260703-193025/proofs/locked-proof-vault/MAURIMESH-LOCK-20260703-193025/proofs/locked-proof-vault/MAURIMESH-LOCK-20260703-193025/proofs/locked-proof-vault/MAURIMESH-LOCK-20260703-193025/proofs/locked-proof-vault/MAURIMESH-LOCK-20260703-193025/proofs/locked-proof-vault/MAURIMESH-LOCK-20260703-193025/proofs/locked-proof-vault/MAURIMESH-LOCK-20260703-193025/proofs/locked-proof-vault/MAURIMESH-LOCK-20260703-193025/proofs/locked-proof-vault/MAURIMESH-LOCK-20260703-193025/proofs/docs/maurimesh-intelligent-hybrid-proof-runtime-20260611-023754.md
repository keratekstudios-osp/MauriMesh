# MauriMesh Intelligent Hybrid Proof Runtime

Generated: 20260611-023754

Installed:

- `src/maurimesh/intelligent-hybrid-proof/types.ts`
- `src/maurimesh/intelligent-hybrid-proof/meshMemory.ts`
- `src/maurimesh/intelligent-hybrid-proof/meshAiRuntime.ts`
- `app/mesh-hybrid-runtime-proof.tsx`

## Truth Boundary

- A06 + S10 can prove 2-hop physical proof when both are visible in ADB/logcat.
- A-B-C 3-hop physical proof needs a third relay-capable MauriMesh device or a Mac companion bridge.
- AirPods can be BLE observed only. They cannot relay MauriMesh packets.
- Logic trust reaching 100% means the routing logic is signed off, not that unsupported hardware became a relay.

## Next

Build a new APK and install it on both phones.

```bash
npx eas-cli build --platform android --profile preview-apk --clear-cache --non-interactive
```
