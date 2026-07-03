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

type RoleKey = "PHONE_A" | "PHONE_B" | "PHONE_C";
type DeviceName = "A06" | "S10" | "A16";
type ExamMode = "MANUAL" | "GUIDED_AUTO";
type Approval = "PENDING" | "APPROVED" | "REJECTED";

type Stage = {
  id: string;
  role: RoleKey;
  title: string;
  description: string;
};

const BUILD_MARKER = "SAFE_3_DEVICE_SCREEN_20260612";

const DEVICE_OPTIONS: DeviceName[] = ["A06", "S10", "A16"];

const STAGES: Stage[] = [
  {
    id: "PACKET_ID_GENERATED",
    role: "PHONE_A",
    title: "Generate / Confirm Packet ID",
    description: "PHONE_A locks the proof packet identity.",
  },
  {
    id: "TX_A06_TO_S10",
    role: "PHONE_A",
    title: "A06 TX -> S10",
    description: "Sender transmits packet toward relay.",
  },
  {
    id: "RX_S10_FROM_A06",
    role: "PHONE_B",
    title: "S10 RX from A06",
    description: "Relay receives packet from sender.",
  },
  {
    id: "RELAY_S10_TO_A16",
    role: "PHONE_B",
    title: "S10 Relay -> A16",
    description: "Relay forwards packet to receiver.",
  },
  {
    id: "RX_A16_FROM_S10",
    role: "PHONE_C",
    title: "A16 RX from S10",
    description: "Receiver gets packet from relay.",
  },
  {
    id: "ACK_A16_TO_S10",
    role: "PHONE_C",
    title: "A16 ACK -> S10",
    description: "Receiver returns ACK to relay.",
  },
  {
    id: "ACK_RELAY_S10_TO_A06",
    role: "PHONE_B",
    title: "S10 ACK Relay -> A06",
    description: "Relay returns ACK to sender.",
  },
  {
    id: "ACK_RECEIVED_A06",
    role: "PHONE_A",
    title: "A06 ACK Received",
    description: "Sender confirms ACK returned through full path.",
  },
];

function makePacketId() {
  const alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
  let left = "";
  let right = "";

  for (let i = 0; i < 6; i += 1) {
    left += alphabet[Math.floor(Math.random() * alphabet.length)];
    right += alphabet[Math.floor(Math.random() * alphabet.length)];
  }

  return `MM3-${left}-${right}`;
}

function roleTone(role: RoleKey) {
  if (role === "PHONE_A") return "#00D084";
  if (role === "PHONE_B") return "#38BDF8";
  return "#F59E0B";
}

function roleTitle(role: RoleKey) {
  if (role === "PHONE_A") return "PHONE_A / Sender";
  if (role === "PHONE_B") return "PHONE_B / Relay";
  return "PHONE_C / Receiver + ACK";
}

export default function Ble3DeviceProofScreen() {
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

  const uniqueDeviceCount = new Set(Object.values(roles)).size;
  const rolesReady = uniqueDeviceCount === 3;
  const doneCount = STAGES.filter((stage) => done[stage.id]).length;
  const sequenceComplete = rolesReady && packetId.length > 0 && doneCount === STAGES.length;
  const currentIndex = useMemo(() => STAGES.findIndex((stage) => !done[stage.id]), [done]);

  function proofLine(role: RoleKey, stageId: string, activePacketId: string, message: string) {
    const line =
      `${new Date().toISOString()} | MAURIMESH_3_DEVICE_PROOF | ${role} | ${roles[role]} | ${stageId} | packetId=${activePacketId} | ${message}`;

    console.log(line);
    setProofLog((prev) => [...prev, line]);
    return line;
  }

  function chooseDevice(role: RoleKey, device: DeviceName) {
    setRoles((prev) => ({ ...prev, [role]: device }));
  }

  function confirmPacketId() {
    const cleaned = String(packetInput || "").trim().toUpperCase();
    const finalPacketId = cleaned || makePacketId();

    setPacketId(finalPacketId);
    setPacketInput(finalPacketId);
    setDone((prev) => ({ ...prev, PACKET_ID_GENERATED: true }));
    setApproval("PENDING");

    proofLine("PHONE_A", "PACKET_ID_GENERATED", finalPacketId, "PHONE_A packetId confirmed.");

    Alert.alert(
      "PHONE_A packetId confirmed",
      `Use this same packetId across all devices:\n\n${finalPacketId}`
    );
  }

  function startExam() {
    if (!rolesReady) {
      Alert.alert("Select 3 unique devices", "PHONE_A, PHONE_B, and PHONE_C must each use a different device.");
      return;
    }

    if (!packetId) {
      Alert.alert("Packet ID required", "Confirm or generate the PHONE_A packetId first.");
      return;
    }

    setExamStarted(true);
    setApproval("PENDING");

    console.log(
      `MAURIMESH_3_DEVICE_PROOF | EXAM_STARTED | mode=${examMode} | packetId=${packetId} | PHONE_A=${roles.PHONE_A} | PHONE_B=${roles.PHONE_B} | PHONE_C=${roles.PHONE_C}`
    );

    if (examMode === "GUIDED_AUTO") {
      Alert.alert(
        "Guided Auto Mode",
        "This completes the expected app sequence only. Real proof still needs matching logs and screenshots.",
        [
          { text: "Cancel", style: "cancel" },
          { text: "Run", onPress: runGuidedAuto },
        ]
      );
      return;
    }

    Alert.alert("Manual exam started", "Press each lit-up proof button in order.");
  }

  function runGuidedAuto() {
    const nextDone: Record<string, boolean> = {};
    const lines: string[] = [];

    STAGES.forEach((stage) => {
      nextDone[stage.id] = true;

      const line =
        `${new Date().toISOString()} | MAURIMESH_3_DEVICE_PROOF | ${stage.role} | ${roles[stage.role]} | ${stage.id} | packetId=${packetId} | GUIDED_AUTO_EXPECTED_SEQUENCE`;

      console.log(line);
      lines.push(line);
    });

    setDone(nextDone);
    setProofLog((prev) => [...prev, ...lines]);

    askApproval();
  }

  function pressStage(index: number) {
    const stage = STAGES[index];

    if (!examStarted) {
      Alert.alert("Start exam first", "Press Start Proof Exam before using the lit-up buttons.");
      return;
    }

    if (!packetId) {
      Alert.alert("Packet ID required", "Confirm PHONE_A packetId first.");
      return;
    }

    if (index !== currentIndex) {
      Alert.alert("Stage locked", "Press the lit-up READY button only.");
      return;
    }

    setDone((prev) => ({ ...prev, [stage.id]: true }));
    proofLine(stage.role, stage.id, packetId, stage.title);

    if (index === STAGES.length - 1) {
      askApproval();
    } else {
      Alert.alert("Stage complete", `${stage.title}\n\nContinue to the next lit-up button.`);
    }
  }

  function askApproval() {
    Alert.alert(
      "Approve proof exam?",
      "Approve only if screenshots and logcat show this same packetId across PHONE_A, PHONE_B, and PHONE_C.",
      [
        {
          text: "No, reset",
          style: "destructive",
          onPress: () => {
            setApproval("REJECTED");
            setDone({});
            setProofLog([]);
            setExamStarted(false);
            console.log(`MAURIMESH_3_DEVICE_PROOF | EXAM_REJECTED_RESET | packetId=${packetId}`);
          },
        },
        {
          text: "Yes, approve",
          onPress: () => {
            setApproval("APPROVED");
            console.log(`MAURIMESH_3_DEVICE_PROOF | EXAM_APPROVED | packetId=${packetId}`);
            Alert.alert(
              "Congratulations",
              "3-device proof exam approved inside the app. Archive matching logs and screenshots now."
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
    console.log("MAURIMESH_3_DEVICE_PROOF | SCREEN_RESET");
  }

  function buildReport() {
    return [
      "MAURIMESH 3-DEVICE HOP PROOF REPORT",
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
      "Expected path:",
      `${roles.PHONE_A} -> ${roles.PHONE_B} -> ${roles.PHONE_C} -> ${roles.PHONE_B} -> ${roles.PHONE_A} ACK`,
      "",
      "Stage status:",
      ...STAGES.map((stage, index) => `${index + 1}. ${stage.id}: ${done[stage.id] ? "DONE" : "NOT_DONE"} | ${stage.role} | ${roles[stage.role]}`),
      "",
      "Proof log:",
      ...(proofLog.length ? proofLog : ["NO_LOG_LINES_YET"]),
      "",
      "Truth rule:",
      "Real PASS is valid only when matching logs and screenshots show the same packetId across all selected devices.",
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
    Alert.alert("Report printed", "Proof report printed to log output.");
  }

  return (
    <ScrollView style={styles.screen} contentContainerStyle={styles.content}>
      <Text style={styles.kicker}>MAURIMESH PROOF MODE</Text>
      <Text style={styles.title}>3-Device Hop Proof</Text>
      <Text style={styles.marker}>{BUILD_MARKER}</Text>

      <View style={styles.hero}>
        <Text style={styles.heroSmall}>MILESTONE</Text>
        <Text style={styles.heroTitle}>
          {roles.PHONE_A} → {roles.PHONE_B} → {roles.PHONE_C} → {roles.PHONE_B} → {roles.PHONE_A} ACK
        </Text>
        <Text style={styles.body}>
          Real proof is valid only when logs and screenshots show the same packetId across every stage.
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
        <Text style={styles.cardTitle}>PHONE_A packetId</Text>
        <TextInput
          value={packetInput}
          onChangeText={setPacketInput}
          placeholder="Enter PHONE_A packetId or leave blank to generate"
          placeholderTextColor="rgba(255,255,255,0.42)"
          autoCapitalize="characters"
          autoCorrect={false}
          style={styles.input}
        />

        <TouchableOpacity style={styles.blueButton} onPress={confirmPacketId}>
          <Text style={styles.buttonText}>Confirm / Generate PHONE_A Packet ID</Text>
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
          <Text style={styles.buttonText}>Start Proof Exam</Text>
        </TouchableOpacity>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Lit-up proof buttons</Text>

        {STAGES.map((stage, index) => {
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
                MAURIMESH_3_DEVICE_PROOF | {stage.role} | {roles[stage.role]} | {stage.id} | packetId={packetId || "<same_packet_id>"}
              </Text>
            </TouchableOpacity>
          );
        })}
      </View>

      {sequenceComplete ? (
        <View style={styles.worldCard}>
          <Text style={styles.worldTitle}>Congratulations</Text>
          <Text style={styles.body}>
            3-device proof sequence is complete inside the app. Lock final proof only after matching logs and screenshots.
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
        <Text style={styles.buttonText}>Copy Full 3-Device Proof Report</Text>
      </TouchableOpacity>

      <TouchableOpacity style={styles.resetButton} onPress={resetExam}>
        <Text style={styles.resetText}>Reset Proof Exam</Text>
      </TouchableOpacity>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: "#020403" },
  content: { padding: 18, paddingBottom: 46, gap: 14 },
  kicker: { color: "#00D084", fontWeight: "900", letterSpacing: 2, fontSize: 12 },
  title: { color: "white", fontSize: 32, fontWeight: "900" },
  marker: { color: "#F59E0B", fontSize: 11, fontWeight: "900" },
  hero: {
    borderWidth: 1,
    borderColor: "rgba(0,208,132,0.45)",
    backgroundColor: "rgba(0,208,132,0.12)",
    borderRadius: 22,
    padding: 16,
    gap: 8,
  },
  heroSmall: { color: "#00D084", fontSize: 11, fontWeight: "900", letterSpacing: 1.4 },
  heroTitle: { color: "white", fontSize: 18, fontWeight: "900" },
  card: {
    borderWidth: 1,
    borderColor: "rgba(0,208,132,0.28)",
    backgroundColor: "rgba(0,20,12,0.88)",
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
  usedDevice: {
    opacity: 0.42,
  },
  deviceText: { color: "white", fontWeight: "900" },
  input: {
    minHeight: 54,
    borderRadius: 16,
    borderWidth: 1,
    borderColor: "rgba(0,208,132,0.45)",
    backgroundColor: "rgba(0,0,0,0.35)",
    color: "white",
    paddingHorizontal: 14,
    fontSize: 15,
    fontWeight: "900",
  },
  packetText: { color: "#00D084", fontWeight: "900" },
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
