#!/usr/bin/env bash
set -e

echo "=================================================="
echo "ADD NATIVE BLE STATUS BRIDGE — NO EAS BUILD"
echo "=================================================="

BACKUP="$HOME/maurimesh-router-backups/backup-before-native-ble-status-bridge-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP"
cp -R app "$BACKUP/app-current" 2>/dev/null || true
cp -R src "$BACKUP/src-current" 2>/dev/null || true

mkdir -p app src/lib

echo ""
echo "1. Create safe native BLE bridge reader"

cat > src/lib/nativeBleBridge.ts <<'TS'
import { NativeModules, PermissionsAndroid, Platform } from "react-native";

export type NativeBleBridgeStatus = {
  platform: string;
  modulePresent: boolean;
  moduleName: string;
  bluetoothScanPermission: "granted" | "denied" | "unavailable";
  bluetoothConnectPermission: "granted" | "denied" | "unavailable";
  fineLocationPermission: "granted" | "denied" | "unavailable";
  liveBleActive: false;
  truth: string;
};

function hasCallable(value: unknown): value is () => Promise<unknown> {
  return typeof value === "function";
}

async function checkPermission(permission: string | undefined) {
  if (Platform.OS !== "android" || !permission) return "unavailable" as const;

  try {
    const granted = await PermissionsAndroid.check(permission as any);
    return granted ? ("granted" as const) : ("denied" as const);
  } catch {
    return "unavailable" as const;
  }
}

export async function getNativeBleBridgeStatus(): Promise<NativeBleBridgeStatus> {
  const moduleName = "MauriMeshBle";
  const nativeModule = (NativeModules as any)[moduleName];

  const scanPermission =
    Platform.OS === "android"
      ? await checkPermission((PermissionsAndroid.PERMISSIONS as any).BLUETOOTH_SCAN)
      : "unavailable";

  const connectPermission =
    Platform.OS === "android"
      ? await checkPermission((PermissionsAndroid.PERMISSIONS as any).BLUETOOTH_CONNECT)
      : "unavailable";

  const fineLocationPermission =
    Platform.OS === "android"
      ? await checkPermission(PermissionsAndroid.PERMISSIONS.ACCESS_FINE_LOCATION)
      : "unavailable";

  let modulePresent = Boolean(nativeModule);

  if (nativeModule && hasCallable(nativeModule.getStatus)) {
    try {
      await nativeModule.getStatus();
      modulePresent = true;
    } catch {
      modulePresent = true;
    }
  }

  return {
    platform: Platform.OS,
    modulePresent,
    moduleName,
    bluetoothScanPermission: scanPermission,
    bluetoothConnectPermission: connectPermission,
    fineLocationPermission,
    liveBleActive: false,
    truth:
      "Read-only native BLE bridge status. This does not scan, advertise, connect, send, receive, or claim live BLE.",
  };
}
TS

echo ""
echo "2. Create Native BLE Status screen"

cat > app/native-ble-status.tsx <<'TSX'
import React, { useEffect, useState } from "react";
import { ScrollView, StyleSheet, Text, View } from "react-native";
import { getNativeBleBridgeStatus, NativeBleBridgeStatus } from "../src/lib/nativeBleBridge";

const MARKER = "NATIVE_BLE_STATUS_BRIDGE_20260607_A";

export default function NativeBleStatusScreen() {
  const [status, setStatus] = useState<NativeBleBridgeStatus | null>(null);

  useEffect(() => {
    let alive = true;
    getNativeBleBridgeStatus()
      .then((next) => {
        if (alive) setStatus(next);
      })
      .catch(() => {
        if (alive) {
          setStatus({
            platform: "unknown",
            modulePresent: false,
            moduleName: "MauriMeshBle",
            bluetoothScanPermission: "unavailable",
            bluetoothConnectPermission: "unavailable",
            fineLocationPermission: "unavailable",
            liveBleActive: false,
            truth:
              "Native BLE bridge status failed safely. No live BLE action was attempted.",
          });
        }
      });

    return () => {
      alive = false;
    };
  }, []);

  const moduleTone = status?.modulePresent ? "#00D084" : "#F59E0B";

  return (
    <ScrollView style={styles.screen} contentContainerStyle={styles.content}>
      <Text style={styles.brand}>MauriMesh</Text>
      <Text style={styles.title}>Native BLE Status</Text>
      <Text style={styles.marker}>{MARKER}</Text>

      <View style={styles.truthCard}>
        <Text style={styles.cardTitle}>Truth Boundary</Text>
        <Text style={styles.cardText}>
          {status?.truth || "Checking read-only native BLE bridge status..."}
        </Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Native Module</Text>
        <Text style={[styles.bigStatus, { color: moduleTone }]}>
          {status?.modulePresent ? "PRESENT" : "NOT CONFIRMED"}
        </Text>
        <Text style={styles.cardText}>Module name: {status?.moduleName || "MauriMeshBle"}</Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Platform</Text>
        <Text style={styles.cardText}>{status?.platform || "checking..."}</Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Android Permissions</Text>
        <Text style={styles.cardText}>BLUETOOTH_SCAN: {status?.bluetoothScanPermission || "checking..."}</Text>
        <Text style={styles.cardText}>BLUETOOTH_CONNECT: {status?.bluetoothConnectPermission || "checking..."}</Text>
        <Text style={styles.cardText}>ACCESS_FINE_LOCATION: {status?.fineLocationPermission || "checking..."}</Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Live BLE Active</Text>
        <Text style={styles.dangerText}>NO</Text>
        <Text style={styles.cardText}>
          This screen is status-only. Scan, advertise, connect, TX/RX, ACK, and relay are not activated here.
        </Text>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: "#020617" },
  content: { padding: 24, paddingTop: 72, paddingBottom: 42 },
  brand: { color: "#00D084", fontSize: 38, fontWeight: "900", marginBottom: 8 },
  title: { color: "#FFFFFF", fontSize: 28, fontWeight: "900", marginBottom: 8 },
  marker: { color: "#38BDF8", fontSize: 12, fontWeight: "800", marginBottom: 20 },
  card: {
    backgroundColor: "rgba(255,255,255,0.06)",
    borderColor: "rgba(0,208,132,0.28)",
    borderWidth: 1,
    borderRadius: 22,
    padding: 18,
    marginBottom: 14,
  },
  truthCard: {
    backgroundColor: "rgba(245,158,11,0.10)",
    borderColor: "rgba(245,158,11,0.45)",
    borderWidth: 1,
    borderRadius: 22,
    padding: 18,
    marginBottom: 14,
  },
  cardTitle: { color: "#FFFFFF", fontSize: 18, fontWeight: "900", marginBottom: 10 },
  cardText: { color: "rgba(255,255,255,0.76)", fontSize: 14, lineHeight: 22 },
  bigStatus: { fontSize: 28, fontWeight: "900", marginBottom: 8 },
  dangerText: { color: "#EF4444", fontSize: 22, fontWeight: "900", marginBottom: 8 },
});
TSX

echo ""
echo "3. Add Native BLE Status button to dashboard"

python3 <<'PY'
from pathlib import Path

p = Path("app/dashboard.tsx")
text = p.read_text()

if 'Native BLE Status' not in text:
    if '{ title: "Native BLE Audit", route: "/native-ble-audit" },' in text:
        text = text.replace(
            '{ title: "Native BLE Audit", route: "/native-ble-audit" },',
            '{ title: "Native BLE Audit", route: "/native-ble-audit" },\n  { title: "Native BLE Status", route: "/native-ble-status" },'
        )
    elif '{ title: "Proof Ledger", route: "/proof-ledger" },' in text:
        text = text.replace(
            '{ title: "Proof Ledger", route: "/proof-ledger" },',
            '{ title: "Proof Ledger", route: "/proof-ledger" },\n  { title: "Native BLE Status", route: "/native-ble-status" },'
        )

p.write_text(text)
PY

echo ""
echo "4. Active app files"
find app -maxdepth 2 -type f | sort

echo ""
echo "5. Marker check"
grep -R "NATIVE_BLE_STATUS_BRIDGE_20260607_A\|Native BLE Status" app src 2>/dev/null

echo ""
echo "6. Crash-risk scan"
grep -R "unstable-native-tabs\|NativeTabs\|SplashScreen\|preventAutoHide\|hideAsync\|useFonts\|_layout.backup" app 2>/dev/null && {
  echo "FAIL: risky startup pattern found."
  exit 1
} || echo "PASS: no known risky startup patterns"

echo ""
echo "7. TypeScript"
npx tsc --noEmit

echo ""
echo "8. Clean export"
rm -rf dist .expo
npx expo export --platform android --clear

echo ""
echo "=================================================="
echo "NATIVE BLE STATUS BRIDGE READY — NO EAS BUILD USED"
echo "Backup: $BACKUP"
echo "=================================================="
