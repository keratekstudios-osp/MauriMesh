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
