# MauriMesh Replit Rebuild Report — Logcat Bridge APK

Generated: 20260613-181120

## Purpose

Prepare a rebuilt APK after the safe Store-Forward logcat bridge repair.

## Verified

- package.json exists.
- app/store-forward-proof.tsx contains `MAURIMESH_SAFE_STORE_FORWARD_LOGCAT_BRIDGE_V1`.
- No `MAURIMESH_LOGCAT_BRIDGE_DIRECT_` pollution remains.
- Package manager detected: `pnpm`.
- TypeScript check: `PASS`.
- Expo config check: `PASS`.

## Required Reason

Previous raw-device capture connected A06, S10, and A16 successfully, but Android logcat did not contain packet ID `MMSF-RAW-LIVE-001`.

The rebuilt APK must include the safe logcat bridge before rerunning Mac raw capture.

## After Build

Install the rebuilt APK on:

- A06 / 192.168.1.7:5555
- S10 / 192.168.1.10:5555
- A16 / 192.168.1.4:5555

Then run on Mac:

```bash
cd ~/maurimesh-raw-evidence
adb connect 192.168.1.7:5555
adb connect 192.168.1.10:5555
adb connect 192.168.1.4:5555
A06_SERIAL=192.168.1.7:5555 S10_SERIAL=192.168.1.10:5555 A16_SERIAL=192.168.1.4:5555 ./capture-maurimesh-raw-evidence.sh MMSF-RAW-LIVE-001 180
```
