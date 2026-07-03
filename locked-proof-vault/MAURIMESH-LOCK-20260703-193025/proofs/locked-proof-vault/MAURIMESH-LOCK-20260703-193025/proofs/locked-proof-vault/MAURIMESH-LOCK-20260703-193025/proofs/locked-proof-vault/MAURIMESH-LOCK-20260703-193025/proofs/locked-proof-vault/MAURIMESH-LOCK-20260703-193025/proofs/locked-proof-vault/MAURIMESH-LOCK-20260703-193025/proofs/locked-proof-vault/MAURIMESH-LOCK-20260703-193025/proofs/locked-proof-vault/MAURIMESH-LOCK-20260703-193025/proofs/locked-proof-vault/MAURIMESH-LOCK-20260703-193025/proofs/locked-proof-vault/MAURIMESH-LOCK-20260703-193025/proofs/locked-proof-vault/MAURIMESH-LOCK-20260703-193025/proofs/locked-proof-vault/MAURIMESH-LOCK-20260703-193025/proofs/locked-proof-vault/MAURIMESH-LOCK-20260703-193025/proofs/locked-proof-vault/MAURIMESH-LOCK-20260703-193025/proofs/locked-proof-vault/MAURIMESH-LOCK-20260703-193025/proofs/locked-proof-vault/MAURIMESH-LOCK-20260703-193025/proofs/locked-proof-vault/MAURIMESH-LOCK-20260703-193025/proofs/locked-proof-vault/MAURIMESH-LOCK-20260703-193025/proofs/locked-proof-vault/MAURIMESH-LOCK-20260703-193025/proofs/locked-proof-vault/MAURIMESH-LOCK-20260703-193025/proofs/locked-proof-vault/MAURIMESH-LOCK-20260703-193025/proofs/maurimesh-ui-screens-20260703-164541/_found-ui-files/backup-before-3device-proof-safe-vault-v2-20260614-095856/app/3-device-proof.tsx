import React, { useMemo, useState } from "react";
import { ScrollView, StyleSheet, Text, TouchableOpacity, View } from "react-native";
import { nativeBlePacketLogSafe } from "../src/maurimesh/native/nativeBlePacketLogger";
import AsyncStorage from "@react-native-async-storage/async-storage";
type Stage = {
  key: string;
  label: string;
  device: string;
};

const stages: Stage[] = [
  { key: "PACKET_ID_CONFIRMED", label: "Packet ID confirmed", device: "A06 / PHONE_A" },
  { key: "TX_A06_TO_S10", label: "A06 sends packet to S10", device: "A06 / PHONE_A" },
  { key: "RX_S10_FROM_A06", label: "S10 receives from A06", device: "S10 / PHONE_B" },
  { key: "RELAY_S10_TO_A16", label: "S10 relays to A16", device: "S10 / PHONE_B" },
  { key: "RX_A16_FROM_S10", label: "A16 receives from S10", device: "A16 / PHONE_C" },
  { key: "ACK_A16_TO_S10", label: "A16 sends ACK to S10", device: "A16 / PHONE_C" },
  { key: "ACK_RELAY_S10_TO_A06", label: "S10 relays ACK to A06", device: "S10 / PHONE_B" },
  { key: "ACK_RECEIVED_A06", label: "A06 receives ACK", device: "A06 / PHONE_A" },
];

function makePacketId() {
  const part = Math.random().toString(36).slice(2, 8).toUpperCase();
  const part2 = Math.random().toString(36).slice(2, 8).toUpperCase();
  return `MM3-${part}-${part2}`;
}

function logProof(stage: string, packetId: string, device: string) {
  const line = `MAURIMESH_3_DEVICE_PROOF | ${device} | ${stage} | packetId=${packetId}`;
  console.log(line);
}

export default function ThreeDeviceProofScreen() {
  const [packetId, setPacketId] = useState(() => makePacketId());
  const [done, setDone] = useState<Record<string, boolean>>({});
  const [approved, setApproved] = useState(false);

  const completeCount = useMemo(
    () => stages.filter((stage) => done[stage.key]).length,
    [done]
  );

  const allDone = completeCount === stages.length;

  function resetProof() {
    const nextPacketId = makePacketId();
    setPacketId(nextPacketId);
    setDone({});
    setApproved(false);
    console.log(`MAURIMESH_3_DEVICE_PROOF | PHONE_A | EXAM_RESET | packetId=${nextPacketId}`);
  }

  function startExam() {
    setApproved(false);
    console.log(`MAURIMESH_3_DEVICE_PROOF | EXAM_STARTED | mode=MANUAL | PHONE_A=A06 | PHONE_B=S10 | PHONE_C=A16 | packetId=${packetId}`);
  }

  function markStage(stage: Stage) {
    setDone((current) => ({ ...current, [stage.key]: true }));
    logProof(stage.key, packetId, stage.device);
  }

  function approveExam() {
    if (!allDone) {
      console.log(`MAURIMESH_3_DEVICE_PROOF | EXAM_BLOCKED | missingStages=${stages.length - completeCount} | packetId=${packetId}`);
      return;
    }

    setApproved(true);
    console.log(`MAURIMESH_3_DEVICE_PROOF | EXAM_APPROVED | packetId=${packetId}`);

      // MAURIMESH_THREE_DEVICE_VAULT_SAVE_CALL_V1
      void mauriMeshSaveThreeDeviceProofToVault(
        packetId,
        typeof proofLog !== "undefined"
          ? String(proofLog)
          : typeof currentProofLog !== "undefined"
            ? String(currentProofLog)
            : typeof logText !== "undefined"
              ? String(logText)
              : typeof report !== "undefined"
                ? String(report)
                : "3-device relay proof completed. Proof log state name not detected by patch."
      );

  }

  return (
    <ScrollView style={styles.screen} contentContainerStyle={styles.content}>
      <Text style={styles.kicker}>MAURIMESH PROOF EXAM</Text>
      <Text style={styles.title}>3-Device Relay Proof</Text>
      <Text style={styles.subtitle}>
        A06 sender → S10 relay → A16 receiver → ACK back through S10 → A06.
      </Text>

      <View style={styles.card}>
        <Text style={styles.label}>Packet ID</Text>
        <Text selectable style={styles.packet}>{packetId}</Text>
        <Text style={styles.note}>
          PASS requires this same packetId across TX, RX, relay, ACK, and EXAM_APPROVED logs.
        </Text>
      </View>

      <TouchableOpacity style={styles.primaryButton} onPress={startExam}>
        <Text style={styles.primaryText}>Start 3-Device Exam</Text>
      </TouchableOpacity>

      <View style={styles.card}>
        <Text style={styles.sectionTitle}>Manual proof stages</Text>
        {stages.map((stage, index) => {
          const complete = !!done[stage.key];

          return (
            <TouchableOpacity
              key={stage.key}
              style={[styles.stageButton, complete && styles.stageDone]}
              onPress={() => markStage(stage)}
            >
              <Text style={styles.stageIndex}>{index + 1}</Text>
              <View style={styles.stageTextBox}>
                <Text style={styles.stageLabel}>{stage.label}</Text>
                <Text style={styles.stageKey}>{stage.key}</Text>
                <Text style={styles.stageDevice}>{stage.device}</Text>
              </View>
              <Text style={styles.doneText}>{complete ? "DONE" : "TAP"}</Text>
            </TouchableOpacity>
          );
        })}
      </View>

      <TouchableOpacity
        style={[styles.approveButton, allDone && styles.approveReady]}
        onPress={approveExam}
      >
        <Text style={styles.primaryText}>
          {approved ? "EXAM APPROVED" : allDone ? "Approve Exam" : `Complete ${stages.length - completeCount} More`}
        </Text>
      </TouchableOpacity>

      {approved ? (
        <View style={styles.passCard}>
          <Text style={styles.passTitle}>Congratulations</Text>
          <Text style={styles.passText}>
            3-device relay proof approved for packet {packetId}.
          </Text>
        </View>
      ) : null}

      <TouchableOpacity style={styles.secondaryButton} onPress={resetProof}>
        <Text style={styles.secondaryText}>Reset Packet / New Exam</Text>
      </TouchableOpacity>

      <View style={styles.truthCard}>
        <Text style={styles.truthTitle}>Truth class</Text>
        <Text style={styles.truthText}>
          APK proof-screen workflow + ReactNativeJS monitor logs. Native BLE/GATT proof still requires native packet-bound BLE logs.
        </Text>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: "#020403" },
  content: { padding: 20, paddingBottom: 48, gap: 16 },
  kicker: { color: "#00D084", fontSize: 12, fontWeight: "900", letterSpacing: 1.2 },
  title: { color: "white", fontSize: 34, fontWeight: "900" },
  subtitle: { color: "rgba(255,255,255,0.72)", fontSize: 15, lineHeight: 22 },
  card: {
    backgroundColor: "rgba(2,12,8,0.88)",
    borderWidth: 1,
    borderColor: "rgba(34,197,94,0.28)",
    borderRadius: 22,
    padding: 16,
    gap: 10,
  },
  label: { color: "rgba(255,255,255,0.6)", fontSize: 12, fontWeight: "800" },
  packet: { color: "#00D084", fontSize: 22, fontWeight: "900" },
  note: { color: "rgba(255,255,255,0.66)", fontSize: 13, lineHeight: 19 },
  sectionTitle: { color: "white", fontSize: 18, fontWeight: "900" },
  primaryButton: {
    minHeight: 54,
    borderRadius: 18,
    backgroundColor: "#00D084",
    alignItems: "center",
    justifyContent: "center",
  },
  approveButton: {
    minHeight: 54,
    borderRadius: 18,
    backgroundColor: "rgba(245,158,11,0.32)",
    borderWidth: 1,
    borderColor: "rgba(245,158,11,0.5)",
    alignItems: "center",
    justifyContent: "center",
  },
  approveReady: { backgroundColor: "#00D084", borderColor: "#00D084" },
  primaryText: { color: "white", fontSize: 16, fontWeight: "900" },
  secondaryButton: {
    minHeight: 50,
    borderRadius: 18,
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.16)",
    alignItems: "center",
    justifyContent: "center",
  },
  secondaryText: { color: "rgba(255,255,255,0.82)", fontSize: 15, fontWeight: "800" },
  stageButton: {
    flexDirection: "row",
    alignItems: "center",
    gap: 12,
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.1)",
    backgroundColor: "rgba(255,255,255,0.04)",
    borderRadius: 18,
    padding: 12,
  },
  stageDone: {
    borderColor: "#00D084",
    backgroundColor: "rgba(0,208,132,0.14)",
  },
  stageIndex: {
    width: 30,
    height: 30,
    borderRadius: 15,
    backgroundColor: "rgba(0,208,132,0.18)",
    color: "white",
    textAlign: "center",
    lineHeight: 30,
    fontWeight: "900",
  },
  stageTextBox: { flex: 1 },
  stageLabel: { color: "white", fontSize: 14, fontWeight: "900" },
  stageKey: { color: "#00D084", fontSize: 11, fontWeight: "800", marginTop: 3 },
  stageDevice: { color: "rgba(255,255,255,0.58)", fontSize: 11, marginTop: 2 },
  doneText: { color: "white", fontSize: 12, fontWeight: "900" },
  passCard: {
    borderRadius: 22,
    padding: 18,
    backgroundColor: "rgba(0,208,132,0.18)",
    borderWidth: 1,
    borderColor: "#00D084",
  },
  passTitle: { color: "white", fontSize: 24, fontWeight: "900" },
  passText: { color: "rgba(255,255,255,0.75)", marginTop: 6, lineHeight: 20 },
  truthCard: {
    borderRadius: 18,
    padding: 14,
    backgroundColor: "rgba(255,255,255,0.04)",
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.1)",
  },
  truthTitle: { color: "#F59E0B", fontWeight: "900", marginBottom: 6 },
  truthText: { color: "rgba(255,255,255,0.68)", lineHeight: 19 },
});


function mauriMeshNativePacketProofLog(stage: string, packetId: string, detail?: string) {
  nativeBlePacketLogSafe({
    role: "PHONE_PROOF",
    stage,
    packetId,
    transport: "BRIDGE_LOG_ONLY",
    detail: detail || stage,
  });
}
// MAURIMESH_NATIVE_BLE_PACKET_PATCH_MARKER


/*
MAURIMESH_NATIVE_BLE_PACKET_REQUIRED_STAGE_MAP

When proof stage buttons/log events fire, call:

nativeBlePacketLogSafe({
  role: "A06_PHONE_A" | "S10_PHONE_B" | "A16_PHONE_C",
  stage: "GATT_WRITE_PACKET" | "GATT_READ_PACKET" | "RELAY_PACKET_NATIVE" | "ACK_PACKET_NATIVE" | "GATT_CHARACTERISTIC_CHANGED",
  packetId,
  transport: "BRIDGE_LOG_ONLY",
  detail: "TX_A06_TO_S10" | "RX_S10_FROM_A06" | "RELAY_S10_TO_A16" | "RX_A16_FROM_S10" | "ACK_A16_TO_S10" | "ACK_RELAY_S10_TO_A06" | "ACK_RECEIVED_A06"
});

This patch does not claim real BLE/GATT proof.
Real native PASS requires transport=BLE_GATT inside Android Bluetooth/GATT callbacks.
*/



/* MAURIMESH_THREE_DEVICE_RELAY_PROOF_VAULT_STORAGE_V1_START */
async function mauriMeshSaveThreeDeviceProofToVault(packetId: string, proofLog: string) {
  try {
    const safePacketId = String(packetId || "NO_PACKET_ID").trim();
    const key = `maurimesh_proof_3_device_${safePacketId}`;
    const payload = {
      type: "THREE_DEVICE_RELAY_PROOF",
      packetId: safePacketId,
      truthClass: "APK_PROOF_SCREEN_WORKFLOW",
      nativeBleGattPacketBoundPass: false,
      savedAt: new Date().toISOString(),
      proofLog,
      warning:
        "Native BLE/GATT packet-bound PASS is not claimed unless the same packetId appears inside native BLE/GATT transport logs.",
    };

    await AsyncStorage.setItem(key, JSON.stringify(payload));

    console.log(
      `MAURIMESH_PROOF_VAULT_SAVE | THREE_DEVICE_RELAY_PROOF | packetId=${safePacketId} | key=${key} | truthClass=APK_PROOF_SCREEN_WORKFLOW | nativeBleGattPacketBoundPass=false`
    );
  } catch (err) {
    console.log(
      `MAURIMESH_PROOF_VAULT_SAVE_ERROR | THREE_DEVICE_RELAY_PROOF | packetId=${packetId || "NO_PACKET_ID"} | error=${
        err instanceof Error ? err.message : "UNKNOWN"
      }`
    );
  }
}
/* MAURIMESH_THREE_DEVICE_RELAY_PROOF_VAULT_STORAGE_V1_END */



/*
MAURIMESH_THREE_DEVICE_RELAY_PROOF_VAULT_SAVE_CALL_RULE

When this proof reaches EXAM_APPROVED or final completion, call:

void mauriMeshSaveThreeDeviceProofToVault(packetId, proofLogText);

Saved key format:

maurimesh_proof_3_device_<packetId>

Truth:
This stores APK proof-screen workflow evidence only.
It does not claim native BLE/GATT packet-bound proof.
*/

