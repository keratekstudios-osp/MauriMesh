#!/usr/bin/env bash
set -e

echo "=================================================="
echo "ADD NATIVE BLE AUDIT UI — NO EAS BUILD"
echo "=================================================="

BACKUP="$HOME/maurimesh-router-backups/backup-before-native-ble-audit-ui-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP"
cp -R app "$BACKUP/app-current" 2>/dev/null || true
cp -R src "$BACKUP/src-current" 2>/dev/null || true
cp -R docs "$BACKUP/docs-current" 2>/dev/null || true

mkdir -p app src/lib

LATEST_REPORT="$(ls -t docs/maurimesh-native-ble-proof-audit-*.md 2>/dev/null | head -1 || true)"

if [ -z "$LATEST_REPORT" ]; then
  echo "ERROR: No native BLE audit report found."
  echo "Run audit-native-ble-proof-layer-no-eas.sh first."
  exit 1
fi

echo "Using audit report: $LATEST_REPORT"

NATIVE_COUNT="$(grep -Ei "ble|bluetooth|maurimesh|proof|packet|ack|gatt|scan|advertis|receiver|transmit|relay" "$LATEST_REPORT" | wc -l | tr -d ' ')"
HAS_PERMISSION="$(grep -Ei "BLUETOOTH|ACCESS_FINE_LOCATION|FOREGROUND_SERVICE" "$LATEST_REPORT" >/dev/null && echo "YES" || echo "NO")"
HAS_RISK="$(grep -Ei "FAIL: risky startup pattern" "$LATEST_REPORT" >/dev/null && echo "YES" || echo "NO")"

cat > src/lib/nativeBleAudit.ts <<TS
export type NativeBleAuditStatus = {
  reportPath: string;
  nativeSignalCount: number;
  androidPermissionsSeen: "YES" | "NO";
  riskyStartupPatternSeen: "YES" | "NO";
  truth: string;
};

export const nativeBleAuditStatus: NativeBleAuditStatus = {
  reportPath: "$LATEST_REPORT",
  nativeSignalCount: Number("$NATIVE_COUNT"),
  androidPermissionsSeen: "$HAS_PERMISSION" as "YES" | "NO",
  riskyStartupPatternSeen: "$HAS_RISK" as "YES" | "NO",
  truth:
    "Audit only. This confirms project evidence exists; it does not activate live BLE.",
};
TS

cat > app/native-ble-audit.tsx <<'TSX'
import React from "react";
import { ScrollView, StyleSheet, Text, View } from "react-native";
import { nativeBleAuditStatus } from "../src/lib/nativeBleAudit";

const MARKER = "NATIVE_BLE_AUDIT_UI_20260607_A";

export default function NativeBleAuditScreen() {
  const riskTone =
    nativeBleAuditStatus.riskyStartupPatternSeen === "YES" ? "#EF4444" : "#00D084";

  return (
    <ScrollView style={styles.screen} contentContainerStyle={styles.content}>
      <Text style={styles.brand}>MauriMesh</Text>
      <Text style={styles.title}>Native BLE Audit</Text>
      <Text style={styles.marker}>{MARKER}</Text>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Audit Report</Text>
        <Text style={styles.cardText}>{nativeBleAuditStatus.reportPath}</Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Native BLE Evidence Count</Text>
        <Text style={styles.bigNumber}>{nativeBleAuditStatus.nativeSignalCount}</Text>
        <Text style={styles.cardText}>
          Count of audit lines matching BLE, Bluetooth, GATT, scan, advertise,
          packet, ACK, relay, proof, or MauriMesh native signals.
        </Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Android Permissions Seen</Text>
        <Text style={styles.status}>{nativeBleAuditStatus.androidPermissionsSeen}</Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Startup Crash Risk Seen</Text>
        <Text style={[styles.status, { color: riskTone }]}>
          {nativeBleAuditStatus.riskyStartupPatternSeen}
        </Text>
      </View>

      <View style={styles.truthCard}>
        <Text style={styles.cardTitle}>Truth Boundary</Text>
        <Text style={styles.cardText}>{nativeBleAuditStatus.truth}</Text>
        <Text style={styles.cardText}>
          Real BLE activation still requires native module wiring, Android
          permission validation, physical phone logs, and TX/RX/ACK proof.
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
  bigNumber: { color: "#00D084", fontSize: 42, fontWeight: "900", marginBottom: 8 },
  status: { color: "#00D084", fontSize: 22, fontWeight: "900" },
});
TSX

echo ""
echo "Update dashboard with Native BLE Audit button"

python3 <<'PY'
from pathlib import Path

p = Path("app/dashboard.tsx")
text = p.read_text()

if 'Native BLE Audit' not in text:
    text = text.replace(
        '{ title: "Proof Ledger", route: "/proof-ledger" },',
        '{ title: "Proof Ledger", route: "/proof-ledger" },\n  { title: "Native BLE Audit", route: "/native-ble-audit" },'
    )

p.write_text(text)
PY

echo ""
echo "1. Active app files"
find app -maxdepth 2 -type f | sort

echo ""
echo "2. Marker check"
grep -R "NATIVE_BLE_AUDIT_UI_20260607_A\|Native BLE Audit" app src 2>/dev/null

echo ""
echo "3. Crash-risk scan"
grep -R "unstable-native-tabs\|NativeTabs\|SplashScreen\|preventAutoHide\|hideAsync\|useFonts\|_layout.backup" app 2>/dev/null && {
  echo "FAIL: risky startup pattern found."
  exit 1
} || echo "PASS: no known risky startup patterns"

echo ""
echo "4. TypeScript"
npx tsc --noEmit

echo ""
echo "5. Clean export"
rm -rf dist .expo
npx expo export --platform android --clear

echo ""
echo "=================================================="
echo "NATIVE BLE AUDIT UI READY — NO EAS BUILD USED"
echo "Backup: $BACKUP"
echo "=================================================="
