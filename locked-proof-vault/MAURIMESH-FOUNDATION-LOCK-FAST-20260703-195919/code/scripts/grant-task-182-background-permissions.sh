#!/usr/bin/env bash
set -euo pipefail

PKG="${1:-com.maurimesh.messenger}"

echo "Granting background runtime permissions for $PKG"

adb shell pm grant "$PKG" android.permission.POST_NOTIFICATIONS 2>/dev/null || true
adb shell pm grant "$PKG" android.permission.ACCESS_FINE_LOCATION 2>/dev/null || true
adb shell pm grant "$PKG" android.permission.BLUETOOTH_SCAN 2>/dev/null || true
adb shell pm grant "$PKG" android.permission.BLUETOOTH_CONNECT 2>/dev/null || true
adb shell pm grant "$PKG" android.permission.BLUETOOTH_ADVERTISE 2>/dev/null || true

adb shell appops set "$PKG" POST_NOTIFICATION allow 2>/dev/null || true
adb shell appops set "$PKG" FINE_LOCATION allow 2>/dev/null || true
adb shell appops set "$PKG" BLUETOOTH_SCAN allow 2>/dev/null || true
adb shell appops set "$PKG" BLUETOOTH_CONNECT allow 2>/dev/null || true
adb shell appops set "$PKG" BLUETOOTH_ADVERTISE allow 2>/dev/null || true

adb shell am force-stop "$PKG"
adb shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1

echo "Done. Open Dashboard -> Foreground Runtime Proof."
