#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH DASHBOARD CRASH RECOVERY SAFE v1"
echo "============================================================"
echo "Goal:"
echo "- Stop dashboard crash"
echo "- Replace dashboard with dependency-light safe route screen"
echo "- Keep all proof routes visible"
echo "- Include Native BLE/GATT Proof route"
echo "- Do not change proof logic"
echo "- Do not claim native BLE/GATT PASS"
echo "============================================================"

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
TARGET="$ROOT/app/dashboard.tsx"
BACKUP="$ROOT/backup-before-dashboard-crash-recovery-safe-v1-$STAMP"
REPORT_DIR="$ROOT/docs/runtime-crash"
REPORT="$REPORT_DIR/DASHBOARD_CRASH_RECOVERY_SAFE_V1_$STAMP.md"

mkdir -p "$BACKUP/app" "$REPORT_DIR" "$ROOT/archives"

if [ -f "$TARGET" ]; then
  cp "$TARGET" "$BACKUP/app/dashboard.tsx"
else
  echo "WARN: app/dashboard.tsx did not exist. Creating safe dashboard."
fi

cat > "$TARGET" <<'TSX'
import { useRouter } from "expo-router";
import React from "react";
import {
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from "react-native";

type RouteItem = {
  title: string;
  route: string;
  subtitle: string;
  tone?: "green" | "blue" | "amber" | "red";
};

const routes: RouteItem[] = [
  {
    title: "Unified Spine Exam",
    route: "/maurimesh-spine-exam",
    subtitle: "Routing + resilience + governance + proof + exam spine.",
    tone: "green",
  },
  {
    title: "2-Hop Proof",
    route: "/proof-2-hop",
    subtitle: "A06 → S10 → ACK back to A06 proof workflow.",
    tone: "blue",
  },
  {
    title: "3-Device Relay Proof",
    route: "/3-device-proof",
    subtitle: "A06 → S10 → A16 → ACK back through relay.",
    tone: "blue",
  },
  {
    title: "BLE 3-Device Proof",
    route: "/ble-3-device-proof",
    subtitle: "BLE-labelled 3-device proof route if present.",
    tone: "blue",
  },
  {
    title: "Store-Forward Proof",
    route: "/store-forward-proof",
    subtitle: "Delayed delivery, hold, forward, ACK proof workflow.",
    tone: "green",
  },
  {
    title: "Native BLE/GATT Proof",
    route: "/native-ble-gatt-proof",
    subtitle: "Native callback capture gate. Packet-bound PASS remains pending.",
    tone: "amber",
  },
  {
    title: "Locked Proof Vault Guard",
    route: "/locked-proof-vault",
    subtitle: "Crash-safe vault guard. Does not claim native BLE/GATT PASS.",
    tone: "amber",
  },
  {
    title: "Proof Vault Health / Storage Reader",
    route: "/proof-vault-health",
    subtitle: "Reads vault entries, proof counts, bytes, checksums, packet IDs.",
    tone: "green",
  },
  {
    title: "Learner Core",
    route: "/learner-core",
    subtitle: "Evidence classifier, scoring, recovery, and trust state.",
    tone: "green",
  },
];

export default function DashboardScreen() {
  const router = useRouter();

  return (
    <ScrollView style={styles.screen} contentContainerStyle={styles.content}>
      <Text style={styles.kicker}>MAURIMESH SAFE RUNTIME</Text>
      <Text style={styles.title}>Safe Dashboard</Text>

      <View style={styles.truthBox}>
        <Text style={styles.truthTitle}>Truth State</Text>
        <Text style={styles.truthLine}>Safe Dashboard: ACTIVE</Text>
        <Text style={styles.truthLine}>Route entry: dependency-light</Text>
        <Text style={styles.truthLine}>Proof-screen workflow: ALLOWED</Text>
        <Text style={styles.truthLine}>
          Native BLE/GATT packet-bound PASS: NOT CLAIMED
        </Text>
        <Text style={styles.truthLine}>Vault guard: /locked-proof-vault</Text>
        <Text style={styles.truthLine}>
          Storage reader: /proof-vault-health
        </Text>
      </View>

      <Text style={styles.section}>Proof + Recovery Routes</Text>

      {routes.map((item) => (
        <RouteCard
          key={item.route}
          item={item}
          onPress={() => router.push(item.route as never)}
        />
      ))}

      <View style={styles.warningBox}>
        <Text style={styles.warningTitle}>Native BLE/GATT Truth Lock</Text>
        <Text style={styles.warningText}>
          This dashboard only opens routes. It does not claim native BLE/GATT
          packet-bound PASS. Final PASS requires the same packetId inside native
          BLE/GATT transport logs from physical devices.
        </Text>
      </View>

      <Text style={styles.footer}>
        If a route crashes, repair that route only. Do not destroy existing
        proof logic, vault evidence, ACK logic, or store-forward logic.
      </Text>
    </ScrollView>
  );
}

function RouteCard({
  item,
  onPress,
}: {
  item: RouteItem;
  onPress: () => void;
}) {
  const toneStyle =
    item.tone === "blue"
      ? styles.blue
      : item.tone === "amber"
        ? styles.amber
        : item.tone === "red"
          ? styles.red
          : styles.green;

  return (
    <Pressable
      onPress={onPress}
      style={({ pressed }) => [
        styles.card,
        toneStyle,
        pressed && { opacity: 0.75, transform: [{ scale: 0.985 }] },
      ]}
    >
      <Text style={styles.cardTitle}>{item.title}</Text>
      <Text style={styles.route}>{item.route}</Text>
      <Text style={styles.cardSubtitle}>{item.subtitle}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  screen: {
    flex: 1,
    backgroundColor: "#020403",
  },
  content: {
    padding: 20,
    paddingBottom: 56,
    gap: 14,
  },
  kicker: {
    color: "#00D084",
    fontSize: 12,
    fontWeight: "900",
    letterSpacing: 2,
    marginTop: 8,
  },
  title: {
    color: "#FFFFFF",
    fontSize: 38,
    lineHeight: 42,
    fontWeight: "900",
  },
  section: {
    color: "#FFFFFF",
    fontSize: 22,
    fontWeight: "900",
    marginTop: 8,
  },
  truthBox: {
    borderWidth: 1,
    borderColor: "rgba(0,208,132,0.35)",
    backgroundColor: "rgba(0,32,20,0.72)",
    borderRadius: 22,
    padding: 16,
    gap: 6,
  },
  truthTitle: {
    color: "#00D084",
    fontSize: 18,
    fontWeight: "900",
    marginBottom: 4,
  },
  truthLine: {
    color: "rgba(255,255,255,0.84)",
    fontSize: 14,
    lineHeight: 20,
    fontWeight: "700",
  },
  card: {
    borderWidth: 1,
    borderRadius: 20,
    padding: 16,
    gap: 6,
    backgroundColor: "rgba(255,255,255,0.055)",
  },
  green: {
    borderColor: "rgba(0,208,132,0.42)",
  },
  blue: {
    borderColor: "rgba(56,189,248,0.42)",
  },
  amber: {
    borderColor: "rgba(245,158,11,0.48)",
  },
  red: {
    borderColor: "rgba(239,68,68,0.5)",
  },
  cardTitle: {
    color: "#FFFFFF",
    fontSize: 18,
    fontWeight: "900",
  },
  route: {
    color: "#00D084",
    fontSize: 12,
    fontWeight: "900",
  },
  cardSubtitle: {
    color: "rgba(255,255,255,0.72)",
    fontSize: 14,
    lineHeight: 20,
  },
  warningBox: {
    borderWidth: 1,
    borderColor: "rgba(245,158,11,0.5)",
    backgroundColor: "rgba(245,158,11,0.08)",
    borderRadius: 20,
    padding: 16,
    gap: 8,
    marginTop: 8,
  },
  warningTitle: {
    color: "#F59E0B",
    fontSize: 17,
    fontWeight: "900",
  },
  warningText: {
    color: "rgba(255,255,255,0.78)",
    lineHeight: 21,
    fontWeight: "700",
  },
  footer: {
    color: "rgba(255,255,255,0.62)",
    lineHeight: 21,
    fontWeight: "700",
    marginTop: 8,
  },
});
TSX

echo ""
echo "============================================================"
echo "VERIFY REQUIRED ROUTE FILES"
echo "============================================================"

for f in \
  app/dashboard.tsx \
  app/native-ble-gatt-proof.tsx \
  app/maurimesh-spine-exam.tsx \
  app/proof-vault-health.tsx \
  app/locked-proof-vault.tsx
do
  if [ -f "$ROOT/$f" ]; then
    echo "PASS: $f"
  else
    echo "WARN: missing $f"
  fi
done

echo ""
echo "============================================================"
echo "TYPESCRIPT CHECK"
echo "============================================================"

npx tsc --noEmit

echo ""
echo "============================================================"
echo "EXPO ANDROID EXPORT CHECK"
echo "============================================================"

npx expo export --platform android --output-dir dist-dashboard-recovery-safe-v1

cat > "$REPORT" <<MD
# MauriMesh Dashboard Crash Recovery Safe v1

Generated: $STAMP

## Result

Safe dashboard replaced app/dashboard.tsx.

## Why

The APK crashed after opening dashboard after dashboard route patching.

## Recovery Action

Dashboard was replaced with a dependency-light React Native screen:
- no custom component imports
- no proof logic imports
- no vault logic imports
- no native BLE imports
- route cards only
- truth labels preserved

## Routes Included

- /maurimesh-spine-exam
- /proof-2-hop
- /3-device-proof
- /ble-3-device-proof
- /store-forward-proof
- /native-ble-gatt-proof
- /locked-proof-vault
- /proof-vault-health
- /learner-core

## Truth

Native BLE/GATT packet-bound PASS is not claimed.

## Backup

$BACKUP
MD

tar -czf "$ROOT/archives/dashboard-crash-recovery-safe-v1-$STAMP.tar.gz" \
  "$REPORT" "$BACKUP" "$TARGET" 2>/dev/null || true

echo ""
echo "============================================================"
echo "DASHBOARD RECOVERY COMPLETE"
echo "============================================================"
echo "Report: $REPORT"
echo "Backup: $BACKUP"
echo "Archive: $ROOT/archives/dashboard-crash-recovery-safe-v1-$STAMP.tar.gz"
echo ""
echo "Next:"
echo "1. Build fresh APK"
echo "2. Install on phone"
echo "3. Open dashboard"
echo "4. Tap Native BLE/GATT Proof"
echo "============================================================"
