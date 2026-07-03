#!/usr/bin/env bash
set -euo pipefail

PKG="${1:-com.maurimesh.messenger}"

echo "============================================================"
echo "#182 Screen-lock foreground service proof"
echo "Package: $PKG"
echo "============================================================"

adb logcat -c

echo "Launch app"
adb shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1

echo ""
echo "Now on phone:"
echo "1. Dashboard -> Foreground Runtime Proof"
echo "2. Press Start Mesh Foreground Service"
echo "3. Confirm notification says MauriMesh Mesh Active"
echo "4. Lock screen for 10+ minutes"
echo "5. Unlock and press Refresh Status"
echo ""
echo "Capturing current relevant logs..."
sleep 5

adb logcat -d | grep -E "MauriMeshForeground|FOREGROUND_SERVICE_HEARTBEAT|TASK_182|AndroidRuntime|FATAL EXCEPTION" | tail -250 || true
