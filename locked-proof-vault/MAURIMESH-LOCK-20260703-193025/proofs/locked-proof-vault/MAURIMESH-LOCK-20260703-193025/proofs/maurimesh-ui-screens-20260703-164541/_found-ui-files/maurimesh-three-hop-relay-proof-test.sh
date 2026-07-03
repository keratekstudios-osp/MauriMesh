#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH THREE-HOP BLE RELAY PROOF TEST"
echo "Proof path: PHONE_A -> PHONE_B -> PHONE_C -> ACK back to A"
echo "============================================================"
echo ""

ROOT="/home/runner/workspace"
STAMP="$(date +%Y%m%d-%H%M%S)"
DOCS="$ROOT/docs"
REPORT="$DOCS/maurimesh-three-hop-relay-proof-$STAMP.md"
LATEST="$DOCS/maurimesh-three-hop-relay-proof-latest.md"
PROOF_ID="MM-3HOP-$STAMP"
PACKET_ID="pkt3hop-$STAMP"
ROUTE_ID="route-A-B-C-$STAMP"

mkdir -p "$DOCS"

if [ ! -f "$ROOT/package.json" ]; then
  echo "ERROR: package.json not found. Run from /home/runner/workspace."
  exit 1
fi

cd "$ROOT"

cat > "$REPORT" <<MD
# MauriMesh Three-Hop BLE Relay Proof Test

Generated: $STAMP

## Proof Identity

- proofId: $PROOF_ID
- packetId: $PACKET_ID
- routeId: $ROUTE_ID
- path: PHONE_A -> PHONE_B -> PHONE_C
- ack path: PHONE_C -> PHONE_B -> PHONE_A

## Required Evidence

A real 3-hop proof requires all of these exact stages:

1. PHONE_A_TX_BLE_START
2. PHONE_B_RX_BLE_FROM_A
3. PHONE_B_RELAY_TX_TO_C
4. PHONE_C_RX_BLE_FROM_B
5. PHONE_C_STRICT_ACK_SENT
6. PHONE_B_RELAY_ACK_FROM_C
7. PHONE_A_STRICT_OR_RELAY_ACK_RECEIVED

The same packetId and routeId must appear across all phones.

MD

echo "Proof report:"
echo "$REPORT"
echo ""

echo "============================================================"
echo "1. ROUTE CHECK"
echo "============================================================"

REQUIRED_ROUTES=(
  "app/mauricore-ble-runtime.tsx"
  "app/route-lab.tsx"
  "app/message-fallback.tsx"
  "app/proof-ledger.tsx"
  "app/full-mesh-test-report.tsx"
  "app/device-proof.tsx"
)

for f in "${REQUIRED_ROUTES[@]}"; do
  if [ -f "$f" ]; then
    echo "PASS: $f exists"
    echo "- [PASS] $f exists" >> "$REPORT"
  else
    echo "WARN: $f missing"
    echo "- [WARN] $f missing" >> "$REPORT"
  fi
done

echo ""
echo "============================================================"
echo "2. CREATE THREE-HOP TEST CARD"
echo "============================================================"

mkdir -p "$ROOT/src/maurimesh/three-hop-proof"

cat > "$ROOT/src/maurimesh/three-hop-proof/threeHopProof.ts" <<TS
export type ThreeHopStage =
  | "PHONE_A_TX_BLE_START"
  | "PHONE_B_RX_BLE_FROM_A"
  | "PHONE_B_RELAY_TX_TO_C"
  | "PHONE_C_RX_BLE_FROM_B"
  | "PHONE_C_STRICT_ACK_SENT"
  | "PHONE_B_RELAY_ACK_FROM_C"
  | "PHONE_A_STRICT_OR_RELAY_ACK_RECEIVED";

export type ThreeHopProofEvent = {
  proofId: string;
  packetId: string;
  routeId: string;
  phoneRole: "PHONE_A" | "PHONE_B" | "PHONE_C";
  stage: ThreeHopStage;
  timestamp: string;
  detail: string;
};

export const threeHopProofTemplate = {
  proofId: "$PROOF_ID",
  packetId: "$PACKET_ID",
  routeId: "$ROUTE_ID",
  path: ["PHONE_A", "PHONE_B", "PHONE_C"],
  ackPath: ["PHONE_C", "PHONE_B", "PHONE_A"],
  requiredStages: [
    "PHONE_A_TX_BLE_START",
    "PHONE_B_RX_BLE_FROM_A",
    "PHONE_B_RELAY_TX_TO_C",
    "PHONE_C_RX_BLE_FROM_B",
    "PHONE_C_STRICT_ACK_SENT",
    "PHONE_B_RELAY_ACK_FROM_C",
    "PHONE_A_STRICT_OR_RELAY_ACK_RECEIVED",
  ] as ThreeHopStage[],
};

export function formatThreeHopProofLine(event: ThreeHopProofEvent) {
  return [
    "[MauriMesh3HopProof]",
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

echo "Created: src/maurimesh/three-hop-proof/threeHopProof.ts"
echo "- [PASS] Created three-hop proof template source file" >> "$REPORT"

echo ""
echo "============================================================"
echo "3. OPTIONAL UI ROUTE: /three-hop-relay-proof"
echo "============================================================"

cat > "$ROOT/app/three-hop-relay-proof.tsx" <<TSX
import React from "react";
import { ScrollView, StyleSheet, Text, View } from "react-native";

const proof = {
  proofId: "$PROOF_ID",
  packetId: "$PACKET_ID",
  routeId: "$ROUTE_ID",
  path: "PHONE_A -> PHONE_B -> PHONE_C",
  ackPath: "PHONE_C -> PHONE_B -> PHONE_A",
  stages: [
    "PHONE_A_TX_BLE_START",
    "PHONE_B_RX_BLE_FROM_A",
    "PHONE_B_RELAY_TX_TO_C",
    "PHONE_C_RX_BLE_FROM_B",
    "PHONE_C_STRICT_ACK_SENT",
    "PHONE_B_RELAY_ACK_FROM_C",
    "PHONE_A_STRICT_OR_RELAY_ACK_RECEIVED",
  ],
};

export default function ThreeHopRelayProofScreen() {
  return (
    <ScrollView style={styles.root} contentContainerStyle={styles.content}>
      <View style={styles.hero}>
        <Text style={styles.kicker}>MAURIMESH THREE-HOP RELAY PROOF</Text>
        <Text style={styles.title}>A → B → C Strict ACK Test</Text>
        <Text style={styles.text}>
          This screen prepares the proof identifiers for a physical three-phone BLE relay test.
          It does not claim success until matching TX/RX/RELAY/ACK logs are captured from real devices.
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

        <Text style={styles.label}>ack path</Text>
        <Text style={styles.value}>{proof.ackPath}</Text>
      </View>

      <Text style={styles.section}>Required Log Stages</Text>

      {proof.stages.map((stage, index) => (
        <View key={stage} style={styles.row}>
          <Text style={styles.stageNo}>{index + 1}</Text>
          <Text style={styles.stage}>{stage}</Text>
        </View>
      ))}

      <View style={styles.truth}>
        <Text style={styles.truthTitle}>TRUTH GATE</Text>
        <Text style={styles.text}>
          PASS only when all seven stages appear with the same packetId and routeId.
          Missing relay or ACK evidence means NOT_PROVEN.
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
  title: { color: "#FFFFFF", fontSize: 30, lineHeight: 36, fontWeight: "900", marginTop: 6 },
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
  stageNo: { color: "#00D084", fontWeight: "900", width: 24 },
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

echo "Created: app/three-hop-relay-proof.tsx"
echo "- [PASS] Created /three-hop-relay-proof route" >> "$REPORT"

echo ""
echo "============================================================"
echo "4. WRITE OPERATOR INSTRUCTIONS"
echo "============================================================"

cat >> "$REPORT" <<MD

## Phone Setup

Use three phones:

### PHONE A — Sender
Open:
- /three-hop-relay-proof
- /mauricore-ble-runtime
- /route-lab

Action:
- Send packetId: $PACKET_ID
- routeId: $ROUTE_ID
- target path: PHONE_A -> PHONE_B -> PHONE_C

Expected log:
\`\`\`txt
[MauriMesh3HopProof] proofId=$PROOF_ID packetId=$PACKET_ID routeId=$ROUTE_ID phoneRole=PHONE_A stage=PHONE_A_TX_BLE_START
\`\`\`

### PHONE B — Relay
Open:
- /mauricore-ble-runtime
- /message-fallback
- /proof-ledger

Action:
- Receive from PHONE_A.
- Relay same packetId and routeId to PHONE_C.
- Return ACK from PHONE_C back to PHONE_A.

Expected logs:
\`\`\`txt
[MauriMesh3HopProof] proofId=$PROOF_ID packetId=$PACKET_ID routeId=$ROUTE_ID phoneRole=PHONE_B stage=PHONE_B_RX_BLE_FROM_A
[MauriMesh3HopProof] proofId=$PROOF_ID packetId=$PACKET_ID routeId=$ROUTE_ID phoneRole=PHONE_B stage=PHONE_B_RELAY_TX_TO_C
[MauriMesh3HopProof] proofId=$PROOF_ID packetId=$PACKET_ID routeId=$ROUTE_ID phoneRole=PHONE_B stage=PHONE_B_RELAY_ACK_FROM_C
\`\`\`

### PHONE C — Receiver
Open:
- /mauricore-ble-runtime
- /proof-ledger

Action:
- Receive packet from PHONE_B.
- Send strict ACK back through PHONE_B.

Expected logs:
\`\`\`txt
[MauriMesh3HopProof] proofId=$PROOF_ID packetId=$PACKET_ID routeId=$ROUTE_ID phoneRole=PHONE_C stage=PHONE_C_RX_BLE_FROM_B
[MauriMesh3HopProof] proofId=$PROOF_ID packetId=$PACKET_ID routeId=$ROUTE_ID phoneRole=PHONE_C stage=PHONE_C_STRICT_ACK_SENT
\`\`\`

### PHONE A Final ACK
Expected log:
\`\`\`txt
[MauriMesh3HopProof] proofId=$PROOF_ID packetId=$PACKET_ID routeId=$ROUTE_ID phoneRole=PHONE_A stage=PHONE_A_STRICT_OR_RELAY_ACK_RECEIVED
\`\`\`

## PASS Rule

PASS only when all seven required stages appear with:
- same proofId
- same packetId
- same routeId
- correct phone roles
- no fatal AndroidRuntime / ReactNativeJS fatal crash

MD

cat > "$DOCS/maurimesh-three-hop-required-patterns-$STAMP.txt" <<TXT
PHONE_A_TX_BLE_START
PHONE_B_RX_BLE_FROM_A
PHONE_B_RELAY_TX_TO_C
PHONE_C_RX_BLE_FROM_B
PHONE_C_STRICT_ACK_SENT
PHONE_B_RELAY_ACK_FROM_C
PHONE_A_STRICT_OR_RELAY_ACK_RECEIVED
$PROOF_ID
$PACKET_ID
$ROUTE_ID
TXT

cp "$DOCS/maurimesh-three-hop-required-patterns-$STAMP.txt" "$DOCS/maurimesh-three-hop-required-patterns-latest.txt"

echo "Proof ID:   $PROOF_ID"
echo "Packet ID:  $PACKET_ID"
echo "Route ID:   $ROUTE_ID"

echo ""
echo "============================================================"
echo "5. TYPE CHECK"
echo "============================================================"

if command -v pnpm >/dev/null 2>&1 && [ -f pnpm-lock.yaml ]; then
  pnpm exec tsc --noEmit || true
elif command -v npm >/dev/null 2>&1; then
  npx tsc --noEmit || true
else
  echo "WARN: npm/pnpm unavailable"
fi

echo ""
echo "============================================================"
echo "6. EXPORT CHECK"
echo "============================================================"

if [ -f app.json ] || [ -f app.config.js ] || [ -f app.config.ts ]; then
  npx expo export --platform android --output-dir ".maurimesh-three-hop-export-$STAMP" || true
else
  echo "WARN: Expo config not found"
fi

echo ""
echo "============================================================"
echo "7. GIT STATUS"
echo "============================================================"
git status --short || true

cp "$REPORT" "$LATEST"

echo ""
echo "============================================================"
echo "THREE-HOP RELAY PROOF TEST PREP COMPLETE"
echo "============================================================"
echo "Open route in APK:"
echo "/three-hop-relay-proof"
echo ""
echo "Proof report:"
echo "$LATEST"
echo ""
echo "Required patterns:"
echo "$DOCS/maurimesh-three-hop-required-patterns-latest.txt"
echo ""
echo "Next:"
echo "1. Rebuild APK."
echo "2. Install APK on 3 phones."
echo "3. Open /three-hop-relay-proof."
echo "4. Run Mac logcat capture for each phone."
echo "============================================================"
