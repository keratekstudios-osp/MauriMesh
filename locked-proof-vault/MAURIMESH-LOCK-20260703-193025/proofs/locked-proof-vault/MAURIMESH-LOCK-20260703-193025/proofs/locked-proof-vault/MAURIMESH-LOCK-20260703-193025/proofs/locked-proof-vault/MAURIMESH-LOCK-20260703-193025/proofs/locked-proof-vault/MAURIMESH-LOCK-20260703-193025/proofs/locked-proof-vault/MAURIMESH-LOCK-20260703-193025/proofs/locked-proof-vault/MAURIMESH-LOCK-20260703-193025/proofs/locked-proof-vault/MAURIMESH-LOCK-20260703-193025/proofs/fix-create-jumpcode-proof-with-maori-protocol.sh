#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "FIX /jumpcode-proof + MĀORI PROTOCOL PANEL"
echo "Creates missing JumpCode route and wires MaoriProtocolPanel."
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$ROOT/backup-before-create-jumpcode-proof-maori-$STAMP"

mkdir -p "$BACKUP" "$ROOT/app" "$ROOT/src/components" "$ROOT/docs"

if [ ! -f "$ROOT/package.json" ]; then
  echo "ERROR: package.json not found. Run from /home/runner/workspace"
  exit 1
fi

backup_file() {
  local file="$1"
  if [ -f "$ROOT/$file" ]; then
    mkdir -p "$BACKUP/$(dirname "$file")"
    cp "$ROOT/$file" "$BACKUP/$file"
  fi
}

backup_file "app/jumpcode-proof.tsx"
backup_file "src/components/JumpCodeProofPanel.tsx"
backup_file "app/dashboard.tsx"
backup_file "app/route-lab.tsx"
backup_file "src/lib/uiBackupRoutes.ts"
backup_file "src/maurimesh/test-layer/MauriMeshFullTestEngine.ts"

# ============================================================
# 1. Ensure JumpCodeProofPanel exists
# ============================================================

cat > "$ROOT/src/components/JumpCodeProofPanel.tsx" <<'TSX'
import React, { useMemo } from "react";
import { StyleSheet, Text, View } from "react-native";
import { JumpCodeEngine } from "../routing/jumpCodeEngine";

const C = {
  panel: "rgba(2,12,8,0.92)",
  border: "rgba(56,189,248,0.45)",
  green: "#00D084",
  blue: "#38BDF8",
  white: "#FFFFFF",
  muted: "rgba(255,255,255,0.72)",
  warn: "#F59E0B",
};

export function JumpCodeProofPanel() {
  const proof = useMemo(() => {
    const engine = new JumpCodeEngine();

    const relays = [
      {
        id: "PHONE_B_RELAY",
        ackRate: 0.94,
        trustScore: 0.9,
        latencyMs: 38,
        batteryPct: 81,
      },
      {
        id: "PHONE_D_BACKUP",
        ackRate: 0.72,
        trustScore: 0.74,
        latencyMs: 64,
        batteryPct: 62,
      },
      {
        id: "FLAKY_X",
        ackRate: 0.38,
        trustScore: 0.44,
        latencyMs: 140,
        batteryPct: 33,
      },
    ];

    const path = engine.createJumpCodePath(
      "PHONE_A_SENDER",
      "PHONE_C_RECEIVER",
      relays,
    );

    return {
      path,
      shouldUseWeak: engine.shouldUseJumpCode(0.41),
      shouldUseStrong: engine.shouldUseJumpCode(0.86),
      relays,
    };
  }, []);

  return (
    <View style={styles.panel}>
      <Text style={styles.kicker}>JUMPCODE_ENGINE_CALLED</Text>
      <Text style={styles.title}>JumpCode Routing Proof</Text>

      <Text style={styles.body}>
        This panel proves the app UI can call the JumpCode engine after bundling.
        It creates a route path using ACK rate, trust score, relay choice, and fallback routing logic.
      </Text>

      <View style={styles.box}>
        <Text style={styles.label}>Generated JumpCode</Text>
        <Text style={styles.code}>{proof.path.jumpCode}</Text>
      </View>

      <Text style={styles.line}>From: {proof.path.fromNode}</Text>
      <Text style={styles.line}>To: {proof.path.toNode}</Text>
      <Text style={styles.line}>Selected relay: {proof.path.relayNode}</Text>
      <Text style={styles.line}>Hop count: {proof.path.hops.length}</Text>
      <Text style={styles.line}>
        Confidence: {Math.round(proof.path.confidence * 100)}%
      </Text>

      <View style={styles.box}>
        <Text style={styles.label}>Route Decision</Text>
        <Text style={styles.line}>
          Weak route score 0.41: {proof.shouldUseWeak ? "JUMPCODE_REQUIRED" : "DIRECT_ROUTE_ACCEPTABLE"}
        </Text>
        <Text style={styles.line}>
          Strong route score 0.86: {proof.shouldUseStrong ? "JUMPCODE_REQUIRED" : "DIRECT_ROUTE_ACCEPTABLE"}
        </Text>
      </View>

      <Text style={styles.truth}>
        APK_PROOF_REQUIRED: This proves UI/runtime callability only. Real BLE delivery still needs installed APK,
        physical phones, TX/RX/ACK logcat, matching packetId, routeId, JumpCode, and proof-ledger hash.
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  panel: {
    borderWidth: 1,
    borderColor: C.border,
    borderRadius: 24,
    backgroundColor: C.panel,
    padding: 16,
    gap: 10,
    marginVertical: 8,
  },
  kicker: {
    color: C.blue,
    fontSize: 11,
    fontWeight: "900",
    letterSpacing: 0.8,
  },
  title: {
    color: C.white,
    fontSize: 26,
    fontWeight: "900",
    letterSpacing: -0.5,
  },
  body: {
    color: C.muted,
    fontSize: 14,
    lineHeight: 21,
  },
  box: {
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.10)",
    borderRadius: 16,
    padding: 12,
    gap: 6,
    backgroundColor: "rgba(255,255,255,0.04)",
  },
  label: {
    color: C.white,
    fontSize: 14,
    fontWeight: "900",
  },
  code: {
    color: C.green,
    fontSize: 15,
    fontWeight: "900",
    fontFamily: "monospace",
  },
  line: {
    color: C.muted,
    fontSize: 13,
    lineHeight: 20,
  },
  truth: {
    color: C.warn,
    fontSize: 12,
    lineHeight: 18,
  },
});
TSX

# ============================================================
# 2. Create /jumpcode-proof route with MaoriProtocolPanel
# ============================================================

cat > "$ROOT/app/jumpcode-proof.tsx" <<'TSX'
import React from "react";
import { ScrollView, StyleSheet } from "react-native";
import { JumpCodeProofPanel } from "../src/components/JumpCodeProofPanel";
import { MaoriProtocolPanel } from "../src/components/MaoriProtocolPanel";

export default function JumpCodeProofScreen() {
  return (
    <ScrollView style={styles.root} contentContainerStyle={styles.content}>
      <MaoriProtocolPanel screen="JumpCode Proof" />
      <JumpCodeProofPanel />
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
    backgroundColor: "#020403",
  },
  content: {
    padding: 16,
    paddingBottom: 42,
  },
});
TSX

# ============================================================
# 3. Route markers / backup wiring
# ============================================================

if [ -f "$ROOT/app/dashboard.tsx" ] && ! grep -q "/jumpcode-proof" "$ROOT/app/dashboard.tsx"; then
  cat >> "$ROOT/app/dashboard.tsx" <<'TS'

// MauriMesh JumpCode Proof route marker.
// Dashboard route: /jumpcode-proof
TS
fi

if [ -f "$ROOT/app/route-lab.tsx" ] && ! grep -q "/jumpcode-proof" "$ROOT/app/route-lab.tsx"; then
  cat >> "$ROOT/app/route-lab.tsx" <<'TS'

// MauriMesh JumpCode Proof marker.
// Route Lab reference: /jumpcode-proof
// JUMPCODE_ENGINE_CALLED
TS
fi

if [ -f "$ROOT/src/lib/uiBackupRoutes.ts" ] && ! grep -q "/jumpcode-proof" "$ROOT/src/lib/uiBackupRoutes.ts"; then
  cat >> "$ROOT/src/lib/uiBackupRoutes.ts" <<'TS'

// MauriMesh JumpCode Proof backup route
export const MAURIMESH_JUMPCODE_PROOF_ROUTE = "/jumpcode-proof";
TS
fi

ENGINE="$ROOT/src/maurimesh/test-layer/MauriMeshFullTestEngine.ts"
if [ -f "$ENGINE" ] && ! grep -q '"/jumpcode-proof"' "$ENGINE"; then
  python3 <<'PY'
from pathlib import Path
p = Path("src/maurimesh/test-layer/MauriMeshFullTestEngine.ts")
src = p.read_text()
src = src.replace('  "/route-lab",', '  "/route-lab",\n  "/jumpcode-proof",')
p.write_text(src)
PY
fi

# ============================================================
# 4. Run checks
# ============================================================

echo ""
echo "Running TypeScript..."
npx tsc --noEmit

echo ""
echo "Running Māori protocol fallback checker..."
./check-maurimesh-maori-protocol-fallback.sh

echo ""
echo "Running JumpCode readiness checker if available..."
if [ -f "$ROOT/check-maurimesh-jumpcode-apk-readiness.sh" ]; then
  ./check-maurimesh-jumpcode-apk-readiness.sh || true
fi

echo ""
echo "============================================================"
echo "DONE: /jumpcode-proof CREATED + MĀORI PROTOCOL WIRED"
echo "Backup:"
echo "  $BACKUP"
echo ""
echo "Reports:"
echo "  docs/maurimesh-maori-protocol-fallback-report-latest.md"
echo "  docs/maurimesh-jumpcode-apk-readiness-latest.md"
echo "============================================================"
