#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH TWO-PHONE HOTSPOT GATEWAY PROOF"
echo "PHONE A = hotspot/gateway"
echo "PHONE B = client/sender connected to hotspot"
echo "============================================================"
echo ""

ROOT="/home/runner/workspace"
STAMP="$(date +%Y%m%d-%H%M%S)"
DOCS="$ROOT/docs"
PROOF_ID="MM-HOTSPOT-2PHONE-$STAMP"
PACKET_ID="pkt-hotspot-$STAMP"
ROUTE_ID="route-phoneB-phoneA-hotspot-$STAMP"
REPORT="$DOCS/maurimesh-two-phone-hotspot-gateway-proof-$STAMP.md"
LATEST="$DOCS/maurimesh-two-phone-hotspot-gateway-proof-latest.md"

mkdir -p "$DOCS"
mkdir -p "$ROOT/src/maurimesh/two-phone-hotspot-proof"

if [ ! -f "$ROOT/package.json" ]; then
  echo "ERROR: package.json missing. Run from /home/runner/workspace."
  exit 1
fi

cd "$ROOT"

cat > "$ROOT/src/maurimesh/two-phone-hotspot-proof/twoPhoneHotspotProof.ts" <<TS
export type TwoPhoneHotspotStage =
  | "PHONE_A_HOTSPOT_ON"
  | "PHONE_A_GATEWAY_READY"
  | "PHONE_B_CONNECTED_TO_PHONE_A_HOTSPOT"
  | "PHONE_B_TX_PACKET_START"
  | "PHONE_A_GATEWAY_RX_FROM_B"
  | "PHONE_A_GATEWAY_FORWARD_ATTEMPT"
  | "PHONE_A_GATEWAY_FORWARD_SUCCESS"
  | "PHONE_A_GATEWAY_ACK_TO_B"
  | "PHONE_B_ACK_RECEIVED";

export type TwoPhoneHotspotProofEvent = {
  proofId: string;
  packetId: string;
  routeId: string;
  phoneRole: "PHONE_A_GATEWAY" | "PHONE_B_CLIENT";
  stage: TwoPhoneHotspotStage;
  timestamp: string;
  detail: string;
};

export const twoPhoneHotspotProofTemplate = {
  proofId: "$PROOF_ID",
  packetId: "$PACKET_ID",
  routeId: "$ROUTE_ID",
  path: ["PHONE_B_CLIENT", "PHONE_A_HOTSPOT_GATEWAY", "INTERNET_OR_API"],
  requiredStages: [
    "PHONE_A_HOTSPOT_ON",
    "PHONE_A_GATEWAY_READY",
    "PHONE_B_CONNECTED_TO_PHONE_A_HOTSPOT",
    "PHONE_B_TX_PACKET_START",
    "PHONE_A_GATEWAY_RX_FROM_B",
    "PHONE_A_GATEWAY_FORWARD_ATTEMPT",
    "PHONE_A_GATEWAY_FORWARD_SUCCESS",
    "PHONE_A_GATEWAY_ACK_TO_B",
    "PHONE_B_ACK_RECEIVED",
  ] as TwoPhoneHotspotStage[],
};

export function formatTwoPhoneHotspotProofLine(event: TwoPhoneHotspotProofEvent) {
  return [
    "[MauriMeshHotspotProof]",
    \`proofId=\${event.proofId}\`,
    \`packetId=\${event.packetId}\`,
    \`routeId=\${event.routeId}\`,
    \`phoneRole=\${event.phoneRole}\`,
    \`stage=\${event.stage}\`,
    \`timestamp=\${event.timestamp}\`,
    \`detail=\${event.detail}\`,
  ].join(" ");
}
TS

cat > "$ROOT/app/two-phone-hotspot-proof.tsx" <<TSX
import React from "react";
import { ScrollView, StyleSheet, Text, View } from "react-native";

const proof = {
  proofId: "$PROOF_ID",
  packetId: "$PACKET_ID",
  routeId: "$ROUTE_ID",
  path: "PHONE_B_CLIENT -> PHONE_A_HOTSPOT_GATEWAY -> INTERNET_OR_API",
  requiredStages: [
    "PHONE_A_HOTSPOT_ON",
    "PHONE_A_GATEWAY_READY",
    "PHONE_B_CONNECTED_TO_PHONE_A_HOTSPOT",
    "PHONE_B_TX_PACKET_START",
    "PHONE_A_GATEWAY_RX_FROM_B",
    "PHONE_A_GATEWAY_FORWARD_ATTEMPT",
    "PHONE_A_GATEWAY_FORWARD_SUCCESS",
    "PHONE_A_GATEWAY_ACK_TO_B",
    "PHONE_B_ACK_RECEIVED",
  ],
};

export default function TwoPhoneHotspotProofScreen() {
  return (
    <ScrollView style={styles.root} contentContainerStyle={styles.content}>
      <View style={styles.hero}>
        <Text style={styles.kicker}>MAURIMESH TWO-PHONE HOTSPOT PROOF</Text>
        <Text style={styles.title}>PHONE B → PHONE A Hotspot Gateway</Text>
        <Text style={styles.text}>
          This proof is for two phones only. PHONE A shares hotspot/internet. PHONE B connects to
          PHONE A hotspot and sends through the gateway path. This does not claim 3-hop BLE relay.
        </Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.label}>proofId</Text>
        <Text style={styles.value}>{proof.proofId}</Text>

        <Text style={styles.label}>packetId</Text>
        <Text style={styles.value}>{proof.packetId}</Text>

        <Text style={styles.label}>routeId</Text>
        <Text style={styles.value}>{proof.routeId}</Text>

        <Text style={styles.label}>path</Text>
        <Text style={styles.value}>{proof.path}</Text>
      </View>

      <Text style={styles.section}>Required Proof Stages</Text>

      {proof.requiredStages.map((stage, index) => (
        <View key={stage} style={styles.row}>
          <Text style={styles.no}>{index + 1}</Text>
          <Text style={styles.stage}>{stage}</Text>
        </View>
      ))}

      <View style={styles.truth}>
        <Text style={styles.truthTitle}>TRUTH GATE</Text>
        <Text style={styles.text}>
          PASS only when PHONE A and PHONE B logs show the same proofId, packetId, routeId,
          gateway receive, gateway forward, and ACK back to PHONE B. Without those logs, status remains NOT_PROVEN.
        </Text>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: "#020403" },
  content: { padding: 18, paddingBottom: 48 },
  hero: {
    borderWidth: 1,
    borderColor: "rgba(34,197,94,0.35)",
    backgroundColor: "rgba(2,12,8,0.9)",
    borderRadius: 24,
    padding: 18,
    marginBottom: 14,
  },
  kicker: { color: "#00D084", fontWeight: "900", letterSpacing: 1, fontSize: 12 },
  title: { color: "#FFFFFF", fontSize: 28, lineHeight: 34, fontWeight: "900", marginTop: 6 },
  text: { color: "rgba(255,255,255,0.74)", lineHeight: 21, marginTop: 6 },
  card: {
    borderWidth: 1,
    borderColor: "rgba(34,197,94,0.24)",
    backgroundColor: "rgba(255,255,255,0.05)",
    borderRadius: 20,
    padding: 14,
    marginBottom: 16,
  },
  label: { color: "#00D084", fontWeight: "900", marginTop: 8 },
  value: { color: "#FFFFFF", fontWeight: "800", marginTop: 3 },
  section: { color: "#FFFFFF", fontSize: 22, fontWeight: "900", marginTop: 18, marginBottom: 10 },
  row: {
    flexDirection: "row",
    gap: 10,
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.12)",
    borderRadius: 16,
    padding: 12,
    marginBottom: 8,
  },
  no: { color: "#00D084", fontWeight: "900", width: 24 },
  stage: { color: "#FFFFFF", fontWeight: "800", flex: 1 },
  truth: {
    borderWidth: 1,
    borderColor: "rgba(245,158,11,0.55)",
    backgroundColor: "rgba(245,158,11,0.1)",
    borderRadius: 22,
    padding: 15,
    marginTop: 18,
  },
  truthTitle: { color: "#F59E0B", fontWeight: "900" },
});
TSX

cat > "$REPORT" <<MD
# MauriMesh Two-Phone Hotspot Gateway Proof

Generated: $STAMP

## Proof Identity

- proofId: $PROOF_ID
- packetId: $PACKET_ID
- routeId: $ROUTE_ID
- path: PHONE_B_CLIENT -> PHONE_A_HOTSPOT_GATEWAY -> INTERNET_OR_API

## Phone Roles

### PHONE A
Role: hotspot/gateway

Required:
- Mobile data ON or internet available
- Hotspot ON
- MauriMesh APK open
- Open /two-phone-hotspot-proof
- Open /mauricore-ble-runtime or /route-lab if available

Expected stages:
\`\`\`txt
PHONE_A_HOTSPOT_ON
PHONE_A_GATEWAY_READY
PHONE_A_GATEWAY_RX_FROM_B
PHONE_A_GATEWAY_FORWARD_ATTEMPT
PHONE_A_GATEWAY_FORWARD_SUCCESS
PHONE_A_GATEWAY_ACK_TO_B
\`\`\`

### PHONE B
Role: client/sender

Required:
- Connect Wi-Fi to PHONE A hotspot
- MauriMesh APK open
- Open /two-phone-hotspot-proof
- Send proof packet

Expected stages:
\`\`\`txt
PHONE_B_CONNECTED_TO_PHONE_A_HOTSPOT
PHONE_B_TX_PACKET_START
PHONE_B_ACK_RECEIVED
\`\`\`

## PASS Rule

PASS only when logs show all required stages with the same:

- proofId: $PROOF_ID
- packetId: $PACKET_ID
- routeId: $ROUTE_ID

## Not 3-Hop

This is a two-phone gateway proof, not a three-hop BLE relay proof.
MD

cat > "$DOCS/maurimesh-two-phone-hotspot-required-patterns-$STAMP.txt" <<TXT
MauriMeshHotspotProof
$PROOF_ID
$PACKET_ID
$ROUTE_ID
PHONE_A_HOTSPOT_ON
PHONE_A_GATEWAY_READY
PHONE_B_CONNECTED_TO_PHONE_A_HOTSPOT
PHONE_B_TX_PACKET_START
PHONE_A_GATEWAY_RX_FROM_B
PHONE_A_GATEWAY_FORWARD_ATTEMPT
PHONE_A_GATEWAY_FORWARD_SUCCESS
PHONE_A_GATEWAY_ACK_TO_B
PHONE_B_ACK_RECEIVED
TXT

cp "$REPORT" "$LATEST"
cp "$DOCS/maurimesh-two-phone-hotspot-required-patterns-$STAMP.txt" "$DOCS/maurimesh-two-phone-hotspot-required-patterns-latest.txt"

echo ""
echo "============================================================"
echo "VERIFY"
echo "============================================================"
echo "Created: app/two-phone-hotspot-proof.tsx"
echo "Created: src/maurimesh/two-phone-hotspot-proof/twoPhoneHotspotProof.ts"
echo "Report:  $LATEST"
echo ""
grep -RIn "two-phone-hotspot-proof\|MauriMeshHotspotProof\|PHONE_A_HOTSPOT_ON" app src docs 2>/dev/null || true

echo ""
echo "============================================================"
echo "TYPE CHECK"
echo "============================================================"
if command -v pnpm >/dev/null 2>&1 && [ -f pnpm-lock.yaml ]; then
  pnpm exec tsc --noEmit || true
elif command -v npm >/dev/null 2>&1; then
  npx tsc --noEmit || true
fi

echo ""
echo "============================================================"
echo "EXPORT CHECK"
echo "============================================================"
npx expo export --platform android --output-dir ".maurimesh-two-phone-hotspot-export-$STAMP" || true

echo ""
echo "============================================================"
echo "DONE"
echo "Open route in APK after rebuild:"
echo "/two-phone-hotspot-proof"
echo ""
echo "Build command:"
echo "npx eas-cli build --platform android --profile preview-apk --clear-cache --non-interactive"
echo "============================================================"
