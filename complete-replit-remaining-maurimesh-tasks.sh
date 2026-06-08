#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH REPLIT REMAINING TASK COMPLETION"
echo "Adds final Replit completion gate + audit + proof links"
echo "Does NOT fake physical BLE proof"
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$HOME/maurimesh-router-backups/replit-final-completion-$STAMP"

mkdir -p "$BACKUP" \
  "$ROOT/docs" \
  "$ROOT/scripts" \
  "$ROOT/src/maurimesh/replit" \
  "$ROOT/app"

echo ""
echo "1. Backup key files"

for f in \
  "$ROOT/app/dashboard.tsx" \
  "$ROOT/app/index.tsx" \
  "$ROOT/app/_layout.tsx" \
  "$ROOT/src/maurimesh/replit/completionRegistry.ts" \
  "$ROOT/app/replit-completion-gate.tsx"
do
  if [ -f "$f" ]; then
    cp "$f" "$BACKUP/$(basename "$f").bak"
  fi
done

echo "Backup: $BACKUP"

echo ""
echo "2. Create Replit completion registry"

cat > "$ROOT/src/maurimesh/replit/completionRegistry.ts" <<'TS'
export const REPLIT_COMPLETION_GATE_MARKER =
  "MAURIMESH_REPLIT_COMPLETION_GATE_20260608_A";

export type CompletionTruth =
  | "complete_in_replit"
  | "installed_needs_apk"
  | "physical_proof_required"
  | "missing_or_unverified";

export type MauriMeshCompletionItem = {
  id: string;
  title: string;
  truth: CompletionTruth;
  evidence: string[];
  next: string;
};

export const mauriMeshCompletionItems: MauriMeshCompletionItem[] = [
  {
    id: "#56",
    title: "Real BLE scan data spine",
    truth: "complete_in_replit",
    evidence: [
      "Native BLE scan bridge exists",
      "Live Mesh Ops screen exists",
      "Scan proof previously showed SCAN ACTIVE and discovered devices",
    ],
    next: "Use physical phone to continue scan proof when needed.",
  },
  {
    id: "#61/#64",
    title: "Persistent mesh node registry foundation",
    truth: "complete_in_replit",
    evidence: [
      "Live mesh registry/store files installed",
      "Node count persisted into Live Mesh Ops",
    ],
    next: "Upgrade persistence backend later if SQLite/native DB is required.",
  },
  {
    id: "Route Safety Persistence",
    title: "Route blacklist survives restart",
    truth: "complete_in_replit",
    evidence: [
      "Restart proof passed",
      "Blacklist remained blocked after new engine instance",
      "Seen packet duplicate cache remained memory-only",
    ],
    next: "No Replit work remaining for this task.",
  },
  {
    id: "#165",
    title: "Central-side raw packet transport",
    truth: "installed_needs_apk",
    evidence: [
      "MeshCentralClient.kt installed",
      "sendRawPacket installed",
      "broadcastRawPacket installed",
      "WRITE_TYPE_NO_RESPONSE path installed",
      "Expo export passed",
    ],
    next: "Build APK and prove write path on two phones.",
  },
  {
    id: "#165B",
    title: "Receiver GATT server and ACK proof layer",
    truth: "installed_needs_apk",
    evidence: [
      "MeshRawPacketGattServer.kt installed",
      "Writable raw packet characteristic installed",
      "startRawPacketReceiver bridge installed",
      "ACK return attempt installed",
      "Raw Packet Proof screen installed",
      "Expo export passed",
    ],
    next: "Build APK, install on two phones, run /raw-packet-proof, capture RX_RAW_PACKET and ACK_SENT logs.",
  },
  {
    id: "#191",
    title: "BLE/relay failure paths to RuntimeErrorLedger",
    truth: "missing_or_unverified",
    evidence: [
      "Needs audit before marking installed",
    ],
    next: "Run final audit. If files are missing, install RuntimeErrorLedger wiring next.",
  },
  {
    id: "#223",
    title: "Auto promote proof scope after real native BLE detection",
    truth: "missing_or_unverified",
    evidence: [
      "Needs audit before marking installed",
    ],
    next: "Run final audit. If files are missing, install native attestation proof-scope route next.",
  },
  {
    id: "#182",
    title: "Keep MauriMesh alive when screen locks",
    truth: "physical_proof_required",
    evidence: [
      "Foreground/background survival cannot be proven in Replit",
    ],
    next: "Requires APK, phone lock test, and heartbeat proof.",
  },
  {
    id: "Relay Complete",
    title: "Raw packet relay completion",
    truth: "physical_proof_required",
    evidence: [
      "Needs Phone A -> Phone B -> Phone C relay logs",
      "Needs ACK chain proof",
    ],
    next: "After #165B two-phone proof, add three-phone relay proof.",
  },
];

export function getCompletionSummary() {
  const total = mauriMeshCompletionItems.length;
  const completeInReplit = mauriMeshCompletionItems.filter(
    (item) => item.truth === "complete_in_replit"
  ).length;
  const installedNeedsApk = mauriMeshCompletionItems.filter(
    (item) => item.truth === "installed_needs_apk"
  ).length;
  const physicalProofRequired = mauriMeshCompletionItems.filter(
    (item) => item.truth === "physical_proof_required"
  ).length;
  const missingOrUnverified = mauriMeshCompletionItems.filter(
    (item) => item.truth === "missing_or_unverified"
  ).length;

  return {
    marker: REPLIT_COMPLETION_GATE_MARKER,
    total,
    completeInReplit,
    installedNeedsApk,
    physicalProofRequired,
    missingOrUnverified,
  };
}
TS

echo ""
echo "3. Create Replit Completion Gate screen"

cat > "$ROOT/app/replit-completion-gate.tsx" <<'TSX'
import React from "react";
import { Pressable, ScrollView, StyleSheet, Text, View } from "react-native";
import { useRouter } from "expo-router";
import {
  getCompletionSummary,
  mauriMeshCompletionItems,
  REPLIT_COMPLETION_GATE_MARKER,
} from "../src/maurimesh/replit/completionRegistry";

function toneColor(truth: string): string {
  if (truth === "complete_in_replit") return "#22C55E";
  if (truth === "installed_needs_apk") return "#38BDF8";
  if (truth === "physical_proof_required") return "#F59E0B";
  return "#EF4444";
}

export default function ReplitCompletionGateScreen() {
  const router = useRouter();
  const summary = getCompletionSummary();

  return (
    <ScrollView style={styles.root} contentContainerStyle={styles.content}>
      <Text style={styles.marker}>{REPLIT_COMPLETION_GATE_MARKER}</Text>
      <Text style={styles.title}>Replit Completion Gate</Text>
      <Text style={styles.body}>
        This screen separates Replit-complete work from APK and physical phone proof.
        It prevents fake completion while showing what is installed and ready.
      </Text>

      <View style={styles.summary}>
        <Text style={styles.summaryText}>Total: {summary.total}</Text>
        <Text style={styles.summaryText}>Complete in Replit: {summary.completeInReplit}</Text>
        <Text style={styles.summaryText}>Installed, needs APK: {summary.installedNeedsApk}</Text>
        <Text style={styles.summaryText}>Physical proof required: {summary.physicalProofRequired}</Text>
        <Text style={styles.summaryText}>Missing/unverified: {summary.missingOrUnverified}</Text>
      </View>

      <Pressable style={styles.button} onPress={() => router.push("/raw-packet-proof" as never)}>
        <Text style={styles.buttonText}>Open Raw Packet Proof</Text>
      </Pressable>

      <Pressable style={styles.button} onPress={() => router.push("/live-mesh-ops" as never)}>
        <Text style={styles.buttonText}>Open Live Mesh Ops</Text>
      </Pressable>

      {mauriMeshCompletionItems.map((item) => (
        <View key={item.id} style={styles.card}>
          <View style={styles.row}>
            <Text style={styles.id}>{item.id}</Text>
            <Text style={[styles.pill, { borderColor: toneColor(item.truth), color: toneColor(item.truth) }]}>
              {item.truth}
            </Text>
          </View>
          <Text style={styles.cardTitle}>{item.title}</Text>
          {item.evidence.map((line) => (
            <Text key={line} style={styles.evidence}>• {line}</Text>
          ))}
          <Text style={styles.next}>Next: {item.next}</Text>
        </View>
      ))}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: "#020403" },
  content: { padding: 18, gap: 14 },
  marker: { color: "#00D084", fontSize: 11, fontWeight: "900" },
  title: { color: "#FFFFFF", fontSize: 32, fontWeight: "900" },
  body: { color: "rgba(255,255,255,0.74)", lineHeight: 21 },
  summary: {
    borderWidth: 1,
    borderColor: "rgba(0,208,132,0.35)",
    backgroundColor: "rgba(255,255,255,0.06)",
    borderRadius: 18,
    padding: 14,
    gap: 6,
  },
  summaryText: { color: "#D1FAE5", fontWeight: "800" },
  button: {
    minHeight: 52,
    borderRadius: 16,
    backgroundColor: "#00D084",
    alignItems: "center",
    justifyContent: "center",
    paddingHorizontal: 14,
  },
  buttonText: { color: "#FFFFFF", fontWeight: "900" },
  card: {
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.12)",
    backgroundColor: "rgba(255,255,255,0.055)",
    borderRadius: 18,
    padding: 14,
    gap: 8,
  },
  row: { flexDirection: "row", justifyContent: "space-between", gap: 10, alignItems: "center" },
  id: { color: "#FFFFFF", fontWeight: "900", fontSize: 15 },
  pill: {
    borderWidth: 1,
    borderRadius: 999,
    paddingHorizontal: 10,
    paddingVertical: 4,
    fontSize: 10,
    fontWeight: "900",
    overflow: "hidden",
  },
  cardTitle: { color: "#FFFFFF", fontSize: 18, fontWeight: "900" },
  evidence: { color: "rgba(255,255,255,0.74)", lineHeight: 19 },
  next: { color: "#FDE68A", lineHeight: 20, fontWeight: "700" },
});
TSX

echo ""
echo "4. Patch dashboard with Completion Gate + Raw Packet Proof buttons if possible"

if [ -f "$ROOT/app/dashboard.tsx" ]; then
python3 <<'PY'
from pathlib import Path

path = Path("app/dashboard.tsx")
text = path.read_text()
original = text

if '"/replit-completion-gate"' not in text:
    marker = '<MauriButton title="Settings" onPress={() => router.push("/settings")} />'
    insert = '''
        <MauriButton title="Completion Gate" onPress={() => router.push("/replit-completion-gate")} />
        <MauriButton title="Raw Packet Proof" onPress={() => router.push("/raw-packet-proof")} />'''
    if marker in text:
        text = text.replace(marker, insert + "\n        " + marker)
    else:
        # fallback: insert before last closing View in dashboard
        text = text.replace("</View>\n    </AppShell>", insert + "\n      </View>\n    </AppShell>", 1)

path.write_text(text)

print("Dashboard patched" if text != original else "Dashboard unchanged")
PY
else
  echo "WARN: app/dashboard.tsx not found. Completion screen still available at /replit-completion-gate"
fi

echo ""
echo "5. Create final Replit audit script"

cat > "$ROOT/scripts/maurimesh-replit-final-gate.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo "MAURIMESH REPLIT FINAL GATE"
echo "============================================================"

pass=0
warn=0
fail=0

check_file() {
  local file="$1"
  local label="$2"
  if [ -f "$file" ]; then
    echo "✅ $label: $file"
    pass=$((pass+1))
  else
    echo "❌ $label missing: $file"
    fail=$((fail+1))
  fi
}

check_marker() {
  local pattern="$1"
  local path="$2"
  local label="$3"
  if grep -RniE "$pattern" "$path" >/tmp/maurimesh_gate_grep.txt 2>/dev/null; then
    echo "✅ $label"
    cat /tmp/maurimesh_gate_grep.txt | head -20
    pass=$((pass+1))
  else
    echo "⚠️ $label not found"
    warn=$((warn+1))
  fi
  rm -f /tmp/maurimesh_gate_grep.txt
}

echo ""
echo "1. Core Replit completion files"
check_file "app/replit-completion-gate.tsx" "Completion Gate screen"
check_file "src/maurimesh/replit/completionRegistry.ts" "Completion registry"
check_file "app/raw-packet-proof.tsx" "Raw Packet Proof screen"

echo ""
echo "2. Native raw packet integration"
check_file "android/app/src/main/java/com/maurimesh/messenger/MeshCentralClient.kt" "MeshCentralClient"
check_file "android/app/src/main/java/com/maurimesh/messenger/MeshRawPacketGattServer.kt" "Raw Packet GATT server"
check_file "android/app/src/main/java/com/maurimesh/messenger/MeshRawPacketTypes.kt" "Raw packet UUID types"

check_marker "sendRawPacket|broadcastRawPacket|WRITE_TYPE_NO_RESPONSE" "android/app/src/main/java/com/maurimesh/messenger" "#165 central-side transport markers"
check_marker "startRawPacketReceiver|RX_RAW_PACKET|ACK_SENT|PROPERTY_WRITE_NO_RESPONSE" "android/app/src/main/java/com/maurimesh/messenger" "#165B receiver + ACK markers"
check_marker "TASK_165B_RAW_PACKET_PROOF_CLIENT|sendRawPacketUtf8" "src/maurimesh/ble" "#165B JS proof client"

echo ""
echo "3. Route safety persistence"
check_marker "ROUTE_SAFETY_PERSISTENCE|routeSafetyBlacklist|route_safety_blacklist" "artifacts lib docs scripts" "Route safety persistence markers"
check_marker "ROUTE_SAFETY_RESTART_PROOF_20260608_A" "." "Route safety restart proof marker"

echo ""
echo "4. Live mesh / scan data spine"
check_marker "LIVE_MESH_OPS|useLiveMesh|nativeBleLiveSource|startScanProof" "app src" "Live mesh scan data markers"

echo ""
echo "5. RuntimeErrorLedger / proof scope / foreground service checks"
check_marker "RuntimeErrorLedger|recordRuntimeError|errors/record|TASK_191" "artifacts src app scripts docs" "#191 Runtime error ledger markers"
check_marker "runtime/verify|acceptNativeAttestation|TASK_223|proofScope" "artifacts src app scripts docs" "#223 native attestation proof-scope markers"
check_marker "ForegroundService|startForegroundMeshRuntime|TASK_182|foreground-runtime" "android src app scripts docs" "#182 foreground runtime markers"

echo ""
echo "6. TypeScript"
if npx tsc --noEmit; then
  echo "✅ TypeScript PASS"
  pass=$((pass+1))
else
  echo "❌ TypeScript FAIL"
  fail=$((fail+1))
fi

echo ""
echo "7. Expo export"
rm -rf dist .expo
if npx expo export --platform android --clear; then
  echo "✅ Expo export PASS"
  pass=$((pass+1))
else
  echo "❌ Expo export FAIL"
  fail=$((fail+1))
fi

echo ""
echo "============================================================"
echo "FINAL GATE RESULT"
echo "PASS: $pass"
echo "WARN: $warn"
echo "FAIL: $fail"
echo ""
echo "Truth boundary:"
echo "- PASS means Replit code/export layer is ready."
echo "- WARN means task may be missing or not installed yet."
echo "- Physical BLE packet delivery still requires APK + two phones."
echo "============================================================"

if [ "$fail" -gt 0 ]; then
  exit 1
fi
SH

chmod +x "$ROOT/scripts/maurimesh-replit-final-gate.sh"

echo ""
echo "6. Create final status document"

cat > "$ROOT/docs/maurimesh-replit-final-completion-status.md" <<'MD'
# MauriMesh Replit Final Completion Status

Marker: `MAURIMESH_REPLIT_COMPLETION_GATE_20260608_A`

## Replit-complete

- Route Safety Persistence
- Route Safety Restart Proof
- Live BLE scan data spine foundation
- Persistent mesh node registry foundation
- Completion Gate UI
- Raw Packet Proof UI
- #165 central-side raw packet transport code
- #165B receiver GATT server and ACK code path

## Installed but needs APK

- `MeshCentralClient.sendRawPacket`
- `MeshCentralClient.broadcastRawPacket`
- Native raw packet GATT receiver
- Raw packet characteristic
- ACK return attempt
- `/raw-packet-proof` screen

## Cannot be completed inside Replit

- Physical packet received on second phone
- ACK received back on first phone
- Relay completed across three phones
- Foreground service screen-lock survival proof
- BLE radio behavior under real Android background limits

## Final audit command

```bash
bash scripts/maurimesh-replit-final-gate.sh
