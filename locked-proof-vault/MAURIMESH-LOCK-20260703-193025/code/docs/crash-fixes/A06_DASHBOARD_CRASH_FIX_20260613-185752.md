# A06 Dashboard Crash Fix

Generated: 20260613-185752

## Problem

The new APK crashed on Samsung A06 after pressing **Open Dashboard**.

## Fix Applied

`app/dashboard.tsx` was replaced with a safe fallback dashboard that:

- Uses only local React Native primitives.
- Avoids risky imported dashboard components.
- Avoids API calls on dashboard mount.
- Keeps proof routes accessible.
- Emits `MAURIMESH_DASHBOARD_SAFE` logcat lines.
- Backs up the previous dashboard before change.

## Backup

`backups/a06-dashboard-crash-fix-20260613-185752/dashboard.tsx.backup`

## Next Required Action

1. Rebuild APK.
2. Install rebuilt APK on A06 first.
3. Open app.
4. Press **Open Dashboard**.
5. Confirm dashboard stays open.
6. Then install on S10 and A16.

## A06 Test Command After Install

Run on Mac:

```bash
adb connect 192.168.1.7:5555
adb -s 192.168.1.7:5555 logcat -c
adb -s 192.168.1.7:5555 shell monkey -p com.maurimesh.messenger -c android.intent.category.LAUNCHER 1
adb -s 192.168.1.7:5555 logcat -d | grep -E "MAURIMESH_DASHBOARD_SAFE|FATAL EXCEPTION|AndroidRuntime|ReactNativeJS" | tail -n 120
```
