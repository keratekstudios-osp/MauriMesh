#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "FIX JUMPCODE MĀORI PROTOCOL PANEL"
echo "Adds MaoriProtocolPanel directly to /jumpcode-proof route."
echo "============================================================"
echo ""

ROOT="$(pwd)"
ROUTE="$ROOT/app/jumpcode-proof.tsx"
BACKUP="$ROOT/backup-before-jumpcode-maori-panel-fix-$(date +%Y%m%d-%H%M%S)"

mkdir -p "$BACKUP"

if [ ! -f "$ROUTE" ]; then
  echo "ERROR: Missing app/jumpcode-proof.tsx"
  exit 1
fi

cp "$ROUTE" "$BACKUP/jumpcode-proof.tsx"

cat > "$ROUTE" <<'TSX'
import React from "react";
import { ScrollView, StyleSheet, View } from "react-native";
import { JumpCodeProofPanel } from "../src/components/JumpCodeProofPanel";
import { MaoriProtocolPanel } from "../src/components/MaoriProtocolPanel";

export default function JumpCodeProofScreen() {
  return (
    <ScrollView style={styles.root} contentContainerStyle={styles.content}>
      <MaoriProtocolPanel screen="JumpCode Proof" compact />
      <View style={styles.panelWrap}>
        <JumpCodeProofPanel />
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
    backgroundColor: "#020403",
  },
  content: {
    padding: 0,
    paddingBottom: 24,
  },
  panelWrap: {
    flex: 1,
  },
});
TSX

echo ""
echo "Running TypeScript..."
npx tsc --noEmit

echo ""
echo "Running Māori protocol fallback checker..."
./check-maurimesh-maori-protocol-fallback.sh

echo ""
echo "============================================================"
echo "DONE: JUMPCODE MĀORI PROTOCOL PANEL FIXED"
echo "Backup:"
echo "  $BACKUP"
echo ""
echo "Latest report:"
echo "  docs/maurimesh-maori-protocol-fallback-report-latest.md"
echo "============================================================"
