import React, { useMemo, useState } from "react";
import {
  Alert,
  Platform,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from "react-native";
import {
  STORE_FORWARD_PROOF,
  STORE_FORWARD_STAGES,
} from "../src/maurimesh/proof/storeForwardProof";

type RoleKey = "PHONE_A" | "PHONE_B" | "PHONE_C";
type DeviceName = "A06" | "S10" | "A16";
type ExamMode = "MANUAL" | "GUIDED_AUTO";
type Approval = "PENDING" | "APPROVED" | "REJECTED";

const BUILD_MARKER = "STORE_FORWARD_PROOF_20260612";
const DEVICE_OPTIONS: DeviceName[] = ["A06", "S10", "A16"];

function makePacketId() {
  const alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
  let left = "";
  let right = "";
  for (let i = 0; i < 6; i += 1) {
    left += alphabet[Math.floor(Math.random() * alphabet.length)];
    right += alphabet[Math.floor(Math.random() * alphabet.length)];
  }
  return `MMSF-${left}-${right}`;
}

function roleTone(role: RoleKey) {
  if (role === "PHONE_A") return "#00D084";
  if (role === "PHONE_B") return "#38BDF8";
  return "#F59E0B";
}

function roleTitle(role: RoleKey) {
  if (role === "PHONE_A") return "PHONE_A / Sender";
  if (role === "PHONE_B") return "PHONE_B / Store-Forward Relay";
  return "PHONE_C / Delayed Receiver + ACK";
}

export default function StoreForwardProofScreen() {
  const [roles, setRoles] = useState<Record<RoleKey, DeviceName>>({
    PHONE_A: "A06",
    PHONE_B: "S10",
    PHONE_C: "A16",
  });

  const [packetInput, setPacketInput] = useState("");
  const [packetId, setPacketId] = useState("");
  const [done, setDone] = useState<Record<string, boolean>>({});
  const [proofLog, setProofLog] = useState<string[]>([]);
  const [examMode, setExamMode] = useState<ExamMode>("MANUAL");
  const [examStarted, setExamStarted] = useState(false);
  const [approval, setApproval] = useState<Approval>("PENDING");

  const rolesReady = new Set(Object.values(roles)).size === 3;
  const doneCount = STORE_FORWARD_STAGES.filter((stage) => done[stage.id]).length;
  const sequenceComplete =
    rolesReady && packetId.length > 0 && doneCount === STORE_FORWARD_STAGES.length;
  const currentIndex = useMemo(
    () => STORE_FORWARD_STAGES.findIndex((stage) => !done[stage.id]),
    [done]
  );

  function chooseDevice(role: RoleKey, device: DeviceName) {
    setRoles((prev) => ({ ...prev, [role]: device }));
  }

  function proofLine(role: RoleKey, stageId: string, activePacketId: string, message: string) {
    const line =
      `${new Date().toISOString()} | MAURIMESH_STORE_FORWARD_PROOF | ${role} | ${roles[role]} | ${stageId} | packetId=${activePacketId} | ${message}`;
    console.log(line);
    setProofLog((prev) => [...prev, line]);
    return line;
  }

  function confirmPacketId() {
    const cleaned = String(packetInput || "").trim().toUpperCase();
    const finalPacketId = cleaned || makePacketId();

    setPacketId(finalPacketId);
    setPacketInput(finalPacketId);
    setDone((prev) => ({ ...prev, PACKET_ID_CONFIRMED: true }));
    setApproval("PENDING");

    proofLine("PHONE_A", "PACKET_ID_CONFIRMED", finalPacketId, "Store-forward packetId confirmed.");

    Alert.alert(
      "Store-forward packetId confirmed",
      `Use this same packetId across all devices:\n\n${finalPacketId}`
    );
  }

  function startExam() {
    if (!rolesReady) {
      Alert.alert("Select 3 unique devices", "PHONE_A, PHONE_B, and PHONE_C must each use a different device.");
      return;
    }

    if (!packetId) {
      Alert.alert("Packet ID required", "Confirm or generate the store-forward packetId first.");
      return;
    }

    setExamStarted(true);
    setApproval("PENDING");

    console.log(
      `MAURIMESH_STORE_FORWARD_PROOF | EXAM_STARTED | mode=${examMode} | packetId=${packetId} | PHONE_A=${roles.PHONE_A} | PHONE_B=${roles.PHONE_B} | PHONE_C=${roles.PHONE_C}`
    );

    if (examMode === "GUIDED_AUTO") {
      Alert.alert(
        "Guided Auto Mode",
        "This completes the expected app sequence only. Real proof still requires matching logs and screenshots.",
        [
          { text: "Cancel", style: "cancel" },
          { text: "Run", onPress: runGuidedAuto },
        ]
      );
      return;
    }

    Alert.alert("Manual store-forward exam started", "Press each lit-up proof button in order.");
  }

  function runGuidedAuto() {
    const nextDone: Record<string, boolean> = {};
    const lines: string[] = [];

    STORE_FORWARD_STAGES.forEach((stage) => {
      nextDone[stage.id] = true;
      const line =
        `${new Date().toISOString()} | MAURIMESH_STORE_FORWARD_PROOF | ${stage.role} | ${roles[stage.role]} | ${stage.id} | packetId=${packetId} | GUIDED_AUTO_EXPECTED_SEQUENCE`;
      console.log(line);
      lines.push(line);
    });

    setDone(nextDone);
    setProofLog((prev) => [...prev, ...lines]);
    askApproval();
  }

  function pressStage(index: number) {
    const stage = STORE_FORWARD_STAGES[index];

    if (!examStarted) {
      Alert.alert("Start exam first", "Press Start Store-Forward Exam before using lit-up buttons.");
      return;
    }

    if (!packetId) {
      Alert.alert("Packet ID required", "Confirm packetId first.");
      return;
    }

    if (index !== currentIndex) {
      Alert.alert("Stage locked", "Press the lit-up READY button only.");
      return;
    }

    setDone((prev) => ({ ...prev, [stage.id]: true }));
    proofLine(stage.role, stage.id, packetId, stage.title);

    if (index === STORE_FORWARD_STAGES.length - 1) {
      askApproval();
    } else {
      Alert.alert("Stage complete", `${stage.title}\n\nContinue to the next lit-up button.`);
    }
  }

  function askApproval() {
    Alert.alert(
      "Approve store-forward proof?",
      "Approve only if screenshots and logcat show this same packetId across store, hold, rediscovery, forward, RX, and ACK.",
      [
        {
          text: "No, reset",
          style: "destructive",
          onPress: () => {
            setApproval("REJECTED");
            setDone({});
            setProofLog([]);
            setExamStarted(false);
            console.log(`MAURIMESH_STORE_FORWARD_PROOF | EXAM_REJECTED_RESET | packetId=${packetId}`);
          },
        },
        {
          text: "Yes, approve",
          onPress: () => {
            setApproval("APPROVED");
            console.log(`MAURIMESH_STORE_FORWARD_PROOF | EXAM_APPROVED | packetId=${packetId}`);
            Alert.alert(
              "Congratulations",
              "Store-forward proof exam approved inside the app. Archive matching logs and screenshots now."
            );
          },
        },
      ]
    );
  }

  function resetExam() {
    setPacketInput("");
    setPacketId("");
    setDone({});
    setProofLog([]);
    setExamStarted(false);
    setApproval("PENDING");
    console.log("MAURIMESH_STORE_FORWARD_PROOF | SCREEN_RESET");
  }

  function buildReport() {
    return [
      "MAURIMESH STORE-FORWARD DELAY PROOF REPORT",
      "",
      `Build marker: ${BUILD_MARKER}`,
      `Packet ID: ${packetId || "NOT_CONFIRMED"}`,
      `Exam mode: ${examMode}`,
      `Exam started: ${examStarted ? "YES" : "NO"}`,
      `Approval: ${approval}`,
      `Sequence complete: ${sequenceComplete ? "YES" : "NO"}`,
      "",
      `PHONE_A: ${roles.PHONE_A}`,
      `PHONE_B: ${roles.PHONE_B}`,
      `PHONE_C: ${roles.PHONE_C}`,
      "",
      `Expected path: ${STORE_FORWARD_PROOF.path}`,
      "",
      "Stage status:",
      ...STORE_FORWARD_STAGES.map(
        (stage, index) =>
          `${index + 1}. ${stage.id}: ${done[stage.id] ? "DONE" : "NOT_DONE"} | ${stage.role} | ${roles[stage.role]}`
      ),
      "",
      "Proof log:",
      ...(proofLog.length ? proofLog : ["NO_LOG_LINES_YET"]),
      "",
      `PASS rule: ${STORE_FORWARD_PROOF.passRule}`,
      `Truth: ${STORE_FORWARD_PROOF.truth}`,
    ].join("\n");
  }

  function copyReport() {
    const report = buildReport();

    if (Platform.OS === "web" && typeof navigator !== "undefined" && navigator.clipboard) {
      navigator.clipboard.writeText(report);
      Alert.alert("Report copied");
      return;
    }

    console.log(report);
    Alert.alert("Report printed", "Store-forward report printed to log output.");
  }

  return (
    <ScrollView style={styles.screen} contentContainerStyle={styles.content}>
      <Text style={styles.kicker}>MAURIMESH NEXT TEST</Text>
      <Text style={styles.title}>Store-Forward Delay Proof</Text>
      <Text style={styles.marker}>{BUILD_MARKER}</Text>

      <View style={styles.hero}>
        <Text style={styles.heroSmall}>NEXT MILESTONE</Text>
        <Text style={styles.heroTitle}>A06 → S10 STORE → A16 RETURNS → ACK BACK</Text>
        <Text style={styles.body}>
          This proves the relay can hold a packet during temporary receiver loss, then complete delivery after rediscovery.
        </Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Choose 3 devices</Text>

        {(["PHONE_A", "PHONE_B", "PHONE_C"] as RoleKey[]).map((role) => {
          const tone = roleTone(role);
          return (
            <View key={role} style={styles.roleBlock}>
              <Text style={[styles.roleTitle, { color: tone }]}>{roleTitle(role)}</Text>
              <View style={styles.optionRow}>
                {DEVICE_OPTIONS.map((device) => {
                  const selected = roles[role] === device;
                  const usedElsewhere = Object.entries(roles).some(
                    ([otherRole, selectedDevice]) => otherRole !== role && selectedDevice === device
                  );

                  return (
                    <TouchableOpacity
                      key={`${role}-${device}`}
                      onPress={() => chooseDevice(role, device)}
                      style={[
                        styles.deviceButton,
                        selected && { borderColor: tone, backgroundColor: `${tone}24` },
                        !selected && usedElsewhere && styles.usedDevice,
                      ]}
                    >
                      <Text style={[styles.deviceText, selected && { color: tone }]}>
                        {device}
                      </Text>
                    </TouchableOpacity>
                  );
                })}
              </View>
            </View>
          );
        })}

        <Text style={[styles.body, rolesReady ? styles.good : styles.warn]}>
          {rolesReady ? "3 unique devices selected." : "Select 3 unique devices before starting."}
        </Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Store-forward packetId</Text>
        <TextInput
          value={packetInput}
          onChangeText={setPacketInput}
          placeholder="Enter packetId or leave blank to generate"
          placeholderTextColor="rgba(255,255,255,0.42)"
          autoCapitalize="characters"
          autoCorrect={false}
          style={styles.input}
        />

        <TouchableOpacity style={styles.blueButton} onPress={confirmPacketId}>
          <Text style={styles.buttonText}>Confirm / Generate Store-Forward Packet ID</Text>
        </TouchableOpacity>

        <Text style={styles.packetText}>Locked packetId: {packetId || "NOT CONFIRMED"}</Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Proof Exam Mode</Text>

        <View style={styles.optionRow}>
          <TouchableOpacity
            onPress={() => setExamMode("MANUAL")}
            style={[styles.modeButton, examMode === "MANUAL" && styles.modeActive]}
          >
            <Text style={styles.buttonText}>Manual</Text>
          </TouchableOpacity>

          <TouchableOpacity
            onPress={() => setExamMode("GUIDED_AUTO")}
            style={[styles.modeButton, examMode === "GUIDED_AUTO" && styles.modeActiveBlue]}
          >
            <Text style={styles.buttonText}>Guided Auto</Text>
          </TouchableOpacity>
        </View>

        <Text style={styles.body}>Status: {examStarted ? "STARTED" : "NOT STARTED"} / Approval: {approval}</Text>

        <TouchableOpacity style={styles.orangeButton} onPress={startExam}>
          <Text style={styles.buttonText}>Start Store-Forward Exam</Text>
        </TouchableOpacity>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Lit-up proof buttons</Text>

        {STORE_FORWARD_STAGES.map((stage, index) => {
          const isDone = Boolean(done[stage.id]);
          const isReady = examStarted && index === currentIndex && !isDone;
          const tone = roleTone(stage.role);

          return (
            <TouchableOpacity
              key={stage.id}
              onPress={() => pressStage(index)}
              style={[
                styles.stage,
                isDone && styles.stageDone,
                isReady && { borderColor: tone, backgroundColor: `${tone}24` },
                !isDone && !isReady && styles.stageLocked,
              ]}
            >
              <View style={styles.stageTop}>
                <Text style={[styles.stageRole, { color: isReady || isDone ? tone : "#64748B" }]}>
                  {stage.role} / {roles[stage.role]}
                </Text>
                <Text style={[styles.stageState, isDone && styles.good, isReady && { color: tone }]}>
                  {isDone ? "DONE" : isReady ? "READY" : "LOCKED"}
                </Text>
              </View>

              <Text style={styles.stageTitle}>{index + 1}. {stage.title}</Text>
              <Text style={styles.body}>{stage.description}</Text>
              <Text style={styles.expected}>
                MAURIMESH_STORE_FORWARD_PROOF | {stage.role} | {roles[stage.role]} | {stage.id} | packetId={packetId || "<same_packet_id>"}
              </Text>
            </TouchableOpacity>
          );
        })}
      </View>

      {sequenceComplete ? (
        <View style={styles.worldCard}>
          <Text style={styles.worldTitle}>Congratulations</Text>
          <Text style={styles.body}>
            Store-forward sequence is complete inside the app. Lock final proof only after matching logs and screenshots.
          </Text>
        </View>
      ) : null}

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Current proof log</Text>
        <View style={styles.logBox}>
          {proofLog.length ? proofLog.map((line) => (
            <Text key={line} style={styles.logText}>{line}</Text>
          )) : <Text style={styles.logText}>No proof log yet.</Text>}
        </View>
      </View>

      <TouchableOpacity style={styles.copyButton} onPress={copyReport}>
        <Text style={styles.buttonText}>Copy Store-Forward Proof Report</Text>
      </TouchableOpacity>

      <TouchableOpacity style={styles.resetButton} onPress={resetExam}>
        <Text style={styles.resetText}>Reset Store-Forward Exam</Text>
      </TouchableOpacity>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: "#020403" },
  content: { padding: 18, paddingBottom: 46, gap: 14 },
  kicker: { color: "#38BDF8", fontWeight: "900", letterSpacing: 2, fontSize: 12 },
  title: { color: "white", fontSize: 30, fontWeight: "900" },
  marker: { color: "#F59E0B", fontSize: 11, fontWeight: "900" },
  hero: {
    borderWidth: 1,
    borderColor: "rgba(56,189,248,0.45)",
    backgroundColor: "rgba(56,189,248,0.12)",
    borderRadius: 22,
    padding: 16,
    gap: 8,
  },
  heroSmall: { color: "#38BDF8", fontSize: 11, fontWeight: "900", letterSpacing: 1.4 },
  heroTitle: { color: "white", fontSize: 18, fontWeight: "900" },
  card: {
    borderWidth: 1,
    borderColor: "rgba(56,189,248,0.28)",
    backgroundColor: "rgba(2,12,20,0.88)",
    borderRadius: 22,
    padding: 16,
    gap: 12,
  },
  cardTitle: { color: "white", fontSize: 18, fontWeight: "900" },
  body: { color: "rgba(255,255,255,0.78)", lineHeight: 21 },
  roleBlock: {
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.12)",
    borderRadius: 16,
    padding: 12,
    gap: 10,
    backgroundColor: "rgba(255,255,255,0.04)",
  },
  roleTitle: { fontWeight: "900", fontSize: 15 },
  optionRow: { flexDirection: "row", gap: 8, flexWrap: "wrap" },
  deviceButton: {
    minWidth: 74,
    minHeight: 42,
    borderRadius: 14,
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.18)",
    backgroundColor: "rgba(255,255,255,0.06)",
    alignItems: "center",
    justifyContent: "center",
    paddingHorizontal: 12,
  },
  usedDevice: { opacity: 0.42 },
  deviceText: { color: "white", fontWeight: "900" },
  input: {
    minHeight: 54,
    borderRadius: 16,
    borderWidth: 1,
    borderColor: "rgba(56,189,248,0.45)",
    backgroundColor: "rgba(0,0,0,0.35)",
    color: "white",
    paddingHorizontal: 14,
    fontSize: 15,
    fontWeight: "900",
  },
  packetText: { color: "#38BDF8", fontWeight: "900" },
  blueButton: {
    minHeight: 52,
    borderRadius: 16,
    backgroundColor: "#38BDF8",
    alignItems: "center",
    justifyContent: "center",
    paddingHorizontal: 14,
  },
  orangeButton: {
    minHeight: 52,
    borderRadius: 16,
    backgroundColor: "#F59E0B",
    alignItems: "center",
    justifyContent: "center",
    paddingHorizontal: 14,
  },
  modeButton: {
    flex: 1,
    minWidth: 130,
    minHeight: 48,
    borderRadius: 16,
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.18)",
    backgroundColor: "rgba(255,255,255,0.06)",
    alignItems: "center",
    justifyContent: "center",
  },
  modeActive: {
    borderColor: "#00D084",
    backgroundColor: "rgba(0,208,132,0.18)",
  },
  modeActiveBlue: {
    borderColor: "#38BDF8",
    backgroundColor: "rgba(56,189,248,0.18)",
  },
  buttonText: { color: "white", fontWeight: "900", fontSize: 15 },
  stage: {
    borderWidth: 1,
    borderRadius: 18,
    padding: 14,
    gap: 8,
  },
  stageDone: {
    borderColor: "#22C55E",
    backgroundColor: "rgba(34,197,94,0.16)",
  },
  stageLocked: {
    borderColor: "rgba(100,116,139,0.35)",
    backgroundColor: "rgba(100,116,139,0.08)",
  },
  stageTop: { flexDirection: "row", justifyContent: "space-between", gap: 8 },
  stageRole: { flex: 1, fontSize: 11, fontWeight: "900", letterSpacing: 1.1 },
  stageState: { fontSize: 10, fontWeight: "900" },
  stageTitle: { color: "white", fontSize: 16, fontWeight: "900" },
  expected: { color: "rgba(255,255,255,0.52)", fontSize: 11, lineHeight: 16 },
  good: { color: "#22C55E" },
  warn: { color: "#F59E0B" },
  worldCard: {
    borderWidth: 1,
    borderColor: "#FACC15",
    backgroundColor: "rgba(250,204,21,0.12)",
    borderRadius: 22,
    padding: 16,
    gap: 8,
  },
  worldTitle: { color: "#FACC15", fontSize: 22, fontWeight: "900" },
  logBox: {
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.14)",
    backgroundColor: "rgba(0,0,0,0.35)",
    borderRadius: 16,
    padding: 12,
    gap: 5,
  },
  logText: { color: "rgba(255,255,255,0.78)", fontSize: 11, lineHeight: 17 },
  copyButton: {
    minHeight: 56,
    borderRadius: 18,
    backgroundColor: "#00D084",
    alignItems: "center",
    justifyContent: "center",
    paddingHorizontal: 18,
  },
  resetButton: {
    minHeight: 52,
    borderRadius: 18,
    borderWidth: 1,
    borderColor: "rgba(239,68,68,0.5)",
    backgroundColor: "rgba(239,68,68,0.12)",
    alignItems: "center",
    justifyContent: "center",
    paddingHorizontal: 18,
  },
  resetText: { color: "#FCA5A5", fontSize: 15, fontWeight: "900" },
});
