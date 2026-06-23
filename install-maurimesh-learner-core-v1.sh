#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH LEARNER CORE v1 INSTALL"
echo "Evidence memory + proof classifier + trust scoring"
echo "============================================================"

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$ROOT/backup-before-maurimesh-learner-core-v1-$STAMP"

if [ ! -f "$ROOT/package.json" ]; then
  echo "ERROR: package.json not found. Run from project root."
  exit 1
fi

mkdir -p "$BACKUP" \
  "$ROOT/src/maurimesh/learner" \
  "$ROOT/src/maurimesh/learner/data" \
  "$ROOT/docs/learner" \
  "$ROOT/app"

for f in \
  app/dashboard.tsx \
  app/learner-core.tsx \
  src/maurimesh/learner/evidenceMemory.ts \
  src/maurimesh/learner/proofClassifier.ts \
  src/maurimesh/learner/decisionScoring.ts \
  src/maurimesh/learner/badDecisionLearner.ts \
  src/maurimesh/learner/recoveryPlanner.ts \
  src/maurimesh/learner/trustLedger.ts \
  src/maurimesh/learner/mauriMeshLearnerCore.ts
do
  if [ -f "$ROOT/$f" ]; then
    mkdir -p "$BACKUP/$(dirname "$f")"
    cp "$ROOT/$f" "$BACKUP/$f"
  fi
done

cat > "$ROOT/src/maurimesh/learner/types.ts" <<'TS'
export type ProofClass =
  | "APK_WORKFLOW_PROOF"
  | "REACTNATIVEJS_MONITOR_PROOF"
  | "BRIDGE_LOG_ONLY"
  | "NATIVE_BLE_GATT_PACKET_BOUND"
  | "INCONCLUSIVE"
  | "NO_PACKET_FOUND";

export type ProofVerdict =
  | "LOCKED_PASS"
  | "PASS_CANDIDATE"
  | "ATTEMPT_LOCKED"
  | "FAIL"
  | "INCONCLUSIVE";

export type DeviceRole = "A06_PHONE_A" | "S10_PHONE_B" | "A16_PHONE_C" | string;

export type LearnerEvidence = {
  id: string;
  timestamp: string;
  packetId: string;
  event: string;
  role: DeviceRole;
  device?: string;
  source:
    | "APK_SCREEN"
    | "REACT_NATIVE_JS"
    | "NATIVE_BRIDGE"
    | "NATIVE_BLE_GATT"
    | "ADB"
    | "GRADLE"
    | "EAS"
    | "MANUAL"
    | "LEDGER";
  rawLine: string;
  proofClass: ProofClass;
  confidence: number;
};

export type RouteDecision = {
  id: string;
  timestamp: string;
  packetId: string;
  route: string[];
  decision: string;
  score: number;
  reason: string;
  verdict: ProofVerdict;
};

export type DeviceTrust = {
  role: DeviceRole;
  successCount: number;
  failCount: number;
  lastSeen?: string;
  trustScore: number;
  notes: string[];
};

export type RecoveryPlan = {
  issue: string;
  cause: string;
  nextAction: string;
  shellHint?: string;
  confidence: number;
};
TS

cat > "$ROOT/src/maurimesh/learner/proofClassifier.ts" <<'TS'
import { ProofClass } from "./types";

const nativeGattMarkers = [
  "BluetoothGatt",
  "BtGatt",
  "GattService",
  "onScanResult",
  "AdvertiseCallback",
  "AdvertisingSet",
  "writeCharacteristic",
  "readCharacteristic",
  "onCharacteristicWrite",
  "onCharacteristicRead",
  "onCharacteristicChanged",
  "onServicesDiscovered",
  "connectGatt",
  "transport=BLE_GATT",
];

const bridgeMarkers = [
  "MAURIMESH_NATIVE_BLE_PACKET",
  "MauriMeshNativeBlePacket",
  "BRIDGE_LOG_ONLY",
];

const reactMarkers = [
  "ReactNativeJS",
  "MAURIMESH_3_DEVICE_PROOF",
  "MAURIMESH_STORE_FORWARD_PROOF",
  "MAURIMESH_2_HOP_PROOF",
];

const workflowMarkers = [
  "EXAM_APPROVED",
  "TX_A06_TO_S10",
  "RX_S10_FROM_A06",
  "RELAY_S10_TO_A16",
  "RX_A16_FROM_S10",
  "ACK_A16_TO_S10",
  "ACK_RELAY_S10_TO_A06",
  "ACK_RECEIVED_A06",
  "STORE_PACKET",
  "STORED",
];

export function classifyProofLine(line: string, packetId?: string): ProofClass {
  const hasPacket = packetId ? line.includes(packetId) : /packetId=|MM3-|MMSF-|MM-/.test(line);
  if (!hasPacket) return "NO_PACKET_FOUND";

  if (nativeGattMarkers.some((m) => line.includes(m))) {
    return "NATIVE_BLE_GATT_PACKET_BOUND";
  }

  if (bridgeMarkers.some((m) => line.includes(m))) {
    if (line.includes("transport=BLE_GATT")) return "NATIVE_BLE_GATT_PACKET_BOUND";
    return "BRIDGE_LOG_ONLY";
  }

  if (reactMarkers.some((m) => line.includes(m))) {
    return "REACTNATIVEJS_MONITOR_PROOF";
  }

  if (workflowMarkers.some((m) => line.includes(m))) {
    return "APK_WORKFLOW_PROOF";
  }

  return "INCONCLUSIVE";
}

export function classConfidence(proofClass: ProofClass): number {
  switch (proofClass) {
    case "NATIVE_BLE_GATT_PACKET_BOUND":
      return 0.95;
    case "REACTNATIVEJS_MONITOR_PROOF":
      return 0.78;
    case "APK_WORKFLOW_PROOF":
      return 0.7;
    case "BRIDGE_LOG_ONLY":
      return 0.55;
    case "INCONCLUSIVE":
      return 0.25;
    case "NO_PACKET_FOUND":
      return 0;
  }
}
TS

cat > "$ROOT/src/maurimesh/learner/evidenceMemory.ts" <<'TS'
import { classifyProofLine, classConfidence } from "./proofClassifier";
import { LearnerEvidence } from "./types";

function makeId(prefix: string) {
  return `${prefix}-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
}

export function extractPacketId(line: string): string {
  const explicit = line.match(/packetId=([A-Z0-9-]+)/);
  if (explicit?.[1]) return explicit[1];

  const any = line.match(/\b(MM3-[A-Z0-9]+-[A-Z0-9]+|MMSF-[A-Z0-9]+-[A-Z0-9]+|MM-[A-Z0-9]+-[A-Z0-9]+)\b/);
  return any?.[1] || "NO_PACKET_ID";
}

export function inferRole(line: string): string {
  if (/A06|PHONE_A|ACK_RECEIVED_A06|TX_A06/i.test(line)) return "A06_PHONE_A";
  if (/S10|PHONE_B|RELAY|RX_S10|ACK_RELAY/i.test(line)) return "S10_PHONE_B";
  if (/A16|PHONE_C|RX_A16|ACK_A16/i.test(line)) return "A16_PHONE_C";
  return "UNKNOWN_ROLE";
}

export function inferSource(line: string): LearnerEvidence["source"] {
  if (line.includes("MAURIMESH_NATIVE_BLE_PACKET") && line.includes("transport=BLE_GATT")) return "NATIVE_BLE_GATT";
  if (line.includes("MAURIMESH_NATIVE_BLE_PACKET")) return "NATIVE_BRIDGE";
  if (line.includes("ReactNativeJS")) return "REACT_NATIVE_JS";
  if (line.includes("adb") || line.includes("device") || line.includes("offline")) return "ADB";
  if (line.includes("Gradle") || line.includes("BUILD FAILED") || line.includes("BUILD SUCCESSFUL")) return "GRADLE";
  if (line.includes("EAS") || line.includes("Application archive")) return "EAS";
  if (line.includes("SHA-256") || line.includes("LOCKED")) return "LEDGER";
  return "APK_SCREEN";
}

export function rememberEvidenceLine(line: string): LearnerEvidence {
  const packetId = extractPacketId(line);
  const proofClass = classifyProofLine(line, packetId);
  return {
    id: makeId("ev"),
    timestamp: new Date().toISOString(),
    packetId,
    event: line.includes("|") ? line.split("|").map((p) => p.trim())[1] || "EVENT" : "EVENT",
    role: inferRole(line),
    source: inferSource(line),
    rawLine: line,
    proofClass,
    confidence: classConfidence(proofClass),
  };
}

export function rememberEvidenceBlock(text: string): LearnerEvidence[] {
  return text
    .split(/\r?\n/)
    .map((l) => l.trim())
    .filter(Boolean)
    .map(rememberEvidenceLine);
}
TS

cat > "$ROOT/src/maurimesh/learner/decisionScoring.ts" <<'TS'
import { LearnerEvidence, RouteDecision } from "./types";

const required3Device = [
  "TX_A06_TO_S10",
  "RX_S10_FROM_A06",
  "RELAY_S10_TO_A16",
  "RX_A16_FROM_S10",
  "ACK_A16_TO_S10",
  "ACK_RELAY_S10_TO_A06",
  "ACK_RECEIVED_A06",
  "EXAM_APPROVED",
];

export function scorePacketEvidence(packetId: string, evidence: LearnerEvidence[]): RouteDecision {
  const packet = evidence.filter((e) => e.packetId === packetId);
  const joined = packet.map((e) => e.rawLine).join("\n");

  const stageHits = required3Device.filter((stage) => joined.includes(stage)).length;
  const nativeHits = packet.filter((e) => e.proofClass === "NATIVE_BLE_GATT_PACKET_BOUND").length;
  const bridgeHits = packet.filter((e) => e.proofClass === "BRIDGE_LOG_ONLY").length;
  const workflowHits = packet.filter(
    (e) => e.proofClass === "APK_WORKFLOW_PROOF" || e.proofClass === "REACTNATIVEJS_MONITOR_PROOF"
  ).length;

  let score = stageHits * 8 + nativeHits * 15 + workflowHits * 4 + bridgeHits * 2;
  score = Math.min(100, score);

  const verdict =
    nativeHits > 0 && stageHits >= 7
      ? "PASS_CANDIDATE"
      : stageHits >= 7
        ? "ATTEMPT_LOCKED"
        : "INCONCLUSIVE";

  const reason =
    nativeHits > 0
      ? "Packet has native BLE/GATT-marked evidence. Verify path continuity before lock."
      : stageHits >= 7
        ? "Packet has full workflow path but native BLE/GATT transport remains unconfirmed."
        : "Packet evidence is incomplete.";

  return {
    id: `decision-${packetId}-${Date.now()}`,
    timestamp: new Date().toISOString(),
    packetId,
    route: ["A06_PHONE_A", "S10_PHONE_B", "A16_PHONE_C", "S10_PHONE_B", "A06_PHONE_A"],
    decision: "CLASSIFY_PACKET_PROOF",
    score,
    reason,
    verdict,
  };
}
TS

cat > "$ROOT/src/maurimesh/learner/badDecisionLearner.ts" <<'TS'
import { RecoveryPlan, RouteDecision } from "./types";

export function learnFromBadDecision(decision: RouteDecision): RecoveryPlan | null {
  if (decision.verdict === "LOCKED_PASS" || decision.verdict === "PASS_CANDIDATE") return null;

  if (decision.reason.includes("native BLE/GATT transport remains unconfirmed")) {
    return {
      issue: "Native transport not proven",
      cause: "packetId appeared in workflow/bridge logs but not Android BLE/GATT callback lines.",
      nextAction: "Patch real BLE/GATT callbacks or verify the bridge is called from native transport, then rerun logcat capture.",
      shellHint: "Search logcat for MAURIMESH_NATIVE_BLE_PACKET packetId=<id> transport=BLE_GATT",
      confidence: 0.9,
    };
  }

  if (decision.reason.includes("incomplete")) {
    return {
      issue: "Incomplete proof path",
      cause: "Not all required TX/RX/relay/ACK stages were observed for the same packetId.",
      nextAction: "Repeat the proof with all three phones awake, same route screen open, and monitor running before first tap.",
      shellHint: "Run 3-device monitor, then tap proof stages in order.",
      confidence: 0.78,
    };
  }

  return {
    issue: "Unknown proof weakness",
    cause: decision.reason,
    nextAction: "Review packet evidence manually and classify missing stages.",
    confidence: 0.4,
  };
}
TS

cat > "$ROOT/src/maurimesh/learner/recoveryPlanner.ts" <<'TS'
import { RecoveryPlan } from "./types";

export function planRecoveryFromLog(text: string): RecoveryPlan {
  if (/Host is down|offline|unauthorized|no devices\/emulators/i.test(text)) {
    return {
      issue: "ADB device unavailable",
      cause: "Phone is offline, unauthorized, or Wi-Fi ADB dropped.",
      nextAction: "Reconnect by USB, accept debugging, run adb tcpip 5555, then reconnect Wi-Fi ADB.",
      shellHint: "adb devices -l && adb -s <USB_SERIAL> tcpip 5555 && adb connect <PHONE_IP>:5555",
      confidence: 0.92,
    };
  }

  if (/JAVA_HOME is not set|java: command not installed/i.test(text)) {
    return {
      issue: "Java missing",
      cause: "Replit shell has no selected Java runtime.",
      nextAction: "Use Nix Java 17.",
      shellHint: "nix-shell -p zulu17 --run 'java -version'",
      confidence: 0.95,
    };
  }

  if (/SDK location not found|ANDROID_HOME|sdk.dir/i.test(text)) {
    return {
      issue: "Android SDK missing locally",
      cause: "Replit lacks Android SDK path.",
      nextAction: "Use EAS remote Android build for native compile validation.",
      shellHint: "npx eas-cli build -p android --profile preview --clear-cache",
      confidence: 0.9,
    };
  }

  if (/Unexpected keyword 'import'|SyntaxError/i.test(text)) {
    return {
      issue: "TypeScript/Metro syntax error",
      cause: "A generated import or code block was inserted in an invalid location.",
      nextAction: "Repair import placement and rerun expo export.",
      shellHint: "npx expo export --platform android --clear",
      confidence: 0.88,
    };
  }

  return {
    issue: "No known recovery match",
    cause: "The learner has not seen this failure pattern enough.",
    nextAction: "Capture the exact error section and add it to learner memory.",
    confidence: 0.35,
  };
}
TS

cat > "$ROOT/src/maurimesh/learner/trustLedger.ts" <<'TS'
import { DeviceTrust, LearnerEvidence } from "./types";

export function buildTrustLedger(evidence: LearnerEvidence[]): DeviceTrust[] {
  const roles = Array.from(new Set(evidence.map((e) => e.role))).filter(Boolean);

  return roles.map((role) => {
    const rows = evidence.filter((e) => e.role === role);
    const successCount = rows.filter((e) =>
      /ACK|EXAM_APPROVED|RX_|TX_|RELAY|PASS|CONNECTED/i.test(e.rawLine)
    ).length;
    const failCount = rows.filter((e) =>
      /ERROR|FAIL|offline|unauthorized|Host is down|NO_PACKET|INCONCLUSIVE/i.test(e.rawLine)
    ).length;

    const trustScore = Math.max(0, Math.min(100, 50 + successCount * 5 - failCount * 8));

    return {
      role,
      successCount,
      failCount,
      lastSeen: rows.at(-1)?.timestamp,
      trustScore,
      notes: [
        trustScore >= 80 ? "High trust for current evidence set." : "Needs more proof cycles.",
        failCount > 0 ? "Has observed failure signals." : "No failure signals in current memory.",
      ],
    };
  });
}
TS

cat > "$ROOT/src/maurimesh/learner/mauriMeshLearnerCore.ts" <<'TS'
import { learnFromBadDecision } from "./badDecisionLearner";
import { scorePacketEvidence } from "./decisionScoring";
import { rememberEvidenceBlock } from "./evidenceMemory";
import { planRecoveryFromLog } from "./recoveryPlanner";
import { buildTrustLedger } from "./trustLedger";

export function runMauriMeshLearnerCore(logText: string, packetId?: string) {
  const evidence = rememberEvidenceBlock(logText);
  const detectedPacket =
    packetId ||
    evidence.find((e) => e.packetId && e.packetId !== "NO_PACKET_ID")?.packetId ||
    "NO_PACKET_ID";

  const decision = scorePacketEvidence(detectedPacket, evidence);
  const recoveryFromDecision = learnFromBadDecision(decision);
  const recoveryFromLog = planRecoveryFromLog(logText);
  const trustLedger = buildTrustLedger(evidence);

  return {
    generatedAt: new Date().toISOString(),
    packetId: detectedPacket,
    evidenceCount: evidence.length,
    evidence,
    decision,
    recovery: recoveryFromDecision || recoveryFromLog,
    trustLedger,
    truth:
      "Learner Core classifies evidence and recommends recovery. It does not claim native BLE/GATT PASS without native transport packet evidence.",
  };
}
TS

cat > "$ROOT/app/learner-core.tsx" <<'TSX'
import React, { useMemo, useState } from "react";
import { ScrollView, StyleSheet, Text, TextInput, View } from "react-native";
import { runMauriMeshLearnerCore } from "../src/maurimesh/learner/mauriMeshLearnerCore";

const sample = `ReactNativeJS: MAURIMESH_3_DEVICE_PROOF | TX_A06_TO_S10 | packetId=MM3-SAMPLE-123456
ReactNativeJS: MAURIMESH_3_DEVICE_PROOF | RX_S10_FROM_A06 | packetId=MM3-SAMPLE-123456
ReactNativeJS: MAURIMESH_3_DEVICE_PROOF | RELAY_S10_TO_A16 | packetId=MM3-SAMPLE-123456
ReactNativeJS: MAURIMESH_3_DEVICE_PROOF | RX_A16_FROM_S10 | packetId=MM3-SAMPLE-123456
ReactNativeJS: MAURIMESH_3_DEVICE_PROOF | ACK_A16_TO_S10 | packetId=MM3-SAMPLE-123456
ReactNativeJS: MAURIMESH_3_DEVICE_PROOF | ACK_RELAY_S10_TO_A06 | packetId=MM3-SAMPLE-123456
ReactNativeJS: MAURIMESH_3_DEVICE_PROOF | ACK_RECEIVED_A06 | packetId=MM3-SAMPLE-123456
ReactNativeJS: MAURIMESH_3_DEVICE_PROOF | EXAM_APPROVED | packetId=MM3-SAMPLE-123456`;

export default function LearnerCoreScreen() {
  const [input, setInput] = useState(sample);
  const report = useMemo(() => runMauriMeshLearnerCore(input), [input]);

  return (
    <ScrollView style={styles.screen} contentContainerStyle={styles.content}>
      <Text style={styles.title}>MauriMesh Learner Core</Text>
      <Text style={styles.subtitle}>
        Evidence memory, proof classifier, recovery planner, trust ledger.
      </Text>

      <TextInput
        value={input}
        onChangeText={setInput}
        multiline
        style={styles.input}
        placeholder="Paste proof logs here..."
        placeholderTextColor="rgba(255,255,255,0.45)"
      />

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Decision</Text>
        <Text style={styles.line}>Packet: {report.packetId}</Text>
        <Text style={styles.line}>Verdict: {report.decision.verdict}</Text>
        <Text style={styles.line}>Score: {report.decision.score}/100</Text>
        <Text style={styles.line}>Reason: {report.decision.reason}</Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Recovery</Text>
        <Text style={styles.line}>Issue: {report.recovery.issue}</Text>
        <Text style={styles.line}>Cause: {report.recovery.cause}</Text>
        <Text style={styles.line}>Next: {report.recovery.nextAction}</Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Trust Ledger</Text>
        {report.trustLedger.map((d) => (
          <Text key={d.role} style={styles.line}>
            {d.role}: {d.trustScore}/100 · success {d.successCount} · fail {d.failCount}
          </Text>
        ))}
      </View>

      <Text style={styles.truth}>{report.truth}</Text>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: "#020403" },
  content: { padding: 18, gap: 14 },
  title: { color: "#FFFFFF", fontSize: 30, fontWeight: "900" },
  subtitle: { color: "rgba(255,255,255,0.72)", lineHeight: 21 },
  input: {
    minHeight: 220,
    color: "#FFFFFF",
    backgroundColor: "rgba(255,255,255,0.06)",
    borderColor: "rgba(34,197,94,0.28)",
    borderWidth: 1,
    borderRadius: 18,
    padding: 14,
    textAlignVertical: "top",
  },
  card: {
    padding: 16,
    borderRadius: 20,
    borderWidth: 1,
    borderColor: "rgba(34,197,94,0.28)",
    backgroundColor: "rgba(2,12,8,0.84)",
    gap: 8,
  },
  cardTitle: { color: "#00D084", fontSize: 18, fontWeight: "900" },
  line: { color: "#FFFFFF", lineHeight: 20 },
  truth: { color: "#F59E0B", lineHeight: 20, fontWeight: "700" },
});
TSX

cat > "$ROOT/docs/learner/maurimesh-learner-core-v1.md" <<'MD'
# MauriMesh Learner Core v1

## Purpose

The learner turns proof logs, crash logs, ADB states, Gradle results, EAS outcomes, and packet evidence into structured memory.

## It can classify

- APK workflow proof
- ReactNativeJS monitor proof
- bridge-only native log request
- native BLE/GATT packet-bound evidence
- inconclusive evidence

## It can recommend recovery

Known patterns:

- ADB offline or host down
- Java missing
- Android SDK missing
- syntax import error
- incomplete proof path
- native BLE/GATT not confirmed

## Truth rule

The learner does not claim native BLE/GATT PASS unless the same packetId appears in native transport evidence.
MD

echo ""
echo "============================================================"
echo "WIRE DASHBOARD BUTTON IF SAFE"
echo "============================================================"

python3 <<'PY'
from pathlib import Path

p = Path("app/dashboard.tsx")
if not p.exists():
    print("No dashboard found. Skipping dashboard wire.")
    raise SystemExit(0)

s = p.read_text()
if "/learner-core" in s:
    print("Dashboard already has learner-core route.")
    raise SystemExit(0)

# Try to add a simple button after Mesh Status or Settings button patterns.
insert = '''
        <MauriButton title="Learner Core" onPress={() => router.push("/learner-core")} />
'''

if 'title="Settings"' in s:
    idx = s.find('title="Settings"')
    line_start = s.rfind("<MauriButton", 0, idx)
    line_end = s.find("/>", idx)
    if line_start != -1 and line_end != -1:
        s = s[:line_end+2] + "\n" + insert + s[line_end+2:]
        p.write_text(s)
        print("Inserted Learner Core button near Settings.")
    else:
        print("Could not safely insert button.")
else:
    print("Settings button not found. Dashboard not modified.")
PY

echo ""
echo "============================================================"
echo "VALIDATE"
echo "============================================================"

npx tsc --noEmit || true
npx expo export --platform android --clear

REPORT="$ROOT/docs/learner/maurimesh-learner-core-v1-install-report-$STAMP.md"

cat > "$REPORT" <<MD
# MauriMesh Learner Core v1 Install Report

Generated: $STAMP

## Installed

- src/maurimesh/learner/types.ts
- src/maurimesh/learner/evidenceMemory.ts
- src/maurimesh/learner/proofClassifier.ts
- src/maurimesh/learner/decisionScoring.ts
- src/maurimesh/learner/badDecisionLearner.ts
- src/maurimesh/learner/recoveryPlanner.ts
- src/maurimesh/learner/trustLedger.ts
- src/maurimesh/learner/mauriMeshLearnerCore.ts
- app/learner-core.tsx
- docs/learner/maurimesh-learner-core-v1.md

## Truth

Learner Core enhances evidence classification, recovery planning, route scoring, and trust scoring.

It does not claim native BLE/GATT proof by itself.
MD

echo ""
echo "============================================================"
echo "MAURIMESH LEARNER CORE v1 INSTALLED"
echo "============================================================"
echo "Backup: $BACKUP"
echo "Report: $REPORT"
echo ""
echo "Next route:"
echo "/learner-core"
echo "============================================================"
